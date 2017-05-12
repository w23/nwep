SHMIN=mono shader_minifier.exe
INTRO=nwep

all: $(INTRO).sh

$(INTRO).sh: linux_header $(INTRO).gz
	cat linux_header $(INTRO).gz > $@
	chmod +x $@

$(INTRO).gz: $(INTRO).elf
	cat $< | 7z a dummy -tGZip -mx=9 -si -so > $@

.h.glsl:
	$(SHMIN) -o $@ --preserve-externals $<

.h.seq: timepack
	timepack $< $@

timepack: timepack.c
	$(CC) -std=c99 -Wall -Werror -Wextra -pedantic -lm timepack.c -o timepack

# '-nostartfiles -DCOMPACT' result in a libSDL crash on my machine (making older 1k/4k also crash) :(
$(INTRO).elf: $(INTRO).c music/4klang.o
	$(CC) -m32 -Os -Wall -Wno-unknown-pragmas \
		-DFULLSCREEN `pkg-config --cflags --libs sdl` -lGL \
		music/4klang.o $(INTRO).c -o $@
	sstrip $@

$(INTRO).dbg: $(INTRO).c music/4klang.o
	$(CC) -m32 -O0 -g -Wall -Wno-unknown-pragmas \
		`pkg-config --cflags --libs sdl` -lGL \
		music/4klang.o $(INTRO).c -o $@

.PHONY: clean

clean:
	rm -rf $(INTRO).sh $(INTRO).gz $(INTRO).elf $(INTRO) $(INTRO).dbg
