module tida.game.game;

import tida.window;
import tida.graph.render;

__gshared Window _window;
__gshared Renderer render;

public Window window() @trusted
{
    return _window;
}

public Renderer renderer() @trusted
{
    return render;
}

public class Game
{
    import tida.event;
    import tida.scene.manager;
    import tida.fps;
    import tida.game.loader;
    import tida.game.listener;

    private
    {
        EventHandler event;
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
        _loader = new Loader();
        _listener = new Listener();

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
                listener.eventHandle(event);
            }

			listener.timerHandle();

            if(sceneManager.apiThreadCreate) {
                foreach(_; 0 .. sceneManager.apiThreadValue) {
                    auto thread = new InstanceThread(threads.length,renderer);
                    threads ~= thread;

                    thread.start();
                }

                sceneManager.apiThreadCreate = false;
            }

            if(sceneManager.apiExit) {
                exit();
            }

            sceneManager.callStep(0,renderer);

            renderer.drawning = {
                sceneManager.callDraw(renderer);
            };
            
            fps.rate();
        }
    }
}