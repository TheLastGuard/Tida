/++
Module for animation of movement / frames and others. Contains a mutating
variable and a function that depends on it.

See_Also:
	$(HREF https://github.com/ai/easings.net, Easing open source)

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.animobj;

/++
Object animation interface.
+/
interface IAnimated
{
@safe:
	/++
	Object animation function. Through such a call and a coefficient argument, 
	an animation is produced.
	
	Params:
		k = Animation step. Its range is from zero to one.
	+/
    void animation(float k);
}

/// Ease in sine animation
void easeInSine(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : cos, PI;

	step = 1 - cos((k * PI) / 2);
}

/// Ease out sine animation
void easeOutSine(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : sin, PI;
	
	step = sin((k * PI) / 2);
}

/// Ease in out sine animation
void easeInOutSine(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : cos, PI;
	
	step = -(cos(PI * k) - 1) / 2;
}

/// Ease in degree animation
void easeIn(int degree)(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow;
	
	step = pow(k, degree);
}

/// Ease out degree animation
void easeOut(int degree)(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow;

	step = 1 - pow((1 - k), degree);
}

/// Ease in out degree animation
void easeInOut(int degree)(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow;
	
	step = k < 0.5f ? (2 * degree) * pow(k, degree) : 1 - pow(-2 * k + 2, degree) / 2;
}

/// Ease in expo animation
void easeInExpo(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow;

	step = k == 0 ? 0 : pow(2, 10 * k - 10);
}

/// Ease out expo animation
void easeOutExpo(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow;
	
	step = k == 1 ? 1 : 1 - pow(2, -10 * k);
}

/// Ease in out expo
void easeInOutExpo(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : sqrt, pow;
	
	step = k == 0
		? 0
		: k == 1
		? 1
		: k < 0.5f ? pow(2, 20 * k - 10) / 2
		: (2 - pow(2, -20 * k + 10)) / 2;
}

/// Ease in circ animation
void easeInCirc(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : sqrt, pow;
	
	step = 1 - sqrt(1 - pow(k, 2));
}

/// Ease out circ animation
void easeOutCirc(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : sqrt, pow;
	
	step = sqrt(1 - pow(k - 1, 2));
}

/// Ease in out circ animation
void easeInOutCirc(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow, sqrt;
	
	step = k < 0.5f
		? (1 - sqrt(1 - pow(2 * k, 2))) / 2
		: (sqrt(1 - pow(-2 * k + 2, 2)) + 1) / 2;
}

/// Ease in back animation
void easeInBack(ref float step, const(float) k) @safe nothrow pure
{
	immutable c1 = 1.70158f;
	immutable c3 = c1 + 1.0f;
	
	step = c3 * k * k * k - c1 * k * k;
}

/// Ease out back animation
void easeOutBack(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow;
	
	immutable c1 = 1.70158f;
	immutable c3 = c1 + 1.0f;
	
	step = 1 + c3 * pow(k - 1, 3) + c1 * pow(k - 1, 2);
}

/// Ease in out animation
void easeInOutBack(ref float step, const(float) k) @safe nothrow pure
{
	import std.math : pow;

	immutable c1 = 1.70158f;
	immutable c2 = c1 * 1.525;
	
	step = k < 0.5f
		? (pow(2 * k, 2) * ((c2 + 1) * 2 * k - c2)) / 2
		: (pow(2 * k - 2, 2) * ((c2 + 1) * (k * 2 - 2) + c2) + 2) / 2;
}

/++
An object of smooth movement of an object along a function in a template.

The function should contain the parameters of the motion step and the animation 
step, for example:
---
void moveFunction(ref float step, const float k) @safe nothrow pure;
---
+/
class MoveAnimation(alias moveFunction) : IAnimated
{
	import tida.vector;

private:
	Vecf* vector;
	Vecf begin;
	
public:
	float distance;
	Vecf direction; 

	/++
	Animation constructor.
	
	Params:
		vec = The position to move smoothly.
	+/
	this(ref Vecf vec) @trusted
	{
		vector = &vec;
		begin = vec;
	}
	
override @safe:
	void animation(float k)
	{
		float step = 0.0f;
		moveFunction(step, k);
		
		*vector = begin + (direction * (distance * step));
	}
}

/++
Animation object. Animates an object.
+/
class Animator
{
private:
    float k = 0.0f;

public:
	/// Speed animation.
    float speed = 0.01f;

@safe:
	void reset() @safe
	{
		k = 0.0f;
	}

	/++
	Object animation function. The input object receives an animation step from
	which it can play any animation.
	
	Params:
		anim = Animation object.
	+/
    void step(IAnimated anim)
    {
    	if (k > 1.0f)
    		return;
     
    	k += speed;

		anim.animation(k);
    }
    
    /// ditto
    void stepArray(IAnimated[] anim)
    {
    	if (k > 1.0f)
    		return;
    
    	k += speed;
    	
    	foreach(a; anim)
			a.animation(k);
    }
}
