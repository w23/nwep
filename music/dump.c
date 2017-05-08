#include "4klang.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

static SAMPLE_TYPE audio[MAX_SAMPLES * 2];

void __4klang_render(void*);

int main() {
	__4klang_render(audio);
	int fd = open("music.raw", O_CREAT | O_WRONLY, 0644);
	write(fd, audio, sizeof audio);
	close(fd);
	return 0;
}
