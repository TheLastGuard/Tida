/++


Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.softimage;

import tida.render;

/++
Object to draw objects on the image.
+/
class SoftImage : ICanvas
{
    import tida.image, tida.color, tida.shape, tida.vector, tida.window;

private:
    Image image;
    ubyte[] buffer;

    uint _width;
    uint _height;

    uint _pwidth;
    uint _pheight;

    int xput;
    int yput;

    BlendMode bmode;
    BlendFactor[2] sdfactor;

public @safe:
    this(Image img)
    {
        image = img;

        allocatePlace(img.width,img.height);
        viewport(img.width,img.height);

        bmode = BlendMode.withBlend;
        sdfactor = [BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha];
    }

    /++
    Returns the rendered surface.
    +/
    Image done()
    {
        return image;
    }

override:
    void allocatePlace(uint width, uint height)
    {
        buffer = new ubyte[](width * height * 4);

        _width = width;
        _height = height;
    }

    void clearPlane(Color!ubyte color)
    {
        for(size_t i = 0; i < _width * _height * 4; i += 4)
        {
            buffer[i] = color.r;
            buffer[i+1] = color.g;
            buffer[i+2] = color.b;
            buffer[i+3] = color.a;
        }
    }

    void drawTo()
    {
        image.bytes!(PixelFormat.RGBA)(buffer);
    }

    void blendMode(BlendMode mode) @safe @property
    {
        bmode = mode;
    }
    
    @property BlendMode blendMode()
    {
        return bmode;
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor)
    {
        sdfactor = [sfactor, dfactor];
    }

    BlendFactor[2] blendOperation()
    {
        return sdfactor;
    }

    @property ref ubyte[] data()
    {
        return buffer;
    }

    mixin PointToImpl!(PixelFormat.RGBA, 4);

    void viewport(uint w, uint h) @safe
    {
        _pwidth = w;
        _pheight = h;
        allocatePlace(_width,_height);
    }

    void move(int x,int y)
    {
        xput = x;
        yput = y;
    }
    
    @property uint[2] size()
    {
        return [_width, _height];
    }
    
    @property uint[2] portSize()
    {
        return [_pwidth, _pheight];
    }
    
    @property int[2] cameraPosition()
    {
        return [xput, yput];
    }
}
