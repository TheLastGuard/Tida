module app;

import tida;

class Main : Scene
{
    Image image;

    this() @safe
    {

    }

    @Event!Draw
    void onDraw(IRenderer render) @safe
    {
        render.draw(image, vecf(0, 64));
    }
}

mixin GameRun!(GameConfig(1024, 1024, "Tida"), Main);