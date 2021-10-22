# An assembly file for assembling the library in a 64-bit Posix environment.	

# Project build method
DC = dmd
DFLAGSDEF = -version=GL_46 -version=Dynamic_GLX -m64

# Dependencies
# Links to the dependency repository.
bindbc-loader = https://github.com/BindBC/bindbc-loader
bindbc-opengl = https://github.com/BindBC/bindbc-opengl
bindbc-openal = https://github.com/BindBC/bindbc-openal
bindbc-freetype = https://github.com/BindBC/bindbc-freetype
imagefmt = https://github.com/tjhann/imagefmt
mp3decoder = https://github.com/Zoadian/mp3decoder
x11 = https://github.com/nomad-software/x11

# Path to source dependency files.
bindbc-loader-include = bindbc-loader/source/
bindbc-opengl-include = bindbc-opengl/source/
bindbc-openal-include = bindbc-openal/source/
bindbc-freetype-include = bindbc-freetype/source/
imagefmt-include = imagefmt/
mp3decoder-include = mp3decoder/source/
x11-include = x11/source/

# File units in the source code.
bindbc-loader-objs = $(shell find $(bindbc-loader-include) -type f -name '*.d')
bindbc-opengl-objs = $(shell find $(bindbc-opengl-include) -type f -name '*.d')
bindbc-openal-objs = $(shell find $(bindbc-openal-include) -type f -name '*.d')
bindbc-freetype-objs = $(shell find $(bindbc-freetype-include) -type f -name '*.d')
imagefmt-objs = $(shell find $(imagefmt-include)/imagefmt/ -type f -name '*.d')
mp3decoder-objs = $(shell find $(mp3decoder-include) -type f -name '*.d')
x11-objs = $(shell find $(x11-include) -type f -name '*.d')

# Library files to be built.
bindbc-loader-lib = bindbc-loader.a
bindbc-opengl-lib = bindbc-opengl.a
bindbc-openal-lib = bindbc-openal.a
bindbc-freetype-lib = bindbc-freetype.a
imagefmt-lib = imagefmt.a
mp3decoder-lib = mp3decoder.a
x11-lib = x11.a

# Flags for including libraries in the assembly.
LIBDFLAGS = bindbc-loader/$(bindbc-loader-lib) bindbc-opengl/$(bindbc-opengl-lib) bindbc-openal/$(bindbc-openal-lib) bindbc-freetype/$(bindbc-freetype-lib) imagefmt/$(imagefmt-lib) mp3decoder/$(mp3decoder-lib) x11/$(x11-lib)

# Flags to include source files in the assembly.
DEPENDFLAGS = -I$(bindbc-loader-include) -I$(bindbc-opengl-include) -I$(bindbc-openal-include) -I$(bindbc-freetype-include) -I$(imagefmt-include) -I$(mp3decoder-include) -I$(x11-include)

all: 
	@echo Enter \"make help\" for details.

help:
	@echo The available subcommands for doing collection and cleaning manipulation are:
	@echo \"fetch-deps\" - Downloads all necessary dependencies to the project folder.
	@echo \"build-deps\" - Builds all dependencies into libraries for further use by the framework.
	@echo \"build\" - Builds the library into a file \"libtida.lib\"
	@echo \"run-test\" - Collects and runs all unit tests in the project.
	@echo \"clean\" - Cleans the project from assembly garbage.

# Downloads the source code for all required dependencies.
# Execute before building the project.
fetch-deps:
	[ -d ./bindbc-loader ] || git clone $(bindbc-loader)
	[ -d ./bindbc-opengl ] || git clone $(bindbc-opengl)
	[ -d ./bindbc-openal ] || git clone $(bindbc-openal)
	[ -d ./bindbc-freetype ] || git clone $(bindbc-freetype)
	[ -d ./imagefmt ] || git clone $(imagefmt)
	[ -d ./mp3decoder ] || git clone $(mp3decoder)
	[ -d ./x11 ] || git clone $(x11)

fetch-clean:
	[ -f ./bindbc-loader/$(bindbc-loader-lib) ] && rm ./bindbc-loader/$(bindbc-loader-lib) || .
	[ -f ./bindbc-opengl/$(bindbc-opengl-lib) ] && rm ./bindbc-opengl/$(bindbc-opengl-lib) || .
	[ -f ./bindbc-openal/$(bindbc-openal-lib) ] && rm ./bindbc-openal/$(bindbc-openal-lib) || .
	[ -f ./bindbc-freetype/$(bindbc-freetype-lib) ] && rm ./bindbc-freetype/$(bindbc-freetype-lib) || .
	[ -f ./imagefmt/$(imagefmt-lib) ] && rm ./imagefmt/$(imagefmt-lib) || .
	[ -f ./mp3decoder/$(mp3decoder-lib) ] && rm ./mp3decoder/$(mp3decoder-lib) || . 
	[ -f ./x11/$(x11-lib) ] && rm ./x11/$(x11-lib) || .

deps-remove:
	[ -d ./bindbc-loader ] && rm -rf ./bindbc-loader || .
	[ -d ./bindbc-opengl ] && rm -rf ./bindbc-opengl || .
	[ -d ./bindbc-openal ] && rm -rf ./bindbc-openal || .
	[ -d ./bindbc-freetype ] && rm -rf ./bindbc-freetype || .
	[ -d ./imagefmt ] && rm -rf ./imagefmt || .
	[ -d ./mp3decoder ] && rm -rf ./mp3decoder || .
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

# Build the `x11` dependency.
x11-build:
	cd x11
	$(DC) $(DFLAGSDEF) -lib -ofx11/$(x11-lib) $(x11-objs)

# Builds all project dependencies into library files.
# It is necessary for the complete assembly of the project. Must be called before main assembly.
# Before this command, it is advisable to execute `fetch-deps` to get the desired dependencies.
build-deps: bindbc-loader-build bindbc-opengl-build bindbc-openal-build bindbc-freetype-build imagefmt-build mp3decoder-build x11-build

SRC = source/
TIDASRC = $(SRC)tida/
DGLXSRC = $(SRC)dglx/
OBJS = $(TIDASRC)algorithm.d $(TIDASRC)angle.d $(TIDASRC)animation.d $(TIDASRC)collision.d $(TIDASRC)color.d $(TIDASRC)component.d $(TIDASRC)drawable.d $(TIDASRC)each.d $(TIDASRC)event.d $(TIDASRC)fps.d $(TIDASRC)game.d $(TIDASRC)gl.d $(TIDASRC)image.d $(TIDASRC)instance.d $(TIDASRC)listener.d $(TIDASRC)loader.d $(TIDASRC)localevent.d $(TIDASRC)matrix.d $(TIDASRC)package.d $(TIDASRC)render.d $(TIDASRC)runtime.d $(TIDASRC)scene.d $(TIDASRC)scenemanager.d $(TIDASRC)shader.d $(TIDASRC)shape.d $(TIDASRC)softimage.d $(TIDASRC)sound.d $(TIDASRC)sprite.d $(TIDASRC)text.d $(TIDASRC)texture.d $(TIDASRC)vector.d $(TIDASRC)vertgen.d $(TIDASRC)window.d $(DGLXSRC)glx.d

DFLAGS = $(DEPENDFLAGS) $(DFLAGSDEF)

# Builds the project library.
# Before doing this, it is advisable to get the dependencies and build them using the `fetch-deps` and` build-deps` commands.
build: $(OBJS)
	$(DC) -lib -oflibtida.a $(OBJS) $(LIBDFLAGS) $(DFLAGS)

# Builds the library testing program.
build-test:
	$(DC) -c -unittest -main -oftidatest.o $(OBJS) $(DFLAGS)
	$(DC) -oftidatest -L--no-as-needed -L-lX11 -L-ldl tidatest.o $(LIBDFLAGS)

# Builds and run the library testing program.
run-test: build-test
	./tidatest

clean:
	[ -f ./libtida.a ] && rm libtida.a || .
	[ -f ./tidatest ] && rm tidatest || .
	[ -f ./tidatest.o ] && rm tidatest.o || .
	[ -d ./docs ] && rm -rf docs  || .