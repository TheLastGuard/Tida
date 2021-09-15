/++
A module for playing and organizing a game cycle with a scene manager.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.game;

import tida.window;
import tida.render;
import tida.fps;
import tida.scenemanager;
import tida.scene;
import tida.event;
import tida.image;
import tida.listener;
import tida.loader;
import tida.gl;

__gshared
{
    IWindow _window;
    IRenderer _renderer;
    FPSManager _fps;
    Listener _listener;
}

/// Window global object.
@property IWindow window() @trusted
{
    return _window;
}

/// Render global object.
@property IRenderer renderer() @trusted
{
    return _renderer;
}

/// FPS global object
@property FPSManager fps() @trusted
{
    return _fps;
}

/// Listener global object
@property Listener listener() @trusted
{
    return _listener;
}

/++
Game initialization information.
+/
struct GameConfig
{
    import tida.color;

public:
    uint windowWidth = 640; /// Window width.
    uint windowHeight = 480; /// Window height.
    string windowTitle = "Tida"; /// Window title.
    Color!ubyte background = rgb(255, 255, 255); /// Window background.
    int positionWindowX = 100; /// Window position x-axis.
    int positionWindowY = 100; /// Window position y-axis.
    string icon; /// Icon path.
}

class Game
{
private:
    EventHandler event;
    InstanceThread[] threads;
    bool isGame = true;

public:
    int result = 0;

@trusted:
    this(GameConfig config)
    {
        _window = new Window(config.windowWidth, config.windowHeight, config.windowTitle);
        (cast(Window) _window).windowInitialize!(WithContext)(config.positionWindowX,config.positionWindowY);
        loadGraphicsLibrary();
        _renderer = createRenderer(_window);
        _renderer.background = config.background;
        if (config.icon != "")
            _window.icon = new Image().load(config.icon);

        initSceneManager();
        event = new EventHandler((cast(Window) window));
        _fps = new FPSManager();
        _loader = new Loader();
        _listener = new Listener();
    }

    void threadClose(uint value) @safe
    {
        import std.algorithm : remove;

        threads[value].exit();
        foreach(i; value .. threads.length) threads[i].rebindThreadID(i - 1);
        threads.remove(value);
    }

    private void exit() @safe
    {
        import std.algorithm : each;

        isGame = false;
        threads.each!((e) { if(e !is null) e.exit(); });
        sceneManager.callGameExit();
    }

    void run() @trusted
    {
        sceneManager.callGameStart();

        _fps = new FPSManager();

        while (isGame)
        {
            fps.countDown();

            scope (failure)
            {
                sceneManager.callOnError();
            }

            while (event.nextEvent)
            {
                if (event.isQuit)
                {
                    exit();
                    return;
                }

                sceneManager.callEvent(event);
                if (listener !is null) listener.eventHandle(event);
            }

            if (listener !is null) listener.timerHandle();

            foreach (response; sceneManager.api)
            {
                if (response.code == APIType.ThreadClose)
                {
                    if (response.value == 0)
                    {
                        exit();
                        return;
                    } else
                    {
                        if (response.value >= threads.length)
                        {
                            sceneManager.apiError[response.code] = APIError.ThreadIsNotExists;
                            continue;
                        } else
                        {
                            threadClose(response.value);
                        }
                    }
                }else
                if (response.code == APIType.GameClose)
                {
                    result = response.value;
                    exit();
                    return;
                } else
                if (response.code == APIType.ThreadPause)
                {
                    if(response.value >= threads.length)
                    {
                        sceneManager.apiError[response.code] = APIError.ThreadIsNotExists;
                        continue;
                    } else
                    {
                        threads[response.value].pause();
                    }
                } else
                if (response.code == APIType.ThreadResume)
                {
                    if (response.value >= threads.length)
                    {
                        sceneManager.apiError[response.code] = APIError.ThreadIsNotExists;
                        continue;
                    } else
                    {
                        threads[response.value].resume();
                    }
                } else
                if (response.code == APIType.ThreadCreate)
                {
                    auto thread = new InstanceThread(threads.length,renderer);
                    threads ~= thread;

                    thread.start();
                }
            }

            sceneManager.api = []; // GC, please, clear this

            sceneManager.callStep(0,renderer);

            renderer.clear();
                sceneManager.callDraw(renderer);
            renderer.drawning();

            fps.control();
        }
    }
}

template GameRun(GameConfig config, T...)
{
    import tida.runtime;
    import tida.scenemanager;

    int main(string[] args)
    {
        TidaRuntime.initialize(args, AllLibrary);
        Game game = new Game(config);

        static foreach (e; T)
        {
            sceneManager.add(new e());
        }

        debug(single)
        {
            static foreach (e; T)
            {
            mixin("
            debug(single_" ~ e.stringof ~ ")
            {
                sceneManager.gotoin!(" ~ e.stringof ~ ");
            }
            ");
            }
        }else
            sceneManager.inbegin();

        game.run();
        return game.result;
    }
}
