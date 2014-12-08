#if !defined(OSX_HANDMADE_H)

struct osx_offscreen_buffer
{
	// NOTE: Pixels are always 32-bits wide. BB GG RR XX
	//BITMAPINFO Info;
	void* Memory;
	int Width;
	int Height;
	int Pitch;
};


struct osx_window_dimension
{
	int Width;
	int Height;
};


struct osx_sound_output
{
	int SamplesPerSecond;
	uint32 RunningSampleIndex;
	int BytesPerSample;
	real32 tSine;
	int LatencySampleCount;
};


#define OSX_HANDMADE_H
#endif
