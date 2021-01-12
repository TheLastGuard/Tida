module app;

import tida;

void main(string[] args)
{
    LibraryLoader lib;
    lib.openAL = false;
    lib.freeType = false;

    TidaRuntime.initialize(args,lib);

    Window window = new Window(640,480,"Simple render");
    window.initialize!Simple;

    EventHandler event = new EventHandler(window);
    auto render = CreateRenderer(window);
    render.background = rgb(64,64,255);

    bool isGame = true;

    while(isGame)
    {
        while(event.update)
        {
            if(event.isQuit)
                isGame = false;

            if(event.keyDown == Key.Escape)
                isGame = false;

            if(event.isResize) {
                render.camera.shape = Shape.Rectangle(Vecf(0,0),
                                                     Vecf(event.newSizeWindow[0],event.newSizeWindow[1]));
                render.reshape();
            }
        }

        render.clear();
        render.circle(Vecf(128,128),64,rgb(255,0,0),true);
        render.drawning();
    }
}