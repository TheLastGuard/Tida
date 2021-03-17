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
    Init, ///
    Restart, ///
    Entry, ///
    GameStart, ///
    GameExit, ///
    GameRestart, ///
    Leave, ///
    EventHandle, ///
    Step, ///
    Draw, ///
    OnError, ///
    Collision ///
}

/// Example: FunEvent!Step
struct FunEvent(int Type)
{

}

struct CollisionEvent
{
    string name;
    string tag = "";
}

struct TriggerEvent
{
    string name;
}
