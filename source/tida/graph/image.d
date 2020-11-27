/++
    

    Authors: TodNaz
    License: MIT
+/
module tida.graph.image;

import tida.graph.drawable;

public class Image : IDrawable, IDrawableEx
{
    import tida.color;
    import tida.vector;
    import tida.graph.gl;
    import tida.graph.render;
    import imageformats;

    private
    {
        Color!ubyte[] _pixels;
        uint _width;
        uint _height;
        uint _glID;
    }

    this() @safe
    {
        _pixels = null;
    }

    this(uint newWidth,uint newHeight) @safe
    {
        create(width,height);
    }

    this(string path) @safe
    {
        load(path);
    }

    public ubyte[] bytes(PixelFormat format = PixelFormat.RGBA) @safe
    {
        ubyte[] tryPixels;

        foreach(pixel; _pixels)
            tryPixels ~= pixel.fromBytes(format);

        return tryPixels;
    }

    public uint[] colors(PixelFormat format = PixelFormat.RGBA) @safe
    {
        uint[] tryPixels;

        foreach(pixel; _pixels)
            tryPixels ~= pixel.conv!uint(format);

        return tryPixels;
    }

    public override string toString() @safe
    {
        import std.conv : to;

        return "Image(width: "~width.to!string~",height: "~height.to!string~")";
    }

    public Color!ubyte[] pixels() @safe @property
    {
        return _pixels;
    }

    public void pixels(Color!ubyte[] otherPixels) @trusted @property
    {
        _pixels = otherPixels;
    }

    public void setPixel(size_t x,size_t y,Color!ubyte color) @trusted
    {
        if(x >= width || y >= height)
            return;

        _pixels [
                    (width * y) + x
                ] = color;  
    }

    public Color!ubyte getPixel(size_t x,size_t y) @trusted
    {
        return _pixels[(width * y) + x];
    }

    public void blit(Image otherImage,Vecf pos) @trusted
    {
        for(size_t x = pos.intX; x <= pos.intX + otherImage.width; x++)
        {
            for(size_t y = pos.intY; y <= pos.intY + otherImage.height; y++)
            {
                setPixel(x,y,otherImage.getPixel(x - pos.intX,y - pos.intY));
            }
        }
    }

    public ubyte[] bytes(PixelFormat format)() @safe
    {
        ubyte[] tryPixels;

        foreach(pixel; _pixels)
            tryPixels ~= pixel.fromBytes!format;

        return tryPixels;
    }

    public void create(uint newWidth,uint newHeight) @safe
    {
        _pixels = new Color!ubyte[](width * height);

        foreach(ref e; _pixels) {
            e = rgba(0,0,0,0);
        }

        _width = newWidth;
        _height = newHeight;
    }

    public void load(string path) @trusted
    {
        import std.file : exists;

        if(!exists(path))
            throw new Exception("Not find file `"~path~"`!");

        IFImage temp = read_image(path, ColFmt.RGBA);

        _width = temp.w;
        _height = temp.h;

        for(size_t i = 0; i < temp.pixels.length; i+=4) {
            _pixels ~= rgba(temp.pixels[i],
                            temp.pixels[i+1],
                            temp.pixels[i+2],
                            temp.pixels[i+3]);
        }
    }

    public void fromTexture() @safe
    {
        GL.genTextures(1,_glID);

        GL.bindTexture(_glID);

        GL.texParameteri(GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        GL.texParameteri(GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        ubyte[] tryPixels;

        foreach(pixel; _pixels)
            tryPixels ~= pixel.fromBytes(PixelFormat.RGBA);

        GL.texImage2D(_width,_height,tryPixels);

        GL.bindTexture(0);
    }

    public immutable(uint) width() @safe @property
    {
        return _width;
    }

    public immutable(uint) height() @safe @property
    {
        return _height;
    }

    public Image dup() @safe @property
    {
        Image image = new Image();

        image.create(_width,_height);

        image.pixels = pixels.dup;

        return image;
    }

    override void draw(Renderer render,Vecf position) @trusted
    {
        GL.color = rgb(255,255,255);

        GL.bindTexture(_glID);
        GL.enable(GL_TEXTURE_2D);

        GL.draw!Rectangle({
            GL.texCoord2i(0,0); GL.vertex(position);
            GL.texCoord2i(0,1); GL.vertex(position + Vecf(0,height));
            GL.texCoord2i(1,1); GL.vertex(position + Vecf(width,height));
            GL.texCoord2i(1,0); GL.vertex(position + Vecf(width,0));
        });

        GL.disable(GL_TEXTURE_2D);
        GL.bindTexture(0);
    }

    override void drawEx(Renderer renderer,Vecf position,float angle,Vecf center,Vecf size)
    {
        GL.color = rgb(255,255,255);

        GL.bindTexture(_glID);
        GL.enable(GL_TEXTURE_2D);

        GL.loadIdentity();
        GL.translate(position.x + center.x,position.y + center.y,0);
        GL.rotate(angle,0f,0f,1f);
        GL.translate(-(position.x + center.x),-(position.y + center.y),0);

        //position += position + center;

        GL.draw!Rectangle({
            GL.texCoord2i(0,0); GL.vertex(position);
            GL.texCoord2i(0,1); GL.vertex(position + Vecf(0,size.y));
            GL.texCoord2i(1,1); GL.vertex(position + size);
            GL.texCoord2i(1,0); GL.vertex(position + Vecf(size.x,0));
        });

        GL.disable(GL_TEXTURE_2D);
        GL.bindTexture(0);

        GL.loadIdentity();
    }

    public void freeTexture() @trusted
    {
        if(_glID != 0) {
            glDeleteTextures(1,&_glID);
            _glID = 0;
        }
    }

    ~this() @safe
    {
        freeTexture();
    }
}