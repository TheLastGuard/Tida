/++

+/
module tida.exception;

public enum ContextError
{
	fbsNull,
	noContext
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