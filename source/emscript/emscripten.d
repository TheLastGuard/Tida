/++

+/
module emscript.emscripten;

version(WebAssembly):

extern(C) void function(const char* script) emscripten_run_script;
extern(C) int function(const char* script) emscripten_run_script_int;
extern(C) char* function(const char* script) emscripten_run_script_string;

extern(C) void function(void function() func,int fps, int simulate_infinite_loop) emscripten_set_main_loop;
extern(C) void function(int mode,int value) emscripten_set_main_loop_timing;
extern(C) void function() emscripten_pause_main_loop;
extern(C) void function() emscripten_resume_main_loop;
extern(C) void function() emscripten_cancel_main_loop;
extern(C) void function(uint ms) emscripten_sleep;

//html5

alias EM_BOOL = bool;

struct EmscriptenWebGLContextAttributes {
    EM_BOOL alpha;
    EM_BOOL depth;
    EM_BOOL stencil;
    EM_BOOL antialias;
    EM_BOOL premultipliedAlpha;
    EM_BOOL preserveDrawingBuffer;
    EM_BOOL preferLowPowerToHighPerformance;
    EM_BOOL failIfMajorPerformanceCaveat;
    int majorVersion;
    int minorVersion;
    EM_BOOL enableExtensionsByDefault;
}

alias EMSCRIPTEN_WEBGL_CONTEXT_HANDLE = int;

extern(C) void function(EmscriptenWebGLContextAttributes* attributes) emscripten_webgl_init_context_attributes;
extern(C) EMSCRIPTEN_WEBGL_CONTEXT_HANDLE function(const char* target,
                                                   const EmscriptenWebGLContextAttributes* attributes) 
                                                   emscripten_webgl_create_context;

extern(C) int function(EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context) emscripten_webgl_make_context_current;
extern(C) int function(EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context) emscripten_webgl_destroy_context;
extern(C) int function(const char* target,int width,int height) emscripten_set_canvas_element_size;