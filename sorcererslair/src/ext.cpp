//--------------------------------------------------------------------------//
// iq / rgba  .  tiny codes  .  2008                                        //
//--------------------------------------------------------------------------//

#ifdef WINDOWS
#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#include <windows.h>
#endif
#include <GL/gl.h>
#include "glext.h"
#ifdef LINUX
#include <GL/glx.h>
#endif

//--- d a t a ---------------------------------------------------------------

#include "ext.h"
#define FUNCLIST_DO(T, N) T ogl##N;
FUNCLIST FUNCLIST_DBG
#undef FUNCLIST_DO
void EXT_Init( void )
{
#define FUNCLIST_DO(T, N) ogl##N = wglGetProcAddress("gl" # N);
FUNCLIST FUNCLIST_DBG
#undef FUNCLIST_DO
}


