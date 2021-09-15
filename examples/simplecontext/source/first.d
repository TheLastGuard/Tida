module first;

import tida;
import std.stdio;

class First : Scene
{
	@Event!Init
	void onInit() @safe
	{
		writeln("Hello Single!");
	}
}

mixin Single!First;
