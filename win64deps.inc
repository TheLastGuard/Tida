# Project build method.
DC = dmd
DFLAGSDEF = -version=GL_46 -m64 -preview=shortenedMethods

# Dependencies
# Links to the dependency repository.
bindbc-loader = https://github.com/BindBC/bindbc-loader
bindbc-opengl = https://github.com/BindBC/bindbc-opengl
bindbc-openal = https://github.com/BindBC/bindbc-openal
bindbc-freetype = https://github.com/BindBC/bindbc-freetype
imagefmt = https://github.com/tjhann/imagefmt
mp3decoder = https://github.com/Zoadian/mp3decoder
sdlang-d = https://github.com/Abscissa/SDLang-D.git
taggedalgebraic = https://github.com/s-ludwig/taggedalgebraic.git

# Path to source dependency files.
bindbc-loader-include = bindbc-loader\\source\\
bindbc-opengl-include = bindbc-opengl\\source\\
bindbc-openal-include = bindbc-openal\\source\\
bindbc-freetype-include = bindbc-freetype\\source\\
imagefmt-include = imagefmt\\
mp3decoder-include = mp3decoder\\source\\
sdlang-d-include = SDLang-D\\src\\
taggedalgebraic-include = taggedalgebraic\\source\\

# File units in the source code.
bindbc-loader-objs = $(shell dir $(bindbc-loader-include) /s /B | find /I ".d")
bindbc-opengl-objs = $(shell dir $(bindbc-opengl-include) /s /B | find /I ".d")
bindbc-openal-objs = $(shell dir $(bindbc-openal-include) /s /B | find /I ".d")
bindbc-freetype-objs = $(shell dir $(bindbc-freetype-include) /s /B | find /I ".d")
imagefmt-objs = $(shell dir $(imagefmt-include)imagefmt\\ /s /B | find /I ".d")
mp3decoder-objs = $(shell dir $(mp3decoder-include) /s /B | find /I ".d")
sdlang-d-objs = $(shell dir $(sdlang-d-include) /s /B | find /I ".d")
taggedalgebraic-objs =$(shell dir $(taggedalgebraic-include) /s /B | find /I ".d")

sdlang-d-objs = $(shell find $(sdlang-d-include) -type f -name '*.d')
taggedalgebraic-objs = $(shell find $(taggedalgebraic-include) -type f -name '*.d')

# Library files to be built.
bindbc-loader-lib = bindbc-loader.lib
bindbc-opengl-lib = bindbc-opengl.lib
bindbc-openal-lib = bindbc-openal.lib
bindbc-freetype-lib = bindbc-freetype.lib
imagefmt-lib = imagefmt.lib
mp3decoder-lib = mp3decoder.lib
sdlang-d-lib = sdland-d.a
taggedalgebraic-lib = taggedalgebraic.a

# Flags for including libraries in the assembly.
LIBDFLAGS = bindbc-loader/$(bindbc-loader-lib) bindbc-opengl/$(bindbc-opengl-lib) bindbc-openal/$(bindbc-openal-lib) bindbc-freetype/$(bindbc-freetype-lib) imagefmt/$(imagefmt-lib) mp3decoder/$(mp3decoder-lib) SDLang-D/$(sldang-d-lib) taggedalgebraic/$(taggedalgebraic-lib)

# Flags to include source files in the assembly.
DEPENDFLAGS = -I$(bindbc-loader-include) -I$(bindbc-opengl-include) -I$(bindbc-openal-include) -I$(bindbc-freetype-include) -I$(imagefmt-include) -I$(mp3decoder-include) -I$(taggedalgebraic-include) -I$(sdlang-d-include)

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

taggedalgebraic-build:
	cd taggedalgebraic
	$(DC) $(DFLAGSDEF) -lib -oftaggedalgebraic/$(taggedalgebraic-lib) $(taggedalgebraic-objs)

sdlang-d-build:
	cd SDLang-D
	$(DC) $(DFLAGSDEF) -lib -ofSDLang-D/$(sdlang-d-lib) $(sdlang-d-objs) $(taggedalgebraic-objs)

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
	if not exist ".\SDLang" git clone $(sdlang-d)
	if not exist ".\taggedalgebraic" git clone $(taggedalgebraic)

# Cleans up garbage from the dependency collection.
fetch-clean:
	if exist ".\\bindbc-loader\\$(bindbc-loader-lib)" del ".\\bindbc-loader\\$(bindbc-loader-lib)"
	if exist ".\\bindbc-opengl\\$(bindbc-opengl-lib)" del ".\\bindbc-opengl\\$(bindbc-opengl-lib)"
	if exist ".\\bindbc-openal\\$(bindbc-openal-lib)" del ".\\bindbc-openal\\$(bindbc-openal-lib)"
	if exist ".\\bindbc-freetype\\$(bindbc-freetype-lib)" del ".\\bindbc-freetype\\$(bindbc-freetype-lib)"
	if exist ".\\imagefmt\\$(imagefmt-lib)" del ".\\imagefmt\\$(imagefmt-lib)"
	if exist ".\\mp3decoder\\$(mp3decoder-lib)" del ".\\mp3decoder\\$(mp3decoder-lib)" 
	if exist ".\\taggedalgebraic\\$(taggedalgebraic-lib)" del ".\\taggedalgebraic\\$(taggedalgebraic-lib)"
	if exist ".\\SDLang-D\\$(sdlang-d-lib)" del ".\\SDLang-D\\$(sdlang-d-lib)"

# Removes dependency folders. 
deps-remove:
	if exist ".\bindbc-loader" del ".\bindbc-loader"
	if exist ".\bindbc-opengl" del ".\bindbc-opengl"
	if exist ".\bindbc-openal" del ".\bindbc-openal"
	if exist ".\bindbc-freetype" del ".\bindbc-freetype"
	if exist ".\imagefmt" del ".\imagefmt"
	if exist ".\mp3decoder" del ".\mp3decoder"
	if exist ".\taggedalgebraic" del ".\taggedalgebraic"
	if exist ".\SDLang-D" del ".\SDLang-D"
