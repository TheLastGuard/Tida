/++
    A module for drawing some objects on the image, if, for example, you need to create a texture at runtime. 
    All rendering processes go only through the processor.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.softimage;

import tida.graph.render;

/++
    Object to draw objects on the image.
+/
class SoftImage : IPlane
{
    import tida.graph.image, tida.color, tida.shape, tida.vector, tida.window;

    private
    {
        Image image;
        ubyte[] buffer;

        uint _width;
        uint _height;

        uint _pwidth;
        uint _pheight;

        int xput;
        int yput;

        BlendMode bmode;
    }

    this(Image img) @safe
    {
        image = img;

        alloc(img.width,img.height);
        viewport(img.width,img.height);    

        bmode = BlendMode.Blend;
    }

    override void alloc(uint width,uint height) @safe
    {
        if(image.pixels.length == 0)
            buffer = new ubyte[](width * height * 4);
        else
            buffer = image.bytes!(PixelFormat.RGBA);

        _width = width;
        _height = height;
    }

    override void clearPlane(Color!ubyte color) @safe
    {
        for(size_t i = 0; i < _width * _height * 4; i += 4)
        {
            buffer[i] = color.r;
            buffer[i+1] = color.g;
            buffer[i+2] = color.b;
            buffer[i+3] = color.a;
        }
    }

    override void putToWindow(IWindow window) @safe
    {
        image.bytes!(PixelFormat.RGBA)(buffer);
    }

    override void blendMode(BlendMode mode) @safe @property
    {
        bmode = mode;
    }

    override ubyte[] data() @safe @property
    {
        return buffer;
    }

    override void pointTo(Vecf position,Color!ubyte color) @safe @property 
    {
        import std.conv : to;

        position = position - Vecf(xput,yput);

        if(position.x.to!int >= _width || position.y.to!int >= _height || 
           position.x.to!int < 0 || position.y.to!int < 0)
            return;

        if(_pwidth == _width && _pheight == _height)
        {
            auto pos = ((_width * position.y.to!int) + position.x.to!int) * 4;

            if(bmode == BlendMode.Blend) 
                color.colorize!Alpha(rgba(buffer[pos],buffer[pos+1],buffer[pos+2],255));

            buffer[pos] = color.r;
            buffer[pos+1] = color.g;
            buffer[pos+2] = color.b;
        }else
        {
            import tida.graph.each;

            auto scaleWidth = cast(double) _pwidth / cast(double) _width;
            auto scaleHeight = cast(double) _pheight / cast(double) _height;

            int w = cast(int) _width / _pwidth + 1;
            int h = cast(int) _height / _pheight + 1;

            position = Vecf(position.x / scaleWidth, position.y / scaleHeight);

            Color!ubyte original = color;

            foreach(ix, iy; Coord(position.x.to!int + w,position.y.to!int + h,
                                  position.x.to!int,position.y.to!int))
            {
                auto pos = (iy * _width) + ix;
                pos *= 4;

                color = original;
                if(bmode == BlendMode.Blend)
                    color.colorize!Alpha(rgba(buffer[pos],buffer[pos+1],buffer[pos+2],255));

                if(pos < buffer.length)
                {
                    buffer[pos] = color.r;
                    buffer[pos+1] = color.g;
                    buffer[pos+2] = color.b;
                }
            }
        }
    }

    override void viewport(int w,int h) @safe
    {
        _pwidth = w;
        _pheight = h;
        alloc(_width,_height);
    }

    override void move(int x,int y) @safe
    {
        xput = x;
        yput = y;
    }

    /++
        Returns the rendered surface.
    +/
    Image done() @safe
    {
        return image;
    }
}

import tida.graph.image;

/++
    Returns the rendered surface.

    Params:
        soft = Renderer.
+/
Image doneImage(Software soft) @safe
{
    auto plane = cast(SoftImage) soft.getPlane();
    return plane.done();
}