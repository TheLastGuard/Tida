/++
Module for limiting the release of frames per second.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.fps;

import std.datetime;

/++
The object that will keep track of the cycle time, counts and
limits the executable frames.
+/
class FPSManager
{
    import core.thread;

private:
    MonoTime currTime;
    MonoTime lastTime;
    long _deltatime;

    MonoTime startProgramTime;
    bool isCountDownStartTime = false;
    long cfps = 0;
    long cpfps;
    MonoTime ctime;

public:
    /++
    Sets the maximum number of frames per second.
    +/
    long maxFPS = 60;

    /++
    Shows how many frames were formed in a second.
    Please note that the counter is updated once per second.
    +/
    @property long fps() @safe
    {
        return cpfps;
    }

    /++
    Shows the running time of the program.
    +/
    @property Duration timeJobProgram() @safe
    {
        return MonoTime.currTime - startProgramTime;
    }

    /++
    Delta time.
    +/
    @property long deltatime() @safe
    {
        return _deltatime;
    }

@trusted:
    /++
    The origin of the frame unit. Measures time and also changes the
    state of the frame counter.
    +/
    void countDown()
    {
        if (!isCountDownStartTime)
        {
            startProgramTime = MonoTime.currTime;
            isCountDownStartTime = true;
        }

        lastTime = MonoTime.currTime;

        if ((MonoTime.currTime - ctime).total!"msecs" > 1000)
        {
            cpfps = cfps;
            cfps = 0;
            ctime = MonoTime.currTime;
        }
    }

    /++
    Frame limiting function. Also, it counts frames per second.
    +/
    void control()
    {
        cfps++;
        currTime = MonoTime.currTime;
        _deltatime = 1000 / maxFPS - (currTime - lastTime).total!"msecs";

        if (_deltatime > 0)
        {
            Thread.sleep(dur!"msecs"(_deltatime));
        }
    }
}
