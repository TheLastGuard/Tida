/++
    Module for drawing in a window using opengl.

    Authors: TodNaz
    License: MIT
+/
module tida.graph.render;

import tida.window;

/++
    What type of rendering.
+/
enum BlendMode {
    noBlend, // Without alpha channel
    Blend /// With an alpha channel.
};

/++
    Object to draw in a specific window.
+/
public class Renderer
{
    import tida.color;
    import tida.vector;
    import tida.graph.gl;
    import tida.graph.drawable;
    import tida.graph.text;

    private
    {
        Window toRender;
        Color!ubyte _background;
        Vecf size;
    }

    /++
        Render initialization.

        Params:
            window = Window render. 
    +/
    this(Window window) @safe
    {
        GL.initialize();

        toRender = window;

        size = Vecf(window.width,window.height);

        GL.viewport(0,0,window.width,window.height);

        GL.matrixMode(GL_PROJECTION);
        GL.loadIdentity();

        GL.ortho(0.0, size.x, size.y, 0.0, 1.0, -1.0);

        GL.matrixMode(GL_MODELVIEW);
        GL.loadIdentity();

        blend = BlendMode.Blend;
    }

    ///
    public void reshape() @safe
    {
        size = Vecf(toRender.width,toRender.height);

        GL.viewport(0,0,toRender.width,toRender.height);

        GL.matrixMode(GL_PROJECTION);
        GL.loadIdentity();

        GL.ortho(0.0, size.x, size.y, 0.0, 1.0, -1.0);

        GL.matrixMode(GL_MODELVIEW);
        GL.loadIdentity();

        drawning();
    }

    /++
        Object rendering mode.

        Params:
            blend = Rendering mode. 
    +/
    public void blend(BlendMode blend) @trusted
    {
        if(blend == BlendMode.Blend) {
            GL.enable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }else if(blend == BlendMode.noBlend) {
            GL.disable(GL_BLEND);
        }
    }

    /++
        The background.
    +/
    public void background(Color!ubyte color) @safe @property
    {
        _background = color;
        GL.clearColor = color;
    }

    /// ditto
    public Color!ubyte background() @safe @property
    {
        return _background;
    }

    /++
        Clears what is drawn.
    +/
    public void clear() @safe
    {
        GL.clear();
    }

    /++
        Draws only a regular triangle.

        Params:
            points = Tringle vertex.
            color = Triangle color.
            isFill = Triangle is filled.
    +/
    public void triangle(Vecf[3] points,Color!ubyte color,bool isFill = true) @safe
    {
        GL.color = color;

        if(isFill) {
            GL.draw!Polygons({
                GL.vertex(points[0]);
                GL.vertex(points[1]);
                GL.vertex(points[2]);
            });
        }else {
            GL.draw!Lines({
                GL.vertex(points[0]);
                GL.vertex(points[1]);

                GL.vertex(points[1]);
                GL.vertex(points[2]);

                GL.vertex(points[2]);
                GL.vertex(points[0]);
            });
        }
    }

    /++
        Draws a rectangle.

        Params:
            position = Rectangle position.
            width = Rectangle width.
            height = Rectangle height.
            color = Rectangle color.
            isFill = Rectangle is filled.
    +/
    public void rectangle(Vecf position,float width,float height,Color!ubyte color,bool isFill = true) @safe
    {
        GL.color = color;

        if(isFill) {
            GL.draw!Rectangle({
                GL.vertex(position);
                GL.vertex(position + Vecf(width,0));
                GL.vertex(position + Vecf(width,height));
                GL.vertex(position + Vecf(0,height));
            });
        }else {
            GL.draw!Lines({
                GL.vertex(position);
                GL.vertex(position + Vecf(width,0));

                GL.vertex(position + Vecf(width,0));
                GL.vertex(position + Vecf(width,height));

                GL.vertex(position + Vecf(width,height));
                GL.vertex(position + Vecf(0,height));

                GL.vertex(position + Vecf(0,height));
                GL.vertex(position);
            });
        }
    }

    /++
        Draws a line.

        Params:
            points = Line vertex.
            color = Line color.
    +/
    public void line(Vecf[2] points,Color!ubyte color) @safe
    {
        GL.color = color;

        GL.draw!Lines({
            GL.vertex(points[0]);
            GL.vertex(points[1]);
        });
    }

    /++
        Draws a circle.

        Params:
            position = Circle position.
            radious = Circle radious.
            color = Circle color.
            isFill = Circle is filled.
    +/
    public void circle(Vecf position,float radious,Color!ubyte color,bool isFill) @safe
    {
        GL.color = color;

        if (isFill)
        {
            int x = 0;
            int y = cast(int) radious;

            int X1 = position.intX();
            int Y1 = position.intY();

            int delta = 1 - 2 * cast(int) radious;
            int error = 0;

            GL.draw!Lines({
                while (y >= 0)
                {
                    GL.vertex(Vecf(X1 + x, Y1 + y));
                    GL.vertex(Vecf(X1 + x, Y1 - y));

                    GL.vertex(Vecf(X1 - x, Y1 + y));
                    GL.vertex(Vecf(X1 - x, Y1 - y));

                    error = 2 * (delta + y) - 1;
                    if ((delta < 0) && (error <= 0))
                    {
                        delta += 2 * ++x + 1;
                        continue;
                    }
                    if ((delta > 0) && (error > 0))
                    {
                        delta -= 2 * --y + 1;
                        continue;
                    }
                    delta += 2 * (++x - --y);
                }
            });
        }
        else
        {
            int x = 0;
            int y = cast(int) radious;

            int X1 = position.intX();
            int Y1 = position.intY();

            int delta = 1 - 2 * cast(int) radious;
            int error = 0;

            GL.draw!Points({
                while (y >= 0)
                {
                    GL.vertex(Vecf(X1 + x, Y1 + y));
                    GL.vertex(Vecf(X1 + x, Y1 - y));
                    GL.vertex(Vecf(X1 - x, Y1 + y));
                    GL.vertex(Vecf(X1 - x, Y1 - y));


                    error = 2 * (delta + y) - 1;
                    if ((delta < 0) && (error <= 0))
                    {
                        delta += 2 * ++x + 1;
                        continue;
                    }
                    if ((delta > 0) && (error > 0))
                    {
                        delta -= 2 * --y + 1;
                        continue;
                    }
                    delta += 2 * (++x - --y);
                }
            });
        }
    }

    /++
        Draws characters rendered by the text class.

        Params:
            symbols = Symbols rendered.
            position = Text position.
    +/
    public void draw(Symbol[] symbols,Vecf position) @safe
    {
        foreach(s; symbols) 
        {
            if(!s.image.isTexture)
                s.image.fromTexture();

            drawColor(s.image,position - Vecf(0,s.position.y),s.color);
            position.x += s.image.width + s.position.x;
        }
    }

    ///
    public void draw(IDrawable drawable,Vecf position) @safe
    {
        drawable.draw(this,position);
    }

    ///
    public void drawEx(IDrawableEx drawable,Vecf position,float angle,Vecf center,Vecf size) @safe
    {
        drawable.drawEx(this,position,angle,center,size);
    }

    ///
    public void drawColor(IDrawableColor drawable,Vecf position,Color!ubyte color) @safe
    {
        drawable.drawColor(this,position,color);
    }

    /++
        Display the drawing canvas.
    +/
    public void drawning() @safe
    {
        toRender.swapBuffers();
    }

    ///
    public void drawning(void delegate() @safe func) @safe
    {
        this.clear();

        func();

        this.drawning();
    }
}