osx_handmade_minimal
====================

A port of Handmade Hero (http://handmadehero.org) for OS X.

This version is a demonstration of how to create the app without
using Xcode or xib files. This is a work in progress.

See the osx_handmade repository for the "standard" OS X version
that uses an Xcode project.


IMPORTANT
---------
I removed Casey's platform-independent game code from this repository.

Once you clone or update from this repository, copy over the
following files from Casey's source code:
- handmade.cpp
- handmade.h
- handmade_intrinsics.h
- handmade_platform.h
- handmade_random.h
- handmade_tile.cpp
- handmade_tile.h


**TEMPORARY IMPORTANT STEP:**
After copying over the files, edit Day 035's handmade.h line 83 and change the return type of PushSize_() from

```
void *
PushSize_(memory_arena *Arena, memory_index Size)
```

to

```
inline void *
PushSize_(memory_arena *Arena, memory_index Size)
```

The addition of the inline keyword will prevent a duplicate symbol linker error when compiling the project.

With the above change, this repository works with Casey's source code from handmade_hero_day_035_source.


Author
------
Jeff Buck

The original version of Handmade Hero is being created by Casey Muratori.

