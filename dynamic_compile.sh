#!/usr/bin/bash
echo `pwd`
cp ./Contents/code/handmade_config.h .
clang -O3 -Wall -DTRANSLATION_UNIT_INDEX=1 -fno-exceptions -fno-rtti -DHANDMADE_PROFILE=1 -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -DHANDMADE_MIN_OSX -std=c++11 -Wno-null-dereference -Wno-logical-not-parentheses -Wno-switch -Wno-write-strings -Wno-c++11-compat-deprecated-writable-strings -Wno-tautological-compare -Wno-missing-braces -Wno-unused-variable -Wno-unused-function -c handmade_optimized.cpp 
clang -O3 -Wall -Wno-c++11-narrowing -DTRANSLATION_UNIT_INDEX=0 -DHANDMADE_PROFILE=1 -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -DHANDMADE_MIN_OSX -std=c++11 -Wno-null-dereference -fno-exceptions -fno-rtti -Wno-missing-braces -Wno-logical-not-parentheses -Wno-switch -Wno-write-strings -Wno-c++11-compat-deprecated-writable-strings -Wno-tautological-compare -Wno-missing-braces -Wno-unused-variable -Wno-unused-function -c handmade.cpp
clang -dynamiclib -o libhandmade.dylib handmade.o handmade_optimized.o
cp libhandmade.dylib Handmade.app/Contents/MacOS/libhandmade.dylib
cp libhandmade.dylib ./Contents/MacOS/libhandmade.dylib

