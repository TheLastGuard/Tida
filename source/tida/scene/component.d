/++
    Module for instance components.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.scene.component;

/// Component. Can beautify the behavior of instances.
class Component
{
    import tida.scene.instance;
    import tida.graph.render;
    import tida.event;

    public
    {
        string name;
    }
}
