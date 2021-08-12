/++
    A module for describing a scene in the play space.
	
    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.scene.scene;

/++
    Scene.
+/ 
class Scene
{
    import tida.scene.manager;
    import tida.scene.instance;
    import tida.scene.component;
    import tida.graph.camera;
    import tida.graph.render;
    import tida.event;
    import tida.game.tile;
    import std.typecons;

    public
    {
        Camera camera; /// Camera scene
        string name = ""; /// Scene name
    }

    package(tida.scene)
    {
        bool isInit = false; /// Is init scene
    }

    protected
    {
        Instance[] instances;
        Tile[] tiles;

        Instance[] erentInstances;
        Tile[] erentTiles;

        Instance[][] bufferThread;
    }

    ///
    this() @safe nothrow
    {
        if(name == "") {
            name = typeid(this).name;
        }

        bufferThread = [[]];
    }

    /++
        Returns a list of instances.
    +/
    final Instance[] getList() @safe nothrow
    {
        return instances;
    }

    /++
        Returns a buffer of instances from the stream.

        Params:
            index = Thread id.
    +/
    final Instance[] getThreadList(size_t index) @safe nothrow
    {
        return bufferThread[index];
    }

    /++
        Is there such a stream buffer.

        Params:
            index = Thread id.
    +/
    final bool isThreadExists(size_t index) @safe nothrow
    {
        return index < bufferThread.length;
    }

    /// Starts a buffer of instances with the specified number.
    final void initThread(size_t count = 1) @safe nothrow
    {
        foreach(_; 0 .. count)
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
    final void add(T)(T instance,size_t threadID = 0) @safe
    in(isInstance!T,"This is not a instance!")
    in(instance,"Instance is not create!")
    do
    {  
        if(threadID >= bufferThread.length) threadID = 0;

        this.instances ~= instance;
        instance.id = this.instances.length - 1;
        instance.threadID = threadID;

        bufferThread[threadID] ~= instance;

        if(sceneManager !is null)
            sceneManager.InstanceHandle!T(this, instance);

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
    final void add(Name)(size_t threadID = 0) @safe
    in(isInstance!Name,"It's not instance!")
    do
    {
        auto instance = new Name();

        add(instance,threadID);
    }

    /++
        Adds multiple instances at a time.

        Params:
            instances = Instances.
            threadID = In which thread to add execution. 
    +/
    final void add(Instance[] instances,size_t threadID = 0) @safe
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
    final void add(Names...)(size_t threadID = 0) @safe
    {
        static foreach(Name; Names) {
            add!Name(threadID);
        }
    }

    /++
        Returns a sorted list of instances.
    +/
    final Instance[] getErentInstances() @safe nothrow
    {
        return erentInstances;
    }

    /++
        Whether this instance is on the list.

        Params:
            instance = Instance. 
    +/
    final bool hasInstance(Instance instance) @safe nothrow
    {
        foreach(ins; instances) {
            if(instance is ins)
                return true;
        }

        return false;
    }

    ///
    void worldCollision() @trusted
    {
        import tida.game.collision;

        auto collstragt = sceneManager.collisionFunctions;
        auto coll = sceneManager.colliders;

        foreach(first; getList()) {
            foreach(second; getList()) {
                if(first !is second && first.solid && second.solid) {
                    if(first.active && second.active)
                    {
                        import std.algorithm : canFind, each;

                        if(
                            isCollide(  first.mask,
                                        second.mask,
                                        first.position,
                                        second.position)
                        ) {
                            if(first in collstragt) collstragt[first].each!(fun => fun(second));
                            if(second in collstragt) collstragt[second].each!(fun => fun(first));
                            
                            if(first in coll) {
                                foreach(cls; coll[first]) {
                                    if(cls.ev.name != "") {
                                        if(cls.ev.name == second.name) {
                                            if(cls.ev.tag != "") {
                                                if(second.tags.canFind(cls.ev.tag)) {
                                                    cls.fun(second);
                                                }
                                            }else
                                                cls.fun(second);
                                        }
                                    }else {
                                        if(cls.ev.tag != "") {
                                            if(second.tags.canFind(cls.ev.tag)) {
                                                cls.fun(second);
                                            }
                                        } else {
                                            cls.fun(second);
                                        }
                                    }
                                }
                            }

                            if(second in coll) {
                                foreach(cls; coll[second]) {
                                    if(cls.ev.name != "") {
                                        if(cls.ev.name == first.name) {
                                            if(cls.ev.tag != "") {
                                                if(first.tags.canFind(cls.ev.tag)) {
                                                    cls.fun(first);
                                                }
                                            }else
                                                cls.fun(first);
                                        }
                                    }else {
                                        if(first.tags.canFind(cls.ev.tag)) {
                                            cls.fun(first);
                                        }
                                    }
                                }
                            }
                        } else {
                            if(first in collstragt) collstragt[first].each!(fun => fun(null));
                            if(second in collstragt) collstragt[second].each!(fun => fun(null));
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
        import std.algorithm : each, remove;

        instances = instances.remove!(a => a is instance);
        bufferThread[instance.threadID] = bufferThread[instance.threadID].remove!(a => a is instance);

        if(this.instances.length != 0)
        {
            this.instances[instance.id .. $].each!((ref e) => e.id--);
        }

        if(sceneManager !is null) {
            sceneManager.DestroyEventCall(instance);
            sceneManager.DestroyEventSceneCall(this, instance);
        }

        if(sceneManager !is null && isRemoveHandle)
            sceneManager.RemoveHandle(this, instance);

        static if(type == InMemory) {
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
    final void instanceDestroy(ubyte type,Name)() @trusted
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
    final Instance getInstanceByName(string name) @safe nothrow
    {
        foreach(instance; getList)
        {
            if(instance.name == name)
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
    final Instance getInstanceByNameTag(string name,string tag) @safe nothrow
    {
        foreach(instance; getList)
        {
            if(instance.name == name) {
                foreach(tage; instance.tags)
                    if(tag == tage)
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
    final T getInstanceByClass(T)() @safe nothrow
    in(isInstance!T)
    do
    {
        foreach(instance; getList)
        {
            if((cast(T) instance) !is null)
                return cast(T) instance;
        }
    	
        return null;
    }

    unittest
    {
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

    import tida.shape, tida.vector;

    final Instance getInstanceByMask(Shape shape,Vecf position) @safe
    {
        import tida.game.collision;

        foreach(instance; getList)
        {
            if(instance.solid)
            if(isCollide(shape,instance.mask,position,instance.position)) {
                return instance;
            }
        }

        return null;
    }

    unittest
    {
        Scene scene = new Scene();

        Instance a = new Instance();

        a.mask = Shape.Rectangle(Vecf(0,0), Vecf(32,32));
        a.solid = true;

        scene.add(a);

        assert(scene.getInstanceByMask(Shape.Line(Vecf(4,4), Vecf(24, 24)), Vecf(0, 0)) is a);
        assert(scene.getInstanceByMask(Shape.Line(Vecf(128, 64), Vecf(256, 32)) is null);
    }

    ///
    final Instance[] getInstancesByMask(Shape shape,Vecf position) @safe
    {
        import tida.game.collision;

        Instance[] result;

        foreach(instance; getList)
        {
            if(instance.solid)
            if(isCollide(shape,instance.mask,position,instance.position)) {
                result ~= instance;
                continue;
            }
        }

        return result;
    }

    unittest
    {
        Scene scene = new Scene;

        Instance a = new Instance();
        Instance b = new Instance();

        scene.add([a,b]);

        scene.instanceDestroy!InMemory(a);

        assert(scene.getList() == [b]);
    }

    /// Clear sorted list of instances.
    void sortClear() @safe 
    {
        this.erentInstances = null;
        this.erentTiles = null;
    }

    /// Sort list of instances.
    void sort() @trusted 
    {
        void sortErent(T)(ref T[] data,bool delegate(T a,T b) @safe nothrow func) @trusted nothrow
        {
            T tmp;
            for(size_t i = 0; i < data.length; i++)
            {
                for(size_t j = (data.length-1); j >= (i + 1); j--)
                {
                    if(func(data[j],data[j-1])) {
                        tmp = data[j];
                        data[j] = data[j-1];
                        data[j-1] = tmp;
                    }
                }
            }
        }

        sortClear();

        erentInstances = instances.dup;
        erentTiles = tiles.dup;

        sortErent!Instance(erentInstances,(a,b) @safe nothrow => a.depth > b.depth);
        sortErent!Tile(erentTiles,(a,b) => a.depth > b.depth);
    }

    unittest
    {
        Scene scene = new Scene();
        
        Instance a = new Instance(),
                 b = new Instance();

        a.depth = 3;
        b.depth = 7;

        scene.add([a,b]);

        assert(scene.getErentInstances == [b,a]);
    }
}
