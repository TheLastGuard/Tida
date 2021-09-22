/++
Scene description module.

A stage is an object that manages instances, collisions between them and serves
as a place for them (reserves them in a separate array). Such an object can
also be programmable using events (see tida.localevent). It does not have
properties that define behavior without functions, it can only contain
instances that, through it, can refer to other instances.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.scene;

enum
{
    InMemory, /// Delete with memory
    InScene /// Delete with scene
}

/++
Scene object.
+/
class Scene
{
    import tida.scenemanager;
    import tida.instance;
    import tida.component;
    import tida.render;
    import tida.event;

package(tida):
    bool isInit = false;

protected:
    Instance[] instances;
    Instance[] erentInstances;
    Instance[][] bufferThread;

public:
    Camera camera; /// Camera scene
    string name = ""; /// Scene name

@safe:
    this() nothrow
    {
        bufferThread = [[]];
    }

    /++
    Returns a list of instances.
    +/
    @property final Instance[] list() nothrow
    {
        return instances;
    }

    /++
    Returns a buffer of instances from the thread.

    Params:
        index = Thread id.
    +/
    final Instance[] getThreadList(size_t index) nothrow
    {
        return bufferThread[index];
    }

    /++
    Is there such a thread buffer.

    Params:
        index = Thread id.
    +/
    final bool isThreadExists(size_t index) nothrow
    {
        return index < bufferThread.length;
    }

    /++
    Creates an instance buffer for the thread.
    +/
    final void initThread(size_t count = 1) nothrow
    {
        foreach (_; 0 .. count)
        {
            bufferThread ~= [[]];
        }
    }

    /++
    Adds an instance to the scene for interpreting its actions.

    Params:
        instance = Instance.
        threadID = In which thread to add execution.
    +/
    final void add(T)(T instance,size_t threadID = 0)
    in(instance, "Instance is not a create!")
    do
    {
        static assert(isInstance!T, T.stringof ~ " is not a instance!");
        if (threadID >= bufferThread.length) threadID = 0;

        this.instances ~= instance;
        instance.id = this.instances.length - 1;
        instance.threadid = threadID;

        bufferThread[threadID] ~= instance;

        sceneManager.instanceExplore!T(this, instance);

        this.sort();
    }

    /++
    Creates and adds an instance to the scene.

    Params:
        Name = Name class.
        threadID = In which thread to add execution.

    Note:
        There must be no arguments in the constructor.
    +/
    final void add(Name)(size_t threadID = 0)
    {
        static assert(isInstance!T, T.stringof ~ " is not a instance!");
        auto instance = new Name();

        add(instance, threadID);
    }

    /++
    Adds multiple instances at a time.

    Params:
        instances = Instances.
        threadID = In which thread to add execution.
    +/
    final void add(Instance[] instances,size_t threadID = 0)
    {
        foreach(instance; instances) {
            add(instance,threadID);
        }
    }

    /++
    Adds multiple instances at a time.

    Params:
        Names = Names instances.
        threadID = In which thread to add execution.
    +/
    final void add(Names...)(size_t threadID = 0)
    {
        static foreach (Name; Names) {
            add!Name(threadID);
        }
    }

    /++
    Returns a assorted list of instances.
    +/
    final Instance[] getAssortedInstances()
    {
        return erentInstances;
    }

    /++
    Whether this instance is on the list.

    Params:
        instance = Instance.
    +/
    final bool hasInstance(Instance instance) nothrow
    {
        foreach(ins; instances) {
            if(instance is ins)
                return true;
        }

        return false;
    }

    /++
    Checks instances for collisions.
    +/
    void worldCollision() @trusted
    {
        import tida.collision;

        auto collstragt = sceneManager.collisionFunctions;
        auto coll = sceneManager.colliders;

        foreach(first; list())
        {
            foreach(second; list())
            {
                if(first !is second && first.solid && second.solid) {
                    if(first.active && second.active)
                    {
                        import std.algorithm : canFind, each;

                        if (
                            isCollide(  first.mask,
                                        second.mask,
                                        first.position,
                                        second.position)
                        ) {
                            if (first in collstragt)
                                collstragt[first].each!(fun => fun(second));

                            if (second in collstragt)
                                collstragt[second].each!(fun => fun(first));

                            if (first in coll)
                            {
                                foreach (cls; coll[first])
                                {
                                    if (cls.ev.name != "")
                                    {
                                        if (cls.ev.name == second.name)
                                        {
                                            if (cls.ev.tag != "")
                                            {
                                                if (second.tags.canFind(cls.ev.tag))
                                                {
                                                    cls.fun(second);
                                                }
                                            } else
                                                cls.fun(second);
                                        }
                                    } else
                                    {
                                        if (cls.ev.tag != "")
                                        {
                                            if (second.tags.canFind(cls.ev.tag))
                                            {
                                                cls.fun(second);
                                            }
                                        } else
                                        {
                                            cls.fun(second);
                                        }
                                    }
                                }
                            }

                            if (second in coll)
                            {
                                foreach (cls; coll[second])
                                {
                                    if (cls.ev.name != "")
                                    {
                                        if (cls.ev.name == first.name)
                                        {
                                            if (cls.ev.tag != "")
                                            {
                                                if (first.tags.canFind(cls.ev.tag))
                                                {
                                                    cls.fun(first);
                                                }
                                            } else
                                                cls.fun(first);
                                        }
                                    } else
                                    {
                                        if (first.tags.canFind(cls.ev.tag))
                                        {
                                            cls.fun(first);
                                        }
                                    }
                                }
                            }
                        } else
                        {
                            if (first in collstragt)
                                collstragt[first].each!(fun => fun(null));

                            if (second in collstragt)
                                collstragt[second].each!(fun => fun(null));
                        }
                    }
                }
            }
        }
    }

    /++
    Removes an instance from the list and, if a delete method is
    specified in the template, from memory.

    Params:
        type = Type destroy.
        instance = Instance.

    Type:
        `InScene`  - Removes only from the scene, does not free memory.
        `InMemory` - Removes permanently, from the scene and from memory
                     (by the garbage collector).
    +/
    final void instanceDestroy(ubyte type)(Instance instance, bool isRemoveHandle = true) @trusted
    in(hasInstance(instance))
    do
    {
        import std.algorithm : each;

        // dont remove, it's succes work.
        void remove(T)(ref T[] obj, size_t index) @trusted nothrow
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

        remove(instances, instance.id);
        foreach (size_t i; 0 .. bufferThread[instance.threadid].length)
        {
            if (bufferThread[instance.threadid][i] is instance)
            {
                remove(bufferThread[instance.threadid],i);
                break;
            }
        }

        if (this.instances.length != 0)
        {
            this.instances[instance.id .. $].each!((ref e) => e.id--);
        }

        if (sceneManager !is null)
        {
            sceneManager.destroyEventCall(instance);
            sceneManager.destroyEventSceneCall(this, instance);
        }

        if (sceneManager !is null && isRemoveHandle)
            sceneManager.removeHandle(this, instance);

        static if(type == InMemory)
        {
            instance.dissconnectAll();
            destroy(instance);
        }
    }

    /++
    Destroys an instance from the scene or from memory, depending on the template argument, by its class.

    Params:
        type = Type destroy.
        Name = Instance class.

    Type:
        `InScene`  - Removes only from the scene, does not free memory.
        `InMemory` - Removes permanently, from the scene and from memory
                     (by the garbage collector).
    +/
    final void instanceDestroy(ubyte type, Name)() @trusted
    in(isInstance!Name)
    do
    {
        instanceDestroy!type(getInstanceByClass!Name);
    }

    /++
    Returns an instance by name.

    Params:
        name = Instance name.
    +/
    final Instance getInstanceByName(string name) nothrow
    {
        foreach (instance; list())
        {
            if (instance.name == name)
                return instance;
        }

        return null;
    }

    /++
    Returns an instance by name and tag.

    Params:
        name = Instance name.
        tag = Instance tag.
    +/
    final Instance getInstanceByNameTag(string name, string tag) nothrow
    {
        foreach (instance; list())
        {
            if (instance.name == name)
            {
                foreach (tage; instance.tags)
                    if (tag == tage)
                        return instance;
            }
        }

        return null;
    }

    /++
    Returns an object by its instance inheritor.

    Params:
        T = Class name.
    +/
    final T getInstanceByClass(T)() nothrow
    in(isInstance!T)
    do
    {
        foreach (instance; list)
        {
            if ((cast(T) instance) !is null)
                return cast(T) instance;
        }

        return null;
    }

    import tida.shape, tida.vector;

    /++
    Returns instance(-s) by its mask.

    Params:
        shape = Shape mask.
        position = Instance position.
    +/
    final Instance getInstanceByMask(Shapef shape, Vecf position)
    {
        import tida.collision;

        foreach (instance; list())
        {
            if (instance.solid)
            if (isCollide(shape,instance.mask,position,instance.position))
            {
                return instance;
            }
        }

        return null;
    }

    /// ditto
    final Instance[] getInstancesByMask(Shapef shape,Vecf position) @safe
    {
        import tida.collision;

        Instance[] result;

        foreach(instance; list())
        {
            if(instance.solid)
            if(isCollide(shape,instance.mask,position,instance.position)) {
                result ~= instance;
                continue;
            }
        }

        return result;
    }

    /// Clear sorted list of instances.
    void sortClear() @safe
    {
        this.erentInstances = null;
    }

    /// Sort list of instances.
    void sort() @trusted
    {
        void sortErent(T)(ref T[] data, bool delegate(T a, T b) @safe nothrow func) @trusted nothrow
        {
            T tmp;
            for (size_t i = 0; i < data.length; i++)
            {
                for (size_t j = (data.length-1); j >= (i + 1); j--)
                {
                    if (func(data[j],data[j-1]))
                    {
                        tmp = data[j];
                        data[j] = data[j-1];
                        data[j-1] = tmp;
                    }
                }
            }
        }

        sortClear();

        erentInstances = instances.dup;
        sortErent!Instance(erentInstances,(a, b) @safe nothrow => a.depth > b.depth);
    }
}

unittest
{
    import tida.instance;
    import tida.scenemanager;

    initSceneManager();

    class A : Instance { this() @safe { name = "A"; tags = ["A"]; }}
    class B : Instance { this() @safe { name = "B"; tags = ["B"]; }}

    Scene scene = new Scene();

    auto a = new A();
    auto b = new B();
    scene.add([a,b]);

    assert(scene.getInstanceByClass!A == a);
    assert(scene.getInstanceByClass!B == b);

    assert(scene.getInstanceByName("A") == a);
    assert(scene.getInstanceByName("B") == b);

    assert(scene.getInstanceByNameTag("A", "A") == a);
    assert(scene.getInstanceByNameTag("B", "B") == b);
}

unittest
{
    import tida.instance;
    import tida.scenemanager;

    initSceneManager();

    Scene scene = new Scene();

    Instance a = new Instance(),
             b = new Instance();

    a.depth = 3;
    b.depth = 7;

    scene.add([a,b]);

    assert(scene.getAssortedInstances == [b,a]);
}