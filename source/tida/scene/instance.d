/++
    A module for describing an object in the game.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.scene.instance;

import tida.scene.component;
import std.algorithm : remove;

static immutable ubyte InMemory = 0; ///
static immutable ubyte InScene = 1; ///

template isComponent(T)
{
    enum isComponent = is(T : Component);
}

/// Instance information
struct InstanceInfo
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
class Instance
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
        +/
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
    final void sort() @safe
    {
        _sort = 1;
    }

    /++
        Indicates that it is time to destroy this instance.

        Please note that this action will be performed in the next step.
    +/
    final void destroy() @safe
    {
        _destroy = 1;
    }

    /++
        Instance information
    +/
    final InstanceInfo info() @safe @property
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
    final void add(T)(T cmp) @safe
    in
    {
        static assert(isComponent!T);
        assert(cmp,"Component is not create!");
    }do
    {
        import tida.scene.manager : sceneManager, SceneManager;

        if(cmp.name == "") {
            cmp.name = T.stringof;
        }

        cmp.init(this);
        components ~= cmp;

        if(sceneManager !is null)
            sceneManager.ComponentHandle!T(this, cmp);
    }

    /++
        Create a component to an instance.

        Params:
            Name = Component.
    +/
    final void add(Name)() @safe
    in(isComponent!Name,"Its not component!")
    do
    {
        add!Name(new Name());
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
    final T of(T)() @safe
    in(isComponent!T,"It not component!")
    do
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
    final Component of(string name)() @safe
    {
        Component obj;

        foreach(cmp; components) {
            if(cmp.name == name) {
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
    final Component of(string name) @safe
    {
        Component obj;

        foreach(cmp; components) {
            if(cmp.name == name) {
                obj = cmp;
                break;
            }
        }

        return obj;
    }

    /++ 
        Dissconnect component

        Params:
            Name = Class component.
    +/
    final void dissconnect(Name)() @trusted
    in(isComponent!Name,"It's not component!")
    do
    {
        import core.memory;
        import tida.scene.manager;

        Component cmp;

        foreach(i; 0 .. components.length) {
            if(components[i].from!Name !is null) {
                cmp = components[i];
                
                if(sceneManager !is null) {
                    foreach(fun; sceneManager.leaveComponents[cmp]) fun();
                }

                components = components.remove(i);
                break;
            }
        }
    }

    final void dissconnectAll() @trusted
    {
        import tida.scene.manager;

        foreach(i; 0 .. components.length) {
            if(sceneManager !is null) {
                foreach(fun; sceneManager.leaveComponents[components[i]]) fun();
            }

            components = components.remove(i);
        }
    }

    /++
        Dissconnect component

        Params:
            name = Component name.
    +/
    final void dissconnect(string name) @safe
    {
        foreach(i; 0 .. components.length) {
            if(components[i].name == name) {
                components = components.remove(i);
            }
        }
    }

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

    override bool opEquals(Object other) const
    {
        Instance ins = (cast(Instance) other);

        return (ins !is null) ? this.depth == ins.depth : false; 
    }

    int opCmp(ref Object other) const
    {
        Instance ins = (cast(Instance) other);
        if(ins is null) return 0;

        if(this.depth > ins.depth) return 1;
        else if(this.depth < ins.depth) return -1;

        return 0;
    }
}
