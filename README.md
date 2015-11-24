osx_handmade_minimal
====================

A port of Handmade Hero (http://handmadehero.org) for OS X.

This repository works with Casey's source code from handmade_hero_day_220.

This version is a demonstration of how to create the app without
using Xcode or xib files. This is a work in progress.

See the osx_handmade repository for the "standard" OS X version
that uses an Xcode project.


Note 2015-11-24:
----------------
This version is compatible with Day 220.

However, the Handmade Hero source code is currently using the
non-portable _snprintf_s function in handmade_debug.cpp.
To fix the source code, run

    sh fix_handmade_hero_source.sh

after copying over Casey's source code, but before running 'make'
for the first time.

If you would rather fix the error by hand instead of running the above
shell script, just insert the contents of the provided file 'vsprintf.cpp'
near the top of the handmade_debug.cpp (just below the '#include <stdio.h>' line).


IMPORTANT
---------

Once you clone or update this repository, copy over Casey's .cpp
and .h source files to the root directory of this repository.

Also, copy over the test, test2, and test3 asset folders to the
root directory of this repository.

Before you build the application for the first time, you need to
create the packed asset files. To do this, run

    make osx_asset_builder

and then execute the osx_asset_builder command line program. This will
create the .hha files. From then on, you can just run 'make' 
to build the application bundle.

You can then either run 'handmade' directly, or 'open Handmade.app'.
The advantage of running 'handmade' directly is that debug console output 
(printf's, etc.) will be displayed in your terminal window instead
of being logged to the System Console.

Hot-loading is supported, so you can just run 'make' again (or have your
favorite editor do it) while the application is running to build and
reload the newest code.

For better rendering performance, build the project in Release mode
(this is the Makefile default). You can also set the renderAtHalfSpeed
flag in HandmadeView.mm to reduce the effective rendering rate to 30fps
instead of the default 60fps. The proper Core Audio sound buffer size
is automatically adjusted.


Author
------
Jeff Buck

The original version of Handmade Hero is being created by Casey Muratori.

