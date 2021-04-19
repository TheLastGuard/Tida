/++
    A module for controlling the number of frames, and taking into account the time of the program.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.fps;

/// Class for controlling program time and number of frames.
class FPSManager
{
    import std.datetime, core.thread;

    private
    {
        MonoTime time;
        MonoTime lastTime;
        long _deltatime;

        MonoTime _gameJob;
        bool startTimeRate = false;
    }

    public
    {
        long maxFPS = 60; /// The maximum number of frames per second allowed.
    }

    /// Gives the number of frames.
    long fps() @safe
    {
        return (1000 / (_deltatime + 1));
    }

    /// Gives the deltatime.
    long deltatime() @safe
    {
        return _deltatime;
    }

    /// Gives the running time of the program.
    Duration durationJobProgram() @safe
    {
        return MonoTime.currTime - _gameJob;
    }

    /// Counts from the beginning of the cycle body.
    void start() @safe
    {
        time = MonoTime.currTime;

        if(!startTimeRate) {
            _gameJob = MonoTime.currTime;

            startTimeRate = true;
        }
    }

    /// Limiting the number of frames.
    void rate() @trusted
    {
        this.lastTime = MonoTime.currTime;
        this._deltatime = (this.lastTime - this.time).total!"msecs";

        if(this._deltatime < 1000 / maxFPS)
        {
            import std.datetime;
            Thread.sleep(dur!"msecs"((1000 / maxFPS) - this._deltatime));
        }
    }
}