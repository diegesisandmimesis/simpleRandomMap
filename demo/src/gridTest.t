#charset "us-ascii"
//
// gridTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the simpleRandomMap library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f gridTest.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

versionInfo:    GameID
        name = 'simpleRandomMap Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the simpleRandomMap library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple test game that demonstrates the features
		of the simpleRandomMap library.
		<.p>
		The makefile for this demo contains -D SIMPLE_RANDOM_MAP_GRID
		so the map should consist of rooms with exits to the north,
		south, east, and west except at the edges of the map.
		<.p> ";
#ifdef __DEBUG_SIMPLE_RANDOM_MAP
		"<.p>
		You can display a simple ASCII map of the area around your
		current location by typing:
		<.p>\t<b>&gt;M</b> ";
#endif // __DEBUG_SIMPLE_RANDOM_MAP
		"Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

map: SimpleRandomMapGenerator;

me: Person;

gameMain: GameMainDef initialPlayerChar = me;
