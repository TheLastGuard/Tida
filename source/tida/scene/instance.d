/++
    A module for describing an object in the game.

    Authors: TodNaz
    License: MIT
+/
module tida.scene.instance;

static immutable ubyte InMemory = 0; ///
static immutable ubyte InScene = 0; ///

private void remove(T)(ref T[] obj,size_t index) @trusted nothrow
{
    auto dump = obj.dup;
    foreach (i; index .. dump.length)
    {
        import core.exception : RangeError;
        try
        {
            dump[i] = dump[i + 1];
        }
        catch (RangeError e)
        {
            continue;
        }
    }
    obj = dump[0 .. $-1];
}

/// Instance information
public struct InstanceInfo
{
    import tida.vector, tida.shape;

    public
    {
        string name = ""; /// Instance name
        string[] tags = []; /// Instance tags
        Vecf position = Vecf(0,0); /// Instance position
        Vecf previous = Vecf(0,0); /// Instance previous position

        Shape shape = Shape(); /// Instance collision mask
        size_t id = 0; /// The reserved place in the array in the scene.
        size_t threadId = 0; /// Which thread the instance is running on.

        /++
            Instance activity. If you set this variable to `false`,
            then all events will not be processed, i.e. the object
            will actually be frozen.
        +/
        bool active = true;

        /++
            Object visibility. If it is set to `false`, then the 
            rendering of the sprite and the` draw` event will not 
            be processed.
        +/
        bool visible = true;

        /++
            Allows you to move the instance link to another 
            scene upon transition. Turns on once.
        ++/
        bool persistent = false;

        /++
            Maybe the object collides with others
        +/
        bool solid = true;

        bool withDraw = false; /// Tell the scene to only draw it. 
        size_t depth;
    }
}

/++
    A object for describing an object in the game.
+/
public class Instance
{
    import tida.scene.component;
    import tida.vector;
    import tida.game.sprite;
    import tida.shape;
    import tida.event;
    import tida.graph.render;

    protected
    {
        Sprite sprite;
        Component[] components;
    }

    public
    {
        string name = ""; /// Instance name
        string[] tags = []; /// Instance tags

        bool _sort = false; /// Sortable.
        bool _destroy = false; /// Destroy instance from memory.

        Vecf position = Vecf(0,0); /// Instance position
        Vecf previous = Vecf(0,0); /// Instance previous position
        Shape mask = Shape(); /// Instance collision mask
        size_t id = 0; /// The reserved place in the array in the scene.
        size_t threadID = 0; /// Which thread the instance is running on.

        /++
            Instance activity. If you set this variable to `false`,
            then all events will not be processed, i.e. the object
            will actually be frozen.
        +/
        bool active = true;

        /++
            Object visibility. If it is set to `false`, then the 
            rendering of the sprite and the` draw` event will not 
            be processed.
        +/
        bool visible = true;

        /++
            Allows you to move the instance link to another 
            scene upon transition. Turns on once.
        ++/
        bool persistent = false;

        /++
            Maybe the object collides with others
        +/
        bool solid = false;

        bool withDraw = false; /// Tell the scene to only draw it. 

        size_t depth = 0; /// Depth drawning.
    }

    ///
    this() @safe
    {
        sprite = new Sprite();

        if(name == "") {
            name = typeid(this).name;
        }
    }

    /++
        Cause the sorting facilities.

        Please note that this action will be performed in the next step.
    +/
    public void sort() @safe
    {
        _sort = 1;
    }

    /++
        Indicates that it is time to destroy this instance.

        Please note that this action will be performed in the next step.
    +/
    public void destroy() @safe
    {
        _destroy = 1;
    }

    /++
        Instance information
    +/
    public InstanceInfo info() @safe @property
    {
        return InstanceInfo(
            name, tags, position, previous, mask, 
            id, threadID, active, visible, persistent, solid, withDraw, depth
        );
    }

    /++
        Adds a component to an instance.

        Params:
            cmp = Component.
    +/
    public void add(Component cmp) @safe
    in
    {
        assert(cmp,"Component is not create!");
        assert(cmp.getName != "","Give the component a name.");
    }body
    {
        cmp.init(this);
        components ~= cmp;
    }

    /++
        Create a component to an instance.

        Params:
            Name = Component.
    +/
    public void add(Name)() @safe
    in(new Name().from!Component,"Its not component!")
    body
    {
        add(new Name());
    }

    /++
        Returns the component by its class component. 

        Params:
            T = Class.

        Example:
        ---
        instance.add!Gravity;
        instance.of!Gravity.F = 0.1f;
        ---
    +/
    public T of(T)() @safe
    in(new T().from!Component,"It not component!")
    body
    {
        T obj;

        foreach(cmp; components) {
            if((obj = cmp.from!T) !is null)
                break;
        }

        return obj;
    }

    /++
        Return the component by its name.

        Params:
            name = Component name. 
    +/
    public Component of(string name)() @safe
    {
        Component obj;

        foreach(cmp; components) {
            if(cmp.getName() == name) {
                obj = cmp;
                break;
            }
        }

        return obj;
    }

    /++
        Return the component by its name.

        Params:
            name = Component name. 
    +/
    public Component of(string name) @safe
    {
        Component obj;

        foreach(cmp; components) {
            if(cmp.getName() == name) {
                obj = cmp;
                break;
            }
        }

        return obj;
    }

    public void dissconnect(Name)() @trusted
    {
        Component cmp;

        foreach(i; 0 .. components) {
            if(components[i].from!Name !is null) {
                cmp = components[i];
                components.remove(i);
                break;
            }
        }

        if(cmp !is null) destroy(cmp);
    }

    /++
        This event is fired once when control is first transferred 
        to the scene. The next time control is transferred, this 
        event will not be triggered.
        Note:
            It's useless to use `sceneManager.current` to grab the current 
            instance, since this link will enter into the previous scene. 
            For real it is better to use `sceneManager.initable`.
    +/
    public void init() @safe {}
    
    /++
        This event will be triggered when control is not transferred 
        to the scene for the first time. The first time will not be 
        called.
        Note:
            It's useless to use `sceneManager.current` to grab the current 
            instance, since this link will enter into the previous scene. 
            For real it is better to use `sceneManager.initable`.
    +/
    public void restart() @safe {}

    /++
        This event is always called when control is transferred to the scene.
        Note:
            It's useless to use `sceneManager.current` to grab the current 
            instance, since this link will enter into the previous scene. 
            For real it is better to use `sceneManager.initable`.
    +/
    public void entry() @safe {}

    public void leave() @safe {}

    /++
        This event will be triggered when the user enters something. 
        This does not mean that it is equivalent to `step`.
    +/
    public void event(EventHandler event) @safe {}

    /++
        This event is called always and constantly at the rate of the specified 
        frame counter. Also, when new threads are declared and the instance is 
        redefined in a different thread, this event will run on a different thread.
    +/
    public void step() @safe {}

    /++
        This event is for drawing something on the screen.
        Params:
            graph = Instance to render.
    +/
    public void draw(Renderer graph) @safe {}

    /++
        This event is intended for rendering in debug mode.
        Params:
            graph = Instance to render.
    +/
    debug public void drawDebug(Renderer graph) @safe {}

    /++
        This event will be triggered when the game is closed by the user or 
        the program.
    +/
    public void gameExit() @safe {}

    /++
        This event will be triggered when the game is restarted by the program.
    +/
    public void gameRestart() @safe {}

    /++
        This event will be triggered when the game is launched with `game.run`.
    +/
    public void gameStart() @safe {}

    /++
        This event is fired when someone has thrown a trigger.
        Params:
            oftrigger = Trigger name.
    +/
    public void trigger(string oftrigger) @safe {}

    /++
        This event will be thrown when any exception is thrown.
    +/
    public void onError() @safe {}

    /++
        This event will be triggered when the instance is destroyed.
    +/
    public void eventDestroy(ubyte type) @safe {}

    /++
        This event will be triggered when this instance collides with someone.
    +/
    public void collision(Instance other) @safe {}

    package(tida.scene) 
    {
        Sprite spriteDraw() @safe
        {
            return sprite;
        }

        bool isSort() @safe
        {
            return _sort;
        }

        bool isDestroy() @safe
        {
            return _destroy;
        }

        Component[] getComponents() @safe
        {
            return components;
        }
    }

    import tida.scene.manager : from;

    override bool opEquals(Object other) const
    {
        Instance ins = other.from!Instance;

        return (ins !is null) ? this.depth == ins.depth : false; 
    }

    int opCmp(ref Object other) const
    {
        Instance ins = other.from!Instance;
        if(ins is null) return 0;

        if(this.depth > ins.depth) return 1;
        else if(this.depth < ins.depth) return -1;

        return 0;
    }
}