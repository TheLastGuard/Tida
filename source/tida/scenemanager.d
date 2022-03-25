/++
Scene and instance control module.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.scenemanager;

import tida.instance;
import tida.localevent;
import tida.scene;
import tida.render;
import tida.instance;
import tida.component;
import tida.event;
import tida.fps;
import core.thread;

/++
Mistakes of using communication between the manager and the game cycle.
+/
enum APIError : uint
{
    succes, /// Errors are not detected.
    ThreadIsNotExists, /// The stream with which it was necessary to interact - does not exist.
    UnkownResponse
}

/++
Commands that should execute the game cycle.
+/
enum APIType : uint
{
    None, /// None
    ThreadCreate, /// Create the specified number of threads.
    ThreadPause,
    ThreadResume,
    ThreadClose,
    GameClose,
    ThreadClosed,
    ThreadRebindThreadID
}

/++
Container to send a message to the game cycle.
+/
struct APIResponse
{
    uint code; /// Command thah should execute the game cycle.
    uint value; /// Value response
}

__gshared SceneManager _sceneManager;

/// Scene manager instance.
SceneManager sceneManager() @trusted
{
    return _sceneManager;
}

/// Allocates memory under the scene manager.
void initSceneManager() @trusted
{
    _sceneManager = new SceneManager();
}

version (unittest)
{
    auto defaultCamera() @safe
    {
        return null;
    }
} else
auto defaultCamera() @safe
{
    import tida.game : renderer, window;
    import tida.shape;
    import tida.vector;
    import tida.runtime;

    auto camera = new Camera();
    camera.shape = Shape!float.Rectangle(
        vecZero!float, 
        window.fullscreen ? 
            vec!float(runtime.monitorSize) :
            vec!float(window.width, window.height)
    );
    camera.port = camera.shape;
            
    return camera;
}

/++
Class describing scene manager.

Performs the functions of switching the context of the scenes, memorize
the list for subsequent circulation, the ability to execute elementary
events, give an instance access to the current scene or scene, which is
involved in the event.

To transfer the context, use the `gotoin`. Learn the current scene - `current`.
previous - `previous` Contact precisely to the global object - `scenemanager`.
+/
final class SceneManager
{
    import std.algorithm : canFind;
    import core.sync.mutex;

private:
    alias RecoveryDelegate = void delegate(ref Scene) @safe;
    alias LazyInfo = Scene delegate() @safe;

    Scene[string] _scenes;
    Scene _current;
    Scene _previous;
    Scene _ofbegin;
    Scene _ofend;
    Scene _initable;
    Scene _restarted;

    RecoveryDelegate[string] recovDelegates;
    LazyInfo[string] recovLazySpawns;

    LazyInfo[string] lazySpawns;
    bool _thereGoto;

    bool updateThreads = false;

    shared(Mutex) instanceMutex;

public @safe:
    size_t countStartThreads = 0;
    size_t maxThreads = 3;
    size_t functionPerThread = 80;

    this() @safe
    {
        instanceMutex = new shared Mutex;
    }

    /++
    A state indicating whether an instance transition is in progress. 
    Needed to synchronize the stream.
    +/
    @property bool isThereGoto() nothrow pure
    {
        return _thereGoto;
    }
    
    /// List scenes
    @property Scene[string] scenes() nothrow pure
    {
        return _scenes;
    }

    /++
    The first added scene.

    It can be overridden so that when the game
    is restarted, the manager will jump to the
    scene from this line:
    ---
    sceneManager.ofbegin = myScene;
    sceneManager.gameRestart();
    ---
    +/
    @property Scene ofbegin() nothrow pure
    {
        return _ofbegin;
    }

    /++
    The last added scene.
    +/
    @property Scene ofend() nothrow pure
    {
        return _ofend;
    }

    /++
    The previous scene that was active.
    +/
    @property Scene previous() nothrow pure
    {
        return _previous;
    }

    /++
    A scene that restarts at the moment.
    +/
    @property Scene restarted() nothrow pure
    {
        return _restarted;
    }

    /++
    Restarting the game.

    Please note that this function causes complete deletion and creation of all
    scenes in the framework. Therefore, it is recommended to load all resources
    through the resource manager so that when you restart all scenes of the
    constructor of such scenes, the resources are not loaded again.

    Also note that there are resources in the game that may not be reloaded by
    this function. For this there is an event `GameRestart`, in it put the
    implementation of the function that fixes such problems.
    +/
    void gameRestart() @trusted
    {
        foreach (ref scene; scenes)
        {
            _restarted = scene;

            foreach (fun; scene.events.GameRestartFunctions) fun();
            foreach (instance; scene.list())
            {
                foreach (fun; instance.events.IGameRestartFunctions) fun();
                scene.instanceDestroy!InMemory(instance);
            }

            recovDelegates[scene.name](scene);

            _restarted = null;
        }

        gotoin(ofbegin);
    }

    /++
    Link to the current scene.

    Please note that such a pointer is correct only in those events that
    differ from `init`,` restart`, `leave`, they can not go at all on the
    current one that you hoped. Example: In the initialization event, you
    want access to the scene, which is initialized, but here you can make
    a mistake - the pointer leads to the previous scene. You can access
    the current through `sceneManager.initable`.

    See_Also:
        tida.scene.manager.SceneManager.initable
    +/
    @property Scene current() nothrow pure
    {
        return _current;
    }

    /++
    The reference to the scene, which is undergoing context change
    processing.

    The use of such a link is permissible only in context transmission
    events, otherwise, it is possible to detect the scene leading nowhere.
    +/
    @property Scene initable() nothrow pure
    {
        return _initable;
    }

    /++
    The reference to the current stage, as if it is under initialization,
    whether it is during a restart or without them.

    This link is selected depending on what is happening. If this is caused
    during the change of context, it will lead exactly the scene that
    receives the context. If the manager restarts the game, the link leads
    to the scene, which is now restarting if there are no such events, then
    the scene leads to the current working scene.

    Examples:
    ---
    @FunEvent!Init
    void Initialization() @safe
    {
        assert(sceneManager.initable is sceneManager.context); // ok
    }

    @FunEvent!Step
    void Move() @safe
    {
        assert(sceneManager.current is sceneManager.context); // ok
    }

    @FunEvent!GameRestart
    void onGameRestart() @safe
    {
        assert(sceneManager.restarted is sceneManager.context); // ok
    }
    ---
    +/
    @property Scene context() nothrow pure
    {
        return _initable is null ? (_restarted is null ? _current : _restarted) : _initable;
    }

    /++
    Calls a trigger for the current scene, as well as its instances.

    Triggers are required for custom signal and events. By calling, you can
    force to pull functions with special attributes, for example:
    ---
    alias SpecEvent = Trigger("SpecialEvent");

    @SpecEvent
    void onSpec() @safe { ... }
    ...
    sceneManager.trigger("SpecialEvent");
    // Will cause the exact event to be called by calling the function,
    // only for the scene that is being held in the context.
    ---

    Params:
        name = Trigger name.
    +/
    void trigger(string name) @trusted
    {
        auto scene = this.context();

        foreach (fun; scene.events.OnTriggerFunctions)
        {
            if (fun.ev.name == name)
            {
                fun.fun();
            }
        }

        foreach (instance; scene.list())
        {
            foreach (fun; instance.events.IOnTriggerFunctions)
            {
                if (fun.ev.name == name)
                {
                    fun.fun();
                }
            }
        }
    }

    unittest
    {
        enum onSaysHi = Trigger("onSaysHi");

        initSceneManager();

        static class Test : Scene
        {
            bool isSayHi = false;

            @onSaysHi void onSayHi() @safe
            {
                isSayHi = true;
            }
        }

        Test test;

        sceneManager.add (test = new Test());
        sceneManager.gotoin(test);

        sceneManager.trigger("onSaysHi");

        assert (test.isSayHi);
    }

    /++
    Checks if the scene is in the scene list.

    Params:
        scene = Scene.
    +/
    bool hasScene(Scene scene) @trusted
    {
        return _scenes.values.canFind(scene);
    }

    /++
    Checks for the existence of a scene by its original class.

    Params:
        Name = Class name.
    +/
    bool hasScene(Name)()
    {
        return _scenes.values.canFind!(e => (cast(Name) e) !is null);
    }

    /++
    Checks if there is a scene with the specified name.

    Params:
        name = Scene name.
    +/
    bool hasScene(string name)
    {
        return _scenes.values.canFind!(e => e.name == name);
    }

    /++
    Function for lazy loading scenes. In the chalon only specifies the scene.
    At the same time, it will be listed in the scene list, however,
    its resources will not be loaded until the control goes to it.
    After the context change, it does not need to be re-shipped.

    Params:
        T = Lazy scene.
    +/
    void lazyAdd(T)()
    {
        static assert(isScene!T, "`" ~ T.stringof ~ "` is not a scene!");

        auto fun = {
            T scene = new T();
            add!T(scene);

            size_t countThreads = maxThreads;
            if (countStartThreads > countThreads)
                countThreads = countStartThreads;
            scene.initThread(countThreads);

            return scene;
        };

        lazySpawns[T.stringof] = fun;
        recovLazySpawns[T.stringof] = fun;
    }

    unittest
    {
        initSceneManager();

        static class LazyScene : Scene
        {
            int a = 0;

            this() @safe
            {
                a = 32;
            }
        }

        sceneManager.lazyAdd!(LazyScene)();
        assert(!sceneManager.hasScene!LazyScene);

        sceneManager.gotoin!LazyScene;

        assert(sceneManager.hasScene!LazyScene);
    }

    /++
    Adds a scene to the list.

    Params:
        scene = Scene.
    +/
    void add(T)(T scene)
    {
        static assert(isScene!T, "`" ~ T.stringof ~ "` is not a scene!");
        exploreScene!T(scene);

        if (_ofbegin is null)
            _ofbegin = scene;

        recovDelegates[scene.name] = (ref Scene bscene) @safe
        {
            bool isSceneBegin = (ofbegin is bscene);

            bscene = new T();
            exploreScene!T(cast(T) bscene);
            _scenes[bscene.name] = bscene;

            if (isSceneBegin) _ofbegin = bscene;
        };

        _scenes[scene.name] = scene;
    }

    template hasMatch(alias attrib, alias AttribType)
    {
        enum hasMatch = is(typeof(attrib) == AttribType) || is(attrib == AttribType) ||
                        is(typeof(attrib) : AttribType) || is(attrib : AttribType);
    }

    template hasAttrib(T, AttribType, string member)
    {
        import std.traits : isFunction, isSafe;

        alias same = __traits(getMember, T, member);

        static if (isFunction!(same))
        {
            alias attributes = __traits(getAttributes, same);

            static if (attributes.length != 0)
            {
                static foreach (attrib; attributes)
                {
                    static if (hasMatch!(attrib, AttribType))
                    {
                        static assert(isSafe!(same),
                        "The function `" ~ member ~"` does not guarantee safe execution.");

                        enum hasAttrib = true;
                    }else
                    {
                        enum hasAttrib = false;
                    }
                }        
            } else
            {
                enum hasAttrib = false;
            }
        } else
        {
            enum hasAttrib = false;
        }
    }

    template attributeIn(T, AttribType, string member)
    {
        alias same = __traits(getMember, T, member);
        alias attributes = __traits(getAttributes, same);

        static foreach (attrib; attributes)
        {
            static if (hasMatch!(attrib, AttribType))
            {
                enum attributeIn = attrib;
            }
        }   
    }

    /++
    A function to receive events that were described inside 
    the object's implementation.
    
    It is necessary if you need to manually call any functions 
    without using the scene manager. (The object doesn't have to be added somewhere for the function to work).
    
    Params:
        instance = Instance implementation object.
        
    Returns:
        Returns a structure with the event fields that it could detect.
    +/
    InstanceEvents getInstanceEvents(T)(T instance) @trusted
    {
        import std.algorithm : canFind, remove;
        static assert(isInstance!T, "`" ~ T.stringof ~ "` is not a instance!");

        InstanceEvents events;

        events.IInitFunctions = [];
        events.IStepFunctions = [];
        events.IEntryFunctions = [];
        events.IRestartFunctions = [];
        events.ILeaveFunctions = [];
        events.IGameStartFunctions = [];
        events.IGameExitFunctions = [];
        events.IGameRestartFunctions = [];
        events.IEventHandleFunctions = [];
        events.IDrawFunctions = [];
        events.IOnErrorFunctions = [];
        events.IColliderStructs = [];
        events.IOnTriggerFunctions = [];
        events.IOnDestroyFunctions = [];
        events.ICollisionFunctions = [];
        events.IOnAnyTriggerFunctions = [];
        events.IStepThreadFunctions = [0:null];

        void delegate() @safe[]* minStepTh;
        size_t minStepLen;

        static foreach (member; __traits(allMembers, T))
        {
            static if (hasAttrib!(T, tida.localevent.event, member))
            {
                static if (attributeIn!(T, event, member).type == Init)
                {
                    events.IInitFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == Restart)
                {
                    events.IRestartFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == Entry)
                {
                    events.IEntryFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == Leave)
                {
                    events.ILeaveFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == Step)
                {
                    events.IStepFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == GameStart)
                {
                    events.IGameStartFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == GameExit)
                {
                    events.IGameExitFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == GameRestart)
                {
                    events.IGameRestartFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == Input)
                {
                    events.IEventHandleFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == Draw)
                {
                    events.IDrawFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == AnyTrigger)
                {
                    events.IOnAnyTriggerFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == AnyCollision)
                {
                    events.ICollisionFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == Destroy)
                {
                    events.IOnDestroyFunctions ~= &__traits(getMember, instance, member);
                } else
                static if (attributeIn!(T, event, member).type == GameError)
                {
                    events.IOnErrorFunctions ~= &__traits(getMember, instance, member);
                }
            } else
            static if (hasAttrib!(T, Trigger, member))
            {
                events.IOnTriggerFunctions ~= InstanceEvents.SRTrigger (attributeIn!(T, Trigger, member),
                                                        &__traits(getMember, instance, member));
            } else
            static if (hasAttrib!(T, StepThread, member))
            {
                events.IStepThreadFunctions
                [attributeIn!(T, StepThread, member).id] ~= &__traits(getMember, instance, member);

                if (countStartThreads < attributeIn!(T, StepThread, member).id)
                {
                    countStartThreads = attributeIn!(T, StepThread, member).id;
                }
            } else
            static if (hasAttrib!(T, Collision, member))
            {
                events.IColliderStructs ~= InstanceEvents.SRCollider(attributeIn!(T, Collision, member),
                                                         &__traits(getMember, instance, member));
            }else
            static if (hasAttrib!(T, stepThreadSafe, member))
            {
                import std.algorithm : maxElement;

                if (events.IStepThreadFunctions.length != 1)
                {       
                    minStepLen = events.IStepThreadFunctions.values.maxElement!(a => a.length).length;
                    foreach (key, value; events.IStepThreadFunctions)
                    {
                        if (value.length < minStepLen)
                        {
                            minStepTh = &events.IStepThreadFunctions[key];
                            minStepLen = value.length;
                        }
                    }
                } else
                {
                    foreach (i; 1 .. maxThreads + 1)
                        events.IStepThreadFunctions[i] = [];
                        
                    minStepTh = &events.IStepThreadFunctions[maxThreads];
                    minStepLen = events.IStepThreadFunctions[maxThreads].length;
                }
            
                if (minStepLen > functionPerThread)
                {
                    events.IStepFunctions ~= &__traits(getMember, instance, member);
                }
                else
                {
                    *minStepTh ~= &__traits(getMember, instance, member);
                }
            }
        }

        return events;
    }

    ComponentEvents getComponentEvents(T)(Instance instance, T component) @safe
    {
        ComponentEvents events;

        events.CStepFunctions = [];
        events.CLeaveFunctions = [];
        events.CEventHandleFunctions = [];
        events.CDrawFunctions = [];
        events.COnErrorFunctions = [];
        events.COnTriggerFunctions = [];
        events.COnAnyTriggerFunctions = [];

        static foreach (member; __traits(allMembers, T))
        {
            static if (hasAttrib!(T, tida.localevent.event, member))
            {
                static if (attributeIn!(T, event, member).type == Init)
                {
                    events.CInitFunctions ~= ComponentEvents.FEInit(
                        instance,
                        &__traits(getMember, component, member)
                    );
                } else
                static if (attributeIn!(T, event, member).type == Leave)
                {
                    events.CLeaveFunctions ~= &__traits(getMember, component, member);
                } else
                static if (attributeIn!(T, event, member).type == Step)
                {
                    events.CStepFunctions ~= &__traits(getMember, component, member);
                } else
                static if (attributeIn!(T, event, member).type == Input)
                {
                    events.CEventHandleFunctions ~= &__traits(getMember, component, member);
                } else
                static if (attributeIn!(T, event, member).type == Draw)
                {
                    events.CDrawFunctions ~= &__traits(getMember, component, member);
                } else
                static if (attributeIn!(T, event, member).type == AnyTrigger)
                {
                    events.COnAnyTriggerFunctions ~= &__traits(getMember, component, member);
                } else
                static if (attributeIn!(T, event, member).type == AnyCollision)
                {
                    events.COnAnyCollisionFunctions ~= &__traits(getMember, component, member);
                } else
                static if (attributeIn!(T, event, member).type == GameError)
                {
                    events.COnErrorFunctions ~= &__traits(getMember, component, member);
                }
            } else
            static if (hasAttrib!(T, Trigger, member))
            {
                events.COnTriggerFunctions ~= ComponentEvents.SRTrigger (attributeIn!(T, Trigger, member),
                                                        &__traits(getMember, component, member));
            }
        }

        return events;
    }

    SceneEvents getSceneEvents(T)(T scene) @safe
    {
        SceneEvents events;

        events.InitFunctions = [];
        events.StepFunctions = [];
        events.EntryFunctions = [];
        events.RestartFunctions = [];
        events.LeaveFunctions = [];
        events.GameStartFunctions = [];
        events.GameExitFunctions = [];
        events.GameRestartFunctions = [];
        events.EventHandleFunctions = [];
        events.DrawFunctions = [];
        events.OnErrorFunctions = [];
        events.OnTriggerFunctions = [];
        events.OnDestroyFunctions = [];
        events.StepThreadFunctions = [0:null];

        void delegate() @safe[]* minStepTh;
        size_t minStepLen;

        static foreach (member; __traits(allMembers, T))
        {
            static if (hasAttrib!(T, tida.localevent.event, member))
            {
                static if (attributeIn!(T, event, member).type == Init)
                {
                    events.InitFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == Restart)
                {
                    events.RestartFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == Entry)
                {
                    events.EntryFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == Leave)
                {
                    events.LeaveFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == Step)
                {
                    events.StepFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == GameStart)
                {
                    events.GameStartFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == GameExit)
                {
                    events.GameExitFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == GameRestart)
                {
                    events.GameRestartFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == Input)
                {
                    events.EventHandleFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == Draw)
                {
                    events.DrawFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == AnyTrigger)
                {
                    events.OnAnyTriggerFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == AnyCollision)
                {
                    events.OnAnyCollisionFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == Destroy)
                {
                    events.OnDestroyFunctions ~= &__traits(getMember, scene, member);
                } else
                static if (attributeIn!(T, event, member).type == GameError)
                {
                    events.OnErrorFunctions ~= &__traits(getMember, scene, member);
                }
            } else
            static if (hasAttrib!(T, Trigger, member))
            {
                events.OnTriggerFunctions ~= SceneEvents.SRTrigger (attributeIn!(T, Trigger, member),
                                                        &__traits(getMember, scene, member));
            } else
            static if (hasAttrib!(T, StepThread, member))
            {
                events.StepThreadFunctions
                [attributeIn!(T, StepThread, member).id] ~= &__traits(getMember, scene, member);

                if (countStartThreads < attributeIn!(T, StepThread, member).id)
                {
                    countStartThreads = attributeIn!(T, StepThread, member).id;
                }
            } else
            static if (hasAttrib!(T, stepThreadSafe, member))
            {
                import std.algorithm : maxElement;

                if (events.StepThreadFunctions.length != 1)
                {
                    minStepLen = events.StepThreadFunctions.values.maxElement!(a => a.length).length;
                    foreach (key, value; events.StepThreadFunctions)
                    {
                        if (value.length < minStepLen)
                        {
                            minStepTh = &events.StepThreadFunctions[key];
                            minStepLen = value.length;
                        }
                    }
                } else
                {
                    foreach (i; 1 .. maxThreads + 1)
                        events.StepThreadFunctions[i] = [];

                    minStepTh = &events.StepThreadFunctions[maxThreads];
                    minStepLen = events.StepThreadFunctions[maxThreads].length;
                }

                if (minStepLen > functionPerThread)
                {
                    events.StepFunctions ~= &__traits(getMember, scene, member);
                }
                else
                {
                    *minStepTh ~= &__traits(getMember, scene, member);
                }
            }
        }

        return events;
    }

    unittest
    {
        initSceneManager();

        static class A : Instance
        {
            @event(Init)
            void onInit() @safe { }

            @event(Draw)
            void onDraw(IRenderer render) @safe { }
        }

        A a = new A();
        auto evs = sceneManager.getInstanceEvents(a);

        assert (evs.IInitFunctions[0] == &a.onInit);
        assert (evs.IDrawFunctions[0] == &a.onDraw);
    }

    /++
    Raise the event of destruction of the instance. (@FunEvent!Destroy)

    Params:
        instance = Instance.
    +/
    void destroyEventCall(T)(T instance) @trusted
    if (isInstance!T)
    {
        foreach(func; instance.events.IOnDestroyFunctions)
            func(instance);
    }

    /++
    Reise the event of destruction in current scene. (@FunEvent!Destroy)

    Params:
        scene = Current scene.
        instance = Instance.
    +/
    void destroyEventSceneCall(T, R)(T scene, R instance) @trusted
    {
        static assert(isScene!T, "`" ~ T.stringof ~ "` is not a scene!");
        static assert(isInstance!R, "`" ~ R.stringof ~ "` is not a instance!");

        foreach(func; scene.events.OnDestroyFunctions) func(instance);
    }

    package(tida) void componentExplore(T)(Instance instance, T component) @trusted
    if (isComponent!T)
    {
        component.events = getComponentEvents!T(instance, component);

        foreach (fun; component.events.CInitFunctions)
            fun.fun (fun.instance);
    }

    private void exploreScene(T)(T scene) @trusted
    {
        scene.events = getSceneEvents!T(scene);
    }

    package(tida) void instanceExplore(T)(Scene scene, T instance) @trusted
    if (isInstance!T)
    {
        instance.events = getInstanceEvents!T(instance);
    }

    package(tida) void removeHandle(Scene scene, Instance instance) @trusted
    {
        // TODO: Implement this
    }

    /++
    Creates and adds a scene to the list.

    Params:
        T = Scene name.

    Example:
    ---
    sceneManager.add!MyScene;
    ---
    +/
    void add(T)() @trusted
    {
        auto scene = new T();
        add!T(scene);
    }

    void remove(T)(T scene) @trusted
    {
        scenes.remove(scene.name);
        destroy(scene);
    }

    void remove(T)() @trusted
    {
        static assert(isScene!T, "`" ~ T.stringof ~ "` is not a scene!");

        foreach(scene; scenes)
        {
            if((cast(T) scene) !is null)
            {
                remove(scene);
                return;
            }
        }
    }

    void remove(string name) @trusted
    {
        foreach(scene; scenes)
        {
            if(scene.name == name)
            {
                remove(scene);
                return;
            }
        }
    }

    public
    {
        /++
        Array of requests. At each stroke of the cycle, it is checked,
        processed and cleaned. If an error occurs during the request,
        they are added to `apiError`.
        +/
        APIResponse[] api;
        
        /++
        An array of pre-known commands to execute without chasing data for each thread.
        +/
        APIResponse[][size_t] threadAPI;

        /++
        An array of request errors associated with the request type.
        +/
        uint[uint] apiError;
    }

    /++
    Exits the game with a successful error code.
    +/
    void close(int code = 0) @safe
    {
        api ~= APIResponse(APIType.GameClose, code);
    }

    /++
    Creates the specified count of anonymous threads.

    Params:
        count = Count anonymous threads.
    +/
    void initThread(uint count = 1) @safe
    {
        api ~= APIResponse(APIType.ThreadCreate, count);
    }

    /++
    Pauses said thread.

    Params:
        value = Thread identificator.
    +/
    void pauseThread(uint value) @safe
    {
        api ~= APIResponse(APIType.ThreadPause, value);
    }

    /++
    Resumes said thread.

    Params:
        value = Thread identificator.
    +/
    void resumeThread(uint value) @safe
    {
        api ~= APIResponse(APIType.ThreadResume, value);
    }

    void stopThread(uint value) @safe
    {
        api ~= APIResponse(APIType.ThreadClose, value);
    }

    /++
    Goes to the first scene added.
    +/
    void inbegin() @safe
    {
        gotoin(_ofbegin);
    }

    /++
    Goes to the scene by its string name.

    Params:
        name = Scene name.
    +/
    void gotoin(string name)
    {
        foreach (inscene; scenes)
        {
            if(inscene.name == name)
            {
                gotoin(inscene);
                break;
            }
        }
        
        foreach (key, value; lazySpawns)
        {
            if (key == name)
            {
                auto scene = value();
                lazySpawns.remove(key);
                gotoin(scene);
                return;
            }
        }
    }

    /++
    Goes to the scene by its class.

    Params:
        Name = Scene.
    +/
    void gotoin(Name)()
    {
        foreach (s; scenes)
        {
            if ((cast(Name) s) !is null)
            {
                gotoin(s);
                return;
            }
        }

        foreach (key, value; lazySpawns)
        {
            if (key == Name.stringof)
            {
                auto scene = value();
                lazySpawns.remove(key);
                gotoin(scene);
                return;
            }
        }

        throw new Exception("Not find this scene!");
    }

    /++
    Moves to the scene at the pointer.

    It is such a function that generates initialization events, entry,
    transferring the context to the scene and causing the corresponding
    events to lose the context.

    Params:
        scene = Scene heir.
    +/
    void gotoin(Scene scene) @trusted
    {
        import tida.game : renderer, window;
        import tida.shape;
        import tida.vector;
    
        _previous = current;
        _thereGoto = true;

        if (current !is null)
        {
            foreach (fun; scene.events.LeaveFunctions)
            {
                fun();
            }

            foreach (instance; current.list())
            {
                foreach (fun; instance.events.ILeaveFunctions)
                {
                    fun();
                }
            }
        }

        if (current !is null)
        {
            Instance[] persistents;

            foreach (instance; _previous.list())
            {
                if (instance.persistent)
                    persistents ~= instance;
            }

            foreach (e; persistents)
            {
                auto threadID = e.threadid;
                current.instanceDestroy!InScene(e, false);

                if (scene.isThreadExists(threadID))
                    scene.add(e,threadID);
                else
                    scene.add(e);
            }
        }

        _initable = scene;

        if (!scene.isInit)
        {
            foreach (fun; scene.events.InitFunctions)
            {
                fun();
            }

            foreach (instance; scene.list())
            {
                foreach (fun; instance.events.IInitFunctions)
                {
                    fun();
                }
            }

            scene.isInit = true;
        }else
        {
            foreach (fun; scene.events.RestartFunctions)
            {
                fun();
            }

            foreach (instance; scene.list())
            {
                foreach (fun; instance.events.IRestartFunctions)
                {
                    fun();
                }
            }
        }

        foreach(fun; scene.events.EntryFunctions)
        {
            fun();
        }

        foreach (instance; scene.list())
        {
            foreach (fun; instance.events.IEntryFunctions)
            {
                fun();
            }
        }

        _initable = null;

        _current = scene;

        version (unittest)
        {
            // avoid
        } else
        {
            if (scene.camera !is null)
            {
                renderer.camera = scene.camera;
            }
            else
            {
                renderer.camera = defaultCamera();
            }
        }

        _thereGoto = false;
    }

    /++
    Calling the game launch event.

    Should be called before all events, before the beginning of the
    cycle of life.
    +/
    void callGameStart() @trusted
    {
        foreach (scene; scenes)
        {
            foreach (fun; scene.events.GameStartFunctions)
            {
                fun();
            }

            foreach (instance; scene.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    foreach (fun; instance.events.IGameStartFunctions)
                    {
                        fun();
                    }
                }
            }
        }
    }

    /++
    Game completion call events (successful).
    The unsuccessful event should raise the `onError` event.
    +/
    void callGameExit() @trusted
    {
        foreach (scene; scenes)
        {
            foreach (fun; scene.events.GameExitFunctions)
            {
                fun();
            }

            foreach (instance; scene.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    foreach (fun; instance.events.IGameExitFunctions)
                    {
                        fun();
                    }
                }
            }
        }
    }

    unittest
    {
        initSceneManager();

        static class Test : Scene
        {
            int trigger = int.init;

            this() @safe
            {
                name = "Test";
            }
        }

        sceneManager.add (new Test());

        sceneManager.gotoin("Test");

        assert ((cast (Test) sceneManager.scenes["Test"]).trigger == 0);
        (cast (Test) sceneManager.scenes["Test"]).trigger = 32;
        assert ((cast (Test) sceneManager.scenes["Test"]).trigger == 32);

        sceneManager.gameRestart();

        assert ((cast (Test) sceneManager.scenes["Test"]).trigger == 0);
    }

    /++
    Triggering an emergency event.

    Does not terminate the game, should be called on exceptions. After that,
    the programmer himself decides what to do next (if he implements his own
    life cycle). Called usually on `scope (failure)`, however, it will not
    throw a specific exception.
    +/
    void callOnError() @trusted
    {
        if (current !is null)
        {
            foreach (fun; current.events.OnErrorFunctions)
            {
                fun();
            }

            foreach (instance; current.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    foreach (fun; instance.events.IOnErrorFunctions)
                    {
                        fun();
                    }
                }
            }
        }
    }

    /++
    Calling a game step. Should always be called during a loop step in an
    exception when the thread is suspended.

    Params:
        thread = Thread identificator.
        rend   = Renderer instance.
    +/
    void callStep(size_t thread, IRenderer rend) @trusted
    {
        if (current !is null)
        {
            if (thread == 0)
            {
                current.worldCollision();
            
                if (current.camera !is null)
                    current.camera.followObject();

                foreach (fun; current.events.StepFunctions)
                {
                    fun();
                }
            }

            if (thread in current.events.StepThreadFunctions)
            {
                foreach (fun; current.events.StepThreadFunctions[thread])
                    fun();
            }

            foreach (instance; current.getThreadList(thread))
            {
                if (instance.isDestroy)
                {
                    current.instanceDestroy!InMemory(instance);
                    current.sort();
                    continue;
                }

                if (!instance.active || instance.onlyDraw) continue;

                foreach (fun; instance.events.IStepFunctions)
                {
                    fun();
                }

                foreach (component; instance.getComponents())
                {
                    foreach (fun; component.events.CStepFunctions)
                    {
                        fun();
                    }
                }
            }

            foreach(instance; current.list())
            {
                if (!instance.active || instance.onlyDraw) 
                    continue;

                if (thread in instance.events.IStepThreadFunctions)
                {
                    foreach (fun; instance.events.IStepThreadFunctions[thread])
                        fun();
                }

                foreach (component; instance.getComponents())
                {
                    if (thread in component.events.CStepThreadFunctions)
                    {
                        foreach(fun; component.events.CStepThreadFunctions[thread])
                        {
                            fun();
                        }
                    }
                }
            }
        }
    }

    /++
    System event event for scenes and instances of the current context.

    Params:
        event = System event handler instance.
    +/
    void callEvent(EventHandler event) @trusted
    {
        if (current !is null)
        {
            foreach (fun; current.events.EventHandleFunctions)
            {
                fun(event);
            }

            foreach (instance; current.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    foreach(fun; instance.events.IEventHandleFunctions)
                    {
                        fun(event);
                    }

                    foreach (component; instance.getComponents())
                    {
                        foreach(fun; component.events.CEventHandleFunctions)
                        {
                            fun(event);
                        }
                    }
                }
            }
        }
    }

    /++
    Calling an event to render scenes and instances of the current context.

    Params:
        render = Render instance.
    +/
    void callDraw(IRenderer render) @trusted
    {
        import tida.vector;

        if (current !is null)
        {
            foreach (fun; current.events.DrawFunctions)
            {
                fun(render);
            }

            foreach (instance; current.getAssortedInstances())
            {
                if (instance.active && instance.visible)
                {
                    render.draw(instance.spriteDraw(), instance.position);

                    foreach (fun; instance.events.IDrawFunctions)
                    {
                        fun(render);
                    }

                    foreach (component; instance.getComponents())
                    {
                        foreach (fun; component.events.CDrawFunctions)
                        {
                            fun(render);
                        }
                    }
                }
            }
        }
    }

    /// Free memory.
    void free() @safe
    {
        _scenes = null;
    }

    ~this() @safe
    {
        free();
    }
}

unittest
{
    initSceneManager();

    static class A : Scene
    {
        this() @safe
        {
            name = "Test";
        }
    }

    sceneManager.add(new A());
    assert(("Test" in sceneManager.scenes) !is null);
}

unittest
{
    initSceneManager();

    static class A : Scene
    {
        @event(Init)
        void onInit() @safe { }
    }

    A obj = new A();
    sceneManager.add(obj);

    assert((obj.events.InitFunctions[0].ptr) == ((&obj.onInit).ptr));
}

unittest
{
    initSceneManager();

    static class A : Scene
    {
        this() @safe
        {
            name = "Test";
        }
    }

    sceneManager.add(new A());
    assert(sceneManager.hasScene("Test"));
}
