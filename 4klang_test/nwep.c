#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#define VC_LEANMEAN
#define VC_EXTRALEAN

#include <windows.h>
#include <mmsystem.h>
#include <mmreg.h>

#include "music/4klang.h"
#define INTRO_LENGTH (1000ull * MAX_SAMPLES / SAMPLE_RATE)

#ifdef __cplusplus
extern "C"
{
#endif
	int  _fltused = 0;
#ifdef __cplusplus
}
#endif

#pragma data_seg(".wavefmt")
static const WAVEFORMATEX WaveFMT =
{
#ifdef FLOAT_32BIT
	WAVE_FORMAT_IEEE_FLOAT,
#else
	WAVE_FORMAT_PCM,
#endif
	2,                                   // channels
	SAMPLE_RATE,                         // samples per sec
	SAMPLE_RATE * sizeof(SAMPLE_TYPE) * 2, // bytes per sec
	sizeof(SAMPLE_TYPE) * 2,             // block alignment;
	sizeof(SAMPLE_TYPE) * 8,             // bits per sample
	0                                    // extension not needed
};

SAMPLE_TYPE	lpSoundBuffer[MAX_SAMPLES * 2];
HWAVEOUT	hWaveOut;

#pragma data_seg(".wavehdr")
static WAVEHDR WaveHDR =
{
	(LPSTR)lpSoundBuffer, MAX_SAMPLES * sizeof(SAMPLE_TYPE) * 2,0,0,0,0,0,0
};

#pragma code_seg(".entry")
void entrypoint(void) {

	// initialize sound
	HWAVEOUT hWaveOut;
	CreateThread(0, 0, (LPTHREAD_START_ROUTINE)_4klang_render, lpSoundBuffer, 0, 0);
	//_4klang_render(lpSoundBuffer);
	waveOutOpen(&hWaveOut, WAVE_MAPPER, &WaveFMT, NULL, 0, CALLBACK_NULL);
	waveOutPrepareHeader(hWaveOut, &WaveHDR, sizeof(WaveHDR));
	waveOutWrite(hWaveOut, &WaveHDR, sizeof(WaveHDR));

	// play intro
	do {
		//waveOutGetPosition(hWaveOut, &MMTime, sizeof(MMTIME));
		/* hide cursor properly */
		PeekMessageA(0, 0, 0, 0, PM_REMOVE);
	} while (!GetAsyncKeyState(VK_ESCAPE));
	// && MMTime.u.sample < MAX_SAMPLES);
	ExitProcess(0);
}
#endif
