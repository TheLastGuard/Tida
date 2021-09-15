module app;

import std.file;
import std.process : spawnProcess, wait;

static appFile =
`module app;

import tida;

class Main : Scene
{
	this() @safe
	{
		name = "Main";
	}
}

mixin GameRun!(GameConfig(640, 480, "window"), Main);
`;

void writeProject(string dir)
{
	write(dir ~ "/source/app.d", appFile);
}

int main(string[] args)
{
	import std.algorithm;
	import std.array;

	auto dirs = dirEntries(".", SpanMode.depth).filter!(a => a.isDir).array;
	int result = spawnProcess(["dub", "init"]).wait;
	if (result != 0)
		return result;
	
	if (exists("dub.json") || exists("dub.sdl"))
	{
		writeProject(".");
		return 0;
	}
	
	auto edirs = dirEntries(".", SpanMode.depth).filter!(a => a.isDir).array;
	
	for (int i = 0; i < edirs.length; ++i)
	{
		if(i >= dirs.length) break;
		
		if (dirs[i] != edirs[i])
		{
			writeProject(edirs[i]);
			break;
		}
	}
	
	return 0;
}
