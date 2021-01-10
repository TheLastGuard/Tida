/++
    A module for describing an image. This module provides control 
    of the image both with a surface and with a texture.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.image;

import tida.graph.drawable;

static immutable Red = 0; /// Red component
static immutable Green = 1; /// Green component
static immutable Blue = 2; /// Blue component

/// Image.
class Image : IDrawable, IDrawableEx, IDrawableColor
{
    import tida.color, tida.vector, tida.graph.gl, tida.graph.render, tida.graph.each, tida.graph.texture;
    import imageformats;
    import std.algorithm;
    import std.conv : to;

    private
    {
        Color!ubyte[] _pixels;
        uint _width;
        uint _height;
        Texture _texture;
    }

    /// Empty initialization.
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

    /// A sequence of pixels.
    Color!ubyte[] pixels() @safe @property
    {
        return _pixels;
    }

    /// ditto
    void pixels(Color!ubyte[] otherPixels) @safe @property
    {
        _pixels = otherPixels;
    }

    /++
        Returns a sequence of pixels in the format `0xRRGGBBAA` (Depending on the format).

        Params:
            format = Pixel format.
    +/
    ubyte[] bytes(int format = PixelFormat.RGBA)() @safe
    {
        ubyte[] tryBytes;

        foreach(pixel; _pixels)
            tryBytes ~= pixel.fromBytes!(ubyte,format);

        return tryBytes;
    }

    /++
        Fills the entire picture with color.
        
        Params:
            color = Color fill.
    +/
    void fill(Color!ubyte color) @safe
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
        
        image.bytes!(PixelFormat.RGBA)(bt);
        ---
    +/
    void bytes(int format = PixelFormat.RGBA)(ubyte[] bt) @safe
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
        pixels = bt.fromColors!(format);
    }

    /++
        Set the pixel at the specified location.

        Params:
            x = The x-axis position pixel.
            y = The y-axis position pixel.
            color = Pixel.
    +/
    void setPixel(uint x,uint y,Color!ubyte color) @safe
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
    Color!ubyte getPixel(uint x,uint y) @safe
    {
        return _pixels[(width * y) + x];
    }

    /++
        Attaches an image to itself at the specified position.

        Params:
            otherImage = Other image.
            pos = Other image position.
    +/
    void blit(Image otherImage,Vecf pos) @safe
    {
        foreach(x,y; Coord(pos.intX + otherImage.width,pos.intY + otherImage.height,pos.intX,pos.intY))
        {
            setPixel(x,y,otherImage.getPixel(x - pos.intX,y - pos.intY));
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
    Image copy(int x,int y,int cWidth,int cHeight) @safe
    {
        Image image = new Image();

        image.create(cWidth,cHeight);

        foreach(ix,iy; Coord(x + cWidth,y + cHeight,x,y))
        {
            image.setPixel(
                ix - x, iy - y,
                this.getPixel(ix,iy)
            );
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
    void create(uint newWidth,uint newHeight) @safe
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
    auto load(string path) @trusted
    {
        import std.file : exists;

        if(!exists(path))
            throw new Exception("Not find file `"~path~"`!");

        IFImage temp = read_image(path, ColFmt.RGBA);

        _width = temp.w;
        _height = temp.h;

        create(_width,_height);

        this.bytes!(PixelFormat.RGBA)(temp.pixels);

        return this;
    }

    /// Whether the picture is a texture.
    bool isTexture() @safe
    {
        return texture !is null;
    }

    /++
        Convert to a texture for rendering to the window.
    +/
    auto fromTexture() @safe
    {
        if(GL.isInitialize)
        {
            _texture = new Texture();

            _texture.width = _width;
            _texture.height = _height;

            _texture.initFromBytes!(PixelFormat.RGBA)(bytes!(PixelFormat.RGBA));
        }

        return this;
    }

    Texture texture() @safe @property
    {
        return _texture;
    }

    /++
        Resizes the image.

        Params:
            newWidth = Image new width.
            newHeight = Image new height.
    +/
    void resize(uint newWidth,uint newHeight) @safe
    {
        uint oldWidth = _width;
        uint oldHeight = _height;

        _width = newWidth;
        _height = newHeight;

        double scaleWidth = cast(double) newWidth / cast(double) oldWidth;
        double scaleHeight = cast(double) newHeight / cast(double) oldHeight;

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
        Enlarges the image by a factor.

        Params:
            k = factor.
    +/
    void scale(float k) @safe
    {
        uint newWidth = cast(uint) ((cast(float) _width) * k);
        uint newHeight = cast(uint) ((cast(float) _height) * k);

        resize(newWidth,newHeight);
    }

    /++
        Invents the picture by color.
    +/
    void invert() @safe
    {
        import std.algorithm : each;

        _pixels.each!((ref e) => e.invert());
    }

    /++
        Clears the specified color component from the picture.

        Params:
            Component = Component color.
    +/
    void clearComponent(ubyte Component)() @safe
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
    void addComponent(ubyte Component)(ubyte value) @safe
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

    /// The widht of the picture.
    uint width() @safe @property
    {
        return _width;
    }

    /// The height of the picture.
    uint height() @safe @property
    {
        return _height;
    }

    /// Creates a copy of the picture. Doesn't create a copy of the texture.
    Image dup() @safe @property
    {
        Image image = new Image();

        image.create(_width,_height);

        image.pixels = pixels.dup;

        return image;
    }

    /// Updates the texture if the picture has changed.
    void swap() @safe
    {
        if(isTexture) texture.destroy();

        texture.width = _width;
        texture.height = _height;
        texture.initFromBytes!(PixelFormat.RGBA)(bytes!(PixelFormat.RGBA));
    }

    override void draw(IRenderer renderer,Vecf position) @safe
    {
        if(renderer.type == RenderType.OpenGL)
        {
            GL.color = rgb(255,255,255);

            GL.bindTexture(texture.glID);
            GL.enable(GL_TEXTURE_2D);

            GL.draw!Rectangle({
                GL.texCoord2i(0,0); GL.vertex(position);
                GL.texCoord2i(0,1); GL.vertex(position + Vecf(0,height));
                GL.texCoord2i(1,1); GL.vertex(position + Vecf(width,height));
                GL.texCoord2i(1,0); GL.vertex(position + Vecf(width,0));
            });

            GL.disable(GL_TEXTURE_2D);
            GL.bindTexture(0);
        }else
        {
            foreach(x,y; Coord(_width,_height))
                renderer.point(Vecf(x + position.intX,y + position.intY), getPixel(x,y));
        }
    }

    override void drawEx(IRenderer renderer,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha)
    {
        if(renderer.type == RenderType.OpenGL)
        {
            GL.color = rgba(255,255,255,alpha);

            GL.bindTexture(texture.glID);
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
        }else
        {
            if(size.x.to!int != _width || size.y.to!int != _height) {
                Image cp = this.dup();

                cp.resize(size.x.to!int,size.y.to!int);

                renderer.drawEx(cp, position, angle, center, size, alpha);

                return;
            }

             if(angle == 0)
            {
                foreach(x,y; Coord(_width,_height))
                {
                    renderer.point(Vecf(x,y) + position,getPixel(x,y));
                }
            }else
            {
                import tida.angle;

                foreach(x,y; Coord(_width,_height))
                {
                    auto pos = Vecf(position.intX + x,position.intY + y)
                        .rotate(angle.from!(Degrees,Radians), position + center);

                    renderer.point(pos,getPixel(x,y));
                }
            }
        }
    }

    override void drawColor(IRenderer renderer,Vecf position,Color!ubyte color)
    {
        if(renderer.type == RenderType.OpenGL)
        {
            GL.color = color;

            GL.bindTexture(texture.glID);
            GL.enable(GL_TEXTURE_2D);

            GL.draw!Rectangle({
                GL.texCoord2i(0,0); GL.vertex(position);
                GL.texCoord2i(0,1); GL.vertex(position + Vecf(0,height));
                GL.texCoord2i(1,1); GL.vertex(position + Vecf(width,height));
                GL.texCoord2i(1,0); GL.vertex(position + Vecf(width,0));
            });

            GL.disable(GL_TEXTURE_2D);
            GL.bindTexture(0);
        }else
        {
            foreach(x,y; Coord(_width,_height))
            {
                auto pixel = getPixel(x,y);

                pixel.colorize!NoAlpha(color);

                renderer.point(Vecf(position.intX + x,position.intY + y),pixel);
            }
        }
    }

    /// Frees up space for pixels. Does not destroy texture.
    void freePixels() @trusted
    {
        if(_pixels !is null) {
            destroy(_pixels);
            _pixels = null;
        }
    }

    alias free = freePixels;

    ~this() @safe
    {
        if(texture !is null) texture.destroy();
        free();
    }
}