/++

+/
module tida.exception;

public enum ContextError
{
	fbsNull,
	noContext,
	visualNull,
	noDirect
}

public class ExceptionError(T) : Exception
{
	public
	{
		T error;
	}

	this(T error,string message)
	{
		this.error = error;
		super(message);
	}
}

public class ContextException : ExceptionError!ContextError
{
	this(ContextError error,string message) @safe
	{
		super(error,message);
	}
}

public enum WindowError
{
	noCreate
}

public class WindowException : ExceptionError!WindowError
{
	this(WindowError error,string message) @safe
	{
		super(error,message);
	}
}

public enum FontError : int
{
	cannotOpen = 0x001,
	unknownFormat = 0x002,
	invalidFormat = 0x003
}

public class FontException : ExceptionError!int
{
	this(int error,string message) @safe
	{
		super(error,message);
	}
}

enum ShaderError
{
	unknown,
	vertexCompile,
	fragmentCompile
}

public class ShaderException : ExceptionError!ShaderError
{
	this(ShaderError error,string message) @trusted
	{
		string tstr;
		
		if(error == ShaderError.vertexCompile) tstr = "[Vertex]: ";
		if(error == ShaderError.fragmentCompile) tstr = "[Fragment]: ";
		
		super(error,tstr ~ message);
	}
}

public class LoadException : Exception
{
    public
    {
        string file;
    }

    this(string file) @safe
    {
        this.file = file;
        
        super("Not find `"~file~"`!");
    }
}