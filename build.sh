mono shader_minifier.exe -o post.h --preserve-externals post.glsl && \
mono shader_minifier.exe -o raymarch.h --preserve-externals raymarch.glsl && \
cc -std=c99 -Wall -Werror -Wextra -pedantic -lm timepack.c -o timepack && ./timepack timeline.seq timeline.h && \
cc -m32 -Os -Wall -Wno-unknown-pragmas $@ `pkg-config --cflags --libs sdl` -lGL music/4klang.o nwep.c -o nwep
