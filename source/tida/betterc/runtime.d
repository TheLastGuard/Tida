/++

+/
module tida.betterc.runtime;

__gshared TidaRuntime* __runtime;

public TidaRuntime* runtime() @trusted
{
	return __runtime;
}

struct TidaRuntime
{
	static void initialize() @trusted
	{
		import core.stdc.stdlib : malloc;

		__runtime = cast(TidaRuntime*) malloc(__runtime.sizeof);
	}
} 