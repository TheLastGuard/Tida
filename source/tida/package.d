/++
    Tida is an engine that can be compiled for both Linux and Windows, which is designed for developing 2D games.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida;

public
{
    import tida.runtime;
    import tida.window;
    import tida.event;
    import tida.vector;
    import tida.color;
    import tida.shape;
    import tida.fps;
    import tida.angle;

    import tida.graph.camera;
    import tida.graph.drawable;
    import tida.graph.image;
    import tida.graph.render;
    import tida.graph.text;
    import tida.graph.softimage;

    import tida.sound.al;

    import tida.scene;
    import tida.game;
}