#charset "us-ascii"
//
// simpleRandomMapRB.t
//
#include <adv3.h>
#include <en_us.h>

#include "simpleRandomMap.h"

#ifdef SIMPLE_RANDOM_MAP

// A recursive backtracking/depth first generator.
// The default generator will tend to produce maps with a lot of short-ish
// dead ends and few long dead ends.  This generator should do the opposite:
// long dead ends, but fewer of them.
class SimpleRandomMapGeneratorRB: SimpleRandomMapGenerator
	// Unlike the base generator, at any "step" me might want to dig
	// an exit in any direction (where "any" means the four non-diagonal
	// compass directions).
	_dirs = static [ simpleRandomMapNorth, simpleRandomMapSouth,
		simpleRandomMapEast, simpleRandomMapWest ]

	// Replacement map builder.
	// We start out with the starting room, setting it as the current
	// room and pushing it onto a stack.  Then as long as we have any
	// rooms in the stack, we look at the last room on the stack,
	// pick a random neighboring room that isn't already "added" to
	// the map, add it to the map (digging the appropriate reciprocal
	// exits) and add IT to the stack, and repeat.
	// When we can't add another exit to whatever current room we
	// have (because there are no remaining valid neighbors), we
	// remove it from the stack.
	// When the stack is empty, we're done.
	_buildMap() {
		local rm, rm0, stack;

		// Worst case stack size is the size of the map.
		stack = new Vector(_mapSize);

		// Pick our starting room, add it to the stack.
		rm = _getRoom(1);
		stack.appendUnique(rm);

		// Loop while we have a valid room.
		while(rm != nil) {
			// We try to pick a random neighbor from the
			// current room.
			if((rm0 = _nextRoom(rm)) == nil) {
				// If there are no valid neighbors to pick,
				// remove the current room from the stack.
				stack.removeElement(rm);
			} else {
				// Otherwise, we add the newly-picked neighbor
				// to the stack.
				stack.appendUnique(rm0);
			}
			// If our stack length is zero, we're done.  Otherwise
			// we pick the top of the stack, set it as the current
			// room, and iterate.
			if(stack.length == 0)
				rm = nil;
			else
				rm = stack[stack.length];
		}
	}

	// Pick a valid neighbor from the given room.
	_nextRoom(rm) {
		local dirs, idx, r, rm0;

		// Make sure we have a valid room.
		if((rm == nil) || !rm.ofKind(SimpleRandomMapRoom))
			return(nil);

		// Make an empty vector to hold our options.
		dirs = new Vector(4);

		// Go through all possible directions, check to see
		// if the neighbor in that direction is valid.
		_dirs.forEach(function(o) {
			// Nope, no neighbor.
			if((rm0 = getNeighbor(rm, o)) == nil)
				return;

			// Got a neighbor, but it's already used.
			if(rm0.simpleRandomMapFlag == true)
				return;

			// Looks good, remember the direction and room.
			dirs.append([o, rm0]);
		});

		// No options, bail.
		if(dirs.length == 0)
			return(nil);

		// Pick a random option.
		idx = rand(dirs.length) + 1;
		r = dirs[idx];

		// Connect the original room to the neighbor in the appropriate
		// direction.
		_connectRoomObjs(rm, r[2], r[1]);

		// Mark the rooms as used.
		rm.simpleRandomMapFlag = true;
		r[2].simpleRandomMapFlag = true;
		
		// Return the neighbor.
		return(r[2]);
	}
;

#endif // SIMPLE_RANDOM_MAP
