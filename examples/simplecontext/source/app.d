module app;

import tida;
import std.stdio;

class Main : Scene
{
	@Event!Init
	void onInit() @safe
	{
		writeln("Hello Main!");
	}
}

mixin GameRun!(GameConfig config, Main, First, Second);
