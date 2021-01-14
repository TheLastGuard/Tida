/++
    Module for describing animation.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.animation;

/++
    Object for describin animation. 
+/
class Animation
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
    Image currentFrame() @safe
    {
        return _frames[cast(size_t) _current > $ - 1 ? $ - 1 : cast(size_t) _current];
    }

    /// Return position current frame
    float numFrame() @safe 
    {
        return _current;
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
}