//--------------------------------------------------------------------------//
// iq / rgba  .  tiny codes  .  2008                                        //
//--------------------------------------------------------------------------//

#ifndef _EXTENSIONES_H_
#define _EXTENSIONES_H_

#ifdef WINDOWS
#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#include <windows.h>
#endif
#include <GL/gl.h>
#include "glext.h"

#define FUNCLIST \
  FUNCLIST_DO(PFNGLCREATESHADERPROC, CreateShader) \
  FUNCLIST_DO(PFNGLSHADERSOURCEPROC, ShaderSource) \
  FUNCLIST_DO(PFNGLCOMPILESHADERPROC, CompileShader) \
  FUNCLIST_DO(PFNGLCREATEPROGRAMPROC, CreateProgram) \
  FUNCLIST_DO(PFNGLATTACHSHADERPROC, AttachShader) \
  FUNCLIST_DO(PFNGLLINKPROGRAMPROC, LinkProgram) \
  FUNCLIST_DO(PFNGLUSEPROGRAMPROC, UseProgram) \
  FUNCLIST_DO(PFNGLGETUNIFORMLOCATIONPROC, GetUniformLocation) \
  FUNCLIST_DO(PFNGLUNIFORM1IPROC, Uniform1i) \
  FUNCLIST_DO(PFNGLUNIFORM1FPROC, Uniform1f) \
  FUNCLIST_DO(PFNGLUNIFORM2FPROC, Uniform2f) \
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

#define FUNCLIST_DO(T,N) "gl" #N "\0"
static const char gl_names[] =
FUNCLIST FUNCLIST_DBG
;
#undef FUNCLIST_DO

#define FUNCLIST_DO(T,N) extern T ogl##N;
FUNCLIST FUNCLIST_DBG
#undef FUNCLIST_DO

// init
void EXT_Init(void);

#endif
