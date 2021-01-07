/++
    A module for creating a game instance for interpreting a system of scenes and instances.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.game;

import tida.window;
import tida.graph.render;
import tida.templates;

mixin Global!(IWindow,"window");
mixin Global!(IRenderer,"renderer");

struct GameConfig
{
    public
    {
        uint width = 0;
        uint height = 0;
        string caption;
        ubyte contextType;
    }
}

/// Game instance
class Game
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

    this(GameConfig config) @trusted
    {
        initSceneManager();
        _window = new Window(config.width,config.height,config.caption);

        if(config.contextType == Simple) (cast(Window) window).initialize!Simple;
        if(config.contextType == ContextIn) (cast(Window) window).initialize!ContextIn;

        event = new EventHandler(cast(Window) window);
        _renderer = CreateRenderer(window);
        _loader = new Loader();
        _listener = new Listener();

        threads ~= null;
    }

    this(int width,int height,string caption) @trusted
    {
        initSceneManager();
        _window = new Window(width,height,caption);
        (cast(Window) _window).initialize!ContextIn;

        event = new EventHandler(cast(Window) window);
        _renderer = CreateRenderer(window);
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

    /// Run while game
    void run() @trusted
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

            renderer.clear();
                sceneManager.callDraw(renderer);
            renderer.drawning();
            
            fps.rate();
        }
    }
}