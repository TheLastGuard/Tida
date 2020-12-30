/++
	Module for timer and global event handler.

	Authors: TodNaz
	License: MIT
+/
module tida.game.listener;

public import std.datetime;

__gshared Listener _listener;

alias TimerID = size_t;

/// Global access to such an instance.
public Listener listener() @trusted
{
	return _listener;
}

private struct Event
{
	import tida.event;

	public
	{
		void delegate(EventHandler) fn;
	}
}

/++
	Timer.
+/
public struct Timer
{
	import std.datetime;
	
	public 
	{
		MonoTime startTimer; /// The time the timer started the action.
		Duration duration; /// Timer interval.
		bool isRepeat = false; /// Whether the timer needs to be repeated.
		void delegate() onEnd = null; /// Function at timer end.

		alias interval = duration;
	}
	
	package bool tick() @trusted
	{
		if(!isActual) {
			if(onEnd !is null) onEnd();
			
			if(isRepeat) {
				startTimer = MonoTime.currTime;
				return false;
			}else
				return true;
		}else
			return false;
	}

	/// Indicates whether the timer is in effect.
	public bool isActual() @safe
	{
		return MonoTime.currTime - startTimer < duration;
	}

	/// Shows the remaining time.
	public Duration remainder() @safe
	{
		return MonoTime.currTime - startTimer;
	}
}

private void remove(T)(ref T[] obj,size_t index) @trusted nothrow
{
    auto dump = obj.dup;
    foreach (i; index .. dump.length)
    {
        import core.exception : RangeError;
        try
        {
            dump[i] = dump[i + 1];
        }
        catch (RangeError e)
        {
            continue;
        }
    }
    obj = dump[0 .. $-1];
}

/++
	Global timer and event handler.
+/
public class Listener 
{
	import tida.event;
	import std.datetime;
	
	private
	{
		Event[] events;
		Timer[] timers;
	}

	/++
		Stop the timer if there is such an instance.

		Params:
			tm = Timer.
	+/
	public void timerStop(ref Timer tm) @trusted
	{
		foreach(i; 0 .. timers.length)
		{
			if(timers[i] == tm) {
				timers.remove(i);
				return;
			}
		}
	}

	/++
		Start a timer.
		
		Params:
			func = The function to call when the timer expires.
			duration = Timer duration.
			isRepeat = Whether to repeat the timer.
			
		Example:
		---
		listener.timer({
			writeln("3 seconds!");
		},dur!"msecs"(3000),true);
		---

		Returns: A pointer to a timer.
	+/
	public Timer* timer(void delegate() func,Duration duration,bool isRepeat = false) @trusted
	{
		timers ~= Timer(MonoTime.currTime,duration,isRepeat,func);

		return &timers[$];
	}
	
	/++
		Supply a function to handle events, no matter what the scene.
		
		Params:
			func = Function for handler. 
	+/
	public void globalEvent(void delegate(EventHandler) func) @trusted
	{
		events ~= Event(func);
	}

	public void eventHandle(EventHandler event) @trusted
	{
		foreach(ev; events)
		{
			ev.fn(event);
		}
	}
	
	public void timerHandle() @safe
	{
		foreach(i; 0 .. timers.length)
		{
			if(timers[i].tick()) {
				timers.remove(i);
				return;
			}
		}
	}
}