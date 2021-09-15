module app;

import tida;

void main(string[] args)
{
    TidaRuntime.initialize(args);

    Window window = new Window(640,480,"Simple window.");
    window.windowInitialize!(WithContext)(100, 100);

    EventHandler event = new EventHandler(window);

    bool isGame = true;

    while(isGame)
    {
        while(event.nextEvent)
        {
            if(event.isQuit)
                isGame = false;

            if(event.keyDown == Key.Escape)
                isGame = false;
        }
    }
}
