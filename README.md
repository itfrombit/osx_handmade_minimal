osx_handmade_minimal
====================

A port of Handmade Hero (http://handmadehero.org) for OS X.

This version is a demonstration of how to create the app without
using Xcode or xib files. This is a work in progress.

See the osx_handmade repository for the "standard" OS X version
that uses an Xcode project.


Note 2015-10-09:
----------------
I'm currently bringing the Mac port up-to-date after a summer hiatus.
This version is compatible with Day 143 (after Sound Mixing was added).


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
- handmade_asset.cpp
- handmade_asset.h
- handmade_audio.cpp
- handmade_audio.h

Also, copy over the test, test2, and test3 asset folders to the
root directory of this repository.

Once you copy over all of Casey's source code, type 'make' at the command
line to build the executable and the application bundle. You can then 
either run 'handmade' directly, or 'open Handmade.app'.

Hot-loading is supported, so you can just run 'make' again while the 
application is running to build and reload the newest code.

This repository works with Casey's source code from handmade_hero_day_143.

For better rendering performance, build the project in Release mode (this is the Makefile default).
You can also temporarily set the renderAtHalfSpeed flag in HandmadeView.mm to
reduce the effective rendering rate to 30fps instead of the default
60fps. The proper Core Audio sound buffer size is automatically adjusted.

I've implemented the necessary calls to output the Debug Cycle Counters.
To enable this, just replace the three empty stub #defines in handmade_platform.h
at lines 172-174 with the ones just above inside the _MSC_VER check.


Author
------
Jeff Buck

The original version of Handmade Hero is being created by Casey Muratori.

