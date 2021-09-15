/++
Component module. Components extend the functionality of instances, but
independently of a specific one (at least so. Or only one group of instances).

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.component;

/++
Checks if an object is a component for an instance.
+/
template isComponent(T)
{
    enum isComponent = is(T : Component);
}

/++
A component object that extends some functionality to an entire
or group of instances.
+/
class Component
{
public:
    string name; /// Component
    string[] tags; /// Component tags.
}
