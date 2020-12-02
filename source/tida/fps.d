/++

+/
module tida.fps;

public class FPSManager
{
	import std.datetime;

	public
    {
        ulong maxFps = 60; /// Maximum FPS
    }

    private
    {
        MonoTime time;
        MonoTime lastTime;

        long _deltatime;
        long _fps = 0;

        long __frames = 0;
        MonoTime _gameJob;
        bool startTimeRate = false;
    }

    /++
        Give current FPS.

        Returns:
            float - FPS
    ++/
    public immutable(ulong) fps() @safe @property
    {
        return _fps;
    }

    ///
    immutable(ulong) opCall() @safe
    {
        return fps();
    }

    /++
        Returns deltatime
    +/
    public immutable(ulong) deltatime() @safe @property
    {
        return _deltatime;
    }

    /++
        Starts counting.
    ++/
    public void start() @trusted
    {
        this.time = MonoTime.currTime;

        if(!startTimeRate) {
            _gameJob = MonoTime.currTime;

            startTimeRate = true;
        }
    }

    public Duration getTimeJobProgram() @trusted
    {
        return lastTime - _gameJob;
    }

    /++
        Delay process itself.
    ++/
    public void rate() @trusted
    {
        import core.thread;

        this.lastTime = MonoTime.currTime;
        this._deltatime = (this.lastTime - this.time).total!"msecs";

        if(this._deltatime < 1000 / maxFps)
        {
            import std.datetime;
            this._fps = (1000 / (this._deltatime + 1));
            Thread.sleep(dur!"msecs"((1000 / maxFps) - this._deltatime));
        }
    }
}