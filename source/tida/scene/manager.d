/++
    Scene manager module.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.scene.manager;

import tida.scene.instance;
import tida.scene.event;
import tida.scene.scene;
import tida.graph.render;
import tida.scene.instance;
import tida.event;
import tida.fps;

/++
    Mistakes of using communication between the manager and the game cycle.
+/
enum APIError : uint
{
    succes, /// Errors are not detected.
    ThreadIsNotExists /// The stream with which it was necessary to interact - does not exist.
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
}

/++
    Container to send a message to the game cycle.
+/
struct APIResponse
{
    uint code; /// Command thah should execute the game cycle.
    uint value; /// Value response
}

/++
    Returns: Is this class scene.
+/
template isScene(T)
{
    enum isScene = is(T : Scene);
}

/++
    Returns: In this class instance.
+/
template isInstance(T)
{
    enum isInstance = is(T : Instance);
}

import core.thread;

/++
    Thread for execution of steps for scenes and instances.
+/
class InstanceThread : Thread 
{
    private
    {
        bool isJob = true;
        bool isPause = false;
        FPSManager fps;
        Instance[] list;
        size_t thread;
        IRenderer rend;
    }

    /++
        Params: 
            thread =    Unique Identificator for Flow, namely, a place in the array for which it can 
                        contact such arrays for copies of the compliant ideal.
            rend   =    Renderer instance.
    +/
    this(size_t thread,IRenderer rend) @safe
    {
        fps = new FPSManager();

        this.thread = thread;
        this.rend = rend;

        super(&run);
    }

    /// Replaces the idle identifier. 
    void rebindThreadID(size_t newID) @safe {
        thread = newID;
    }

    private void run() @trusted
    {
        while(isJob) {
            if(isPause) continue;

            fps.start();

            sceneManager.callStep(thread,rend);

            fps.rate();
        }
    }

    /// Pause the work of the thread.
    void pause() @safe
    {
        isPause = true;
    }

    /// Continues thread work.
    void resume() @safe
    {
        isPause = false;
    }

    /// Completes the flow of the thread.
    void exit() @safe
    {
        isJob = false;
    }
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
    private
    {
        Scene[string] _scenes;
        Scene _current;
        Scene _previous;
        Scene _ofbegin;
        Scene _ofend;
        Scene _initable;
        Scene _restarted;
    }

    /// List scenes
    Scene[string] scenes() @safe @property
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
    Scene ofbegin() @safe @property
    {
        return _ofbegin;
    }

    /++
        The last added scene.
    +/
    Scene ofend() @safe @property
    {
        return _ofend;
    }

    /++
        The previous scene that was active.
    +/
    Scene previous() @safe @property
    {
        return _previous;
    }

    /++
        A scene that restarts at the moment.
    +/
    Scene restarted() @safe @property
    {
        return _restarted;
    }

    /++
        Restarting the game.

        Please note that this does not affect memory,
        the state of variables, etc., however, gives such a simulation,
        therefore, create a corresponding event for resetting the state
        when the game is restarted, if this is provided.
    +/
    void gameRestart() @trusted
    {
        foreach(scene; scenes)
        {
            if(!scene.isInit) continue;

            _restarted = scene;

            foreach(fun; GameRestartFunctions[scene]) fun();
            foreach(instance; scene.getList())
                foreach(fun; IGameRestartFunctions[instance]) fun();

            scene.isInit = false;

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
    Scene current() @safe @property nothrow
    {
        return _current;
    }

    /++
        The reference to the scene, which is undergoing context change
        processing.

        The use of such a link is permissible only in context transmission
        events, otherwise, it is possible to detect the scene leading nowhere.
    +/
    Scene initable() @safe @property
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
        @Event!Init
        void Initialization() @safe
        {
            assert(sceneManager.initable is sceneManager.context); // ok
        }

        @Event!Step
        void Move() @safe
        {
            assert(sceneManager.current is sceneManager.context); // ok
        }

        @Event!GameRestart
        void onGameRestart() @safe
        {
            assert(sceneManager.restarted is sceneManager.context); // ok
        }
        ---
    +/
    Scene context() @safe @property
    {
        if(_initable is null) {
            if(_restarted is null) {
                return _current;
            }else
                return _restarted;
        }else
            return _initable;

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

        if(scene in OnTriggerFunctions) {
            foreach(fun; OnTriggerFunctions[scene]) {
                if(fun.ev.name == name) {
                    fun.fun();
                }
            }
        }

        foreach(instance; scene.getList()) {
            if(instance in IOnTriggerFunctions) {
                foreach(fun; IOnTriggerFunctions[instance]) {
                    if(fun.ev.name == name) {
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
    bool hasScene(Scene scene) @safe
    {
        if(scene is null)
            return false;

        foreach(inscene; scenes) {
            if(scene is inscene)
                return true;
        }

        return false;
    }

    /++
        Checks for the existence of a scene by its original class.

        Params:
            Name = Class name.
    +/
    bool hasScene(Name)() @safe
    {
        foreach(scene; scenes) {
            if((cast(Name) scene) !is null) return true;
        }

        return false;
    }

    /++
        Checks if there is a scene with the specified name.

        Params:
            name = Scene name.
    +/
    bool hasScene(string name) @safe
    {
        foreach(scene; scenes) {
            if(scene.name == name) return true;
        }

        return false;
    }

    /++
        Adds a scene to the list.

        Params:
            scene = Scene.
    +/
    void add(T)(T scene) @safe
    in(isScene!T, "This is not scene!")
    do
    {
        uScene!T(scene);

        if(_ofbegin is null)
            _ofbegin = scene;

        _scenes[scene.name] = scene;
    }

    protected
    {
        import std.container, std.range, std.traits;
        import tida.scene.component : Component;

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

        alias FECInit = void delegate(Instance) @safe;

        struct SRCollider
        {
            CollisionEvent ev;
            FECollision fun;
        }

        struct SRTrigger
        {
            TriggerEvent ev;
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

        FEStep[][Component] CStepFunctions;
        FEStep[][size_t][Component] CStepThreadFunctions;
        FELeave[][Component] CLeaveFunctions;
        FEEventHandle[][Component] CEventHandleFunctions;
        FEDraw[][Component] CDrawFunctions;
        FEOnError[][Component] COnErrorFunctions;
        SRTrigger[][Component] COnTriggerFunctions;
    }

    /++
        Raise the event of destruction of the instance. (@Event!Destroy)

        Params:
            instance = Instance.
    +/
    void DestroyEventCall(T)(T instance) @trusted
    in(isInstance!T)
    do
    {
        foreach(func; IOnDestroyFunctions[instance]) func(instance);
    }

    /++
        Reise the event of destruction in current scene. (@Event!Destroy)

        Params:
            scene = Current scene.
            instance = Instance.
    +/
    void DestroyEventSceneCall(T, R)(T scene, R instance) @trusted
    in(isScene!T && isInstance!R)
    do
    {
        foreach(func; OnDestroyFunctions[scene]) func(instance);
    }

    package(tida.scene) void ComponentHandle(T)(Instance instance, T component) @trusted
    in(isComponent!T)
    do
    {
        CStepFunctions[component] = [];
        CLeaveFunctions[component] = [];
        CEventHandleFunctions[component] = [];
        CDrawFunctions[component] = [];
        COnErrorFunctions[component] = [];
        COnTriggerFunctions[component] = [];

        static foreach(member; __traits(allMembers, T)) {
            static foreach(attrib; __traits(getAttributes, __traits(getMember, component, member)))
            {
                static if(is(attrib : FunEvent!Init)) {
                    auto fun = cast(FECInit) &__traits(getMember, component, member);
                    fun(instance);
                } else
                static if(is(attrib : FunEvent!Step)) {
                    CStepFunctions[component] ~= &__traits(getMember, component, member);
                } else
                static if(is(attrib : FunEvent!Leave)) {
                    CLeaveFunctions[component] ~= &__traits(getMember, component, member);
                } else
                static if(is(attrib : FunEvent!EventHandle)) {
                    CEventHandleFunctions[component] ~= cast(FEEventHandle) &__traits(getMember, component, member);
                } else
                static if(is(attrib : FunEvent!Draw)) {
                    CDrawFunctions[component] ~= cast(FEDraw) &__traits(getMember, component, member);
                } else
                static if(is(attrib : FunEvent!OnError)) {
                    COnErrorFunctions[component] ~= &__traits(getMember, component, member);
                } else
                static if(attrib.stringof[0 .. 8] == "InThread") {
                    CStepThreadFunctions[instance][attrib.id] ~= &__traits(getMember, instance, member);
                }else
                static if(attrig.stringof[0 .. 12] == "TriggerEvent") {
                    COnTriggerFunctions[component] ~= SRTrigger(attrib,
                    cast(FETrigger) &__traits(getMember, component, member));
                }
            }
        }
    }

    package(tida.scene) FEStep[][size_t][Instance] threadSteps() @safe @property
    {
        return IStepThreadFunctions;
    }

    package(tida.scene) SRCollider[][Instance] colliders() @safe @property
    {
        return IColliderStructs;
    }

    package(tida.scene) FECollision[][Instance] collisionFunctions() @safe @property
    {
        return ICollisionFunctions;    
    }

    package(tida.scene) FELeave[][Component] leaveComponents() @safe @property
    {
        return CLeaveFunctions;
    }

    package(tida.scene) void RemoveHandle(Scene scene, Instance instance) @trusted
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
    }

    package(tida.scene) void InstanceHandle(T)(Scene scene, T instance) @trusted
    {
        import std.algorithm : canFind, remove;
        if(instance in IInitFunctions) return;

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

        static foreach(member; __traits(allMembers, T)) {
            static foreach(attrib; __traits(getAttributes, __traits(getMember, instance, member)))
            {
                static if(is(attrib : FunEvent!Init)) {
                    IInitFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!Step)) {
                    IStepFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!Entry)) {
                    IEntryFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!Restart)) {
                    IRestartFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!Leave)) {
                    ILeaveFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!GameStart)) {
                    IGameStartFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!GameExit)) {
                    IGameExitFuntions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!GameRestart)) {
                    IGameRestartFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!EventHandle)) {
                    IEventHandleFunctions[instance] ~= cast(FEEventHandle) &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!Draw)) {
                    IDrawFunctions[instance] ~= cast(FEDraw) &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!OnError)) {
                    IOnErrorFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!Destroy)) {
                    IOnDestroyFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(is(attrib : FunEvent!Collision)) {
                    ICollisionFunctions[instance] ~= &__traits(getMember, instance, member);
                }else
                static if(attrib.stringof[0 .. 8] == "InThread") {
                    IStepThreadFunctions[instance][attrib.id] ~= &__traits(getMember, instance, member);
                }else
                static if(attrib.stringof[0 .. 12] == "TriggerEvent") {
                    IOnTriggerFunctions[instance] ~= SRTrigger(attrib,
                    cast(FETrigger) &__traits(getMember, instance, member));
                }else
                static if(attrib.stringof[0 .. 14] == "CollisionEvent") {
                    IColliderStructs[instance] ~= SRCollider(attrib,
                    cast(FECollision) &__traits(getMember, instance, member));
                }
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
    in(isScene!T,"It's not a scene!")
    do
    {
        auto scene = new T();       

        add!T(scene);
    }

    void remove(T)(T scene) @trusted
    in(isScene!T,"It's not a scene!")
    do
    {
        scenes.remove(scene.name);
        destroy(scene);
    }

    void remove(T)() @trusted
    in(isScene!T,"It's not a scene!")
    do
    {
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

    private void uScene(T)(T scene) @trusted
    in(isScene!T)
    do
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

        static foreach(member; __traits(allMembers, T)) {
            static foreach(attrib; __traits(getAttributes, __traits(getMember, scene, member)))
            {
                static if(is(attrib : FunEvent!Init)) {
                    InitFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!Step)) {
                    StepFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!Entry)) {
                    EntryFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!Restart)) {
                    RestartFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!Leave)) {
                    LeaveFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!GameStart)) {
                    GameStartFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!GameExit)) {
                    GameExitFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!GameRestart)) {
                    GameRestartFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!EventHandle)) {
                    EventHandleFunctions[scene] ~= cast(FEEventHandle) &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!Draw)) {
                    DrawFunctions[scene] ~= cast(FEDraw) &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!OnError)) {
                    OnErrorFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(is(attrib : FunEvent!Destroy)) {
                    OnDestroyFunctions[scene] ~= &__traits(getMember, scene, member);
                }else
                static if(attrib.stringof[0 .. 8] == "InThread") {
                    StepThreadFunctions[scene][attrib.id] ~= &__traits(getMember, scene, member);
                }else
                static if(attrib.stringof[0 .. 12] == "TriggerEvent") {
                    OnTriggerFunctions[scene] ~= SRTrigger(attrib,
                    cast(FETrigger) &__traits(getMember, scene, member));
                }
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
            An array of request errors associated with the request type.
        +/
        uint[uint] apiError;
    }

    /++
        Exits the game with a successful error code.
    +/
    void close() @safe
    {
        api ~= APIResponse(APIType.ThreadClose, 0);
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
    void gotoin(string name) @safe
    {
        foreach(inscene; scenes) {
            if(inscene.name == name) {
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
    void gotoin(Name)() @safe
    in(isScene!Name)
    in(hasScene!Name)
    do
    {
        Scene scene;

        foreach(s; scenes)
        {
            if((cast(Name) s) !is null)
            {
                gotoin(s);

                break;
            }
        }
    }

    import tida.game.game, tida.graph.camera;

    Camera camera() @trusted
    {
        return _renderer.camera;
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
        _previous = current;

        if(current !is null)
        {
            if(current in LeaveFunctions) {
                foreach(fun; LeaveFunctions[current]) {
                    fun();
                }
            }
        
            foreach(instance; current.getList()) {
                if(instance in ILeaveFunctions) {
                    foreach(fun; ILeaveFunctions[instance]) {
                        fun();
                    }
                }
            }
        }

        if(current !is null) 
        {
            Instance[] persistents;

            foreach(instance; _previous.getList())
            {
                if(instance.persistent)
                    persistents ~= instance;
            }

            foreach(e; persistents)
            {
                auto threadID = e.threadID;
                current.instanceDestroy!InScene(e, false);

                if(scene.isThreadExists(threadID))
                    scene.add(e,threadID);
                else
                    scene.add(e);
            }
        }

        _initable = scene;

        if(!scene.isInit)
        {
            if(scene in InitFunctions)
            {
                foreach(fun; InitFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                if(instance in IInitFunctions) {
                    foreach(fun; IInitFunctions[instance]) {
                        fun();
                    }
                }
            }

            scene.isInit = true;
        }else
        {
            if(scene in RestartFunctions)
            {
                foreach(fun; RestartFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                if(instance in IRestartFunctions) {
                    foreach(fun; IRestartFunctions[instance]) {
                        fun();
                    }
                }
            }
        }

        if(scene in EntryFunctions) {
            foreach(fun; EntryFunctions[scene]) {
                fun();
            }
        }

        foreach(instance; scene.getList()) {
            if(instance in IEntryFunctions) {
                foreach(fun; IEntryFunctions[instance]) {
                    fun();
                }
            }
        }

        _initable = null;

        _current = scene;
    }

    /++
        Calling the game launch event.

        Should be called before all events, before the beginning of the
        cycle of life.
    +/
    void callGameStart() @trusted
    {
        foreach(scene; scenes) {
            if(scene in GameStartFunctions) {
                foreach(fun; GameStartFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                if(instance.active && !instance.withDraw) {
                    if(instance in IGameStartFunctions) {
                        foreach(fun; IGameStartFunctions[instance]) {
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
        foreach(scene; scenes) {
            if(scene in GameExitFunctions) {
                foreach(fun; GameExitFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                if(instance.active && !instance.withDraw) {
                    if(instance in IGameExitFunctions) {
                        foreach(fun; IGameExitFunctions[instance]) {
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
        if(current !is null)
        {
            if(current in OnErrorFunctions) {
                foreach(fun; OnErrorFunctions[current]) {
                    fun();
                }
            }

            foreach(instance; current.getList()) {
                if(instance.active && !instance.withDraw) {
                    if(instance in IOnErrorFunctions) {
                        foreach(fun; IOnErrorFunctions[instance]) {
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
    void callStep(size_t thread,IRenderer rend) @trusted
    {
        if(current !is null)
        {
            current.worldCollision();

            if(thread == 0)
            if(current in StepFunctions)
            {
                foreach(fun; StepFunctions[current]) {
                    fun();
                }
            }

            if(current in StepThreadFunctions) 
            if(thread in StepThreadFunctions[current]) {
                foreach(fun; StepThreadFunctions[current][thread])
                    fun();
            }

            foreach(instance; current.getThreadList(thread)) {
                if(instance.isDestroy) {
                    current.instanceDestroy!InMemory(instance);
                    current.sort();
                    continue;
                }

                if(!instance.active || instance.withDraw) continue;
            
                if(instance in IStepFunctions) {
                    foreach(fun; IStepFunctions[instance]) {
                        fun();
                    }
                }

                foreach(component; instance.getComponents())
                {
                    if(component in CStepFunctions) {
                        foreach(fun; CStepFunctions[component]) {
                            fun();
                        }
                    }
                }
            }

            foreach(instance; current.getList()) {
                if(!instance.active || instance.withDraw) continue;

                if(instance in IStepThreadFunctions)
                if(thread in IStepThreadFunctions[instance])
                {
                    foreach(fun; IStepThreadFunctions[instance][thread])
                        fun();
                }

                foreach(component; instance.getComponents())
                {
                    if(component in CStepThreadFunctions)
                    if(thread in CStepThreadFunctions[component]) {
                        foreach(fun; CStepThreadFunctions[component][thread]) {
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
        if(current !is null)
        {
            if(current in EventHandleFunctions) {
                foreach(fun; EventHandleFunctions[current]) {
                    fun(event);
                }
            }

            foreach(instance; current.getList()) 
            {
                if(instance.active && !instance.withDraw)
                {
                    if(instance in IEventHandleFunctions) {
                        foreach(fun; IEventHandleFunctions[instance]) {
                            fun(event);
                        }
                    }

                    foreach(component; instance.getComponents())
                    {
                        if(component in CEventHandleFunctions) {
                            foreach(fun; CEventHandleFunctions[component]) {
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

        if(current !is null)
        {
            if(current in DrawFunctions) {
                foreach(fun; DrawFunctions[current]) {
                    fun(render);
                }
            }

            foreach(instance; current.getErentInstances()) {
                if(instance.active && instance.visible)
                {
                    render.draw(instance.spriteDraw(),instance.position);

                    if(instance in IDrawFunctions) {
                        foreach(fun; IDrawFunctions[instance]) {
                            fun(render);
                        }
                    }

                    foreach(component; instance.getComponents())
                    {
                        if(component in CDrawFunctions) {
                            foreach(fun; CDrawFunctions[component]) {
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
