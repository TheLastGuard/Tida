/++

+/
module tida.graph.drawable;

public interface IDrawable
{
	import tida.window;
	import tida.vector;
	import tida.graph.render;

	public void draw(Renderer renderer,Vecf position) @trusted;
}

public interface IDrawableEx
{
	import tida.window;
	import tida.vector;
	import tida.graph.render;

	public void drawEx(Renderer renderer,Vecf position,float angle,Vecf center,Vecf size) @trusted;
}