/++

+/
module tida.scene.component;

public class Component
{
	import tida.scene.instance;
	import tida.graph.render;
	import tida.event;

	public
	{
		string name;
	}

	public void init(Instance instance) @safe {};
	public void event(EventHandler event) @safe {}
	public void step() @safe {}
	public void draw(Renderer render) @safe {}

	public string getName() @safe {return name;}
}