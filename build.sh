mono shader_minifier.exe -o post.h --preserve-externals post.glsl && \
mono shader_minifier.exe -o raymarch.h --preserve-externals raymarch.glsl && \
cc -std=c99 -Wall -Werror -Wextra -pedantic -lm timepack.c -o timepack && ./timepack timeline.seq timeline.h && \
cc -Wall -Wno-unknown-pragmas $@ `pkg-config --cflags --libs sdl` -lGL nwep.c -o nwep
