/* File generated with Shader Minifier 1.1.4
* http://www.ctrl-alt-test.fr
*/
#pragma once
const char *out_glsl =
"uniform sampler2D FB;"
"uniform vec2 V;"
"void main()"
"{"
"gl_FragColor=texture2D(FB,gl_FragCoord.rg/V);"
"}";
