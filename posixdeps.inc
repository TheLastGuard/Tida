# Project build method
DC = dmd
DFLAGSDEF = -version=GL_46 -version=Dynamic_GLX -m64

# Dependencies
# Links to the dependency repository.
bindbc-loader = https://github.com/BindBC/bindbc-loader.git
bindbc-opengl = https://github.com/BindBC/bindbc-opengl.git
bindbc-openal = https://github.com/BindBC/bindbc-openal.git
bindbc-freetype = https://github.com/BindBC/bindbc-freetype.git
imagefmt = https://github.com/tjhann/imagefmt.git
mp3decoder = https://github.com/Zoadian/mp3decoder.git
sdlang-d = https://github.com/Abscissa/SDLang-D.git
taggedalgebraic = https://github.com/s-ludwig/taggedalgebraic.git
x11 = https://github.com/nomad-software/x11.git

# Path to source dependency files.
bindbc-loader-include = bindbc-loader/source/
bindbc-opengl-include = bindbc-opengl/source/
bindbc-openal-include = bindbc-openal/source/
bindbc-freetype-include = bindbc-freetype/source/
imagefmt-include = imagefmt/
mp3decoder-include = mp3decoder/source/
sdlang-d-include = SDLang-D/src/
taggedalgebraic-include = taggedalgebraic/source/
x11-include = x11/source/
x11-einclude = $(x11-include)x11/

# File units in the source code.
bindbc-loader-objs = $(shell find $(bindbc-loader-include) -type f -name '*.d')
bindbc-opengl-objs = $(shell find $(bindbc-opengl-include) -type f -name '*.d')
bindbc-openal-objs = $(shell find $(bindbc-openal-include) -type f -name '*.d')
bindbc-freetype-objs = $(shell find $(bindbc-freetype-include) -type f -name '*.d')
imagefmt-objs = $(shell find $(imagefmt-include)/imagefmt/ -type f -name '*.d')
mp3decoder-objs = $(shell find $(mp3decoder-include) -type f -name '*.d')
sdlang-d-objs = $(shell find $(sdlang-d-include) -type f -name '*.d')
taggedalgebraic-objs = $(shell find $(taggedalgebraic-include) -type f -name '*.d')
x11-objs = $(x11-einclude)X.d $(x11-einclude)Xlib.d $(x11-einclude)Xutil.d $(x11-einclude)Xresource.d $(x11-einclude)Xregion.d $(x11-einclude)Xlibint.d $(x11-einclude)Xmd.d $(x11-einclude)Xtos.d $(x11-einclude)Xproto.d $(x11-einclude)Xprotostr.d $(x11-einclude)Xproto_undef.d $(x11-einclude)XlibConf.d $(x11-einclude)keysym.d $(x11-einclude)keysymdef.d
#x11-objs = $(shell find $(x11-include) -type f -name '*.d')

# Library files to be built.
bindbc-loader-lib = bindbc-loader.a
bindbc-opengl-lib = bindbc-opengl.a
bindbc-openal-lib = bindbc-openal.a
bindbc-freetype-lib = bindbc-freetype.a
imagefmt-lib = imagefmt.a
mp3decoder-lib = mp3decoder.a
sdlang-d-lib = sdland-d.a
taggedalgebraic-lib = taggedalgebraic.a
x11-lib = x11.a

# Flags for including libraries in the assembly.
LIBDFLAGS = bindbc-loader/$(bindbc-loader-lib) bindbc-opengl/$(bindbc-opengl-lib) bindbc-openal/$(bindbc-openal-lib) bindbc-freetype/$(bindbc-freetype-lib) imagefmt/$(imagefmt-lib) mp3decoder/$(mp3decoder-lib) x11/$(x11-lib) SDLang-D/$(sdlang-d-lib) taggedalgebraic/$(taggedalgebraic-lib)

# Flags to include source files in the assembly.
DEPENDFLAGS = -I$(bindbc-loader-include) -I$(bindbc-opengl-include) -I$(bindbc-openal-include) -I$(bindbc-freetype-include) -I$(imagefmt-include) -I$(mp3decoder-include) -I$(taggedalgebraic-include) -I$(sdlang-d-include) -I$(x11-include)

# Downloads the source code for all required dependencies.
# Execute before building the project.
fetch-deps:
	[ -d ./bindbc-loader ] || git clone $(bindbc-loader)
	[ -d ./bindbc-opengl ] || git clone $(bindbc-opengl)
	[ -d ./bindbc-openal ] || git clone $(bindbc-openal)
	[ -d ./bindbc-freetype ] || git clone $(bindbc-freetype)
	[ -d ./imagefmt ] || git clone $(imagefmt)
	[ -d ./mp3decoder ] || git clone $(mp3decoder)
	[ -d ./taggedalgebraic ] || git clone $(taggedalgebraic)
	[ -d ./SDLang-D ] || git clone $(sdlang-d)
	[ -d ./x11 ] || git clone $(x11)

fetch-clean:
	[ -f ./bindbc-loader/$(bindbc-loader-lib) ] && rm ./bindbc-loader/$(bindbc-loader-lib) || .
	[ -f ./bindbc-opengl/$(bindbc-opengl-lib) ] && rm ./bindbc-opengl/$(bindbc-opengl-lib) || .
	[ -f ./bindbc-openal/$(bindbc-openal-lib) ] && rm ./bindbc-openal/$(bindbc-openal-lib) || .
	[ -f ./bindbc-freetype/$(bindbc-freetype-lib) ] && rm ./bindbc-freetype/$(bindbc-freetype-lib) || .
	[ -f ./imagefmt/$(imagefmt-lib) ] && rm ./imagefmt/$(imagefmt-lib) || .
	[ -f ./mp3decoder/$(mp3decoder-lib) ] && rm ./mp3decoder/$(mp3decoder-lib) || .
	[ -f ./taggedalgebraic/$(taggedalgebraic-lib) && rm ./taggedalgebraic/$(taggedalgebraic-lib) || .
	[ -f ./SDLang-D/$(sdlang-d-lib) ] && rm ./SDLang-D/$(sdlang-d-lib) || .
	[ -f ./x11/$(x11-lib) ] && rm ./x11/$(x11-lib) || .

deps-remove:
	[ -d ./bindbc-loader ] && rm -rf ./bindbc-loader || .
	[ -d ./bindbc-opengl ] && rm -rf ./bindbc-opengl || .
	[ -d ./bindbc-openal ] && rm -rf ./bindbc-openal || .
	[ -d ./bindbc-freetype ] && rm -rf ./bindbc-freetype || .
	[ -d ./imagefmt ] && rm -rf ./imagefmt || .
	[ -d ./mp3decoder ] && rm -rf ./mp3decoder || .
	[ -d ./taggedalgebraic ] && rm -rf ./taggedalgebraic || .
	[ -d ./SDLang-D ] && rm -rf ./SDLang-D || .
	[ -d ./x11 ] && rm -rf ./x11 || .

# Build the `bindbc-loader` dependency.
bindbc-loader-build: 
	cd bindbc-loader 
	$(DC) $(DFLAGSDEF) -lib -ofbindbc-loader/$(bindbc-loader-lib) $(bindbc-loader-objs)
	cd ../

# Build the `bindbc-opengl` dependency.
bindbc-opengl-build:
	cd bindbc-opengl
	$(DC) $(DFLAGSDEF) -lib -ofbindbc-opengl/$(bindbc-opengl-lib) $(bindbc-opengl-objs) bindbc-loader/$(bindbc-loader-lib) -I$(bindbc-loader-include)
	cd ../

# Build the `bindbc-openal` dependency.
bindbc-openal-build:
	cd bindbc-openal
	$(DC) $(DFLAGSDEF) -lib -ofbindbc-openal/$(bindbc-openal-lib) $(bindbc-openal-objs) -I$(bindbc-loader-include)
	cd ../

# Build the `bindbc-freetype` dependency.
bindbc-freetype-build:
	cd bindbc-freetype
	$(DC) $(DFLAGSDEF) -lib -ofbindbc-freetype/$(bindbc-freetype-lib) $(bindbc-freetype-objs) -I$(bindbc-loader-include)
	cd ..

# Build the `imagefmt` dependency.
imagefmt-build:
	cd imagefmt
	$(DC) $(DFLAGSDEF) -lib -ofimagefmt/$(imagefmt-lib) $(imagefmt-objs)
	cd ..

# Build the `mp3decoder` dependency.
mp3decoder-build:
	cd mp3decoder
	$(DC) $(DFLAGSDEF) -lib -ofmp3decoder/$(mp3decoder-lib) $(mp3decoder-objs)
	cd ..

taggedalgebraic-build:
	cd taggedalgebraic
	$(DC) $(DFLAGSDEF) -lib -oftaggedalgebraic/$(taggedalgebraic-lib) $(taggedalgebraic-objs)

sdlang-d-build:
	cd SDLang-D
	$(DC) $(DFLAGSDEF) -lib -ofSDLang-D/$(sdlang-d-lib) $(sdlang-d-objs) $(taggedalgebraic-objs)

# Build the `x11` dependency.
x11-build:
	cd x11
	$(DC) $(DFLAGSDEF) -lib -ofx11/$(x11-lib) $(x11-objs)

# Builds all project dependencies into library files.
# It is necessary for the complete assembly of the project. Must be called before main assembly.
# Before this command, it is advisable to execute `fetch-deps` to get the desired dependencies.
build-deps: bindbc-loader-build bindbc-opengl-build bindbc-openal-build bindbc-freetype-build imagefmt-build mp3decoder-build taggedalgebraic-build sdlang-d-build x11-build
