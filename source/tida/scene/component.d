/++

+/
module tida.scene.component;

public interface Component
{
	import tida.scene.instance;
	import tida.graph.render;
	import tida.event;

	public void init(Instance) @safe;
	public void event(EventHandler) @safe;
	public void step() @safe;
	public void draw(Renderer) @safe;

	public string getName() @safe;
}