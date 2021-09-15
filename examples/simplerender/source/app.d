module app;

import tida;
import tida.gl;

void main(string[] args)
{
    TidaRuntime.initialize(args);

    Window window = new Window(640, 480, "Simple render");
    window.windowInitialize!(WithContext)(100, 100);
	loadGraphicsLibrary();
	
    EventHandler event = new EventHandler(window);
    auto render = createRenderer(window);
    render.background = rgb(64, 64, 255);

    bool isGame = true;

    while(isGame)
    {
        while(event.nextEvent)
        {
            if(event.isQuit)
                isGame = false;

            if(event.keyDown == Key.Escape)
                isGame = false;

            if(event.isResize) {
                render.camera.port = Shapef.Rectangle(vecf(0,0),
                                                      vecf(event.newSizeWindow[0],event.newSizeWindow[1]));
                render.reshape();
            }
        }

        render.clear();
        render.circle(vecf(128,128), 64, rgb(255,0,0), true);
        render.drawning();
    }
}
