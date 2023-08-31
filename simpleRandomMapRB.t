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
		local rm, stack, v;

		// Worst case stack size is the size of the map.
		stack = new Vector(_mapSize);

		// Pick our starting room, add it to the stack.
		rm = _getRoom(1);
		stack.appendUnique(rm);

		// Loop while we have a valid room.
		while(rm != nil) {
			// Mark the room as "used".
			rm.simpleRandomMapFlag = true;

			// We try to pick a random neighbor from the
			// current room.
			if((v = getRandomNeighbor(rm)) == nil) {
				// If there are no valid neighbors to pick,
				// remove the current room from the stack.
				stack.removeElement(rm);
			} else {
				// Connect the original room to the neighbor
				// and vice versa.
				_connectRoomObjs(rm, v.room, v.dir);

				// Add the neighbor to the stack.
				stack.appendUnique(v.room);
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
;

#endif // SIMPLE_RANDOM_MAP
