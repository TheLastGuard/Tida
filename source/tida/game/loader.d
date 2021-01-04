/++
    Resource loader module

    Using the loader, you can load various resources that 
    will be kept in memory. They can be accessed by their 
    name or path, they can also be unloaded from memory.

    Please note that it is unnecessary to reload `download` since it does 
    not exist, it is implemented using the download-upload method. It will 
    load the resource from the .temp folder.
    
    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.loader;

import std.path : baseName, stripExtension;
import std.file : exists,mkdir;
import tida.templates;

mixin Global!(Loader,"loader");

struct Resource
{
    public
    {
        Object object;
        string type;
        string path;
        string name;
        bool isFont = false;
    }

    void init(T)(T resource) @trusted
    {
        object = resource;
        type = typeid(T).toString;
    }

    T get(T)() @trusted
    in(typeid(T).toString == type)
    body
    {
        return cast(T) object;
    }

    string getPath() @safe nothrow
    {
        return path;
    }

    string getName() @safe nothrow
    {
        return name;
    }

    void free() @trusted
    {
        destroy(object);
    }
}

/++
    Resource loader. Loads resources, fonts and more 
    and keeps it in memory.
+/
class Loader
{
    import std.path;
    import tida.graph.text;

    private
    {
        Resource[] resources;
        Font[] fonts;
    }

    /++
        Will load the resource, having only its path as 
        input. The entire loading implementation lies with 
        the resource itself. The manager will simply keep 
        this resource in memory.

        Params:
            T = Data type.
            path = Path to the file.
            name = Name.

        Retunrs:
            T

        Throws: `LoadException` if the loader determines 
            that the file does not exist. There may be other 
            errors while loading, see their documentation, 
            for example `Image`.

        Example:
        ---
        Image img = loader.load!Image("a.png");
        ---
    +/
    T load(T)(immutable string path,string name = "null") @safe
    {
        if(this.get!T(path) !is null)
            return this.get!T(path);

        T obj = new T();
        Resource res;

        synchronized 
        {
            if(!path.exists)
                throw new Exception("Not find file!");

            if(name == "null")
                name = path.baseName.stripExtension;

            obj.load(path);

            res.path = path;
            res.name = name;
            res.init!T(obj);

            this.resources ~= (res);
        }

        return obj;
    }

    /++
        Loads multiple resources in one fell swoop using an associated array.

        Params:
            T = Data type.
            paths = Paths and names for loading resources.

        Throws: `LoadException` if the loader determines 
            that the file does not exist. There may be other 
            errors while loading, see their documentation, 
            for example `Image`.

        Example:
        ---
        loader.load!Image([
            "op1" : "image.png",
            "op2" : "image2.png"
        ]);
        ---
    +/
    T load(T)(immutable string[string] paths) @safe
    {
        foreach(key; paths.keys) {
            this.load!T(paths[key],key);
        }
    }

    private size_t pos(T)(T res) @safe {
        foreach(size_t i; 0 .. resources.length) {
            if(resources[i].object is res) {
                return i;
            }
        }

        throw new Exception("Unknown resource");
    }

    /++
        Frees the resource from memory by calling the `free` 
        construct on the resource if it has unreleased pointers 
        and so on, and later removes the resource from the array, 
        letting the garbage collector destroy this object.

        Params:
            T = Resource class
            path = Name or Path to file resource

        Example:
        ---
        loader.free!Image("myImage");
        ---
    +/
    void free(T)(immutable string path) @trusted
    {
        auto obj = get!T(path);

        if(obj is null)
            return;

        resources.remove(pos(obj));
        synchronized destroy(obj);
    }

    /++
        Frees the resource from memory by calling the `free` 
        construct on the resource if it has unreleased pointers 
        and so on, and later removes the resource from the array, 
        letting the garbage collector destroy this object.

        Params:
            T = Resource class
            obj = Resource object

        Example:
        ---
        auto myImage = loader.load!Image(...);
        loader.free(myImage);
        ---
    +/
    void free(T)(T obj) @trusted
    {
        if(obj is null)
            return;

        resources.remove(pos!T(obj));
        synchronized destroy(obj);
    }

    /++
        Returns a resource by name or path.

        Params:
            name = name resource(or path)

        Returns:
            `null` if the resource is not found. 
            If found, will return a `T` of the 
            appropriate size.
    +/
    T get(T)(immutable string name) @safe
    {
        foreach(e; this.resources)
        {
            if(e.getPath() == name)
                return e.get!T;

            if(e.getName() == name)
                return e.get!T;
        }

        return null;
    }

    /++
        Will return the font by path / name and size.
        The size is required.

        Params:
            path = Path to file or name.
            size = Font size.

        Returns:
            `null` if the resource is not found. 
            If found, will return a `Font` of the 
            appropriate size.
    +/
    Font getFont(immutable string path,immutable int size) @safe
    {
        foreach(ref e; fonts)
        {
            if(e.path == path)
            {
                if(e.size == size)
                {
                    return e;
                }
            }

            if(e.name == path)
            {
                if(e.size == size)
                {
                    return e;
                }
            }
        }

        return null;
    }

    /++
        Load a font of a specific size.

        Params:
            path = Path to file font
            size = The size of the font by which you can then find the 
            font. It will load a font of a certain size.
            name = The short name by which the font can be found.

        Throws: `LoadException` if the file is not found. `Exception` 
        if something goes wrong while loading the font.

        Returns:
            `Font`
    +/
    Font loadFont(immutable string path,immutable int size,string name = "null") @safe
    {
        if(getFont(path,size) !is null)
            return getFont(path,size);

        Font font = new Font();
        synchronized {
            font.load(path,size);

            if(name != "null")
                font.name = name;

            fonts ~= (font);
        }

        return font;
    }


    /++
        Will add a resource that was not loaded through the manager. 
        Please note that it must have a path and a name.

        Params:
            res = Resource.
    +/
    void add(Resource res) @safe
    {
        this.resources ~= (res);
    }

    ~this() @safe
    {
        foreach(res; resources)
        {
            res.free();
        }
    }
}
