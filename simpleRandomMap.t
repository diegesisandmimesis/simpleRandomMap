#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

// Module ID for the library
simpleRandomMapModuleID: ModuleID {
        name = 'Simple Random Map Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// Base class for our rooms.
// We provide a default description in the assumption that most uses for
// this module will be testing, and a stock description will be sufficient.
class SimpleRandomMapRoom: Room desc = "This is a simple random room. ";

class SimpleRandomMapGenerator: object
	_mapWidth = nil		// length of a side of the map
	_mapSize = nil		// total number of rooms in the map

	_rooms = perInstance(new LookupTable)

	construct(n?) {
		_mapWidth = ((n != nil) ? n : 10);
		_mapSize = _mapWidth * _mapWidth;
	}

	preinit() {
		_createRooms();
		_buildMap();
		gameMain.initialPlayerChar.location = _getRoom(1);
	}

	_createRooms() {
		local i, id, rm;

		i = 1;
		while(i <= _mapSize) {
			id = 'room' + toString(i);
			rm = new SimpleRandomMapRoom();
			rm.roomName = id;
			_rooms[i] = rm;
			i += 1;
		}
	}

	_getRoom(id) { return(_rooms[id]); }

	_buildMap() {
		local i, top;

		top = _mapSize - _mapWidth;

		// Not a typo, we don't twiddle the last room.
		for(i = 1; i < _mapSize; i++) {
			if((i % _mapWidth) == 0) {
				_connectNorth(i);
			} else if(i > top) {
				_connectEast(i);
			} else {
				if(rand(2) == 1) {
					_connectNorth(i);
				} else {
					_connectEast(i);
				}
			}
		}
	}

	_connectNorth(i) { _connectRooms(i, i + _mapWidth, 'n'); }
	_connectEast(i) { _connectRooms(i, i + 1, 'e'); }

	_connectRooms(n0, n1, dir) {
		local rm0, rm1;

		if((rm0 = _getRoom(n0)) == nil)
			return;
		if((rm1 = _getRoom(n1)) == nil)
			return;

		switch(dir) {
			case 'n':
				rm0.north = rm1;
				rm1.south = rm0;
				break;
			case 'e':
				rm0.east = rm1;
				rm1.west = rm0;
				break;
		}
	}
;
