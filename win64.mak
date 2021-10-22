# An assembly file for assembling the library in a 64-bit Windows environment.	

# Project build method.
DC = dmd
DFLAGSDEF = -version=GL_46 -m64

# Dependencies
# Links to the dependency repository.
bindbc-loader = https://github.com/BindBC/bindbc-loader
bindbc-opengl = https://github.com/BindBC/bindbc-opengl
bindbc-openal = https://github.com/BindBC/bindbc-openal
bindbc-freetype = https://github.com/BindBC/bindbc-freetype
imagefmt = https://github.com/tjhann/imagefmt
mp3decoder = https://github.com/Zoadian/mp3decoder

# Path to source dependency files.
bindbc-loader-include = bindbc-loader\\source\\
bindbc-opengl-include = bindbc-opengl\\source\\
bindbc-openal-include = bindbc-openal\\source\\
bindbc-freetype-include = bindbc-freetype\\source\\
imagefmt-include = imagefmt\\
mp3decoder-include = mp3decoder\\source\\

# File units in the source code.
bindbc-loader-objs = $(shell dir $(bindbc-loader-include) /s /B | find /I ".d")
bindbc-opengl-objs = $(shell dir $(bindbc-opengl-include) /s /B | find /I ".d")
bindbc-openal-objs = $(shell dir $(bindbc-openal-include) /s /B | find /I ".d")
bindbc-freetype-objs = $(shell dir $(bindbc-freetype-include) /s /B | find /I ".d")
imagefmt-objs = $(shell dir $(imagefmt-include)imagefmt\\ /s /B | find /I ".d")
mp3decoder-objs = $(shell dir $(mp3decoder-include) /s /B | find /I ".d")

# Library files to be built.
bindbc-loader-lib = bindbc-loader.lib
bindbc-opengl-lib = bindbc-opengl.lib
bindbc-openal-lib = bindbc-openal.lib
bindbc-freetype-lib = bindbc-freetype.lib
imagefmt-lib = imagefmt.lib
mp3decoder-lib = mp3decoder.lib

# Flags for including libraries in the assembly.
LIBDFLAGS = bindbc-loader\\$(bindbc-loader-lib) bindbc-opengl\\$(bindbc-opengl-lib) bindbc-openal\\$(bindbc-openal-lib) bindbc-freetype\\$(bindbc-freetype-lib) imagefmt\\$(imagefmt-lib) mp3decoder\\$(mp3decoder-lib)

# Flags to include source files in the assembly.
DEPENDFLAGS = -I$(bindbc-loader-include) -I$(bindbc-opengl-include) -I$(bindbc-openal-include) -I$(bindbc-freetype-include) -I$(imagefmt-include) -I$(mp3decoder-include)

all: 
	@echo Enter `make help` for details.

help:
	@echo The available subcommands for doing collection and cleaning manipulation are:
	@echo `fetch-deps` - Downloads all necessary dependencies to the project folder.
	@echo `build-deps` - Builds all dependencies into libraries for further use by the framework.
	@echo `build` - Builds the library into a file `libtida.lib`
	@echo `run-test` - Collects and runs all unit tests in the project.
	@echo `clean` - Cleans the project from assembly garbage.

# Build the `bindbc-loader` dependency.
bindbc-loader-build:
	cd bindbc-loader && $(DC) $(DFLAGSDEF) -lib -of$(bindbc-loader-lib) $(bindbc-loader-objs)

# Build the `bindbc-opengl` dependency.
bindbc-opengl-build:
	cd bindbc-opengl && $(DC) $(DFLAGSDEF) -lib -of$(bindbc-opengl-lib) $(bindbc-opengl-objs) -I..\\$(bindbc-loader-include) -version=GL_46

# Build the `bindbc-openal` dependency.
bindbc-openal-build:
	cd bindbc-openal && $(DC) $(DFLAGSDEF) -lib -of$(bindbc-openal-lib) $(bindbc-openal-objs) -I..\\$(bindbc-loader-include)

# Build the `bindbc-freetype` dependency.
bindbc-freetype-build:
	cd bindbc-freetype && $(DC) $(DFLAGSDEF) -lib -of$(bindbc-freetype-lib) $(bindbc-freetype-objs) -I..\\$(bindbc-loader-include)

# Build the `imagefmt` dependency.
imagefmt-build:
	cd imagefmt && $(DC) $(DFLAGSDEF) -lib -of$(imagefmt-lib) $(imagefmt-objs)

# Build the `mp3decoder` dependency.
mp3decoder-build:
	cd mp3decoder && $(DC) $(DFLAGSDEF) -lib -of$(mp3decoder-lib) $(mp3decoder-objs)

# Builds all project dependencies into library files.
# It is necessary for the complete assembly of the project. Must be called before main assembly.
# Before this command, it is advisable to execute `fetch-deps` to get the desired dependencies.
build-deps: bindbc-loader-build bindbc-opengl-build bindbc-openal-build bindbc-freetype-build imagefmt-build mp3decoder-build

# Downloads the source code for all required dependencies.
# Execute before building the project.
fetch-deps:
	if not exist ".\bindbc-loader" git clone $(bindbc-loader)
	if not exist ".\bindbc-opengl" git clone $(bindbc-opengl)
	if not exist ".\bindbc-openal" git clone $(bindbc-openal)
	if not exist ".\bindbc-freetype" git clone $(bindbc-freetype)
	if not exist ".\imagefmt" git clone $(imagefmt)
	if not exist ".\mp3decoder" git clone $(mp3decoder)

# Cleans up garbage from the dependency collection.
fetch-clean:
	if exist ".\\bindbc-loader\\$(bindbc-loader-lib)" del ".\\bindbc-loader\\$(bindbc-loader-lib)"
	if exist ".\\bindbc-opengl\\$(bindbc-opengl-lib)" del ".\\bindbc-opengl\\$(bindbc-opengl-lib)"
	if exist ".\\bindbc-openal\\$(bindbc-openal-lib)" del ".\\bindbc-openal\\$(bindbc-openal-lib)"
	if exist ".\\bindbc-freetype\\$(bindbc-freetype-lib)" del ".\\bindbc-freetype\\$(bindbc-freetype-lib)"
	if exist ".\\imagefmt\\$(imagefmt-lib)" del ".\\imagefmt\\$(imagefmt-lib)"
	if exist ".\\mp3decoder\\$(mp3decoder-lib)" del ".\\mp3decoder\\$(mp3decoder-lib)" 

# Removes dependency folders. 
fetch-remove:
	if exist ".\bindbc-loader" del ".\bindbc-loader"
	if exist ".\bindbc-opengl" del ".\bindbc-opengl"
	if exist ".\bindbc-openal" del ".\bindbc-openal"
	if exist ".\bindbc-freetype" del ".\bindbc-freetype"
	if exist ".\imagefmt" del ".\imagefmt"
	if exist ".\mp3decoder" del ".\mp3decoder"

SRC = source\\
TIDASRC = $(SRC)tida\\
OBJS = $(TIDASRC)algorithm.d $(TIDASRC)angle.d $(TIDASRC)animation.d $(TIDASRC)collision.d $(TIDASRC)color.d $(TIDASRC)component.d $(TIDASRC)drawable.d $(TIDASRC)each.d $(TIDASRC)event.d $(TIDASRC)fps.d $(TIDASRC)game.d $(TIDASRC)gl.d $(TIDASRC)image.d $(TIDASRC)instance.d $(TIDASRC)listener.d $(TIDASRC)loader.d $(TIDASRC)localevent.d $(TIDASRC)matrix.d $(TIDASRC)package.d $(TIDASRC)render.d $(TIDASRC)runtime.d $(TIDASRC)scene.d $(TIDASRC)scenemanager.d $(TIDASRC)shader.d $(TIDASRC)shape.d $(TIDASRC)softimage.d $(TIDASRC)sound.d $(TIDASRC)sprite.d $(TIDASRC)text.d $(TIDASRC)texture.d $(TIDASRC)vector.d $(TIDASRC)vertgen.d $(TIDASRC)window.d

DFLAGS = $(DEPENDFLAGS) $(DFLAGSDEF)

# Builds the project library.
# Before doing this, it is advisable to get the dependencies and build them using the `fetch-deps` and` build-deps` commands.
build: $(OBJS)
	$(DC) -lib -oflibtida.lib $(OBJS) $(LIBDFLAGS) $(DFLAGS)

build-docs: $(OBJS)
	if not exist docs mkdir docs
	$(DC) -D -Dddocs -main $(OBJS) $(LIBDFLAGS) user32.lib gdi32.lib $(DFLAGS)

# Builds the library testing program.
build-test: $(OBJS)
	$(DC) -unittest -main user32.lib gdi32.lib -oftidatest.exe $(OBJS) $(LIBDFLAGS) $(DFLAGS)

# Builds and run the library testing program.
run-test: build-test
	.\\tidatest.exe

# Cleans the project from debris.
clean:
	if exist "libtida.lib" del libtida.lib
	if exist "tidatest.exe" del tidatest.exe
	if exist "tidatest.o" del tidatest.o
	if exist "docs" del docs

# Cleans up project and junk dependencies.
clean-all: clean fetch-clean