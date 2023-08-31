#charset "us-ascii"
//
// simpleRandomMapBraid.t
//
#include <adv3.h>
#include <en_us.h>

#include "simpleRandomMap.h"

#ifdef SIMPLE_RANDOM_MAP

// A braided map generator.
// "Braided" in this context means that there are no dead ends.  To
// Accomplish this, we just use build a list of dead ends and then
// loop through them, adding an additional exit to each.
class SimpleRandomMapGeneratorBraid: SimpleRandomMapGeneratorRB
	_dirs = static [ simpleRandomMapNorth, simpleRandomMapSouth,
		simpleRandomMapEast, simpleRandomMapWest ]

	// Replacement map builder.
	_buildMap() {
		local deadEnds, v;

		// First, we build the map the same way our base class would.
		inherited();

		// Next we get a list of all the dead ends.
		// If we have none(!) we have nothing to do, so we return.
		// Should never happen.
		if((deadEnds = listDeadEnds()) == nil)
			return;

		// We have dead ends, so we loop through them.
		deadEnds.forEach(function(rm) {
			// First, make sure we're still a dead end.  We do
			// this because we might be looking at the end of
			// the list, and a room that started out as a dead
			// end might no longer be one because it got connected
			// to a different former dead end that occurred earlier
			// in the list.
			if(isDeadEnd(rm) != true)
				return;

			// Get a random neighbor, it CAN be "used" (second
			// arg) but it CANNOT be connected to the room already
			// (third arg).
			if((v = getRandomNeighbor(rm, true, true)) == nil) {
				return;
			}

			// Connect the room to its neighbor.  Poof, a dead
			// end no more.
			_connectRoomObjs(rm, v.room, v.dir);
		});
	}
;

#endif // SIMPLE_RANDOM_MAP
