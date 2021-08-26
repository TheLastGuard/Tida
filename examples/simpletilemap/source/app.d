module app;

import tida;
import tida.tiled;
import std.stdio;

class Main : Scene
{
    TileMap tilemap;

    this() @trusted
    {
        tilemap = new TileMap();
        tilemap.load("test.tmx");
        tilemap.setup();
        renderer.background = tilemap.mapinfo.backgroundColor;
    }

    @Event!EventHandle
    void onEvent(EventHandler event) @safe
    {
        if(event.isResize) {
            window.eventResize(event.newSizeWindow);
            renderer.camera.shape = Shape.Rectangle(Vecf(0, 0), Vecf(event.newSizeWindow[0], event.newSizeWindow[1]));
            renderer.reshape();
        }
    }

    @Event!Draw
    void onDraw(IRenderer render) @safe
    {
        render.draw(tilemap, Vecf(0, 0));
    }
}

mixin GameRun!(WindowConfig!(640, 480, "GUI"), Main);
