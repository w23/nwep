#include "atto/app.h"
#define ATTO_GL_H_IMPLEMENT
#define ATTO_GL_DEBUG
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
#include <cstring>

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

		aAppDebugPrintf("Reread file %s", filename_.c_str());

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
	Program(String &vtx, String &frg) : vertex_src_(vtx), fragment_src_(frg), program_(0) {}

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

const char fs_vtx_source[] =
	"void main() {\n"
		"gl_Position = gl_Vertex;\n"
	"}"
;

class Intro {
	int paused_;
	const ATimeUs time_end_;
	ATimeUs time_, last_frame_time_;
	ATimeUs loop_a_, loop_b_;

	float cam_r_, cam_y_, cam_axz_;
	float at_r_, at_y_, at_axz_;

	AVec3f mouse;

	int frame_width, frame_height;

	String fs_vtx;
	FileString raymarch_src;
	Program raymarch_prg;
	FileString post_src;
	Program post_prg;
	FileString out_src;
	Program out_prg;

	enum {
		FbTex_None,
		FbTex_Random,
		FbTex_Ray,
		FbTex_Frame,
		FbTex_COUNT
	};
	GLuint tex_[FbTex_COUNT];
	GLuint fb_[FbTex_COUNT];

	static void createTexture(GLint t, int w, int h)
	{
		AGL__CALL(glBindTexture(GL_TEXTURE_2D, t));
		AGL__CALL(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, w, h, 0, GL_RGBA, GL_FLOAT, 0));
		AGL__CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
		AGL__CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
		AGL__CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER));
		AGL__CALL(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER));
	}

public:
	Intro(int width, int height)
		: paused_(0)
		, time_end_(150 * 1000000)
		, time_(0)
		, last_frame_time_(0)
		, loop_a_(0)
		, loop_b_(time_end_)
		, cam_r_(40.f), cam_y_(2.f), cam_axz_(0.f)
		, at_r_(0.f), at_y_(0.f), at_axz_(0.f)
		, mouse(aVec3ff(0))
		, frame_width(width)
		, frame_height(height)
		, fs_vtx(fs_vtx_source)
		, raymarch_src("raymarch.glsl")
		, raymarch_prg(fs_vtx, raymarch_src)
		, post_src("post.glsl")
		, post_prg(fs_vtx, post_src)
		, out_src("out.glsl")
		, out_prg(fs_vtx, out_src)
	{
		tex_[0] = fb_[0] = 0;
		AGL__CALL(glGenTextures(FbTex_COUNT-1, tex_ + 1));
		AGL__CALL(glGenFramebuffers(FbTex_COUNT-1, fb_ + 1));

		for (int i = 0; i < FbTex_COUNT; ++i)
			aAppDebugPrintf("tex_[%d] = %u; fb_[%d] = %u;", i, tex_[i], i, fb_[i]);

		createTexture(tex_[FbTex_Ray], frame_width, frame_height);
		AGL__CALL(glBindFramebuffer(GL_FRAMEBUFFER, fb_[FbTex_Ray]));
		AGL__CALL(glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex_[FbTex_Ray], 0));
		int status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
		ATTO_ASSERT(status == GL_FRAMEBUFFER_COMPLETE);

		createTexture(tex_[FbTex_Frame], frame_width, frame_height);
		AGL__CALL(glBindFramebuffer(GL_FRAMEBUFFER, fb_[FbTex_Frame]));
		AGL__CALL(glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex_[FbTex_Frame], 0));
		status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
		ATTO_ASSERT(status == GL_FRAMEBUFFER_COMPLETE);
	}

	void drawPass(float now, int tex, int prog, int fb) {
		AGL__CALL(glBindTexture(GL_TEXTURE_2D, tex));
		AGL__CALL(glUseProgram(prog));
		AGL__CALL(glBindFramebuffer(GL_FRAMEBUFFER, fb));
		if (fb > 0) {
			AGL__CALL(glViewport(0, 0, frame_width, frame_height));
			AGL__CALL(glUniform3f(glGetUniformLocation(prog, "V"), frame_width, frame_height, now));
		} else {
			AGL__CALL(glViewport(0, 0, a_app_state->width, a_app_state->height));
			AGL__CALL(glUniform3f(glGetUniformLocation(prog, "V"), a_app_state->width, a_app_state->height, now));
		}
		AGL__CALL(glUniform1i(glGetUniformLocation(prog, "B"), 0));
		AGL__CALL(glUniform3f(glGetUniformLocation(prog, "C"), cam_r_, cam_y_, cam_axz_));
		AGL__CALL(glUniform3f(glGetUniformLocation(prog, "A"), at_r_, at_y_, at_axz_));
		AGL__CALL(glUniform1f(glGetUniformLocation(prog, "TPCT"), (float)time_ / (float)time_end_));
		AGL__CALL(glRects(-1,-1,1,1));
	}

	void paint(ATimeUs ts) {
		if (!paused_) {
			const ATimeUs delta = ts - last_frame_time_;
			time_ += delta;
			if (time_ < loop_a_) time_ = loop_a_;
			if (time_ > loop_b_) time_ = loop_a_ + time_ % (loop_b_ - loop_a_);
		}
		last_frame_time_ = ts;

		const float now = 1e-6f * time_;

		cam_r_ = 20.f + sinf(now*.1f) * 18.f;

		raymarch_prg.update();
		post_prg.update();
		out_prg.update();

		drawPass(now, 0, raymarch_prg.program(), FbTex_Ray);
		drawPass(now, FbTex_Ray, post_prg.program(), FbTex_Frame);
		drawPass(now, FbTex_Frame, out_prg.program(), 0);
	}

	void adjustTime(int delta) {
		if (delta < 0 && -delta > (int)(time_ - loop_a_))
			time_ = loop_a_;
		else
			time_ += delta;
	}

	void key(ATimeUs ts, AKey key) {
		(void)ts;
		switch (key) {
			case AK_Space: paused_ ^= 1; break;
			case AK_Right: adjustTime(5000000); break;
			case AK_Left: adjustTime(-5000000); break;
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

	int width = 1280, height = 720;
	for (int iarg = 1; iarg < a_app_state->argc; ++iarg) {
		const char *argv = a_app_state->argv[iarg];
		if (strcmp(argv, "-w") == 0)
			width = atoi(a_app_state->argv[++iarg]);
		else if (strcmp(argv, "-h") == 0)
			height = atoi(a_app_state->argv[++iarg]);
	}

	intro.reset(new Intro(width, height));
}
