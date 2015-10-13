osx_handmade_minimal
====================

A port of Handmade Hero (http://handmadehero.org) for OS X.

This repository works with Casey's source code from handmade_hero_day_161.

This version is a demonstration of how to create the app without
using Xcode or xib files. This is a work in progress.

See the osx_handmade repository for the "standard" OS X version
that uses an Xcode project.


Note 2015-10-13:
----------------
I'm currently bringing the Mac port up-to-date after a summer hiatus.
This version is compatible with Day 161 (after the block allocator, 
before fonts).

Note that this version might suffer from an audio glitch that Casey has not
yet debugged. I believe the OS X Core Audio streaming is working properly.

IMPORTANT
---------

Once you clone or update this repository, copy over Casey's .cpp
and .h source files to the root directory of this repository.

Also, copy over the test, test2, and test3 asset folders to the
root directory of this repository.

Before you build the application for the first time, you need to
create the packed asset files. To do this, run 'make test_asset_builder',
and then execute the test_asset_builder command line program. This will
create the test*.hha files. From then on, you can just run 'make' 
to build the application bundle.

You can then either run 'handmade' directly, or 'open Handmade.app'.

Hot-loading is supported, so you can just run 'make' again while the 
application is running to build and reload the newest code.

For better rendering performance, build the project in Release mode
(this is the Makefile default). You can also set the renderAtHalfSpeed
flag in HandmadeView.mm to reduce the effective rendering rate to 30fps
instead of the default 60fps. The proper Core Audio sound buffer size
is automatically adjusted.

I've implemented the necessary calls to output the Debug Cycle Counters.
To enable this, just replace the three empty stub #defines in handmade_platform.h
at lines 189-191 with the ones just above (inside the _MSC_VER check).


Author
------
Jeff Buck

The original version of Handmade Hero is being created by Casey Muratori.

