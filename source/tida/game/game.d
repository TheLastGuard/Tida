module tida.game.game;

import tida.window;

__gshared Window _window;

public Window window() @trusted
{
    return _window;
}

public class Game
{
    import tida.event;
    import tida.graph.render;
    import tida.scene.manager;
    import tida.fps;

    private
    {
        EventHandler event;
        Renderer render;
        bool isGame = true;
        InstanceThread[] threads;
    }

    this(int width,int height,string caption) @trusted
    {
        initSceneManager();
        _window = new Window(width,height,caption);
        _window.initialize!ContextIn;

        _window.resizable = false;

        event = new EventHandler(window);
        render = new Renderer(window);

        threads ~= null;
    }

    private void exit() @safe
    {
        import std.algorithm : each;

        isGame = false;
        threads.each!((e) { if(e !is null) e.exit(); });
        sceneManager.callGameExit();
    }

    public void run() @trusted
    {
        sceneManager.callGameStart();

        FPSManager fps = new FPSManager();

        while(isGame)
        {
            fps.start();
            
            scope(failure) {
                sceneManager.callOnError();
            }

            while(event.update)
            {
                if(event.isQuit) {
                    exit();
                    isGame = false;
                }

                sceneManager.callEvent(event);
            }

            if(sceneManager.apiThreadCreate) {
                foreach(_; 0 .. sceneManager.apiThreadValue) {
                    auto thread = new InstanceThread(threads.length);
                    threads ~= thread;

                    thread.start();
                }

                sceneManager.apiThreadCreate = false;
            }

            if(sceneManager.apiExit) {
                exit();
            }

            sceneManager.callStep();

            render.drawning = {
                sceneManager.callDraw(render);
            };
            
            fps.rate();
        }
    }
}