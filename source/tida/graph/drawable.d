/++
    A module for describing the rendering of elements.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.drawable;

/++
    The interface for normal rendering by coordinates. 
    All properties are specified in the constructor at best.

    Example:
    ---
    class Rectangle : IDrawable
    {
        public
        {
            uint width, height;
            Color!ubyte color;
        }

        this(uint width,uint height,Color!ubyte color);

        override void draw(Renderer renderer,Vecf position) @safe
        {
            renderer.rectangle(position,width,height,color,true);
        }
    }
    ---
+/
public interface IDrawable
{
    import tida.window;
    import tida.vector;
    import tida.graph.render;

    ///
    public void draw(IRenderer renderer,Vecf position) @trusted;
}

/++
    Interface for advanced object rendering. 
    It contains both the rotation of the object and such a property as size.
+/
public interface IDrawableEx
{
    import tida.window;
    import tida.vector;
    import tida.graph.render;

    ///
    public void drawEx(IRenderer renderer,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha) @trusted;
}

/++
    Interface for rendering an object with a given color.
+/
public interface IDrawableColor
{
    import tida.window;
    import tida.vector;
    import tida.color;
    import tida.graph.render;

    ///
    public void drawColor(IRenderer renderer,Vecf position,Color!ubyte color) @trusted;
}