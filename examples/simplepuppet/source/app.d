import tida;
import tida.puppet;
import std.json, std.file;
import tida.graph.vertgen;

class Main : Scene
{
    Puppet puppet;
    Vecf mousePos = Vecf(0, 0);

    this() @safe
    {
        Image image = new Image().load("test.png").fromTextureWithoutShape();

        puppet = new Puppet();

        puppet.load("data.inp");
    }

    @Event!EventHandle
    void onEvent(EventHandler event) @safe {
        mousePos = Vecf(event.mousePosition[0], event.mousePosition[1]);
    }

    @Event!Draw
    void onDraw(IRenderer render) @safe {
        render.draw(puppet, mousePos);
    }
}

mixin GameRun!(WindowConfig!(640, 480, "TidaPuppet"), Main);