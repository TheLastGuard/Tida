# An assembly file for assembling the library in a 64-bit Windows environment.	
include win64deps.inc

all: 
	@echo Enter `make help` for details.

help:
	@echo The available subcommands for doing collection and cleaning manipulation are:
	@echo `fetch-deps` - Downloads all necessary dependencies to the project folder.
	@echo `build-deps` - Builds all dependencies into libraries for further use by the framework.
	@echo `build` - Builds the library into a file `libtida.lib`
	@echo `run-test` - Collects and runs all unit tests in the project.
	@echo `clean` - Cleans the project from assembly garbage.

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
