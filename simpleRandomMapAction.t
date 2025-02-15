#charset "us-ascii"
//
// simpleRandomMapAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "simpleRandomMap.h"

#ifdef SIMPLE_RANDOM_MAP

#ifdef __DEBUG_SIMPLE_RANDOM_MAP

modify playerActionMessages
	srmNoRoom = 'Map display failed:  unable to determine current room. '
	srmBadRoom = 'Map display failed:  not in a mappable room. '
	srmNoGenerator = 'Map display failed:  unable to determine map
		generator. '
;

DefineSystemAction(SimpleRandomMap)
	execSystemAction() {
		local buf, buf0, buf1, obj, rm, rm0, v, x, y, x0, y0, x1, y1;

		if((rm = gPlayerChar.location.getOutermostRoom()) == nil) {
			reportFailure(&srmNoRoom);
			return;
		}
		if(!rm.ofKind(SimpleRandomMapRoom)
			|| (rm.simpleRandomMapID == nil)) {
			reportFailure(&srmBadRoom);
			return;
		}

		obj = rm.simpleRandomMapGenerator;

		v = rm.simpleRandomMapXY;

		if(obj.mapWidth > 10) {
			x0 = v[1] - 5;
			x1 = v[1] + 5;
			y0 = v[2] - 5;
			y1 = v[2] + 5;
			if(x0 < 1) x0 = 1;
			if(x1 > obj.mapWidth) x1 = obj.mapWidth;
			if(y0 < 1) y0 = 1;
			if(y1 > obj.mapWidth) y1 = obj.mapWidth;
		} else {
			x0 = 1;
			x1 = obj.mapWidth;
			y0 = 1;
			y1 = obj.mapWidth;
		}

		buf = new StringBuffer();
		buf0 = new StringBuffer();
		buf1 = new StringBuffer();

		if(obj.mapWidth > 10)
			buf.append('Showing (<<toString(x0)>>, <<toString(y0)>>)
				- (<<toString(x1)>>, <<toString(y1)>>)\n ');

		for(y = y1; y >= y0; y--) {
			buf0.deleteChars(0);
			buf1.deleteChars(0);
			for(x = x0; x <= x1; x++) {
				rm0 = obj.xyToRoom(x, y);

				// Top line.  We don't have diagonals, so
				// this always starts with a "blank".
				buf0.append('...');

				// The top line either contains an exit or
				// another blank.
				if(rm0.north)
					buf0.append('.|.');
				else
					buf0.append('...');

				/// The middle line.  We either have an
				// exit to the west or a blank.
				if(rm0.west)
					buf1.append('===');
				else
					buf1.append('...');

				// Figure out if this is the current room.
				if(rm == rm0)
					buf1.append('[*]');
				else
					buf1.append('[_]');
			}
			// Add padding onto the end of each line, then
			// add it to the main output buffer.
			buf0.append('...\n ');

			// Never needed if we're a single random maze,
			// but check to see if we're connected to
			// something else.
			if(rm0.east)
				buf1.append('===\n ');
			else
				buf1.append('...\n ');

			buf.append(buf0);
			buf.append(buf1);
		}

		// If we're outputting the entire map, add a "blank" line
		// at the bottom.  Purely for cosmetics.
		if(obj.mapWidth <= 10) {
			buf0.deleteChars(0);
			for(x = x0; x <= x1; x++) {
				buf0.append('...');
				rm0 = obj.xyToRoom(x, y0);
				if(rm0.south)
					buf0.append('.|.');
				else
					buf0.append('...');

				//buf0.append('......');
			}
			buf0.append('...\n ');
			buf.append(buf0);
		}

		defaultReport(toString(buf));
	}
;
VerbRule(SimpleRandomMap) 'm' : SimpleRandomMapAction verbPhrase = 'm/ming';

#endif // __DEBUG_SIMPLE_RANDOM_MAP
#endif // SIMPLE_RANDOM_MAP
