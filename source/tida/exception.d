/++
	A module for describing exceptions with the operation of some components.

	Authors: TodNaz
	License: MIT
+/
module tida.exception;

/// Errors when working with the context.
public enum ContextError
{
	fbsNull, ///
	noContext, ///
	visualNull, ///
	noDirect ///
}

/++
	Template for exceptions listing errors.

	Params:
		T = Type error.
+/
public class ExceptionError(T) : Exception
{
	public
	{
		T error; /// Error
	}

	this(T error,string message)
	{
		this.error = error;
		super(message);
	}
}

/// Template for exceptions listing errors.
public class ContextException : ExceptionError!ContextError
{
	this(ContextError error,string message) @safe
	{
		super(error,message);
	}
}


/// Template for exceptions listing errors.
public enum WindowError
{
	noCreate ///
}

/// Exception when working with a window.
public class WindowException : ExceptionError!WindowError
{
	this(WindowError error,string message) @safe
	{
		super(error,message);
	}
}

/// Enumeration of errors when working with fonts.
public enum FontError : int
{
	cannotOpen = 0x001,
	unknownFormat = 0x002,
	invalidFormat = 0x003
}

/// Exceptioon whem working with a font.
public class FontException : ExceptionError!int
{
	this(int error,string message) @safe
	{
		super(error,message);
	}
}

///
enum ShaderError
{
	unknown,
	vertexCompile,
	fragmentCompile
}

///
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

/// Exception when the file is not found.
public class LoadException : Exception
{
    public
    {
        string file;
    }

    /++
		Exception when the file is not found.

		Params:
			file = Path to the file.
    +/
    this(string file) @safe
    {
        this.file = file;
        
        super("Not find `"~file~"`!");
    }
}

/// Enumerations when working with OpenAL.
enum OpenALError
{
	noLibrary, ///
	noDevice, ///
	noMakeContext, ///
	errorMakeContext ///
}

/// Exceptioon whem working with a OpenAL.
public class OpenALException : ExceptionError!OpenALError
{
	this(OpenALError error,string message)
	{
		super(error,message);
	}
}

///
enum SoftwareError
{
	noGC,
	flushError
}

///
public class  SoftwareException : ExceptionError!SoftwareError
{
	this(SoftwareError error,string message)
	{
		super(error,message);
	}
}