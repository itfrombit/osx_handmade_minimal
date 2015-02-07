osx_handmade_minimal
====================

A port of Handmade Hero (http://handmadehero.org) for OS X.

This version is a demonstration of how to create the app without
using Xcode or xib files. This is a work in progress.

See the osx_handmade repository for the "standard" OS X version
that uses an Xcode project.


IMPORTANT
---------

Once you clone or update from this repository, copy over the
following files from Casey's source code:
- handmade.cpp
- handmade.h
- handmade_intrinsics.h
- handmade_math.h
- handmade_platform.h
- handmade_random.h
- handmade_world.cpp
- handmade_world.h

Also, copy over the test and test2 bitmap image asset folders to the
root directory of this repository.

Once you copy over all of Casey's source code, type 'make' at the command
line to build the executable and the application bundle. You can then 
either run 'handmade' directly, or 'open Handmade.app'.

Hot-loading is supported, so you can just run 'make' again while the 
application is running to build and reload the newest code.

This repository works with Casey's source code from handmade_hero_day_060_source.


Author
------
Jeff Buck

The original version of Handmade Hero is being created by Casey Muratori.

