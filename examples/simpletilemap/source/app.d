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

    @Event!Input
    void onEvent(EventHandler event) @safe
    {
        if(event.isResize) {
            renderer.camera.shape = Shapef.Rectangle(vecf(0, 0), vecf(event.newSizeWindow[0], event.newSizeWindow[1]));
            renderer.reshape();
        }
    }

    @Event!Draw
    void onDraw(IRenderer render) @safe
    {
        render.draw(tilemap, Vecf(0, 0));
    }
}

mixin GameRun!(GameConfig(640, 480, "GUI"), Main);
