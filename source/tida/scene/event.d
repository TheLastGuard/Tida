/++
    A module for describing events that need to be processed not only in a separate function.
    Example:
    ---
    class Test : Scene
    {
        @Event!Step
        void MyStep() @safe
        {
            ...
        }

        @Event!Draw
        void MyDraw(IRenderer render) @safe
        {
            ...
        }
    }

    class Bar : Instance
    {
        @Event!Init
        void Initialize() @safe
        {
            ...
        }

        @CollisionEvent("NameObject", "Tag")
        void onCollision(Instance other) @safe
        {

        }
    }
    ---

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.scene.event;

/// Example: Event!Step
alias Event = FunEvent;

enum : int
{
    Init, /++   Object initialization event. When the scene is first initialized, 
                this function is called, and subsequent initializations fire the Restart event. +/
    Restart, /++    Reinitialization event. When the scene was previously initialized and control 
                    was re-assigned to it, this function is called. +/
    Entry, /++  Take control function. Whenever the scene gains control, this function is called. +/
    TriggerAll, /++ Reaction event for all triggers. +/
    GameStart, /++ An event called when the game starts. +/
    GameExit, /++ An event called when the game end +/
    GameRestart, /++ An event called when game restart +/
    Leave, /++ The event that is called when the scene transfers control. +/
    EventHandle, /++ An event for handling external events. +/
    Step, /++ An event called every tick of the program's life cycle. +/
    Draw, /++ An event called every tick in the life cycle of the drawing program. +/
    OnError, /++    Exception event. After - the program turns off. This event is solely for saving 
                    critical data before going into a failure. +/
    Collision, /++ An event when an object touched another. +/
    Destroy /++ The event when an object is destroyed in the scene. +/
}

/// Example: FunEvent!Step
struct FunEvent(int Type)
{

}

/// Example: CollisionEvent("NameObject","TagObject")
struct CollisionEvent
{
    string name;
    string tag = "";
}

/// Example: CollisionTagEvent("TagObject") or CollisionEvent("", "TagObject").
template CollisionTagEvent(string tag)
{
    enum CollisionTagEvent = CollisionEvent("", tag);
}

// Example: TriggerEvent("MyTriggeredTrigger")
struct TriggerEvent
{
    string name;
}
