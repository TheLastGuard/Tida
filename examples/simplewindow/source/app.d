module app;

import tida;

void main(string[] args)
{
    TidaRuntime.initialize(args);

    Window window = new Window(640,480,"Simple window.");
    window.initialize!Simple;

    EventHandler event = new EventHandler(window);

    bool isGame = true;

    while(isGame)
    {
        while(event.update)
        {
            if(event.isQuit)
                isGame = false;

            if(event.getKeyDown == Key.Escape)
                isGame = false;
        }
    }
}