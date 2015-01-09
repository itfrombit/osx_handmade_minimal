CXX			= clang
HANDMADE_FLAGS = -Dsize_t=__darwin_size_t -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1 -DHANDMADE_MIN_OSX -Wno-null-dereference

COPTS		= -g -Wall $(HANDMADE_FLAGS)

#COPTS		= -O3 -Wall $(HANDMADE_FLAGS)


CPP11_FLAGS	= -std=c++11 -stdlib=libc++
CPP11_LD_FLAGS = -lstdc++

OSX_FLAGS = 
OSX_LD_FLAGS = -framework Cocoa -framework QuartzCore -framework OpenGL -framework IOKit -framework AudioUnit

CLANG_ARC_FLAGS = -fobjc-arc

BINARIES = handmade libhandmade.dylib

default: libhandmade.dylib handmade

#handmade: osx_main.o osx_handmade.o libhandmade.dylib HandmadeView.o
#	$(CXX) $(COPTS) $(OSX_LD_FLAGS) -L. -lhandmade -o $@ $^

handmade: osx_main.o osx_handmade.o
	$(CXX) $(COPTS) $(OSX_LD_FLAGS) -o $@ $^
	rm -rf Handmade.app
	rm -rf ./Contents/Resources
	mkdir -p Handmade.app/Contents/MacOS
	mkdir -p Handmade.app/Contents/Resources
	cp handmade Handmade.app/Contents/MacOS/Handmade
	cp -R test Handmade.app/Contents/Resources/test
	mkdir -p Contents/Resources
	cp -R test ./Contents/Resources/test
	cp libhandmade.dylib Handmade.app/Contents/MacOS/libhandmade.dylib


libhandmade.dylib: handmade.o
	$(CXX) $(COPTS) -dynamiclib -o $@ $^

HandmadeView.o: HandmadeView.mm HandmadeView.h
	$(CXX) $(COPTS) -c $<

osx_handmade.o: osx_handmade.cpp osx_handmade.h
	$(CXX) $(COPTS) -c $<

handmade.o: handmade.cpp handmade.h
	$(CXX) $(COPTS) -Wno-c++11-compat-deprecated-writable-strings -c $<

osx_main.o: osx_main.mm osx_handmade.cpp osx_handmade.h handmade.h handmade.cpp HandmadeView.mm HandmadeView.h
	$(CXX) $(COPTS) -c $<

clean:
	rm -rf *.o $(BINARIES) Handmade.app

