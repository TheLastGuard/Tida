/++
    A module for describing an image. This module provides control 
    of the image both with a surface and with a texture.

    Authors: TodNaz
    License: MIT
+/
module tida.graph.image;

import tida.graph.drawable;

static immutable Red = 0; /// Red component
static immutable Green = 1; /// Green component
static immutable Blue = 2; /// Blue component

/// Image.
public class Image : IDrawable, IDrawableEx, IDrawableColor
{
    import tida.color;
    import tida.vector;
    import tida.graph.gl;
    import tida.graph.render;
    import imageformats;
    import std.algorithm;

    private
    {
        Color!ubyte[] _pixels;
        uint _width;
        uint _height;
        uint _glID;
    }

    /// Empty initilization.
    this() @safe
    {
        _pixels = null;
    }

    /++
        Creates a surface with the specified size. Note that it is 
        not yet a texture, and you don’t need to draw it right away, 
        to do this, convert it to a texture.

        Params:
            newWidth = Image width.
            newHeight = Image height.
    +/
    this(uint newWidth,uint newHeight) @safe
    {
        _pixels = new Color!ubyte[](newWidth * newHeight);

       	_pixels.fill(rgb(0,0,0));

        _width = newWidth;
        _height = newHeight;
    }

    /++
        Loads a surface from a file. Supported formats are described here:
        `https://code.dlang.org/packages/imageformats`

        Params:
            path = Relative or full path to the image file.
    +/
    this(string path) @safe
    {
        this.load(path);
    }

    /++
        Gives a sequence of bytes that encodes a color in 
        the specified color format.

        Params:
            format = Pixel format.
    +/
    public T[] bytes(T)(PixelFormat format = PixelFormat.RGBA) @safe
    {
        T[] tryPixels;

        foreach(pixel; _pixels)
            tryPixels ~= pixel.fromBytes!T(format);

        return tryPixels;
    }

    /++
        Returns a sequence of pixels in the format `0xRRGGBBAA` (Depending on the format).

        Params:
            format = Pixel format.
    +/
    public T[] colors(T)(PixelFormat format = PixelFormat.RGBA) @safe
    {
        T[] tryPixels;

        foreach(pixel; _pixels)
            tryPixels ~= pixel.conv!T(format);

        return tryPixels;
    }

    override string toString() @safe const
    {
        import std.conv : to;

        return "Image(width: "~width.to!string~",height: "~height.to!string~")";
    }

    /++
        A sequence of pixels.
    +/
    public Color!ubyte[] pixels() @safe @property
    {
        return _pixels;
    }

    /++
        A sequence of pixels.
    +/
    public void pixels(Color!ubyte[] otherPixels) @safe @property
    {
        _pixels = otherPixels;
    }

	/++
		Fills the entire picture with color.
		
		Params:
			color = Color fill.
	+/
	public void fill(Color!ubyte color) @safe
	{
		_pixels.fill(color);
	}

    /++
        Converting pixels from an array to a color structure.
        
        Params:
        	bt = Pixel byte array.
        	format = Pixel format.
        	
        Example:
        ---
        import std.algorithm : fill;
        
        auto bt = new ubyte()[32 * 32 * 4]; // Create virtual image 32x32
        bt.fill(255); // Fill image white color
        
        image.bytes!ubyte(bt,PixelFormat.RGBA);
        ---
    +/
    public void bytes(T)(T[] bt,PixelFormat format = PixelFormat.RGBA) @safe
    in
    {
        if(format == PixelFormat.RGB)
            assert(bt.length <= _width * _height * 3,
            "The size of the picture is much larger than this one!");
        else
            assert(bt.length <= _width * _height * 4,
            "The size of the picture is much larger than this one!");
    }
    do
    {
        size_t k = format == PixelFormat.RGB ? 3 : 4;
        for(size_t i = 0; i < bt.length; i += k) {
        	_pixels[i / k] = Color!ubyte(bt[i .. i+k],format);
        }
    }

    /++
        Set the pixel at the specified location.

        Params:
            x = The x-axis position pixel.
            y = The y-axis position pixel.
            color = Pixel.
    +/
    public void setPixel(size_t x,size_t y,Color!ubyte color) @safe
    {
        if(x >= width || y >= height)
            return;

        _pixels [
                    (width * y) + x
                ] = color;  
    }

    /++
        Returns the pixel at the specified location.

        Params:
            x = The x-axis position pixel.
            y = The y-axis position pixel.
    +/
    public Color!ubyte getPixel(size_t x,size_t y) @safe
    {
        return _pixels[(width * y) + x];
    }

    /++
        Attaches an image to itself at the specified position.
    +/
    public void blit(Image otherImage,Vecf pos) @safe
    {
        for(size_t x = pos.intX; x < pos.intX + otherImage.width; x++)
        {
            for(size_t y = pos.intY; y < pos.intY + otherImage.height; y++)
            {
                setPixel(x,y,otherImage.getPixel(x - pos.intX,y - pos.intY));
            }
        }
    }

	/++
		Redraws the part to a new picture.
		
		Params:
			x = The x-axis position.
			y = The y-axis position.
			cWidth = Width new picture.
			cHeight = Hight new picture.
	+/
    public Image copy(int x,int y,int cWidth,int cHeight) @safe
    {
        Image image = new Image();

        image.create(cWidth,cHeight);

        for(size_t ix = x; ix < x + cWidth; ix++)
        {
            for(size_t iy = y; iy < y + cHeight; iy++)
            {
                image.setPixel(
                    ix - x, iy - y,
                    this.getPixel(ix,iy)
                );
            }
        }

        return image;
    }

    /++
        Creates a surface with the specified size. Note that it is 
        not yet a texture, and you don’t need to draw it right away, 
        to do this, convert it to a texture.

        Params:
            newWidth = Image width.
            newHeight = Image height.
    +/
    public void create(uint newWidth,uint newHeight) @safe
    {
        _pixels = new Color!ubyte[](newWidth * newHeight);

       	_pixels.fill(rgb(0,0,0));

        _width = newWidth;
        _height = newHeight;
    }

    /++
        Loads a surface from a file. Supported formats are described here:
        `https://code.dlang.org/packages/imageformats`

        Params:
            path = Relative or full path to the image file.
    +/
    public void load(string path) @trusted
    {
        import std.file : exists;

        if(!exists(path))
            throw new Exception("Not find file `"~path~"`!");

        IFImage temp = read_image(path, ColFmt.RGBA);

        _width = temp.w;
        _height = temp.h;

        create(_width,_height);

        this.bytes!ubyte(temp.pixels,PixelFormat.RGBA);
    }

    /// Whether the picture is a texture.
    public bool isTexture() @safe
    {
        return _glID != 0;
    }

    /++
        Convert to a texture for rendering to the window.
    +/
    public Image fromTexture() @safe
    {
        GL.genTextures(1,_glID);

        GL.bindTexture(_glID);

        GL.texParameteri(GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        GL.texParameteri(GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        ubyte[] tryPixels;

        foreach(pixel; _pixels)
            tryPixels ~= pixel.fromBytes!ubyte(PixelFormat.RGBA);

        GL.texImage2D(_width,_height,tryPixels);

        GL.bindTexture(0);

        return this;
    }

    /++
        Resizes the image.

        Params:
            newWidth = Image new width.
            newHeight = Image new height.
    +/
    public void resize(uint newWidth,uint newHeight) @safe
    {
        uint oldWidth = _width;
        uint oldHeight = _height;

        _width = newWidth;
        _height = newHeight;

        double scaleWidth = cast(double) newWidth / cast(double) oldWidth;
        double scaleHeight = cast(double) newHeight / cast(double) oldWidth;

        Color!ubyte[] npixels = new Color!ubyte[](newWidth * newHeight);

        foreach(cy; 0 .. newHeight)
        {
            foreach(cx; 0 .. newWidth)
            {
                uint pixel = (cy * (newWidth)) + (cx);
                uint nearestMatch = (cast(uint) (cy / scaleHeight)) * (oldWidth) + (cast(uint) ((cx / scaleWidth)));

                npixels[pixel] = _pixels[nearestMatch];
            }
        }

        _pixels = npixels;
    }

    /++
        Invents the picture by color.
    +/
    public void invert() @safe
    {
        import std.algorithm : each;

        _pixels.each!((ref e) => e.invert());
    }

    /++
        Clears the specified color component from the picture.

        Params:
            Component = Component color.
    +/
    public void clearComponent(ubyte Component)() @safe
    {
        import std.algorithm : each;

        static if(Component == Red) _pixels.each!((ref e) => e.clearRed());
        static if(Component == Green) _pixels.each!((ref e) => e.clearGreen());
        static if(Component == Blue) _pixels.each!((ref e) => e.clearBlue());
    }

    /++
        Adds a component to all colors in the picture.

        Params:
            Component = Component color.
            value = How much to increase.
    +/
    public void addComponent(ubyte Component)(ubyte value) @safe
    {
        import std.algorithm : each;

        static if(Component == Red) {
            _pixels.each!((ref e) {
                if(cast(int) e.r + cast(int) value < 255)
                    e.r += value;
                else
                    e.r = 255;
            });
        }

        static if(Component == Green) { 
            _pixels.each!((ref e) { 
                if(cast(int) e.g + cast(int) value < 255)
                    e.g += value;
                else
                    e.g = 255;
            });
        }

        static if(Component == Blue) {
            _pixels.each!((ref e) { 
                if(cast(int) e.b + cast(int) value < 255)
                    e.b += value;
                else
                    e.b = 255;
            });
        }
    }

    /++
        The width of the picture.
    +/
    public immutable(uint) width() @safe @property
    {
        return _width;
    }

    /// ditto
    public immutable(uint) width() @safe @property const
    {
        return _width;
    }

    /++
        The height of the picture.
    +/
    public immutable(uint) height() @safe @property
    {
        return _height;
    }

    /// ditto
    public immutable(uint) height() @safe @property const
    {
        return _height;
    }

    /++
        Creates a copy of the picture. Doesn't create a copy of the texture.
    +/
    public Image dup() @safe @property
    {
        Image image = new Image();

        image.create(_width,_height);

        image.pixels = pixels.dup;

        return image;
    }

    /// Updates the texture if the picture has changed.
    public void swap() @safe
    {
        if(isTexture) freeTexture();
        fromTexture();
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

    override void drawEx(Renderer renderer,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha)
    {
        GL.color = rgba(255,255,255,alpha);

        GL.bindTexture(_glID);
        GL.enable(GL_TEXTURE_2D);

        GL.loadIdentity();
        GL.translate(position.x + center.x,position.y + center.y,0);
        GL.rotate(angle,0f,0f,1f);
        GL.translate(-(position.x + center.x),-(position.y + center.y),0);

        GL.draw!Rectangle({
            GL.texCoord2i(0,0); GL.vertex(position);
            GL.texCoord2i(0,1); GL.vertex(position + Vecf(0,size.y));
            GL.texCoord2i(1,1); GL.vertex(position + size);
            GL.texCoord2i(1,0); GL.vertex(position + Vecf(size.x,0));
        });

        GL.color = rgba(255,255,255,255);

        GL.disable(GL_TEXTURE_2D);
        GL.bindTexture(0);

        GL.loadIdentity();
    }

    override void drawColor(Renderer renderer,Vecf position,Color!ubyte color)
    {
        GL.color = color;

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

    /++
        Destroys the texture, not the image.
    +/
    public void freeTexture() @trusted
    {
        if(_glID != 0) {
            glDeleteTextures(1,&_glID);
            _glID = 0;
        }
    }

    /++
        Frees up space for pixels. Does not destroy texture.
    +/
    public void freePixels() @trusted
    {
        if(_pixels !is null) {
            destroy(_pixels);
            _pixels = null;
        }
    }

    /++
        Frees memory completely from texture and pixels.
    +/
    public void free() @trusted
    {
        freeTexture();
        freePixels();

        _width = 0;
        _height = 0;
    }

    ~this() @safe
    {
        free();
    }
}