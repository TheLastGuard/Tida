/++
    Scene manager module.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.scene.manager;

import tida.scene.instance;
import tida.scene.scene;
import tida.scene.event;

static enum APIError : ubyte
{
    succes = 0,
    unknownThread = 1,
    noCreateThread = 2
}

T from(T)(Object obj) @trusted
{
    return cast(T) obj;
}

template isScene(T)
{
    enum isScene = is(T : Scene);
}

template isInstance(T)
{
    enum isInstance = is(T : Instance);
}

import core.thread;

class InstanceThread : Thread 
{
    import tida.fps;
    import tida.scene.instance;
    import tida.graph.render;

    private
    {
        bool isJob = true;
        bool isPause = false;
        FPSManager fps;
        Instance[] list;
        size_t thread;
        IRenderer rend;
    }

    this(size_t thread,IRenderer rend) @safe
    {
        fps = new FPSManager();

        this.thread = thread;
        this.rend = rend;

        super(&run);
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

    void exit() @safe
    {
        isJob = false;
    }
}

import tida.templates;

__gshared SceneManager _sceneManager;

/// Scene manager instance.
SceneManager sceneManager() @trusted
{
    return _sceneManager;
}

void initSceneManager() @trusted
{
    _sceneManager = new SceneManager();
}

/// Scene manager
class SceneManager
{
    import tida.scene.scene;
    import tida.graph.render;
    import tida.event;

    private
    {
        Scene[string] _scenes;
        Scene _current;
        Scene _previous;
        Scene _ofbegin;
        Scene _ofend;
        Scene _initable;
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
        Link to the currently active scene. With the help of it, 
        it will be convenient for the instances to communicate 
        with the scene. 
            For more convenient communication, there 
        is a function `from`, by which you can access the
        functions of the heir, but the main thing is to check 
        the correctness of the scene, otherwise you can get 
        an error:
        ---
        sceneManager.current.from!HeirScene.callback();
        ---
    +/
    Scene current() @safe @property nothrow
    {
        return _current;
    }

    /++
        Temporary reference during initialization. Use it only 
        in the `init`,` restart`, `entry` events. Contains a 
        link to the current scene, which will be initialized 
        (i.e., control is transferred).
    +/
    Scene initable() @safe @property
    {
        return _initable;
    }

    Scene context() @safe @property
    {
        return current is null ? initable : current;
    }

    /++
        Calls a trigger for the current scene, as well as its instances.

        Params:
            name = Trigger name.
    +/
    void trigger(string name) @trusted
    {
        auto scene = current is null ? initable : current;

        scene.trigger(name);

        if(scene in OnTriggerFunctions) {
            foreach(fun; OnTriggerFunctions[scene]) {
                if(fun.ev.name == name) {
                    fun.fun();
                }
            }
        }

        foreach(instance; scene.getList()) {
            instance.trigger(name);

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

    bool hasScene(Name)() @safe
    {
        foreach(scene; scenes) {
            if(scene.from!Name !is null) return true;
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
    body
    {
        uScene!T(scene);

        if(_ofbegin is null)
            _ofbegin = scene;

        _scenes[scene.name] = scene;
    }

    protected
    {
        import std.container, std.range, std.traits;

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

        Array!FEInit[Scene] InitFunctions;
        Array!FEStep[Scene] StepFunctions;
        Array!FERestart[Scene] RestartFunctions;
        Array!FEEntry[Scene] EntryFunctions;
        Array!FELeave[Scene] LeaveFunctions;
        Array!FEGameStart[Scene] GameStartFunctions;
        Array!FEGameExit[Scene] GameExitFunctions;
        Array!FEGameRestart[Scene] GameRestartFunctions;
        Array!FEEventHandle[Scene] EventHandleFunctions;
        Array!FEDraw[Scene] DrawFunctions;
        Array!FEOnError[Scene] OnErrorFunctions;
        Array!SRTrigger[Scene] OnTriggerFunctions;

        Array!FEInit[Instance] IInitFunctions;
        Array!FEStep[Instance] IStepFunctions;
        Array!FERestart[Instance] IRestartFunctions;
        Array!FEEntry[Instance] IEntryFunctions;
        Array!FELeave[Instance] ILeaveFunctions;
        Array!FEGameStart[Instance] IGameStartFunctions;
        Array!FEGameExit[Instance] IGameExitFunctions;
        Array!FEGameRestart[Instance] IGameRestartFunctions;
        Array!FEEventHandle[Instance] IEventHandleFunctions;
        Array!FEDraw[Instance] IDrawFunctions;
        Array!FEOnError[Instance] IOnErrorFunctions;
        Array!SRCollider[Instance] IColliderStructs;
        Array!SRTrigger[Instance] IOnTriggerFunctions;
    }

    Array!SRCollider[Instance] colliders() @safe @property
    {
        return IColliderStructs;
    }

    void RemoveHandle(Scene scene, Instance instance) @trusted
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
        IOnTriggerFunctions.remove(instance);
    }

    void InstanceHandle(T)(Scene scene, T instance) @trusted
    {
        IInitFunctions[instance] = Array!FEInit();
        IStepFunctions[instance] = Array!FEStep();
        IEntryFunctions[instance] = Array!FEEntry();
        IRestartFunctions[instance] = Array!FERestart();
        ILeaveFunctions[instance] = Array!FELeave();
        IGameStartFunctions[instance] = Array!FEGameStart();
        IGameExitFunctions[instance] = Array!FEGameExit();
        IGameRestartFunctions[instance] = Array!FEGameRestart();
        IEventHandleFunctions[instance] = Array!FEEventHandle();
        IDrawFunctions[instance] = Array!FEDraw();
        IOnErrorFunctions[instance] = Array!FEOnError();
        IColliderStructs[instance] = Array!SRCollider();
        IOnTriggerFunctions[instance] = Array!SRTrigger();

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
                static if(attrib.stringof[0 .. 14] == "CollisionEvent") {
                    IColliderStructs[instance] ~= SRCollider(attrib,
                    cast(FECollision) &__traits(getMember, instance, member));
                }else
                static if(attrig.stringof[0 .. 12] == "TriggerEvent") {
                    IOnTriggerFunctions[instance] ~= SRTrigger(attrib,
                    cast(FETrigger) &__traits(getMember, instance, member));
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
    body
    {
        auto scene = new T();       

        add!T(scene);
    }

    void remove(T)(T scene) @trusted
    in(isScene!T,"It's not a scene!")
    body
    {
        scenes.remove(scene.name);
        destroy(scene);
    }

    void remove(T)() @trusted
    in(isScene!T,"It's not a scene!")
    body
    {
        foreach(scene; scenes)
        {
            if(scene.from!T !is null) {
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
    {
        InitFunctions[scene] = Array!FEInit();
        StepFunctions[scene] = Array!FEStep();
        EntryFunctions[scene] = Array!FEEntry();
        RestartFunctions[scene] = Array!FERestart();
        LeaveFunctions[scene] = Array!FELeave();
        GameStartFunctions[scene] = Array!FEGameStart();
        GameExitFunctions[scene] = Array!FEGameExit();
        GameRestartFunctions[scene] = Array!FEGameRestart();
        EventHandleFunctions[scene] = Array!FEEventHandle();
        DrawFunctions[scene] = Array!FEDraw();
        OnErrorFunctions[scene] = Array!FEOnError();
        OnTriggerFunctions[scene] = Array!SRTrigger();

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
                static if(attrib.stringof[0 .. 12] == "TriggerEvent") {
                    OnTriggerFunctions[scene] ~= SRTrigger(attrib,
                    cast(FETrigger) &__traits(getMember, scene, member));
                }
            }
        }
    }

    public
    {
        bool apiThreadCreate = false;
        bool apiThreadPause = false;
        bool apiThreadResume = false;
        size_t apiThreadValue = 0;
        size_t apiError = 0;

        bool apiExit = false;
    }

    ///
    void close() @safe
    {
        apiExit = true;
    }

    ///
    void initThread(size_t count = 1) @safe
    {
        apiThreadCreate = true;
        apiThreadValue = count; 
    }

    ///
   void pauseThread(size_t value) @safe
    {
        apiThreadPause = true;
        apiThreadValue = value;
    }

    void resumeThread(size_t value) @safe
    {
        apiThreadResume = true;
        apiThreadValue = value;
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
    body
    {
        Scene scene;

        foreach(s; scenes)
        {
            if(s.from!Name !is null)
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
        Goes to the scene by his heir name.

        Params:
            scene = Scene heir. 
    +/
    void gotoin(Scene scene) @trusted
    in(hasScene(scene))
    body
    {
        _previous = current;

        if(current !is null)
        {
            current.leave();

            if(current in LeaveFunctions) {
                foreach(fun; LeaveFunctions[current]) {
                    fun();
                }
            }
        
            foreach(instance; current.getList()) {
                instance.leave();

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
                current.instanceDestroy!InScene(e);

                if(scene.isThreadExists(threadID))
                    scene.add(e,threadID);
                else
                    scene.add(e);
            }
        }

        _initable = scene;

        if(!scene.isInit)
        {
            scene.init();

            if(scene in InitFunctions)
            {
                foreach(fun; InitFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                instance.init();

                if(instance in IInitFunctions) {
                    foreach(fun; IInitFunctions[instance]) {
                        fun();
                    }
                }
            }

            scene.isInit = true;
        }else
        {
            scene.restart();

            if(scene in RestartFunctions)
            {
                foreach(fun; RestartFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                instance.restart();

                if(instance in IRestartFunctions) {
                    foreach(fun; IRestartFunctions[instance]) {
                        fun();
                    }
                }
            }
        }

        scene.entry();

        if(scene in EntryFunctions) {
            foreach(fun; EntryFunctions[scene]) {
                fun();
            }
        }

        foreach(instance; scene.getList()) {
            instance.entry();

            if(instance in IEntryFunctions) {
                foreach(fun; IEntryFunctions[instance]) {
                    fun();
                }
            }
        }

        _initable = null;

        _current = scene;
    }

    ///
    void callGameStart() @trusted
    {
        foreach(scene; scenes) {
            scene.gameStart();

            if(scene in GameStartFunctions) {
                foreach(fun; GameStartFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                if(instance.active && !instance.withDraw) {
                    instance.gameStart();

                    if(instance in IGameStartFunctions) {
                        foreach(fun; IGameStartFunctions[instance]) {
                            fun();
                        }
                    }
                }
            }
        }
    }

    ///
    void callGameExit() @trusted
    {
        foreach(scene; scenes) {
            scene.gameExit();

            if(scene in GameExitFunctions) {
                foreach(fun; GameExitFunctions[scene]) {
                    fun();
                }
            }

            foreach(instance; scene.getList()) {
                if(instance.active && !instance.withDraw) {
                    instance.gameExit();

                    if(instance in IGameExitFunctions) {
                        foreach(fun; IGameExitFunctions[instance]) {
                            fun();
                        }
                    }
                }
            }
        }
    }

    ///
    void callOnError() @trusted
    {
        if(current !is null)
        {
            current.onError();
            if(current in OnErrorFunctions) {
                foreach(fun; OnErrorFunctions[current]) {
                    fun();
                }
            }

            foreach(instance; current.getList()) {
                if(instance.active && !instance.withDraw) {
                    instance.onError();

                    if(instance in IOnErrorFunctions) {
                        foreach(fun; IOnErrorFunctions[instance]) {
                            fun();
                        }
                    }
                }
            }
        }
    }

    ///
    void callStep(size_t thread,IRenderer rend) @trusted
    {
        if(current !is null)
        {
            current.worldCollision();
            current.step();

            if(current in StepFunctions)
            {
                foreach(fun; StepFunctions[current]) {
                    fun();
                }
            }

            foreach(instance; current.getThreadList(thread)) {
                if(instance.isDestroy) {
                    current.instanceDestroy!InMemory(instance);
                    current.sort();
                    continue;
                }
            
                instance.step();

                if(instance in IStepFunctions) {
                    foreach(fun; IStepFunctions[instance]) {
                        fun();
                    }
                }

                foreach(component; instance.getComponents())
                {
                    component.step();
                }
            }
        }
    }

    ///
    void callEvent(EventHandler event) @trusted
    {
        if(current !is null)
        {
            current.event(event);

            if(current in EventHandleFunctions) {
                foreach(fun; EventHandleFunctions[current]) {
                    fun(event);
                }
            }

            foreach(instance; current.getList()) 
            {
                if(instance.active && !instance.withDraw)
                {
                    instance.event(event);

                    if(instance in IEventHandleFunctions) {
                        foreach(fun; IEventHandleFunctions[instance]) {
                            fun(event);
                        }
                    }

                    foreach(component; instance.getComponents())
                    {
                        component.event(event);
                    }
                }
            }
        }
    }

    ///
    void callDraw(IRenderer render) @trusted
    {
        import tida.vector;

        if(current !is null)
        {
            current.draw(render);

            if(current in DrawFunctions) {
                foreach(fun; DrawFunctions[current]) {
                    fun(render);
                }
            }

            foreach(instance; current.getErentInstances()) {
                if(instance is null) continue;
                
                if(instance.visible) render.draw(instance.spriteDraw(),instance.position);
            }

            foreach(instance; current.getErentInstances()) {
                if(instance is null) continue;

                if(instance.active && instance.visible)
                {
                    instance.draw(render);

                    if(instance in IDrawFunctions) {
                        foreach(fun; IDrawFunctions[instance]) {
                            fun(render);
                        }
                    }

                    foreach(component; instance.getComponents())
                    {
                        component.draw(render);
                    }
                }
            }

            debug
            {
                current.drawDebug(render);

                foreach(instance; current.getList())
                {
                    if(instance is null) continue;
                    if(!instance.visible) continue;
                    
                    instance.drawDebug(render);
                }
            }
        }
    }

    void free() @safe
    {
        _scenes = null;
    }

    ~this() @safe
    {
        free();
    }
}
