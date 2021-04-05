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
        RenderType renderType = RenderType.AUTO; /// RenderType
        Color!ubyte background = rgb(255, 255, 255); /// Window background
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
            if(config.renderType == RenderType.AUTO) {
                _renderer = CreateRenderer(window);
            } else {
                if(config.renderType == RenderType.OpenGL) {
                    _renderer = new GLRender(window);
                } else
                    _renderer = new Software(window);
            }

            _renderer.background = config.background;
        }

        if(config.isLoaderCreate) _loader = new Loader();
        if(config.isListenerCreate) _listener = new Listener();

        if(config.icon !is null) window.icon = config.icon;

        if(config.onDrawCall !is null) onDrawCall = config.onDrawCall;

        threads ~= null;
    }

    this(int width,int height,string caption) @safe
    {
        GameConfig config;
        config.width = width;
        config.height = height;
        config.caption = caption;

        this(config);
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
                    return;
                }

                sceneManager.callEvent(event);
                if(listener !is null) listener.eventHandle(event);
            }

            if(sceneManager.apiExit) {
                exit();
                return;
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

template WindowConfig(int w, int h, string caption)
{
    enum WindowConfig = GameConfig(w, h, caption);
}

import tida.runtime;

template GameRun(GameConfig config, LibraryLoader ll, T...)
{
    int main(string[] args) {
        TidaRuntime.initialize(args, ll);

        Game game = new Game(config);

        static foreach(scene; T) {
            sceneManager.add!scene;
        }

        sceneManager.inbegin();

        game.run();

        return 0;
    }
}

template GameRun(GameConfig config, T...)
{
    mixin GameRun!(config, AllLibrary, T);
}