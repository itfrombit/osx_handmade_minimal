osx_handmade_minimal
====================

A port of Handmade Hero (http://handmadehero.org) for OS X.

This repository works with Casey's source code from handmade_hero_day_219.

This version is a demonstration of how to create the app without
using Xcode or xib files. This is a work in progress.

See the osx_handmade repository for the "standard" OS X version
that uses an Xcode project.


Note 2015-11-22:
----------------
This version is compatible with Day 219.

However, the clang/llvm compiler flags some errors in Casey's
Handmade Hero source code that need to be fixed before compiling
under OS X. To fix the source code, run

    sh fix_handmade_hero_source.sh

after copying over Casey's source code, but before running 'make'
for the first time.

The shell script is not very robust at finding the lines to change,
so if you are using source code other than Day 219, this may not work.  
If you would rather fix the errors by hand instead of running the above
shell script, here's a summary of the compile errors:

1. handmade_platform.h:501:11 - There's extra junk after the #endif. Just delete it.
2. handmade_generated.h - All of the (u32) casts should be (u64) casts.
3. handmade_debug.cpp - non-portable _snprintf_s functions are not available on OS X. Insert the contents of the provided file 'vsprintf.cpp' near the top of the file (just after the '#include <stdio.h>' line) to fix.
4. handmade_debug.cpp:750 - Change the two (u32) casts to (u64) casts in the first line of the GetOrCreateDebugViewFor() function.


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

