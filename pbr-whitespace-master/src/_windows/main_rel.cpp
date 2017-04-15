#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#define VC_LEANMEAN
#define VC_EXTRALEAN
#include <windows.h>
#include <mmsystem.h>
#include "../config.h"
#include <GL/gl.h>
#include "../ext.h"

enum { Uni_T, Uni_V, Uni_FB, Uni_COUNT };

#include "../shaders/fragment.inl"
#include "../shaders/out.inl"
#include "../shaders/post.inl"

#include "../4klang.h"
#include "mmsystem.h"
#include "mmreg.h"


#pragma code_seg(".fltused")
extern "C" { int _fltused = 1; }


static const PIXELFORMATDESCRIPTOR pfd = {
	sizeof(PIXELFORMATDESCRIPTOR), 1, PFD_DRAW_TO_WINDOW|PFD_SUPPORT_OPENGL|PFD_DOUBLEBUFFER, PFD_TYPE_RGBA,
	32, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 32, 0, 0, PFD_MAIN_PLANE, 0, 0, 0, 0 };

static DEVMODE screenSettings = { {0},
	#if _MSC_VER < 1400
	0,0,148,0,0x001c0000,{0},0,0,0,0,0,0,0,0,0,{0},0,32,XRES,YRES,0,0,      // Visual C++ 6.0
	#else
	0,0,156,0,0x001c0000,{0},0,0,0,0,0,{0},0,32,XRES,YRES,{0}, 0,           // Visual Studio 2005+
	#endif
	#if(WINVER >= 0x0400)
	0,0,0,0,0,0,
	#if (WINVER >= 0x0500) || (_WIN32_WINNT >= 0x0400)
	0,0
	#endif
	#endif
	};

SAMPLE_TYPE	lpSoundBuffer[MAX_SAMPLES * 2];
static HWAVEOUT hWaveOut;

#pragma data_seg(".wavefmt")
static WAVEFORMATEX WaveFMT =
{
#ifdef FLOAT_32BIT	
	WAVE_FORMAT_IEEE_FLOAT,
#else
	WAVE_FORMAT_PCM,
#endif		
	2,                                   // channels
	SAMPLE_RATE,                         // samples per sec
	SAMPLE_RATE*sizeof(SAMPLE_TYPE) * 2, // bytes per sec
	sizeof(SAMPLE_TYPE) * 2,             // block alignment;
	sizeof(SAMPLE_TYPE) * 8,             // bits per sample
	0                                    // extension not needed
};

#pragma data_seg(".wavehdr")
static WAVEHDR WaveHDR =
{
	(LPSTR)lpSoundBuffer, MAX_SAMPLES*sizeof(SAMPLE_TYPE)*2,0,0,0,0,0,0
};

static MMTIME MMTime =
{
	TIME_SAMPLES, 0
};

#define SHADER_DEBUG
static int compileProgram(const char *fragment) {
	const int pid = oglCreateProgram();
	const int fsId = oglCreateShader(GL_FRAGMENT_SHADER);
	oglShaderSource(fsId, 1, &fragment, 0);
	oglCompileShader(fsId);

#ifdef SHADER_DEBUG
	int result;
	char info[2048];
#define oglGetObjectParameteriv ((PFNGLGETOBJECTPARAMETERIVARBPROC) wglGetProcAddress("glGetObjectParameterivARB"))
#define oglGetInfoLog ((PFNGLGETINFOLOGARBPROC) wglGetProcAddress("glGetInfoLogARB"))
	oglGetObjectParameteriv(fsId, GL_OBJECT_COMPILE_STATUS_ARB, &result);
	oglGetInfoLog(fsId, 2047, NULL, (char*)info);
	if (!result)
	{
		MessageBox(NULL, info, "COMPILE", 0x00000000L);
		ExitProcess(0);
	}
#endif

	oglAttachShader(pid, fsId);
	oglLinkProgram(pid);

#ifdef SHADER_DEBUG
#define oglGetObjectParameteriv ((PFNGLGETOBJECTPARAMETERIVARBPROC) wglGetProcAddress("glGetObjectParameterivARB"))
#define oglGetInfoLog ((PFNGLGETINFOLOGARBPROC) wglGetProcAddress("glGetInfoLogARB"))
		oglGetObjectParameteriv(pid, GL_OBJECT_LINK_STATUS_ARB, &result);
		oglGetInfoLog(pid, 2047, NULL, (char*)info);
		if (!result)
		{
			MessageBox(NULL, info, "LINK", 0x00000000L);
			ExitProcess(0);
		}
#endif
	return pid;
}

static void initFbTex(int fb, int tex) {
	glBindTexture(GL_TEXTURE_2D, tex);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, XRES, YRES, 0, GL_RGBA, GL_FLOAT, 0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	oglBindFramebuffer(GL_FRAMEBUFFER, fb);
	oglFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
}

static void paint(int prog, int src_tex, int dst_fb, float time) {
	oglUseProgram(prog);
	glBindTexture(GL_TEXTURE_2D, src_tex);
	oglBindFramebuffer(GL_FRAMEBUFFER, dst_fb);
	oglUniform1f(oglGetUniformLocation(prog, "T"), time);
	oglUniform2f(oglGetUniformLocation(prog, "V"), XRES, YRES);
	oglUniform1i(oglGetUniformLocation(prog, "FB"), 0);
	glRects(-1, -1, 1, 1);
}

enum { FbTex_Ray = 1, FbTex_Dof, FbTex_COUNT };


#define FULLSCREEN
#define SHADER_DEBUG
void entrypoint( void )
{
	// initialize window
	#ifdef FULLSCREEN
	ChangeDisplaySettings(&screenSettings,CDS_FULLSCREEN);
	ShowCursor(0);
	HDC hDC = GetDC(CreateWindow((LPCSTR)0xC018, 0, WS_POPUP | WS_VISIBLE, 0, 0, XRES, YRES, 0, 0, 0, 0));
	#else
	HDC hDC = GetDC(CreateWindow("static", 0, WS_POPUP | WS_VISIBLE, 0, 0, XRES, YRES, 0, 0, 0, 0));
	#endif	

	// initalize opengl
	SetPixelFormat(hDC,ChoosePixelFormat(hDC,&pfd),&pfd);
	wglMakeCurrent(hDC,wglCreateContext(hDC));
	EXT_Init();

	const int p_ray = compileProgram(fragment_glsl);
	const int p_dof = compileProgram(post_glsl);
	const int p_out = compileProgram(out_glsl);

	GLuint tex[FbTex_COUNT], fb[FbTex_COUNT];
	glGenTextures(FbTex_COUNT, tex);
	oglGenFramebuffers(FbTex_COUNT, fb);

	initFbTex(tex[FbTex_Ray], fb[FbTex_Ray]);
	initFbTex(tex[FbTex_Dof], fb[FbTex_Dof]);
// initialize sound
	CreateThread(0, 0, (LPTHREAD_START_ROUTINE)_4klang_render, lpSoundBuffer, 0, 0);
	waveOutOpen(&hWaveOut, WAVE_MAPPER, &WaveFMT, NULL, 0, CALLBACK_NULL);
	waveOutPrepareHeader(hWaveOut, &WaveHDR, sizeof(WaveHDR));
	waveOutWrite(hWaveOut, &WaveHDR, sizeof(WaveHDR));
	const int to = timeGetTime();
	
	//glViewport(0, 0, XRES, YRES);
	// play intro
	do 
	{
		waveOutGetPosition(hWaveOut, &MMTime, sizeof(MMTIME));
		const float time = (timeGetTime() - to) * 1e-3f;
		//paint(p_ray, 0, 0/*fb[FbTex_Ray]*/, ray, time);
		paint(p_ray, 0, fb[FbTex_Ray], time);
		paint(p_dof, tex[FbTex_Ray], fb[FbTex_Dof], time);
		paint(p_out, tex[FbTex_Dof], 0, time);
		SwapBuffers(hDC);
	} while(!GetAsyncKeyState(VK_ESCAPE) && MMTime.u.sample < 5990000);

	#ifdef CLEANDESTROY
	sndPlaySound(0,0);
	ChangeDisplaySettings( 0, 0 );
	ShowCursor(1);
	#endif

	ExitProcess(0);
}
