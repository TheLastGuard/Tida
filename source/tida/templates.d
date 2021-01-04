/++
	A set of templates you need when you need them.

	Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.templates;

mixin template Global(T,string name)
{
	mixin("__gshared "~T.stringof~" _"~name~";");
	mixin("public "~T.stringof~" "~name~"() @trusted { return _"~name~"; }");
}