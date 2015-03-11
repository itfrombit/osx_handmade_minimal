#!/bin/bash
clang -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -Wno-null-dereference -Wno-c++11-compat-deprecated-writable-strings -c handmade.cpp
clang -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -Wno-null-dereference -dynamiclib -o libhandmade.dylib handmade.o
clang -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -Wno-null-dereference -c osx_main.mm
clang -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -Wno-null-dereference -c osx_handmade.cpp
clang -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -Wno-null-dereference -c HandmadeView.mm
clang -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -Wno-null-dereference -framework Cocoa -framework QuartzCore -framework OpenGL -framework IOKit -framework AudioUnit -o handmade osx_main.o osx_handmade.o HandmadeView.o
rm -rf Handmade.app
mkdir -p Handmade.app/Contents/MacOS
mkdir -p Handmade.app/Contents/Resources
cp handmade Handmade.app/Contents/MacOS/Handmade
cp libhandmade.dylib Handmade.app/Contents/MacOS/libhandmade.dylib

