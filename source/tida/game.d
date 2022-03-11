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

import std.concurrency;

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

struct ClosedThreadMessage { }

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
    
    size_t maxThreads = 3;
    size_t functionPerThread = 80;
}

private void workerThread(Tid owner, size_t id)
{
    bool isRun = true;
    bool isPaused = false;
    FPSManager threadFPS = new FPSManager();
    
    while (isRun)
    {
        threadFPS.countDown();
        
        if (id in sceneManager.threadAPI)
        {   
            import std.range : popFront, front, empty;  
            while(!sceneManager.threadAPI[id].empty)
            {
                immutable response = sceneManager.threadAPI[id].front;
                sceneManager.threadAPI[id].popFront();
                
                switch (response.code)
                {
                    case APIType.ThreadClose:
                        isRun = 0;
                        owner.send(APIType.ThreadClosed);
                        return;
                        
                    case APIType.ThreadPause:
                        isPaused = true;
                    break;
                    
                    case APIType.ThreadResume:
                        isPaused = false;
                    break;
                    
                    default:
                        continue;
                }
            }
        }
        
        if (isPaused)
            continue;
        
        if (!sceneManager.isThereGoto)
            sceneManager.callStep(id, null);
        
        threadFPS.control();
    }
}

class Game
{
private:
    EventHandler event;
    Tid[] threads;
    
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
        
        sceneManager.maxThreads = config.maxThreads;
        sceneManager.functionPerThread = config.functionPerThread;
    }

    void threadClose(uint value) @trusted
    {
        import std.algorithm : remove;

        threads[value].send(APIType.ThreadClose, 0);

        foreach(i; value .. threads.length) 
        {
            threads[i].send(APIType.ThreadRebindThreadID, i - 1);
        }
        
        threads.remove(value);
    }

    private void exit() @trusted
    {
        isGame = false;
        
        foreach (size_t i, ref e; threads)
        {
            sceneManager.threadAPI[i + 1] ~= APIResponse(APIType.ThreadClose, cast(uint) i);
        }
        
        sceneManager.callGameExit();
    }

    /++
    Starts the game loop of the game.
    +/
    void run() @trusted
    {
        sceneManager.callGameStart();

        version (manualThreadControl)
        {
            // Manual support thread...
        } else
        {
            size_t countThreads = sceneManager.maxThreads;
            if (sceneManager.countStartThreads > countThreads)
                countThreads = sceneManager.countStartThreads;
        
            foreach (i; 0 .. countThreads)
            {
                immutable id = i + 1;
                threads ~= spawn(&workerThread, thisTid, id);
            }

            foreach (e; sceneManager.scenes)
            {
                e.initThread(countThreads);
            }

            sceneManager.countStartThreads = 0;
        }

        while (isGame)
        {
            _fps.countDown();

            scope (failure)
            {
                sceneManager.callOnError();
                exit();
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
                switch (response.code)
                {
                    case APIType.ThreadCreate:
                    {
                        foreach (i; 0 .. response.value)
                        {
                            immutable id = i + 1;
                            threads ~= spawn(&workerThread, thisTid, id);
                        }
                    }
                    break;
                    
                    case APIType.ThreadPause, APIType.ThreadResume:
                    {
                        if (response.value > threads.length)
                        {
                            sceneManager.apiError[response.code] = APIError.ThreadIsNotExists;
                            continue;
                        }
                        
                        sceneManager.threadAPI[response.value] ~= response;
                    }
                    break;
                    
                    case APIType.ThreadClose:
                    {
                        if (response.value > threads.length)
                        {
                            sceneManager.apiError[response.code] = APIError.ThreadIsNotExists;
                            continue;
                        }
                        
                        if (response.value == 0)
                            exit();
                        else
                            sceneManager.threadAPI[response.value] ~= response;
                    }
                    break;
                    
                    case APIType.GameClose:
                    {
                    	result = response.value;
                    	exit();
                    }
                    break;
                    
                    default:
                        sceneManager.apiError[response.code] = APIError.UnkownResponse;
                        break;
                }
            }

            sceneManager.api = []; // GC, please, clear this

            sceneManager.callStep(0, renderer);

            renderer.clear();
            sceneManager.callDraw(renderer);
            renderer.drawning();

            _fps.control();
        }
    }
}

template Lazy (T)
if (isScene!T)
{
    struct Lazy
    {
        T scene;
    }
}

template isLazy (T)
{
    import std.traits : TemplateOf;
    
    enum isLazy = __traits(isSame, TemplateOf!(T), Lazy);
}

template lazyScene (T)
if (isLazy!T)
{
    alias lazyScene = typeof(T.scene);
}

/++
Game entry point template.
+/
template GameRun(GameConfig config, T...)
{
    import tida.runtime;
    import tida.scenemanager;

    version(unittest) {} else
    int main(string[] args)
    {
        TidaRuntime.initialize(args, AllLibrary);
        Game game = new Game(config);

        static foreach (e; T)
        {
            static if (isScene!e)
            {
                sceneManager.add(new e());
            } else
            static if (isLazy!e)
            {
                sceneManager.lazyAdd!(lazyScene!e);
            }
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
