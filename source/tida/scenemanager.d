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

auto defaultCamera() @safe
{
    import tida.game : renderer, window;
    import tida.shape;
    import tida.vector;

    auto camera = new Camera();
    camera.shape = Shape!float.Rectangle(vec!float(0, 0), vec!float(window.width, window.height));
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

private:
    alias RecoveryDelegate = void delegate(ref Scene) @safe;

    Scene[string] _scenes;
    Scene _current;
    Scene _previous;
    Scene _ofbegin;
    Scene _ofend;
    Scene _initable;
    Scene _restarted;
    RecoveryDelegate[string] recovDelegates;
    bool _thereGoto;

public @safe:
    /++
    A state indicating whether an instance transition is in progress. 
    Needed to synchronize the stream.
    +/
    @property bool isThereGoto() nothrow pure => _thereGoto;
    
    /// List scenes
    @property Scene[string] scenes() nothrow pure => _scenes;

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
    @property Scene ofbegin() nothrow pure => _ofbegin;

    /++
    The last added scene.
    +/
    @property Scene ofend() nothrow pure => _ofend;

    /++
    The previous scene that was active.
    +/
    @property Scene previous() nothrow pure => _previous;

    /++
    A scene that restarts at the moment.
    +/
    @property Scene restarted() nothrow pure => _restarted;

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

            foreach (fun; GameRestartFunctions[scene]) fun();
            foreach (instance; scene.list())
            {
                foreach (fun; IGameRestartFunctions[instance]) fun();
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
    @property Scene current() nothrow pure => _current;

    /++
    The reference to the scene, which is undergoing context change
    processing.

    The use of such a link is permissible only in context transmission
    events, otherwise, it is possible to detect the scene leading nowhere.
    +/
    @property Scene initable() nothrow pure => _initable;

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
    @property Scene context() nothrow pure => _initable is null ? (_restarted is null ? _current : _restarted) : _initable;

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

        if (scene in OnTriggerFunctions)
        {
            foreach (fun; OnTriggerFunctions[scene])
            {
                if (fun.ev.name == name)
                {
                    fun.fun();
                }
            }
        }

        foreach (instance; scene.list())
        {
            if (instance in IOnTriggerFunctions)
            {
                foreach (fun; IOnTriggerFunctions[instance])
                {
                    if (fun.ev.name == name)
                    {
                        fun.fun();
                    }
                }
            }
        }
    }

    /++
    Checks if the scene is in the scene list.

    Params:
        scene = Scene.
    +/
    bool hasScene(Scene scene) @trusted => _scenes.values.canFind(scene); 

    /++
    Checks for the existence of a scene by its original class.

    Params:
        Name = Class name.
    +/
    bool hasScene(Name)() => _scenes.values.canFind!(e => (cast(Name) e) !is null);

    /++
    Checks if there is a scene with the specified name.

    Params:
        name = Scene name.
    +/
    bool hasScene(string name) => _scenes.values.canFind!(e => e.name == name);

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

    package(tida)
    {
        import std.container, std.range, std.traits;
        import tida.component : Component;

        alias FEInit = void delegate() @safe;
        alias FEStep = void delegate() @safe;
        alias FERestart = void delegate() @safe;
        alias FEEntry = void delegate() @safe;
        alias FELeave = void delegate() @safe;
        alias FEGameStart = void delegate() @safe;
        alias FEGameExit = void delegate() @safe;
        alias FEGameRestart = void delegate() @safe;
        alias FEEventHandle = void delegate(EventHandler) @safe;
        alias FEDraw = void delegate(IRenderer) @safe;
        alias FEOnError = void delegate() @safe;
        alias FECollision = void delegate(Instance) @safe;
        alias FETrigger = void delegate() @safe;
        alias FEDestroy = void delegate(Instance) @safe;
        alias FEATrigger = void delegate(string) @safe;

        alias FECInit = void delegate(Instance) @safe;

        struct SRCollider
        {
            Collision ev;
            FECollision fun;
        }

        struct SRTrigger
        {
            Trigger ev;
            FETrigger fun;
        }

        FEInit[][Scene] InitFunctions;
        FEStep[][Scene] StepFunctions;
        FEStep[][size_t][Scene] StepThreadFunctions;
        FERestart[][Scene] RestartFunctions;
        FEEntry[][Scene] EntryFunctions;
        FELeave[][Scene] LeaveFunctions;
        FEGameStart[][Scene] GameStartFunctions;
        FEGameExit[][Scene] GameExitFunctions;
        FEGameRestart[][Scene] GameRestartFunctions;
        FEEventHandle[][Scene] EventHandleFunctions;
        FEDraw[][Scene] DrawFunctions;
        FEOnError[][Scene] OnErrorFunctions;
        SRTrigger[][Scene] OnTriggerFunctions;
        FEDestroy[][Scene] OnDestroyFunctions;
        FEATrigger[][Scene] OnAnyTriggerFunctions;
        FECollision[][Scene] OnAnyCollisionFunctions;

        FEInit[][Instance] IInitFunctions;
        FEStep[][Instance] IStepFunctions;
        FEStep[][size_t][Instance] IStepThreadFunctions;
        FERestart[][Instance] IRestartFunctions;
        FEEntry[][Instance] IEntryFunctions;
        FELeave[][Instance] ILeaveFunctions;
        FEGameStart[][Instance] IGameStartFunctions;
        FEGameExit[][Instance] IGameExitFunctions;
        FEGameRestart[][Instance] IGameRestartFunctions;
        FEEventHandle[][Instance] IEventHandleFunctions;
        FEDraw[][Instance] IDrawFunctions;
        FEOnError[][Instance] IOnErrorFunctions;
        SRCollider[][Instance] IColliderStructs;
        FECollision[][Instance] ICollisionFunctions;
        SRTrigger[][Instance] IOnTriggerFunctions;
        FEDestroy[][Instance] IOnDestroyFunctions;
        FEATrigger[][Instance] IOnAnyTriggerFunctions;

        FEStep[][Component] CStepFunctions;
        FEStep[][size_t][Component] CStepThreadFunctions;
        FELeave[][Component] CLeaveFunctions;
        FEEventHandle[][Component] CEventHandleFunctions;
        FEDraw[][Component] CDrawFunctions;
        FEOnError[][Component] COnErrorFunctions;
        SRTrigger[][Component] COnTriggerFunctions;
    }

    struct EventsInstance
    {
        FEInit[] IInitFunctions;
        FEStep[] IStepFunctions;
        FEStep[][size_t] IStepThreadFunctions;
        FERestart[] IRestartFunctions;
        FEEntry[] IEntryFunctions;
        FELeave[] ILeaveFunctions;
        FEGameStart[] IGameStartFunctions;
        FEGameExit[] IGameExitFunctions;
        FEGameRestart[] IGameRestartFunctions;
        FEEventHandle[] IEventHandleFunctions;
        FEDraw[] IDrawFunctions;
        FEOnError[] IOnErrorFunctions;
        SRCollider[] IColliderStructs;
        FECollision[] ICollisionFunctions;
        SRTrigger[] IOnTriggerFunctions;
        FEDestroy[] IOnDestroyFunctions;
        FEATrigger[] IOnAnyTriggerFunctions;
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
    static auto getInstanceEvents(T)(T instance) @trusted
    {
        EventsInstance events;
        
        static if (T.stringof != Instance.stringof)
        static foreach (member; __traits(allMembers, T))
        {
            static if (hasAttrib!(T, FunEvent!Init, member))
            {
                events.IInitFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Step, member))
            {
                events.IStepFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Entry, member))
            {
                events.IEntryFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Restart, member))
            {
                events.IRestartFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Leave, member))
            {
                events.ILeaveFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameStart, member))
            {
                events.IGameStartFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameExit, member))
            {
                events.IGameExitFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameRestart, member))
            {
                events.IGameRestartFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Input, member))
            {
                events.IEventHandleFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Draw, member))
            {
                events.IDrawFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameError, member))
            {
                events.IOnErrorFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, Collision, member))
            {
                events.IColliderStructs ~= SRCollider(attributeIn!(T, Collision, member),
                                                         &__traits(getMember, instance, member));
            } else
            static if (hasAttrib!(T, Trigger, member))
            {
                events.IOnTriggerFunctions ~= SRTrigger( attributeIn!(T, Trigger, member),
                                                            &__traits(getMember, instance, member));
            } else
            static if (hasAttrib!(T, FunEvent!Destroy, member))
            {
                events.IOnDestroyFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!AnyCollision, member))
            {
                events.ICollisionFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!AnyTrigger, member))
            {
                events.IOnAnyTriggerFunctions ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, StepThread, member))
            {
                events.IStepThreadFunctions
                    [attributeIn!(T, StepThread, member).id] ~= &__traits(getMember, instance, member);
            }
        }
        
        return events;
    }
    
    unittest
    {
        static class A : Instance 
        {
            @Event!Init
            void onInit() @safe { }
            
            @Event!Draw
            void onDraw(IRenderer render) @safe { }
        }
        
        A a = new A();
        auto evs = SceneManager.getInstanceEvents(a);
    }

    /++
    A function to call the render event of the instance.
    
    Params:
        instance = Instance object.
        render = Render object.
    +/
    void instanceCallDraws(Instance instance, IRenderer render) @safe
    {
        foreach (fun; IDrawFunctions[instance]) fun(render);
    }
    
    /++
    A function to call the input event of the instance.
    
    Params:
        instance = Instance object.
        event = Event handler object.
    +/
    void instanceCallDraws(Instance instance, EventHandler event) @safe
    {
        foreach (fun; IEventHandleFunctions[instance]) fun(event);
    }
    
    /++
    A function to call the step event of the instance.
    
    Params:
        instance = Instance object.
    +/
    void instanceCallStep(Instance instance) @safe
    {
        foreach (fun; IStepFunctions[instance]) fun();
    }
    
    /++
    A function to call the threaded step event of the instance.
    
    Params:
        instance = Instance object.
        threadID = Thread identificator.
    +/
    void instanceCallThreadStep(Instance instance, size_t threadID) @safe
    {
        foreach (fun; IStepThreadFunctions[instance][threadID]) fun();
    }
    
    /++
    A function to call the initialize event of the instance.
    
    Params:
        instance = Instance object.
    +/
    void instanceCallInit(Instance instance) @safe
    {
        foreach (fun; IInitFunctions[instance]) fun();
    }
    
    /++
    A function to call the restart event of the instance.
    
    Params:
        instance = Instance object.
    +/
    void instanceCallRestart(Instance instance) @safe
    {
        foreach (fun; IRestartFunctions[instance]) fun();
    }
    
    /++
    A function to call the leave event of the instance.
    
    Params:
        instance = Instance object.
    +/
    void instanceCallLeave(Instance instance) @safe
    {
        foreach (fun; ILeaveFunctions[instance]) fun();
    }
    
    /++
    A function to call the entry event of the instance.
    
    Params:
        instance = Instance object.
    +/
    void instanceCallEntry(Instance instance) @safe
    {
        foreach (fun; IEntryFunctions[instance]) fun();
    }
    
    /++
    A function to call the trigger event of the instance.
    
    Params:
        instance = Instance object.
    +/
    void instanceCallTrigger(Instance instance, string triggerMessage) @safe
    {
        foreach (fun; IOnAnyTriggerFunctions[instance]) fun(triggerMessage);
        
        foreach (ev; IOnTriggerFunctions[instance])
            if (ev.ev.name == triggerMessage)
                ev.fun();
    }

    /++
    Raise the event of destruction of the instance. (@FunEvent!Destroy)

    Params:
        instance = Instance.
    +/
    void destroyEventCall(T)(T instance) @trusted
    {
        static assert(isInstance!T, "`" ~ T.stringof ~ "` is not a instance!");
        foreach(func; IOnDestroyFunctions[instance]) func(instance);
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

        foreach(func; OnDestroyFunctions[scene]) func(instance);
    }

    package(tida) void componentExplore(T)(Instance instance, T component) @trusted
    {
        import tida.component : isComponent;

        static assert(isComponent!T, "`" ~ T.stringof ~ "` is not a component!");

        CStepFunctions[component] = [];
        CLeaveFunctions[component] = [];
        CEventHandleFunctions[component] = [];
        CDrawFunctions[component] = [];
        COnErrorFunctions[component] = [];
        COnTriggerFunctions[component] = [];

        static foreach (member; __traits(allMembers, T))
        {
            static if (hasAttrib!(T, FunEvent!Init, member))
            {
                __traits(getMember, component, member)(instance);
            } else
            static if (hasAttrib!(T, FunEvent!Step, member))
            {
                CStepFunctions[component] ~= &__traits(getMember, component, member);
            } else
            static if (hasAttrib!(T, FunEvent!Leave, member))
            {
                CLeaveFunctions[component] ~= &__traits(getMember, component, member);
            } else
            static if (hasAttrib!(T, FunEvent!Input, member))
            {
                CEventHandleFunctions[component] ~= cast(FEEventHandle) &__traits(getMember, component, member);
            } else
            static if (hasAttrib!(T, FunEvent!Draw, member))
            {
                CDrawFunctions[component] ~= cast(FEDraw) &__traits(getMember, component, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameError, member))
            {
                COnErrorFunctions[component] ~= &__traits(getMember, component, member);
            } else
            static if (hasAttrib!(T, StepThread, member))
            {
                CStepThreadFunctions[component][attributeIn!(T, StepThread, member).id] ~= &__traits(getMember, instance, member);
            }else
            static if (hasAttrib!(T, Trigger, member))
            {
                COnTriggerFunctions[component] ~= SRTrigger(attrib,
                cast(FETrigger) &__traits(getMember, component, member));
            }
        }
    }

    package(tida) @property FEStep[][size_t][Instance] threadSteps() => IStepThreadFunctions;

    package(tida) @property SRCollider[][Instance] colliders() => IColliderStructs;

    package(tida) @property FECollision[][Instance] collisionFunctions() => ICollisionFunctions;

    package(tida) @property FELeave[][Component] leaveComponents() => CLeaveFunctions;

    package(tida) void removeHandle(Scene scene, Instance instance) @trusted
    {
        IInitFunctions.remove(instance);
        IStepFunctions.remove(instance);
        IEntryFunctions.remove(instance);
        IRestartFunctions.remove(instance);
        ILeaveFunctions.remove(instance);
        IGameStartFunctions.remove(instance);
        IGameExitFunctions.remove(instance);
        IGameRestartFunctions.remove(instance);
        IEventHandleFunctions.remove(instance);
        IDrawFunctions.remove(instance);
        IOnErrorFunctions.remove(instance);
        IColliderStructs.remove(instance);
        ICollisionFunctions.remove(instance);
        IOnTriggerFunctions.remove(instance);
        IOnDestroyFunctions.remove(instance);
        IStepThreadFunctions.remove(instance);
        IOnAnyTriggerFunctions.remove(instance);
    }

    template hasMatch(alias attrib, alias AttribType)
    {
        enum hasMatch = is(typeof(attrib) == AttribType) || is(attrib == AttribType) ||
                        is(typeof(attrib) : AttribType) || is(attrib : AttribType);
    }

    template hasAttrib(T, AttribType, string member)
    {
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

    package(tida) void instanceExplore(T)(Scene scene, T instance) @trusted
    {
        import std.algorithm : canFind, remove;
        static assert(isInstance!T, "`" ~ T.stringof ~ "` is not a instance!");
        if (instance in IInitFunctions) return;

        IInitFunctions[instance] = [];
        IStepFunctions[instance] = [];
        IEntryFunctions[instance] = [];
        IRestartFunctions[instance] = [];
        ILeaveFunctions[instance] = [];
        IGameStartFunctions[instance] = [];
        IGameExitFunctions[instance] = [];
        IGameRestartFunctions[instance] = [];
        IEventHandleFunctions[instance] = [];
        IDrawFunctions[instance] = [];
        IOnErrorFunctions[instance] = [];
        IColliderStructs[instance] = [];
        IOnTriggerFunctions[instance] = [];
        IOnDestroyFunctions[instance] = [];
        ICollisionFunctions[instance] = [];
        IOnAnyTriggerFunctions[instance] = [];

        static if (T.stringof != Instance.stringof)
        static foreach (member; __traits(allMembers, T))
        {
            static if (hasAttrib!(T, FunEvent!Init, member))
            {
                IInitFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Step, member))
            {
                IStepFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Entry, member))
            {
                IEntryFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Restart, member))
            {
                IRestartFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Leave, member))
            {
                ILeaveFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameStart, member))
            {
                IGameStartFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameExit, member))
            {
                IGameExitFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameRestart, member))
            {
                IGameRestartFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Input, member))
            {
                IEventHandleFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!Draw, member))
            {
                IDrawFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameError, member))
            {
                IOnErrorFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, Collision, member))
            {
                IColliderStructs[instance] ~= SRCollider(attributeIn!(T, Collision, member),
                                                         &__traits(getMember, instance, member));
            } else
            static if (hasAttrib!(T, Trigger, member))
            {
                IOnTriggerFunctions[instance] ~= SRTrigger( attributeIn!(T, Trigger, member),
                                                            &__traits(getMember, instance, member));
            } else
            static if (hasAttrib!(T, FunEvent!Destroy, member))
            {
                IOnDestroyFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!AnyCollision, member))
            {
                ICollisionFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, FunEvent!AnyTrigger, member))
            {
                IOnAnyTriggerFunctions[instance] ~= &__traits(getMember, instance, member);
            } else
            static if (hasAttrib!(T, StepThread, member))
            {
                IStepThreadFunctions
                    [instance]
                    [attributeIn!(T, StepThread, member).id] ~= &__traits(getMember, instance, member);
            }
        }
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
            if((cast(T) scene) !is null) {
                remove(scene);
                return;
            }
        }
    }

    void remove(string name) @trusted
    {
        foreach(scene; scenes) {
            if(scene.name == name) {
                remove(scene);
                return;
            }
        }
    }

    private void exploreScene(T)(T scene) @trusted
    {
        InitFunctions[scene] = [];
        StepFunctions[scene] = [];
        EntryFunctions[scene] = [];
        RestartFunctions[scene] = [];
        LeaveFunctions[scene] = [];
        GameStartFunctions[scene] = [];
        GameExitFunctions[scene] = [];
        GameRestartFunctions[scene] = [];
        EventHandleFunctions[scene] = [];
        DrawFunctions[scene] = [];
        OnErrorFunctions[scene] = [];
        OnTriggerFunctions[scene] = [];
        OnDestroyFunctions[scene] = [];

        static if (T.stringof != Instance.stringof)
        static foreach (member; __traits(allMembers, T))
        {
            static if (hasAttrib!(T, FunEvent!Init, member))
            {
                InitFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!Step, member))
            {
                StepFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!Entry, member))
            {
                EntryFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!Restart, member))
            {
                RestartFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!Leave, member))
            {
                LeaveFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameStart, member))
            {
                GameStartFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameExit, member))
            {
                GameExitFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameRestart, member))
            {
                GameRestartFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!Input, member))
            {
                EventHandleFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!Draw, member))
            {
                DrawFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!GameError, member))
            {
                OnErrorFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, Trigger, member))
            {
                IOnTriggerFunctions[scene] ~= SRTrigger( attributeIn!(T, Collision, member),
                                                            &__traits(getMember, scene, member));
            } else
            static if (hasAttrib!(T, FunEvent!AnyCollision, member))
            {
                ICollisionFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, FunEvent!AnyTrigger, member))
            {
                IOnAnyTriggerFunctions[scene] ~= &__traits(getMember, scene, member);
            } else
            static if (hasAttrib!(T, StepThread, member))
            {
                StepThreadFunctions
                    [scene]
                    [attributeIn!(T, StepThread, member).id] ~= &__traits(getMember, scene, member);
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
    in(hasScene(scene))
    do
    {
        import tida.game : renderer, window;
        import tida.shape;
        import tida.vector;
    
        _previous = current;
        _thereGoto = true;

        if (current !is null)
        {
            if (current in LeaveFunctions)
            {
                foreach (fun; LeaveFunctions[current])
                {
                    fun();
                }
            }

            foreach (instance; current.list())
            {
                if (instance in ILeaveFunctions)
                {
                    foreach (fun; ILeaveFunctions[instance])
                    {
                        fun();
                    }
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
            if (scene in InitFunctions)
            {
                foreach (fun; InitFunctions[scene])
                {
                    fun();
                }
            }

            foreach (instance; scene.list())
            {
                if (instance in IInitFunctions)
                {
                    foreach (fun; IInitFunctions[instance])
                    {
                        fun();
                    }
                }
            }

            scene.isInit = true;
        }else
        {
            if (scene in RestartFunctions)
            {
                foreach (fun; RestartFunctions[scene])
                {
                    fun();
                }
            }

            foreach (instance; scene.list())
            {
                if (instance in IRestartFunctions)
                {
                    foreach (fun; IRestartFunctions[instance])
                    {
                        fun();
                    }
                }
            }
        }

        if (scene in EntryFunctions)
        {
            foreach(fun; EntryFunctions[scene])
            {
                fun();
            }
        }

        foreach (instance; scene.list())
        {
            if (instance in IEntryFunctions)
            {
                foreach (fun; IEntryFunctions[instance])
                {
                    fun();
                }
            }
        }

        _initable = null;

        _current = scene;
        
        if (scene.camera !is null)
        {
            renderer.camera = scene.camera;
        }
        else
        {
            renderer.camera = defaultCamera();
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
            if (scene in GameStartFunctions)
            {
                foreach (fun; GameStartFunctions[scene])
                {
                    fun();
                }
            }

            foreach (instance; scene.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    if (instance in IGameStartFunctions)
                    {
                        foreach (fun; IGameStartFunctions[instance])
                        {
                            fun();
                        }
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
            if (scene in GameExitFunctions)
            {
                foreach (fun; GameExitFunctions[scene])
                {
                    fun();
                }
            }

            foreach (instance; scene.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    if (instance in IGameExitFunctions)
                    {
                        foreach (fun; IGameExitFunctions[instance])
                        {
                            fun();
                        }
                    }
                }
            }
        }
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
            if (current in OnErrorFunctions)
            {
                foreach (fun; OnErrorFunctions[current])
                {
                    fun();
                }
            }

            foreach (instance; current.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    if (instance in IOnErrorFunctions)
                    {
                        foreach (fun; IOnErrorFunctions[instance])
                        {
                            fun();
                        }
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
            current.worldCollision();
            
            if (current.camera !is null)
                current.camera.followObject();

            if (thread == 0)
            if (current in StepFunctions)
            {
                foreach (fun; StepFunctions[current])
                {
                    fun();
                }
            }

            if (current in StepThreadFunctions)
            if (thread in StepThreadFunctions[current])
            {
                foreach (fun; StepThreadFunctions[current][thread])
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

                if (instance in IStepFunctions)
                {
                    foreach (fun; IStepFunctions[instance])
                    {
                        fun();
                    }
                }

                foreach (component; instance.getComponents())
                {
                    if (component in CStepFunctions)
                    {
                        foreach (fun; CStepFunctions[component])
                        {
                            fun();
                        }
                    }
                }
            }

            foreach(instance; current.list())
            {
                if (!instance.active || instance.onlyDraw) continue;

                if (instance in IStepThreadFunctions)
                if (thread in IStepThreadFunctions[instance])
                {
                    foreach (fun; IStepThreadFunctions[instance][thread])
                        fun();
                }

                foreach (component; instance.getComponents())
                {
                    if (component in CStepThreadFunctions)
                    if (thread in CStepThreadFunctions[component])
                    {
                        foreach(fun; CStepThreadFunctions[component][thread])
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
            if (current in EventHandleFunctions)
            {
                foreach (fun; EventHandleFunctions[current])
                {
                    fun(event);
                }
            }

            foreach (instance; current.list())
            {
                if (instance.active && !instance.onlyDraw)
                {
                    if (instance in IEventHandleFunctions)
                    {
                        foreach(fun; IEventHandleFunctions[instance])
                        {
                            fun(event);
                        }
                    }

                    foreach (component; instance.getComponents())
                    {
                        if (component in CEventHandleFunctions)
                        {
                            foreach(fun; CEventHandleFunctions[component])
                            {
                                fun(event);
                            }
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
            if (current in DrawFunctions)
            {
                foreach (fun; DrawFunctions[current])
                {
                    fun(render);
                }
            }

            foreach (instance; current.getAssortedInstances())
            {
                if (instance.active && instance.visible)
                {
                    render.draw(instance.spriteDraw(), instance.position);

                    if (instance in IDrawFunctions)
                    {
                        foreach (fun; IDrawFunctions[instance])
                        {
                            fun(render);
                        }
                    }

                    foreach (component; instance.getComponents())
                    {
                        if (component in CDrawFunctions)
                        {
                            foreach (fun; CDrawFunctions[component])
                            {
                                fun(render);
                            }
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
        @Event!Init
        void onInit() @safe { }
    }

    A obj = new A();
    sceneManager.add(obj);

    assert((sceneManager.InitFunctions[obj][0].ptr) == ((&obj.onInit).ptr));
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

unittest
{
    import tida.component;

    initSceneManager();
    
    static class A : Component
    {
        int trace = 0;
    
        @Event!Init
        void onInit(Instance instance) @safe
        {
            trace++;
        }
    }
    
    Instance instance = new Instance();
    A a;
    instance.add(a = new A());
    
    assert(a.trace == 1);
}