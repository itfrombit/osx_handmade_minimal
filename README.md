osx_handmade_minimal
====================

A port of Handmade Hero (http://handmadehero.org) for OS X.

This version is a demonstration of how to create the app without
using Xcode or xib files. This is a work in progress.

See the osx_handmade repository for the "standard" OS X version
that uses an Xcode project.


Note 2015-10-01:
----------------
I'm currently bringing the Mac port up-to-date after a summer hiatus.
This version is compatible with Day 126.


IMPORTANT
---------

Once you clone or update from this repository, copy over the
following files from Casey's source code:
- handmade.cpp
- handmade.h
- handmade_entity.cpp
- handmade.entity.h
- handmade_intrinsics.h
- handmade_math.h
- handmade_platform.h
- handmade_random.h
- handmade_render_group.cpp
- handmade_render_group.h
- handmade_sim_region.cpp
- handmade_sim_region.h
- handmade_world.cpp
- handmade_world.h

Also, copy over the test and test2 bitmap image asset folders to the
root directory of this repository.

Once you copy over all of Casey's source code, type 'make' at the command
line to build the executable and the application bundle. You can then 
either run 'handmade' directly, or 'open Handmade.app'.

Hot-loading is supported, so you can just run 'make' again while the 
application is running to build and reload the newest code.

This repository works with Casey's source code from handmade_hero_day_126.

For better rendering performance, build the project in Release mode (this is the Makefile default).
You can also temporarily set the renderAtHalfSpeed flag in HandmadeView.mm to
reduce the effective rendering rate to 30fps instead of the default
60fps.

I've implemented the necessary calls to output the Debug Cycle Counters.
To enable this, just replace the three empty stub #defines in handmade_platform.h
at lines 170-172 with the ones just above inside the _MSC_VER check.


Author
------
Jeff Buck

The original version of Handmade Hero is being created by Casey Muratori.

