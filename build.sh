#!/usr/bin/bash
clang -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -framework Cocoa -framework QuartzCore -framework OpenGL -framework IOKit -framework AudioUnit -o handmade osx_handmade.mm
