/++
Scene description module.

A stage is an object that manages instances, collisions between them and serves
as a place for them (reserves them in a separate array). Such an object can
also be programmable using events (see tida.localevent). It does not have
properties that define behavior without functions, it can only contain
instances that, through it, can refer to other instances.

WARNING:
Don't pass any arguments to the scene constructor. 
This breaks the scene restart mechanism.

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
A template that checks if the type is a scene.
+/
template isScene(T)
{
    enum isScene = is(T : Scene);
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
    final void add(T)(T instance, size_t threadID = 0)
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
    Adds multiple instances at a time.

    Params:
        instances = Instances.
        threadID = In which thread to add execution.
    +/
    final void add(Instance[] instances, size_t threadID = 0)
    {
        foreach (instance; instances)
        {
            add(instance,threadID);
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
        import std.algorithm : canFind, each;
        import std.range : empty;
        import std.parallelism : parallel;

        // EXPEREMENTAL
        foreach(first; parallel(list()))
        {
            foreach(second; list())
            {
                if(first !is second && first.solid && second.solid) {
                    if(first.active && second.active)
                    {
                        if (
                            isCollide(  first.mask,
                                        second.mask,
                                        first.position,
                                        second.position)
                        )
                        {
                            auto firstColliders = sceneManager.colliders()[first];
                            auto secondColliders = sceneManager.colliders()[second];

                            auto firstFunctions = sceneManager.collisionFunctions()[first];
                            auto secondFunctions = sceneManager.collisionFunctions()[second];

                            firstFunctions.each!((fun) => fun(second));
                            secondFunctions.each!((fun) => fun(first));

                            foreach (e; firstColliders)
                            {
                                if (e.ev.name.empty)
                                {
                                    if (!e.ev.tag.empty)
                                    {
                                        if (second.tags.canFind(e.ev.tag))
                                        {
                                            e.fun(second);
                                        }   
                                    }else
                                        e.fun(second);
                                } else
                                {
                                    if (e.ev.tag.empty)
                                    {
                                        e.fun(second);
                                    } else
                                    {
                                        if (second.tags.canFind(e.ev.tag))
                                        {
                                            e.fun(second);
                                        }
                                    }
                                }
                            }

                            foreach (e; secondColliders)
                            {
                                if (e.ev.name.empty)
                                {
                                    if (!e.ev.tag.empty)
                                    {
                                        if (first.tags.canFind(e.ev.tag))
                                        {
                                            e.fun(first);
                                        }   
                                    }else
                                        e.fun(first);
                                } else
                                {
                                    if (e.ev.tag.empty)
                                    {
                                        e.fun(first);
                                    } else
                                    {
                                        if (first.tags.canFind(e.ev.tag))
                                        {
                                            e.fun(first);
                                        }
                                    }
                                }
                            }
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
        instance = Instance.
        isRemoveHandle = State remove function pointers in scene manager.

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
		synchronized
		{
			foreach (instance; list())
			{
				if (instance.name == name)
					return instance;
			}

			return null;
		}
    }

    /++
    Returns an instance by name and tag.

    Params:
        name = Instance name.
        tag = Instance tag.
    +/
    final Instance getInstanceByNameTag(string name, string tag) nothrow
    {
		synchronized
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
		synchronized
		{
			foreach (instance; list)
			{
				if ((cast(T) instance) !is null)
					return cast(T) instance;
			}

			return null;
		}
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

		synchronized
        {
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
    }

    /// ditto
    final Instance[] getInstancesByMask(Shapef shape,Vecf position) @safe
    {
        import tida.collision;

        Instance[] result;

		synchronized
		{
			foreach(instance; list())
			{
				if(instance.solid)
				if(isCollide(shape,instance.mask,position,instance.position)) {
					result ~= instance;
					continue;
				}
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

    assert(scene.getInstanceByClass!A is (a));
    assert(scene.getInstanceByClass!B is (b));

    assert(scene.getInstanceByName("A") is (a));
    assert(scene.getInstanceByName("B") is (b));

    assert(scene.getInstanceByNameTag("A", "A") is (a));
    assert(scene.getInstanceByNameTag("B", "B") is (b));
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

    assert(scene.getAssortedInstances == ([b,a]));
}
