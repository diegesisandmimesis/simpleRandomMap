#charset "us-ascii"
//
// simpleRandomMap.t
//
//	A TADS3 module for producing simple random maps.
//
//
//	BASIC USAGE
//
//	Generation is automatic and self-contained, so the only source
//	modification that's required is the addition of a declared
//	instance of the SimpleRandomMapGenerator class.  Example usage:
//
//		myMap: SimpleRandomMapGenerator;
//
//	This will create a random 10x10 map and place the player (as defined
//	by gameMain.initialPlayerChar) to the first room in the generated
//	map.
//
//	Configurable properties and defaults:
//
//		mapWidth = 10		// make a 10x10 map
//		placePlayer = true	// place the player in the generated map
//		player = gameMain.initialPlayerChar	// player to move
//
//
//	The rooms will have generic descriptions and names that indicate
//	their room number.  Rooms are numbered from west to east, south to
//	north.  So the default room arrangement (for a 10x10 map) is:
//
//		91	92	93	...	99	100
//		81	82	83	...	89	90
//
//		...					...
//
//		11	12	13	...	19	20
//		 1	 2	 3	...	 9	10
//
//	By default the player is placed in the first room.  All rooms are
//	guaranteed to be connected (so a path exists between any two
//	rooms picked at random), but the exact path will be random(-ish).
//
//	This is intended to make it easy to implement test cases for
//	pathfinding, NPC scripting, and so on.
//
//	It WILL NOT produce maps suitable for direct inclusion in playable
// 	games.
//
//
//	COMPILER FLAGS
//
//	These flags control what module features are compiled in.  The
//	can be specified via -D [option] on the command line or
//	in your project's makefile.
//
//		SIMPLE_RANDOM_MAP
//			Toggles the entire module.  Compile with this flag
//			to enable the module, compile without it to disable
//			everything.
//
//		SIMPLE_RANDOM_MAP_WIDTH=x
//			Uses x as the default width for all map types.  Note
//			that this WILL NOT override an explicit mapWidth
//			declared on an instance.  It just changes the default
//			value.
//
//		SIMPLE_RANDOM_MAP_GRID
//			If set, instead of generating random exits for each
//			room, every room will get exits in ALL of the four main
//			compass directions (N, S, E, W) except at the edges of
//			the map.
//
//		__DEBUG_SIMPLE_RANDOM_MAP
//			Enables debugging options, notably the debugging
//			commands discussed in the next section.
//
//	
//	DEBUGGING COMMANDS
//
//	The following commands are available if the module is compiled
//	with -D __DEBUG_SIMPLE_RANDOM_MAP.
//
//		M		Displays a simple ASCII map of the map
//				around the player.
//	
//
#include <adv3.h>
#include <en_us.h>

#include "simpleRandomMap.h"

#ifdef SIMPLE_RANDOM_MAP

// Module ID for the library
simpleRandomMapModuleID: ModuleID {
        name = 'Simple Random Map Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

simpleRandomMapInitializer: PreinitObject
	execute() {
		forEachInstance(SimpleRandomMapGenerator, function(obj) {
			obj.preinit();
		});
	}
;

// Base class for our rooms.
// We provide a default description in the assumption that most uses for
// this module will be testing, and a stock description will be sufficient.
class SimpleRandomMapRoom: Room
	desc = "This is a simple random room.  Its coordinates
		are <<getCoords()>>. "

	// Numeric room ID.  Used to make it easier to look things up.
	simpleRandomMapID = nil

	// A 2-element array containing the X and Y coordinates of the
	// room, with [ 1, 1 ] being room 1 in the southwest and
	// [ mapWidth, mapWidth ] being room (_mapSize) in the northeast.
	simpleRandomMapXY = nil

	// A reference to the generator that created the room instance.
	simpleRandomMapGenerator = nil

	// Flag used by some generators to indicate whether or not
	// this room has been added to the map yet or not.
	simpleRandomMapFlag = nil

	// Returns the coordinates of this room as a text string.
	getCoords() {
		return('( <<toString(simpleRandomMapXY[1])>>,
			<<toString(simpleRandomMapXY[2])>> )');
	}
;

enum simpleRandomMapNorth, simpleRandomMapSouth, simpleRandomMapEast,
	simpleRandomMapWest;

// Simple data structure for holding information about map neighbors.
class SimpleRandomMapNeighbor: object
	room = nil
	dir = nil
	construct(rm?, d?) {
		room = rm;
		dir = d;
	}
;

class SimpleRandomMapGenerator: object
	// The generated maps are always square.  mapWidth determines
	// how many rooms wide and high the square is.
#ifdef SIMPLE_RANDOM_MAP_WIDTH
	mapWidth = SIMPLE_RANDOM_MAP_WIDTH
#else // SIMPLE_RANDOM_MAP_WIDTH
	mapWidth = 10
#endif // SIMPLE_RANDOM_MAP_WIDTH

	// Boolean flag indicating whether or not the player should be
	// moved to the first room of the map as part of the map generation
	// process.
	movePlayer = true

	// Object to use as the player.  Only used if movePlayer is true.
	player = gameMain.initialPlayerChar

	roomClass = SimpleRandomMapRoom
	roomBaseName = 'room'

	firstRoom() { return(_rooms[1]); }
	lastRoom() { return(_rooms[_mapSize]); }

	beforeFirst = nil
	afterLast = nil

	// The computed map size.
	_mapSize = nil

	// Table to hold the generated rooms.
	_rooms = perInstance(new LookupTable)

	// The base generator only generates exits in two directions,
	// but we define this because other generators pick random directions
	// from any of the four non-diagonal compass directions.
	_dirs = static [ simpleRandomMapNorth, simpleRandomMapSouth,
		simpleRandomMapEast, simpleRandomMapWest ]

	// Constructor.
	// The optional arg is the map width.
	construct(n?) { if(n != nil) mapWidth = n; }

	// Compute the total map size.
	_checkDefaults() {
		_mapSize = mapWidth * mapWidth;
		return(true);
	}

	// Preinit method.  This is where we do everything we need to do.
	// Called by the PreinitObject.
	preinit() {
		// Validate our configuration.
		if(_checkDefaults() != true)
			return;

		// Create the room objects.
		_createRooms();

		// Build the map by connecting the rooms.
		_buildMap();

		// If we've been asked to move the player into the
		// map we just generated, do so now.
		if(movePlayer == true)
			player.baseMoveInto(_getRoom(1));

		if(beforeFirst) {
			beforeFirst.north = _rooms[1];
			_rooms[1].south = beforeFirst;
		}

		if(afterLast) {
			afterLast.south = _rooms[_mapSize];
			_rooms[_mapSize] = afterLast.south;
		}
	}

	// Create the room objects, saving them to the lookup table.
	_createRooms() {
		local i, id, rm, x, y;

		x = 0;
		y = 0;
		for(i = 1; i <= _mapSize; i++) {
			// The room name is just "room" plus a number.
			id = roomBaseName + toString(i);

			// Create a new room instance.
			rm = roomClass.createInstance();

			// Make the name the ID we generated above.
			rm.roomName = id;

			// Remember the room number, to make it easier to
			// look up later.
			rm.simpleRandomMapID = i;
			
			// Increment the x coordinate.
			x += 1;

			// Check to see if we just wrapped around to start
			// a new row.
			if(!((x - 1) % (mapWidth ))) {
				x = 1;
				y += 1;
			}

			// Remember our coordinates.
			rm.simpleRandomMapXY = [ x, y ];

			// Make a note of the generator that created this
			// instance.
			rm.simpleRandomMapGenerator = self;

			// Add this room to the hash table.
			_rooms[i] = rm;
		}
	}

	// Gets a room from the lookup table.  Arg is the room number.
	_getRoom(id) { return(_rooms[id]); }

	// Build the map.  In this case that means connecting the rooms
	// we previously generated.
	// We use a very simple algorithm that guarantees a path between
	// the first room (which will be the southwest corner of the map)
	// and the highest-numbered room (which will be the northeast corner
	// of the map).
	// For each room we add exactly one exit.  If we're in a room along
	// the east edge of the map we add an exit to the north.  If we're
	// in a room along the north edge of the map we add an exit to the
	// east.  In all other rooms we flip a coin and add an exit either
	// to the north or east depending on the outcome.  All exits are
	// reciprocal, so if we add an exit to the east from one room,
	// then the room to the east will also get an exit to the west
	// to the first room.
	_buildMap() {
		local i, top;

		// Room numbers increase from west to east, south to north.
		// So room 1 is in the southwest and the room number of the
		// room in the northeast is (_mapSize).  The map's square,
		// so all the rooms along the north edge of the map have
		// room numbers greater than (_mapSize - mapWidth).
		top = _mapSize - mapWidth;

		// Not a typo, we don't twiddle the last room.
		for(i = 1; i < _mapSize; i++) {
			if((i % mapWidth) == 0) {
				// Room is on the east edge, connect north.
				_connectNorth(i);
			} else if(i > top) {
				// Room is on the north edge, connect east.
				_connectEast(i);
			} else {
#ifdef SIMPLE_RANDOM_MAP_GRID
				// If we were compiled with the "grid" flag,
				// generate an exit north AND east.
				_connectNorth(i);
				_connectEast(i);
#else // SIMPLE_RANDOM_MAP_GRID
				// Room is not on the north or east edge, flip
				// a coin.
				if(rand(2) == 1) {
					_connectNorth(i);
				} else {
					_connectEast(i);
				}
#endif // SIMPLE_RANDOM_MAP_GRID
			}
		}
	}

	// Convenience methods for connecting rooms in a given direction.
	_connectNorth(i) {
		_connectRooms(i, i + mapWidth, simpleRandomMapNorth);
	 }

	_connectEast(i) {
		_connectRooms(i, i + 1, simpleRandomMapEast);
	}

	// Connect room n0 to room n1 by adding an exit in the given direction,
	// also creating the reciprocal path from n1 back to n0.
	// n0 and n1 are room numbers and dir is from the enum declared earlier
	// in this file.
	_connectRooms(n0, n1, dir) {
		local rm0, rm1;

		// Make sure both rooms exist.
		if((rm0 = _getRoom(n0)) == nil)
			return;
		if((rm1 = _getRoom(n1)) == nil)
			return;

		_connectRoomObjs(rm0, rm1, dir);
	}

	_connectRoomObjs(rm0, rm1, dir) {
		switch(dir) {
			case simpleRandomMapNorth:
				rm0.north = rm1;
				rm1.south = rm0;
				break;
			case simpleRandomMapSouth:
				rm0.south = rm1;
				rm1.north = rm0;
				break;
			case simpleRandomMapEast:
				rm0.east = rm1;
				rm1.west = rm0;
				break;
			case simpleRandomMapWest:
				rm0.west = rm1;
				rm1.east = rm0;
				break;
		}
	}

	// Returns the room with the given coordinates, if it exists.
	xyToRoom(x, y) { return(_getRoom(((y - 1) * mapWidth) + x)); }

	// Get the neighboring room in the given direction.
	getNeighbor(rm, dir) {
		local offX, offY, x, y;

		if((rm == nil) || !rm.ofKind(SimpleRandomMapRoom))
			return(nil);

		x = rm.simpleRandomMapXY[1];
		y = rm.simpleRandomMapXY[2];

		offX = 0;
		offY = 0;

		switch(dir) {
			case simpleRandomMapNorth:
				if(y >= mapWidth)
					return(nil);
				offY = 1;
				break;
			case simpleRandomMapSouth:
				if(y <= 1)
					return(nil);
				offY = -1;
				break;
			case simpleRandomMapEast:
				if(x >= mapWidth)
					return(nil);
				offX = 1;
				break;
			case simpleRandomMapWest:
				if(x <= 1)
					return(nil);
				offX = -1;
				break;
		}

		return(xyToRoom(x + offX, y + offY));
	}

	// Returns an array of all the von Neumann neighbors of the given room.
	// Each element of the array is a 2-element array containing
	// the neighboring room and its direction (from the enum)
	// indicating its position relative to the original room
	getNeighbors(rm, allowUsed?) {
		local neighbors, rm0;

		// Make sure we have a valid room.
		if((rm == nil) || !rm.ofKind(SimpleRandomMapRoom))
			return(nil);

		// Make an empty vector to hold our options.
		neighbors = new Vector(4);

		// Go through all possible directions, check to see
		// if the neighbor in that direction is valid.
		_dirs.forEach(function(o) {
			// Nope, no neighbor.
			if((rm0 = getNeighbor(rm, o)) == nil)
				return;

			// Got a neighbor, but it's already used.
			if(!allowUsed && (rm0.simpleRandomMapFlag == true))
				return;

			// Looks good, remember the direction and room.
			neighbors.append(new SimpleRandomMapNeighbor(rm0, o));
		});

		// No options, bail.
		if(neighbors.length == 0)
			return(nil);

		return(neighbors);
	}

	// Pick a random (unused) von Neumann neighbor for the given room.
	// Returns an instance of the SimpleRandomMapNeighbor class.
	getRandomNeighbor(rm, allowUsed?, skipConnected?) {
		local conn, l;

		// Make sure we have valid neighbors.
		if((l = getNeighbors(rm, allowUsed)) == nil)
			return(nil);

		// If we don't care whether or not the neighbors are
		// currently connected, we're done.
		if(skipConnected != true)
			return(l[rand(l.length) + 1]);

		// This shouldn't happen, but this says that none of
		// our neighbors are connected.  That means that none
		// of the neighbors above are disqualified, so...punt.
		if((conn = getConnectedNeighbors(rm)) == nil)
			return(l[rand(l.length) + 1]);

		// Now go through our list of connected neighbors and
		// remove them from our list of ALL neighbors.
		conn.forEach(function(rm0) {
			local v;

			if((v = l.valWhich({x: x.room == rm0.room})) == nil)
				return;
			l.removeElement(v);
		});

		// If we removed all the neighbors, return nil instead
		// of an empty list.
		if(l.length == 0)
			return(nil);

		// Return a random remaining neighbor.
		return(l[rand(l.length) + 1]);
	}

	// Get all of the von Neumann neighbors of the given room that
	// are connected via exits.
	getConnectedNeighbors(rm) {
		local l, r;

		if((l = getNeighbors(rm, true)) == nil)
			return(nil);

		r = new Vector(l.length);

		l.forEach(function(o) {
			switch(o.dir) {
				case simpleRandomMapNorth:
					if(rm.north == o.room)
						r.append(o);
					break;
				case simpleRandomMapSouth:
					if(rm.south == o.room)
						r.append(o);
					break;
				case simpleRandomMapEast:
					if(rm.east == o.room)
						r.append(o);
					break;
				case simpleRandomMapWest:
					if(rm.west == o.room)
						r.append(o);
					break;
			}
		});

		if(r.length == 0)
			return(nil);

		return(r);
	}

	// Returns a list of dead ends.
	listDeadEnds() {
		local r;

		// Vector to hold our list.
		r = new Vector(_mapSize);

		// We just walk through the list of all the rooms, looking
		// for ones that are only have one connection.
		_rooms.forEach(function(rm) {
			// See if the room is a dead end.
			if(isDeadEnd(rm) != true)
				return;

			// If we reach this point, the room is a dead end.
			// Add it to the list.
			r.append(rm);
		});

		// Return the list.
		return(r);
	}

	// Returns boolean true iff the room is a dead end.  That is,
	// if it is connected to exactly one room.
	isDeadEnd(rm) {
		local l;

		// This should never happen;  it indicates that the
		// room isn't connected at all.  At any rate, whatever's
		// going on here isn't our problem, bail.
		if((l = getConnectedNeighbors(rm)) == nil)
			return(nil);

		// Dead ends have exactly one connected neighbor.
		return(l.length == 1);
	}
;

#endif // SIMPLE_RANDOM_MAP
