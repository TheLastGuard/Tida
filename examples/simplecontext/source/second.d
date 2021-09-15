module second;

import tida;
import std.stdio;

class Second : Scene
{
	@Event!Init
	void onInit() @safe
	{
		writeln("Hello Second!");
	}
}

mixin Single!Second;
