/++
	Module for describing animation.

	Authors: TodNaz
	License: MIT
+/
module tida.game.animation;

/++
	Object for describin animation. 
+/
public class Animation
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
	public Image[] frames() @safe @property
	{
		return _frames;
	}

	/// Animation frames
	public void frames(Image[] value) @safe @property
	{
		_frames = value;
	}

	/// Animation speed
	public float speed() @safe @property
	{
		return _speed;
	}

	/// Animation speed
	public void speed(float value) @safe @property
	in(value != float.nan)
	body
	{
		_speed = value;
	}
	
	/++
		Creates frames from one sample picture.

		Params:
			image = The picture from where the frames will be received.
			x = The beginning of the cut by x-axis.
			y = The beginning of the cut by y-axis.
			w = Width frames.
			h = Height frames.

		Example:
		---
		anim.strip(new Image("atlas.png"),0,0,32,32);
		---
	+/
	public void strip(Image image,int x,int y,int w,int h) @safe
	{
		for(int ix = x; ix < image.width; ix += w) {
			_frames ~= image.copy(ix,y,w,h);
		}
	}

	/// Return current frame
	public Image currentFrame() @safe
	{
		return _frames[cast(size_t) _current > $ - 1 ? $ - 1 : cast(size_t) _current];
	}

	/// Return position current frame
	public float numFrame() @safe 
	{
		return _current;
	}

	/// Step animation
	public Image step() @safe
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