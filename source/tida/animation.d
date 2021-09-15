/++
An module for describing animation
(frame-by-frame, by changing rendering objects among themselves).

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.animation;

import tida.drawable;

/++
An object for describing animation
(frame-by-frame, by changing rendering objects among themselves).
+/
class Animation : IDrawable, IDrawableEx
{
    import tida.vector;
    import tida.color;
    import tida.render;

private:
    float _current = 0.0f;

public:
    /// Animation speed.
    float speed = 0.0f;
    /// Animation frames.
    IDrawableEx[] frames = [];
    /// When the animation ends, whether the animation needs to be re-run.
    bool isRepeat = false;

@safe:
    /++
    The current frame of the animation.
    +/
    @property IDrawableEx currentFrame()
    {
        return frames[cast(size_t) _current > $ - 1 ? $ - 1 : cast(size_t) _current];
    }

    /++
    The current position of the animation.
    +/
    @property float numFrame()
    {
        return _current;
    }

    /++
    The current position of the animation.
    +/
    @property void numFrame(float currFrame)
    {
        _current = currFrame;
    }

    /++
    Starts the animation from the beginning.
    +/
    void reset()
    {
        _current = 0.0f;
    }

    /++
    Carries out animation of objects by frame-by-frame change.

    Returns:
        The current frame of animation.
    +/
    IDrawableEx step()
    {
        if(cast(int) _current >= frames.length) {
            if(isRepeat) {
                _current = -speed;
            }
        }else {
            _current += speed;
        }

        return currentFrame();
    }

override:
    void draw(IRenderer renderer, Vecf position)
    {
        IDrawableEx draws = step();

        draws.drawEx(renderer, position, 0.0, vecfNaN, vecfNaN, 255, rgb(255, 255, 255));
    }

    void drawEx(IRenderer renderer,
                Vecf position,
                float angle,
                Vecf center,
                Vecf size,
                ubyte alpha,
                Color!ubyte color = rgb(255, 255, 255))
    {
        IDrawableEx draws = step();

        draws.drawEx(renderer, position, angle, center, size, alpha, color);
    }
}
