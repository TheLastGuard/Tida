/++
    A module for creating a game instance for interpreting a system of scenes and instances.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.game;

import tida.window;
import tida.graph.render;
import tida.fps;
import tida.templates;

__gshared IWindow _window;
__gshared IRenderer _renderer;
__gshared FPSManager _fps;

/// Window instance.
IWindow window() @trusted
{
    return _window;
}

/// Renderer instance.
IRenderer renderer() @trusted
{
    return _renderer;
}

FPSManager fps() @trusted
{
    return _fps;
}

/// Game config structure
struct GameConfig
{
    import tida.graph.image;
    import tida.color;

    public
    {
        uint width = 320; /// Window width
        uint height = 240; /// Window height
        string caption = "Tida"; /// Window caption
        Image icon = null; /// Window icon
        ubyte contextType = ContextIn; /// Graphics pipeline type
        Color!ubyte background = rgb(0,0,0); /// Window background
        int positionX = 100; /// Window position x-axis
        int positionY = 100; /// Window position y-axis
        bool isRendererCreate = true; ///
        bool isLoaderCreate = true; ///
        bool isListenerCreate = true; ///

        void delegate() @safe onDrawCall = null; ///
    }
}

/// Game instance
class Game
{
    import tida.event;
    import tida.scene.manager;
    import tida.game.loader;
    import tida.game.listener;

    private
    {
        EventHandler event;
        bool isGame = true;
        InstanceThread[] threads;

        void delegate() @safe onDrawCall;
    }

    this(GameConfig config) @trusted
    {
        initSceneManager();
        _window = new Window(config.width,config.height,config.caption);

        if(config.contextType == Simple)    (cast(Window) window).initialize!Simple
                                                (config.positionX,config.positionY);
        if(config.contextType == ContextIn) (cast(Window) window).initialize!ContextIn
                                                (config.positionX,config.positionY);

        event = new EventHandler(cast(Window) window);

        if(config.isRendererCreate) {
            _renderer = CreateRenderer(window);
            _renderer.background = config.background;
        }

        if(config.isLoaderCreate) _loader = new Loader();
        if(config.isListenerCreate) _listener = new Listener();

        if(config.icon !is null) window.icon = config.icon;

        if(config.onDrawCall !is null) onDrawCall = config.onDrawCall;

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

        _fps = new FPSManager();

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
                if(listener !is null) listener.eventHandle(event);
            }

			if(listener !is null) listener.timerHandle();

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

            if(renderer !is null)
            {
                renderer.clear();
                    sceneManager.callDraw(renderer);
                renderer.drawning();
            }else
            {
                onDrawCall();
            }
            
            fps.rate();
        }
    }
}