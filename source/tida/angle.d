/++
	Module for working with corners. While you can work with different types of angles.
	
	Authors: TodNaz
	License: MIT
+/
module tida.angle;

static immutable ubyte Radians = 0; /// Radians
static immutable ubyte Degrees = 1; /// Degrees
static immutable ubyte Turns = 2; /// Turns
static immutable ubyte Gons = 3; /// Gons

/++
	Maximum angle value.
	
	Params:
		Type = Type angle.
		
	Example:
	---
	auto maxRad = max!Radians;
	---
+/
public float max(ubyte Type)() @safe
{
	import std.math;

	static if(Type == Radians) {
		return 2 * PI;
	}else
	static if(Type == Degrees) {
		return 360.0f;
	}else
	static if(Type == Turns) {
		return 1.0f;
	}else
	static if(Type == Gons) {
		return 400.0f;
	}
}

alias perigon = max;

/++
	Returns the right angle.
	
	Params:
		Type = Type angle.
		
	Example:
	---
	auto riaRad = rightAngle!Radians;
	---
+/
public float rightAngle(ubyte Type)() @safe
{
	import std.math;
	
	static if(Type == Radians) {
		return 0.5 * PI;
	}else
	static if(Type == Degrees) {
		return 90.0f;
	}else
	static if(Type == Turns) {
		return 1 / 4;
	}else
	static if(Type == Gons) {
		return 100;
	}else
		static assert(null,"Unknown angle type!");
}

/++
	Returns straight angle.
	
	Params:
		Type = Type angle.
		
	Example:
	---
	auto strRad = straight!Radians;
	---
+/
public float straight(ubyte Type)() @safe
{
	import std.math;
	
	static if(Type == Radians) {
		return PI;
	}else
	static if(Type == Degrees) {
		return 180;
	}else
	static if(Type == Turns) {
		return 0.5;
	}else
	static if(Type == Gons) {
		return 200;
	}else
		static assert(null,"Unknown angle type!");
}

/++
	Translate one system of angles into another.
	
	Params:
		What = What to translate.
		In = What to translate.
		value = Value.
	
	Example:
	---
	from(Degrees,Radians)(45);
	---
+/
public float from(ubyte What,ubyte In)(float value) @safe
{
	import std.math;
	
	static if(What == In) return value;
	static if(In == Turns) return value / max!What;
	static if(What == Turns) return max!In * value;
	
	static if(What == Radians) {
		static if(In == Degrees) {
			return value * 180 / PI;
		}else
		static if(In == Gons) {
			return value * 200 / PI;
		}
	}else
	static if(What == Degrees) {
		static if(In == Radians) {
			return value * PI / 180;
		}else
		static if(In == Gons) {
			return value * 200 / 180;
		}
	}else
	static if(What == Gons) {
		static if(In == Radians) {
			return value * PI / 200;
		}else
		static if(In == Degrees) {
			return value * 180 / 200;
		}
	}
}

/++
	Finds the angle between two angel's. Accepted in any angle change systems.
	
	Params:
		a = First angle.
		b = Second angle.
		
	Returns: Angle between two angel's.
+/
public float betweenAngle(float a,float b) @safe nothrow
{
	return (a + b) / 2;
}

unittest
{
	assert(max!Radians.from!(Radians,Degrees) == max!Degrees);
	assert(max!Degrees.from!(Degrees,Gons) == max!Gons);
	assert(max!Gons.from!(Gons,Turns) == max!Turns);
	
	assert(rightAngle!Radians.from!(Radians,Degrees) == rightAngle!Degrees);
	assert(rightAngle!Degrees.from!(Degrees,Gons) == rightAngle!Gons);
}

import tida.vector;

/++
	Returns the angle between two vectors in radians.
	
	Params:
		a = First point.
		b = Second point.
		
	Returns: Angle in radians.
	
	To convert, for example, to degrees, use the function like this:
	---
	pointDirection(...).from!(Radians,Degrees);
	---
+/
public float pointDirection(Vecf a,Vecf b) @safe nothrow
{
	import std.math;

	float result = atan2(b.y - a.y, b.x - a.x);
	return result;
}
	
unittest
{
	assert(betweenAngle(180,90) == 135);
	assert(betweenAngle(720,0) == max!Degrees);
}

unittest
{
	assert(betweenAngle(180,0).from!(Degrees,Radians) == rightAngle!Radians);
	assert(betweenAngle(0,max!Radians).from!(Radians,Gons) == straight!Gons);
}