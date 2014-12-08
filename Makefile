CXX			= clang
COPTS		= -g -Wall -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_OSX=1
#COPTS		= -O3 -Wall

CPP11FLAGS	= -std=c++11 -stdlib=libc++
CPP11LDFLAGS = -lstdc++

OSXFLAGS = 
OSXLDFLAGS = -framework Cocoa -framework QuartzCore -framework OpenGL -framework IOKit -framework AudioUnit


CFLAGS		= $(COPTS)

BINARIES = handmade

default: handmade

handmade: osx_handmade.o 
	$(CXX) $(COPTS) $(OSXLDFLAGS) -o $@ $^

osx_handmade.o: osx_handmade.mm
	$(CXX) $(COPTS) -c $<

handmade.o: handmade.cpp
	$(CXX) $(COPTS) $(CPP11FLAGS) -c $<

minapp: minapp.o 
	$(CXX) $(COPTS) $(OSXLDFLAGS) -o $@ $^

minapp.o: minapp.m
	$(CXX) $(COPTS) -c $<

clean:
	rm -rf *.o $(BINARIES)

