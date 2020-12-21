/++
    Scene manager module.

    Authors: TodNaz
    License: MIT
+/
module tida.scene.manager;

import tida.scene.instance;
import tida.scene.scene;

static enum APIError : ubyte
{
    succes = 0,
    unknownThread = 1,
    noCreateThread = 2
}

public T from(T)(Object obj) @trusted
{
    return cast(T) obj;
}

import core.thread;

public class InstanceThread : Thread 
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
        Renderer rend;
    }

    this(size_t thread,Renderer rend) @safe
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

    public void exit() @safe
    {
        isJob = false;
    }
}

__gshared SceneManager _sceneManager;

public SceneManager sceneManager() @trusted
{
    return _sceneManager;
}

public void initSceneManager() @trusted
{
    _sceneManager = new SceneManager();
}

/// Scene manager
public class SceneManager
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
    public Scene[string] scenes() @safe @property
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
    public Scene ofbegin() @safe @property
    {
        return _ofbegin;
    }

    /++
        The last added scene.
    +/
    public Scene ofend() @safe @property
    {
        return _ofend;
    }

    /++
        The previous scene that was active.
    +/
    public Scene previous() @safe @property
    {
        return _previous;
    }

    /++
        Link to the currently active scene. With the help of it, 
        it will be convenient for the instances to communicate 
        with the scene. 
            For more convenient communication, there 
        is a function `getScene`, by which you can access the 
        functions of the heir, but the main thing is to check 
        the correctness of the scene, otherwise you can get 
        an error:
        ---
        sceneManager.current.getScene!HeirScene.callback();
        ---
    +/
    public Scene current() @safe @property nothrow
    {
        return _current;
    }

    /++
        Temporary reference during initialization. Use it only 
        in the `init`,` restart`, `entry` events. Contains a 
        link to the current scene, which will be initialized 
        (i.e., control is transferred).
    +/
    public Scene initable() @safe @property
    {
        return _initable;
    }

    /++
        Calls a trigger for the current scene, as well as its instances.

        Params:
            name = Trigger name.
    +/
    public void trigger(string name) @safe
    {
        current.trigger(name);

        foreach(instance; current.getList()) {
            instance.trigger(name);
        }
    }

    /++
        Checks if the scene is in the scene list.

        Params:
            scene = Scene.
    +/
    public bool hasScene(Scene scene) @safe
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
        Adds a scene to the list.

        Params:
            scene = Scene.
    +/
    public void add(Scene scene) @safe
    {
        if(_ofbegin is null)
            _ofbegin = scene;

        _scenes[scene.name] = scene;
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
    public void add(T)() @safe
    in(new T().from!Scene)
    body
    {
        add(new T);
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
    public void close() @safe
    {
        apiExit = true;
    }

    ///
    public void initThread(size_t count = 1) @safe
    {
        apiThreadCreate = true;
        apiThreadValue = count; 
    }

    ///
    public void pauseThread(size_t value) @safe
    {
        apiThreadPause = true;
        apiThreadValue = value;
    }

    public void resumeThread(size_t value) @safe
    {
        apiThreadResume = true;
        apiThreadValue = value;
    }

    /++
        Goes to the first scene added.
    +/
    public void inbegin() @safe
    {
        gotoin(_ofbegin);
    }

    /++
        Goes to the scene by its string name.

        Params:
            name = Scene name.
    +/
    public void gotoin(string name) @safe
    {
        foreach(inscene; scenes) {
            if(inscene.name == name) {
                gotoin(inscene);
                break;
            }
        }
    }

    /++
        Goes to the scene by his heir name.

        Params:
            scene = Scene heir. 
    +/
    public void gotoin(Scene scene) @safe
    in(hasScene(scene))
    body
    {
        _previous = current;

        if(current !is null)
        {
            current.leave();
        
            foreach(instance; current.getList()) {
                instance.leave();
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

            foreach(ref e; persistents)
            {
                auto threadID = e.threadID;
                current.instanceDestroy!InScene(e);
                
                if(scene.isThreadExists(threadID))
                    scene.add(e,threadID);
                else
                    scene.add(e);
            }

            persistents = null;
        }

        _initable = scene;

        if(!scene.isInit)
        {
            scene.init();

            foreach(instance; scene.getList()) {
                instance.init();
            }

            scene.isInit = true;
        }else
        {
            scene.restart();

            foreach(instance; scene.getList()) {
                instance.restart();
            }
        }

        scene.entry();

        foreach(instance; scene.getList()) {
            instance.entry();
        }

        _initable = null;

        _current = scene;
    }

    ///
    public void callGameStart() @safe
    {
        foreach(scene; scenes) {
            scene.gameStart();

            foreach(instance; scene.getList())
                instance.gameStart();
        }
    }

    ///
    public void callGameExit() @safe
    {
        foreach(scene; scenes) {
            scene.gameExit();

            foreach(instance; scene.getList())
                instance.gameExit();
        }
    }

    ///
    public void callOnError() @safe
    {
        if(current !is null)
        {
            current.onError();

            foreach(instance; current.getList())
                instance.onError();
        }
    }

    ///
    public void callStep(size_t thread,Renderer rend) @safe
    {
        if(current !is null)
        {
            rend.camera = current.camera;
            current.worldCollision();
            current.step();

            foreach(instance; current.getThreadList(thread)) {
            	if(instance.isDestroy) {
            		current.instanceDestroy!InMemory(instance);
            		continue;
            	}
            
                instance.step();

                foreach(component; instance.getComponents())
                {
                    component.step();
                }
            }
        }
    }

    ///
    public void callEvent(EventHandler event) @safe
    {
        if(current !is null)
        {
            current.event(event);

            foreach(instance; current.getList()) 
            {
                instance.event(event);

                foreach(component; instance.getComponents())
                {
                    component.event(event);
                }
            }
        }
    }

    ///
    public void callDraw(Renderer render) @safe
    {
        import tida.vector;

        if(current !is null)
        {
            current.draw(render);

            foreach(instance; current.getErentInstances())
                render.draw(instance.spriteDraw(),instance.position);

            foreach(instance; current.getErentInstances())
                instance.draw(render);

            debug
            {
                current.drawDebug(render);

                foreach(instance; current.getList())
                {
                    instance.drawDebug(render);

                    foreach(component; instance.getComponents())
                    {
                        component.draw(render);
                    }
                }
            }
        }
    }

    public void free() @safe
    {
        _scenes = null;
    }

    ~this() @safe
    {
        free();
    }
}