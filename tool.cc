#include "atto/app.h"
#define ATTO_GL_H_IMPLEMENT
#include "atto/gl.h"
#include "atto/math.h"

#include <utility>
#include <memory>
#include <string>

#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

class FileChangePoller {
	const std::string filename_;
	timespec mtime_;

public:
	FileChangePoller(const char *filename) : filename_(filename) {
		mtime_.tv_sec = 0;
		mtime_.tv_nsec = 0;
	}
	~FileChangePoller() {}

	std::string poll() {
		std::string content;
		struct stat st;
		stat(filename_.c_str(), &st);
		if (st.st_mtim.tv_sec == mtime_.tv_sec &&
				st.st_mtim.tv_nsec == mtime_.tv_nsec)
			return content;

		aAppDebugPrintf("Updating..");

		mtime_ = st.st_mtim;

		int fd = open(filename_.c_str(), O_RDONLY);
		if (fd < 0) {
			aAppDebugPrintf("Cannot open file %s", filename_.c_str());
			return content;
		}

		content.resize(st.st_size + 1, 0);

		if (read(fd, &content[0], st.st_size) != st.st_size) {
			aAppDebugPrintf("Cannot read file\n");
			content.resize(0);
			return content;
		}

		close(fd);
		return content;
	}
};

class String {
protected:
	std::string value_;

public:
	String(const std::string &str) : value_(str) {}
	const std::string &string() const { return value_; }
	virtual bool update() { return false; }
};

class FileString : public String {
	FileChangePoller poller_;

public:
	FileString(const char *filename) : String(""), poller_(filename) {}

	bool update() {
		std::string new_content = poller_.poll();
		if (!new_content.empty()) {
			value_ = std::move(new_content);
			return true;
		}
		return false;
	}
};

class Program {
	String &vertex_src_;
	String &fragment_src_;
	AGLProgram program_;

public:
	const AGLProgram& program() const { return program_; }
	Program(String &vtx, String &frg) : vertex_src_(vtx), fragment_src_(frg) {}

	bool update() {
		if (vertex_src_.update() || fragment_src_.update()) {
			AGLProgram new_program = aGLProgramCreateSimple(
					vertex_src_.string().c_str(), fragment_src_.string().c_str());
			if (new_program < 0) {
				aAppDebugPrintf("shader error: %s\n", a_gl_error);
				return false;
			}

			if (program_ > 0)
				aGLProgramDestroy(program_);

			program_ = new_program;
			return true;
		}
		return false;
	}
};

const char raymarch_vtx_source[] =
	"void main() {\n"
		"gl_Position = gl_Vertex;\n"
	"}"
;

class Intro {
	int paused_;
	ATimeUs time_resume_, time_offset_;
	AVec3f mouse;

	int frame_width, frame_height;

	String raymarch_vtx;
	FileString raymarch_src;
	Program raymarch_prg;

public:
	Intro()
		: paused_(0)
		, time_resume_(0)
		, time_offset_(0)
		, mouse(aVec3ff(0))
		, frame_width(1280)
		, frame_height(720)
		, raymarch_vtx(raymarch_vtx_source)
		, raymarch_src("raymarch.glsl")
		, raymarch_prg(raymarch_vtx, raymarch_src)
	{
	}

	void paint(ATimeUs ts) {
		const float now = 1e-6f * (time_offset_ + (!paused_) * (ts - time_resume_));

		//glViewport(0, 0, frame_width, frame_height);

		raymarch_prg.update();

		glViewport(0, 0, a_app_state->width, a_app_state->height);
		glUseProgram(raymarch_prg.program());
		glUniform1f(glGetUniformLocation(raymarch_prg.program(), "T"), now);
		glUniform2f(glGetUniformLocation(raymarch_prg.program(), "V"), a_app_state->width, a_app_state->height);
		glUniform3f(glGetUniformLocation(raymarch_prg.program(), "M"), mouse.x, mouse.y, mouse.z);
		glRects(-1,-1,1,1);
	}

	void key(ATimeUs ts, AKey key)
	{
		switch (key) {
			case AK_Space:
				if (paused_ ^= 1)
					time_offset_ = ts - time_resume_;
				time_resume_ = ts;
				break;
			case AK_Right: time_offset_ += 5000000; break;
			case AK_Left: time_offset_ -= 5000000; break;
			case AK_Esc: aAppTerminate(0);
			default: break;
		}
	}

	void pointer(int dx, int dy, unsigned buttons, unsigned btn_ch) {
		if (buttons) {
			mouse.x += dx;
			mouse.y += dy;
		}

		if (btn_ch & AB_WheelUp) mouse.z += 1.f;
		if (btn_ch & AB_WheelDown) mouse.z -= 1.f;
	}
};

static std::unique_ptr<Intro> intro;

void paint(ATimeUs ts, float dt) {
	(void)(dt);
	intro->paint(ts);
}

void key(ATimeUs ts, AKey key, int down) {
	(void)(ts);
	if (down) intro->key(ts, key);
}

void pointer(ATimeUs ts, int dx, int dy, unsigned int buttons_changed_bits) {
	(void)(ts);
	(void)(dx);
	(void)(dy);
	(void)(buttons_changed_bits);
	intro->pointer(dx, dy, a_app_state->pointer.buttons, buttons_changed_bits);
}

void attoAppInit(struct AAppProctable *ptbl) {
	ptbl->key = key;
	ptbl->pointer = pointer;
	ptbl->paint = paint;

	intro.reset(new Intro());
}
