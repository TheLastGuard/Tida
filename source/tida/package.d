/++
	
	Authors: TodNaz
	License: MIT
+/
module tida;

version(betterC) 
{
	import tida.betterc.runtime;
	import tida.betterc.window;
}
else:
public
{
	import tida.runtime;
	import tida.window;
	import tida.color;
	import tida.event;
	import tida.vector;
	import tida.info;
	import tida.graph.render;
	import tida.graph.image;
	import tida.graph.text;
	import tida.fps;
	import tida.shape;
	import tida.sound.al;
	import tida.graph.camera;
	import tida.game;
}