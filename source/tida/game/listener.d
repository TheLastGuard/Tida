/++
    Module for timer and global event handler.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.listener;

public import std.datetime;
import std.algorithm : remove;

__gshared Listener _listener;

Listener listener() @trusted
{
    return _listener;
}

alias TimerID = size_t;

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
struct Timer
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
    
    bool tick() @trusted
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
    bool isActual() @safe
    {
        return MonoTime.currTime - startTimer < duration;
    }

    /// Shows the remaining time.
    Duration remainder() @safe
    {
        return MonoTime.currTime - startTimer;
    }
}

/++
    Global timer and event handler.
+/
class Listener 
{
    import tida.event;
    import std.datetime;
    
    private
    {
        Event[] events;
        Timer[] timers;
    }

    void clearTimers() @trusted {
        timers = [];
    }

    /++
        Stop the timer if there is such an instance.

        Params:
            tm = Timer.
    +/
    void timerStop(ref Timer tm) @trusted
    {
        foreach(i; 0 .. timers.length)
        {
            if(timers[i] == tm) {
                timers = timers.remove(i);
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
    Timer* timer(void delegate() func,Duration duration,bool isRepeat = false) @trusted
    {
        timers ~= Timer(MonoTime.currTime,duration,isRepeat,func);

        return &timers[$-1];
    }
    
    /++
        Supply a function to handle events, no matter what the scene.
        
        Params:
            func = Function for handler. 
    +/
    void globalEvent(void delegate(EventHandler) func) @trusted
    {
        events ~= Event(func);
    }

    void eventHandle(EventHandler event) @trusted
    {
        foreach(ev; events)
        {
            ev.fn(event);
        }
    }
    
    void timerHandle() @safe
    {
        foreach(i; 0 .. timers.length)
        {
            if(timers[i].tick()) {
                timers = timers.remove(i);
                return;
            }
        }
    }
}