#charset "us-ascii"
//
// simpleRandomMapAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "simpleRandomMap.h"

#ifdef SIMPLE_RANDOM_MAP

modify playerActionMessages
	srmNoRoom = 'Map display failed:  unable to determine current room. '
	srmBadRoom = 'Map display failed:  not in a mappable room. '
	srmNoGenerator = 'Map display failed:  unable to determine map
		generator. '
;

DefineSystemAction(Srm)
	execSystemAction() {
		local buf, obj, rm, rm0, v, x, y, x0, y0, x1, y1;

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
		if(x1 > obj.mapWidth) x0 = obj.mapWidth;
		if(y0 < 1) y0 = 1;
		if(y1 > obj.mapWidth) y1 = obj.mapWidth;

		buf = new StringBuffer();

		for(y = y1; y >= y0; y--) {
			for(x = x0; x <= x1; x++) {
				rm0 = obj.xyToRoom(x, y);
				buf.append('<<toString(rm0.simpleRandomMapID)>> ');
			}
			buf.append('\n ');
		}

		defaultReport(toString(buf));
	}
;
VerbRule(Srm) 'srm' : SrmAction verbPhrase = 'srm/srming';

#endif // SIMPLE_RANDOM_MAP
