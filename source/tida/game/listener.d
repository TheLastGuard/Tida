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

private struct Timer
{
	import std.datetime;
	
	public 
	{
		MonoTime startTimer;
		Duration duration;
		bool isRepeat = false;
		void delegate() onEnd = null;
	}
	
	public bool tick() @trusted
	{
		if(MonoTime.currTime - startTimer > duration) {
			if(onEnd !is null) onEnd();
			
			if(isRepeat) {
				startTimer = MonoTime.currTime;
				return false;
			}else
				return true;
		}else
			return false;
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

	public bool timerIsActual(TimerID tm) @safe 
	{
		return (tm < timers.length);
	}

	public Duration timerRemaind(TimerID tm) @safe
	in(timerIsActual(tm))
	body
	{
		auto tmr = timers[tm];

		return MonoTime.currTime - tmr.startTimer;
	}

	public Duration timerDuration(TimerID tm) @safe
	in(timerIsActual(tm))
	body
	{
		return timers[tm].duration;
	}

	public void timerStop(TimerID tm) @safe
	in(timerIsActual(tm))
	body
	{
		timers.remove(tm);
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

		Returns: ID
	+/
	public TimerID timer(void delegate() func,Duration duration,bool isRepeat = false) @trusted
	{
		timers ~= Timer(MonoTime.currTime,duration,isRepeat,func);

		return timers.length - 1;
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