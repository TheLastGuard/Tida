/++
    Module for describing animation.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.animation;

import tida.graph.drawable;

/++
    Object for describin animation. 
+/
class Animation : IDrawable, IDrawableEx
{
    import tida.graph.image;

    private
    {
        Image[] _frames;
        float _speed = 0.0f;
        float _current = 0.0f;
    }

    public
    {
        bool isRepeat = true; /// Whether the animation needs to be repeated.
    }

    /// Animation frames.
    Image[] frames() @safe @property
    {
        return _frames;
    }

    /// Animation frames
    void frames(Image[] value) @safe @property
    {
        _frames = value;
    }

    /// Animation speed
    float speed() @safe @property
    {
        return _speed;
    }

    /// Animation speed
    void speed(float value) @safe @property
    in(value != float.nan)
    body
    {
        _speed = value;
    }

    /// Return current frame
    Image currentFrame() @safe @property
    {
        return _frames[cast(size_t) _current > $ - 1 ? $ - 1 : cast(size_t) _current];
    }

    /// Return position current frame
    float numFrame() @safe @property
    {
        return _current;
    }

    /// Resets the animation to the beginning.
    void reset() @safe {
        _current = 0.0f;
    }

    /// Step animation
    Image step() @safe
    {
        if(cast(int) _current >= _frames.length) {
            if(isRepeat) {
                _current = -speed;
            } 
        }else {
            _current += speed;
        }

        return currentFrame();
    }

    import tida.graph.render;
    import tida.vector;
    import tida.color;

    override void draw(IRenderer render, Vecf position) @safe
    {
        render.draw(this.step(), position);
    }

    override void drawEx(IRenderer render, Vecf position, float angle, Vecf center, Vecf size, ubyte alpha, Color!ubyte color) @safe
    {
        render.drawEx(this.step(), position, angle, center, size, alpha, color);
    }
}
