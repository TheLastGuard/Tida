import std.process;
import std.stdio;
import std.datetime;

void main(string[] args) {
	MonoTime currTime = MonoTime.currTime;
	wait(spawnProcess(args[1]));
	writeln(MonoTime.currTime - currTime);
}
