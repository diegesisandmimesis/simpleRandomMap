#charset "us-ascii"
//
// simpleRandomMapRB.t
//
#include <adv3.h>
#include <en_us.h>

#include "simpleRandomMap.h"

#ifdef SIMPLE_RANDOM_MAP

class SimpleRandomMapGeneratorRB: SimpleRandomMapGenerator
	_dirs = static [ simpleRandomMapNorth, simpleRandomMapSouth,
		simpleRandomMapEast, simpleRandomMapWest ]

	_buildMap() {
		local rm, rm0, stack;

		stack = new Vector(_mapSize);

		rm = _getRoom(1);
		stack.appendUnique(rm);
		while(rm != nil) {
			if((rm0 = _nextRoom(rm)) == nil) {
				stack.removeElement(rm);
			} else {
				stack.appendUnique(rm0);
			}
			if(stack.length == 0)
				rm = nil;
			else
				rm = stack[stack.length];
		}
	}
	_nextRoom(rm) {
		local dirs, idx, r, rm0;

		if((rm == nil) || !rm.ofKind(SimpleRandomMapRoom))
			return(nil);

		dirs = new Vector(4);

		_dirs.forEach(function(o) {
			if((rm0 = getNeighbor(rm, o)) == nil)
				return;
			if(rm0.simpleRandomMapFlag == true)
				return;
			dirs.append([o, rm0]);
		});

		if(dirs.length == 0)
			return(nil);

		idx = rand(dirs.length) + 1;

		r = dirs[idx];

		_connectRoomObjs(rm, r[2], r[1]);

		rm.simpleRandomMapFlag = true;
		r[2].simpleRandomMapFlag = true;
		
		return(r[2]);
	}
;

#endif // SIMPLE_RANDOM_MAP
