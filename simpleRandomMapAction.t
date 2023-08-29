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
		local buf, buf0, buf1, buf2, obj, rm, rm0, v, x, y, x0, y0, x1, y1;

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
		x0 = v[1] - 2;
		x1 = v[1] + 2;
		y0 = v[2] - 2;
		y1 = v[2] + 2;
		if(x0 < 1) x0 = 1;
		if(x1 > obj.mapWidth) x1 = obj.mapWidth;
		if(y0 < 1) y0 = 1;
		if(y1 > obj.mapWidth) y1 = obj.mapWidth;

		buf = new StringBuffer();
		buf0 = new StringBuffer();
		buf1 = new StringBuffer();
		buf2 = new StringBuffer();

		buf.append('Showing (<<toString(x0)>>, <<toString(y0)>>) - (<<toString(x1)>>, <<toString(y1)>>)\n ');

		for(y = y1; y >= y0; y--) {
			buf0.deleteChars(1);
			buf1.deleteChars(1);
			buf2.deleteChars(1);
			for(x = x0; x <= x1; x++) {
				rm0 = obj.xyToRoom(x, y);
				buf0.append('...');
				if(rm0.north)
					buf0.append('.|.');
				else
					buf0.append('...');
				buf0.append('...');
				if(rm0.west)
					buf1.append('===');
				else
					buf1.append('...');
				//buf1.append('<<toString(rm0.simpleRandomMapID)>> ');
				if(rm == rm0)
					buf1.append('***');
				else
					buf1.append('###');
				if(rm0.east)
					buf1.append('===');
				else
					buf1.append('...');
				buf2.append('...');
				if(rm0.south)
					buf2.append('.|.');
				else
					buf2.append('...');
				buf2.append('...');
			}
			buf0.append('\n ');
			buf1.append('\n ');
			buf2.append('\n ');
			buf.append(buf0);
			buf.append(buf1);
			buf.append(buf2);
		}

		defaultReport(toString(buf));
	}
;
VerbRule(SimpleRandomMap) 'm' : SimpleRandomMapAction verbPhrase = 'm/ming';

#endif // __DEBUG_SIMPLE_RANDOM_MAP
#endif // SIMPLE_RANDOM_MAP
