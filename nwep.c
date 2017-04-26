#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#define VC_LEANMEAN
#define VC_EXTRALEAN
#include <windows.h>
#include <mmsystem.h>
#include <mmreg.h>
#include <GL/gl.h>

#define XRES 1280
#define YRES 720
#define INTRO_LENGTH 130*1000

#include "raymarch.h"
#include "post.h"

#include "music/4klang.h"

#include "glext.h"

#if 0
FUNCLIST_DO(PFNGLCREATESHADERPROC, CreateShader) \
FUNCLIST_DO(PFNGLSHADERSOURCEPROC, ShaderSource) \
FUNCLIST_DO(PFNGLCOMPILESHADERPROC, CompileShader) \
FUNCLIST_DO(PFNGLCREATEPROGRAMPROC, CreateProgram) \
FUNCLIST_DO(PFNGLATTACHSHADERPROC, AttachShader) \
FUNCLIST_DO(PFNGLLINKPROGRAMPROC, LinkProgram)
#endif
#define FUNCLIST \
  FUNCLIST_DO(PFNGLCREATESHADERPROGRAMVPROC, CreateShaderProgramv) \
  FUNCLIST_DO(PFNGLUSEPROGRAMPROC, UseProgram) \
  FUNCLIST_DO(PFNGLGETUNIFORMLOCATIONPROC, GetUniformLocation) \
  FUNCLIST_DO(PFNGLUNIFORM1IPROC, Uniform1i) \
  FUNCLIST_DO(PFNGLUNIFORM3FPROC, Uniform3f) \
  FUNCLIST_DO(PFNGLGENFRAMEBUFFERSPROC, GenFramebuffers) \
  FUNCLIST_DO(PFNGLBINDFRAMEBUFFERPROC, BindFramebuffer) \
  FUNCLIST_DO(PFNGLFRAMEBUFFERTEXTURE2DPROC, FramebufferTexture2D)
#ifndef DEBUG
#define FUNCLIST_DBG
#else
#define FUNCLIST_DBG \
  FUNCLIST_DO(PFNGLGETPROGRAMINFOLOGPROC, GetProgramInfoLog) \
  FUNCLIST_DO(PFNGLGETSHADERINFOLOGPROC, GetShaderInfoLog) \
  FUNCLIST_DO(PFNGLCHECKFRAMEBUFFERSTATUSPROC, CheckFramebufferStatus)
#endif

#pragma code_seg(".fltused")
/*extern "C" {*/ int _fltused = 1; /*}*/


static const PIXELFORMATDESCRIPTOR pfd = {
	sizeof(PIXELFORMATDESCRIPTOR), 1, PFD_DRAW_TO_WINDOW|PFD_SUPPORT_OPENGL|PFD_DOUBLEBUFFER, PFD_TYPE_RGBA,
	32, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 32, 0, 0, PFD_MAIN_PLANE, 0, 0, 0, 0 };

static const DEVMODE screenSettings = { {0},
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

static SAMPLE_TYPE lpSoundBuffer[MAX_SAMPLES * 2];
static HWAVEOUT hWaveOut;

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

/*
static MMTIME MMTime =
{
	TIME_SAMPLES, 0
};
*/

#pragma data_seg(".glfuncs")
#define FUNCLIST_DO(T,N) static T ogl##N;
FUNCLIST FUNCLIST_DBG
#undef FUNCLIST_DO

#pragma data_seg(".compileProgram")
static int compileProgram(const char *fragment) {
#if 0
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

#else
	const int pid = oglCreateShaderProgramv(GL_FRAGMENT_SHADER, 1, &fragment);
#endif

#ifdef SHADER_DEBUG
	{
		int result;
		char info[2048];
#define oglGetObjectParameteriv ((PFNGLGETOBJECTPARAMETERIVARBPROC) wglGetProcAddress("glGetObjectParameterivARB"))
#define oglGetInfoLog ((PFNGLGETINFOLOGARBPROC) wglGetProcAddress("glGetInfoLogARB"))
		oglGetObjectParameteriv(pid, GL_OBJECT_LINK_STATUS_ARB, &result);
		oglGetInfoLog(pid, 2047, NULL, (char*)info);
		if (!result)
		{
			MessageBox(NULL, info, "LINK", 0x00000000L);
			ExitProcess(0);
		}
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

static void paint(int prog, int src_tex, int dst_fb, int time) {
	oglUseProgram(prog);
	glBindTexture(GL_TEXTURE_2D, src_tex);
	oglBindFramebuffer(GL_FRAMEBUFFER, dst_fb);
	oglUniform1i(oglGetUniformLocation(prog, "B"), 0);
	oglUniform3f(oglGetUniformLocation(prog, "V"), XRES, YRES, time * 1e-3f);
	glRects(-1, -1, 1, 1);
}

enum { FbTex_Ray, FbTex_COUNT };

#pragma data_seg(".entry")
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
	
#define FUNCLIST_DO(T, N) ogl##N = (T)wglGetProcAddress("gl" # N);
	FUNCLIST FUNCLIST_DBG
#undef FUNCLIST_DO

	const int p_ray = compileProgram(raymarch_glsl);
	const int p_dof = compileProgram(post_glsl);
	//const int p_out = compileProgram(out_glsl);

	GLuint tex[FbTex_COUNT], fb[FbTex_COUNT];
	glGenTextures(FbTex_COUNT, tex);
	oglGenFramebuffers(FbTex_COUNT, fb);

	initFbTex(tex[FbTex_Ray], fb[FbTex_Ray]);
	//initFbTex(tex[FbTex_Dof], fb[FbTex_Dof]);

	// initialize sound
	CreateThread(0, 0, (LPTHREAD_START_ROUTINE)_4klang_render, lpSoundBuffer, 0, 0);
	//_4klang_render(lpSoundBuffer);
	waveOutOpen(&hWaveOut, WAVE_MAPPER, &WaveFMT, NULL, 0, CALLBACK_NULL);
	waveOutPrepareHeader(hWaveOut, &WaveHDR, sizeof(WaveHDR));
	waveOutWrite(hWaveOut, &WaveHDR, sizeof(WaveHDR));
	const int to = timeGetTime();

	// play intro
	do 
	{
		//waveOutGetPosition(hWaveOut, &MMTime, sizeof(MMTIME));
		//const float time = (timeGetTime() - to) * 1e-3f;
		const int time = timeGetTime() - to;
		paint(p_ray, 0, fb[FbTex_Ray], time);
		paint(p_dof, tex[FbTex_Ray], 0, time);
		SwapBuffers(hDC);

		/* hide cursor properly */
		PeekMessageA(0, 0, 0, 0, PM_REMOVE);
		if (time > INTRO_LENGTH) break;
	} while (!GetAsyncKeyState(VK_ESCAPE));
		// && MMTime.u.sample < 5990000);

	#ifdef CLEANDESTROY
	sndPlaySound(0,0);
	ChangeDisplaySettings( 0, 0 );
	ShowCursor(1);
	#endif

	ExitProcess(0);
}
