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

static immutable Parallel = 0;
static immutable NoParallel = 1;
enum DefaultOperation = Parallel;

template isCorrectComponent(int cmp)
{
    enum isCorrectComponent = cmp == Red || cmp == Green || cmp == Blue;
}

enum M_PI = 3.14159265358979323846;

static immutable XAxis = 0;
static immutable YAxis = 1;

template isCorrectAxis(int axis)
{
    enum isCorrectAxis = axis == XAxis || axis == YAxis;
}

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
    this() @safe nothrow
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
    this(uint newWidth,uint newHeight) @safe nothrow
    {
        _pixels = new Color!ubyte[](newWidth * newHeight);

        _pixels.fill(rgb(0,0,0));

        _width = newWidth;
        _height = newHeight;
    }

    /// A sequence of pixels.
    Color!ubyte[] pixels() @safe @property nothrow
    {
        return _pixels;
    }

    /// ditto
    void pixels(Color!ubyte[] otherPixels) @safe @property nothrow
    {
        _pixels = otherPixels;
    }

    /++
        Returns a sequence of pixels in the format `0xRRGGBBAA` (Depending on the format).

        Params:
            format = Pixel format.
    +/
    ubyte[] bytes(int format = PixelFormat.RGBA)() @safe nothrow
    in(isCorrectFormat!format)
    body
    {
        ubyte[] tryBytes;

        foreach(pixel; _pixels) {
            tryBytes ~= pixel.fromBytes!(ubyte,format);
        }

        return tryBytes;
    }

    /++
        Fills the entire picture with color.
        
        Params:
            color = Color fill.
    +/
    auto fill(Color!ubyte color) @safe nothrow
    {
        _pixels.fill(color);

        return this;
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
    void bytes(int format = PixelFormat.RGBA)(ubyte[] bt) @safe nothrow
    in
    {
        static assert(isCorrectFormat!format, "You cannot find out the format on the fly.");

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
    void setPixel(int x,int y,Color!ubyte color) @safe nothrow
    {
        if(x >= width || y >= height || x < 0 || y < 0)
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
    Color!ubyte getPixel(int x,int y) @safe nothrow
    {
        if(x >= width || y >= height || x < 0 || y < 0) return rgba(0,0,0,0);

        return _pixels[(width * y) + x];
    }

    /++
        Attaches an image to itself at the specified position.

        Params:
            otherImage = Other image.
            pos = Other image position.
    +/
    void blit(int Type = DefaultOperation)(Image otherImage,Vecf pos) @trusted
    {
        static if(Type == NoParallel)
        {
            foreach(x,y; Coord(pos.intX + otherImage.width,pos.intY + otherImage.height,pos.intX,pos.intY))
            {
                setPixel(x,y,otherImage.getPixel(x - pos.intX,y - pos.intY));
            }
        }else
        static if(Type == Parallel)
        {
            import std.parallelism, std.range;

            foreach(x; parallel(iota(pos.intX,pos.intX + otherImage.width)))
            {
                foreach(y; parallel(iota(pos.intY,pos.intY + otherImage.height)))
                {
                    setPixel(x,y,otherImage.getPixel(x - pos.intX,y - pos.intY));
                }
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
    Image copy(int Type = DefaultOperation)(int x,int y,int cWidth,int cHeight) @trusted
    {
        Image image = new Image();

        image.create(cWidth,cHeight);

        static if(Type == NoParallel)
        {
            foreach(ix,iy; Coord(x + cWidth,y + cHeight,x,y))
            {
                image.setPixel(
                    ix - x, iy - y,
                    this.getPixel(ix,iy)
                );
            }
        }else
        static if(Type == Parallel)
        {
            import std.parallelism, std.range;

            foreach(ix; parallel(iota(x,x + cWidth)))
            {
                foreach(iy; parallel(iota(y,y + cHeight)))
                {
                    image.setPixel(
                        ix - x, iy - y,
                        this.getPixel(ix,iy)
                    );
                }
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
    void create(uint newWidth,uint newHeight) @safe nothrow
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
    bool isTexture() @safe nothrow
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

    Texture texture() @safe @property nothrow
    {
        return _texture;
    }

    /++
        Resizes the image.

        Params:
            newWidth = Image new width.
            newHeight = Image new height.
    +/
    auto resize(uint newWidth,uint newHeight) @safe nothrow
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

        return this;
    }

    /++
        Enlarges the image by a factor.

        Params:
            k = factor.
    +/
    auto scale(float k) @safe nothrow
    {
        uint newWidth = cast(uint) ((cast(float) _width) * k);
        uint newHeight = cast(uint) ((cast(float) _height) * k);

        return resize(newWidth,newHeight);
    }

    /++
        Invents the picture by color.
    +/
    auto invert() @safe nothrow
    {
        import std.algorithm : each;

        _pixels.each!((ref e) => e.invert());

        return this;
    }

    /++
        Clears the specified color component from the picture.

        Params:
            Component = Component color.
    +/
    auto clearComponent(ubyte Component)() @safe nothrow
    in(isCorrectComponent!Component)
    body
    {
        import std.algorithm : each;

        static if(Component == Red) _pixels.each!((ref e) => e.clearRed());
        static if(Component == Green) _pixels.each!((ref e) => e.clearGreen());
        static if(Component == Blue) _pixels.each!((ref e) => e.clearBlue());

        return this;
    }

    /++
        Applies alpha blending. Works only when drawing on other surfaces, 
        because this function edits the alpha channel of colors.

        Params:
            value = Alpha-channel.
    +/
    auto alpha(ubyte value) @safe nothrow
    {
        import std.algorithm : each;

        _pixels.each!((ref e) => e.alpha = value);

        return this;
    }

    /++
        Adds a component to all colors in the picture.

        Params:
            Component = Component color.
            value = How much to increase.
    +/
    auto addComponent(ubyte Component)(ubyte value) @safe nothrow
    in(isCorrectComponent!Component)
    body
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

        return this;
    }

    /++
        Reverses the picture along the specified axis.

        Params:
            FlipType = Axis.

        Example:
        ---
        image
            .flip!XAxis
            .flip!YAxis;
        ---
    +/
    auto flip(int FlipType)() @safe
    in(isCorrectAxis!FlipType)
    body
    {
        Image image = this.dup();

        static if(FlipType == XAxis) {
            foreach(x,y; Coord(width,height)) {
                setPixel(width - x,y, image.getPixel(x,y));
            }
        }else
        static if(FlipType == YAxis)
        {
            foreach(x,y; Coord(width,height)) {
                setPixel(x, height - y, image.getPixel(x,y));
            }
        }

        image.freePixels();

        return this;
    }

    /// The widht of the picture.
    uint width() @safe @property nothrow
    {
        return _width;
    }

    /// The height of the picture.
    uint height() @safe @property nothrow 
    {
        return _height;
    }

    /// Creates a copy of the picture. Doesn't create a copy of the texture.
    Image dup() @safe @property nothrow 
    {
        Image image = new Image();

        image.create(_width,_height);

        image.pixels = pixels.dup;

        return image;
    }

    /// Updates the texture if the picture has changed.
    void swap() @safe nothrow
    {
        if(isTexture) texture.destroy();

        texture.width = _width;
        texture.height = _height;
        texture.initFromBytes!(PixelFormat.RGBA)(bytes!(PixelFormat.RGBA));
    }

    override string toString()
    {
        import std.conv : to;

        return "Image(width: "~width.to!string~", height: "~height.to!string~")";
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
        free();
    }
}

/++
    Save image in file.

    Params:
        image = Image.
        path = Path to the file.
+/
void saveImageFromFile(Image image,string path) @trusted
{
    import imageformats;
    import tida.color;

    write_image(path, image.width, image.height, image.bytes!(PixelFormat.RGBA), ColFmt.RGBA);
}

import tida.shape;

/++
    Creates a cropped version of the picture according to the given shape.

    Params:
        shape = Shape.
        image = Cropped shape.
        outImage = Link to the edited picture. Usually needed for recursion.

    Returns: Cropped picture.
+/
Image shapeCopy(int Type = DefaultOperation)(Shape shape,Image image,Image outImage = null) @safe
in(shape.type != ShapeType.triangle)
body
{
    import tida.graph.each;
    import tida.color, std.conv : to;
    import tida.vector;

    Image copyImage;

    if(outImage is null) {
        copyImage = new Image(image.width, image.height);
        copyImage.fill(rgba(0,0,0,0));
    } else {
        copyImage = outImage;
    }

    Color!ubyte[] pixels = image.pixels;

    switch(shape.type)
    {
        case ShapeType.point:
            copyImage.setPixel(shape.begin.x.to!int, shape.begin.y.to!int,
                image.getPixel(shape.x.to!int,shape.y.to!int));
        break;

        case ShapeType.line:
            foreach(x,y; Line(shape.begin,shape.end)) 
            {
                copyImage.setPixel(x,y, image.getPixel(x,y));
            }
        break;

        case ShapeType.rectangle:
            copyImage = image.blit!Type(shape.x.to!int,shape.y.to!int,shape.width.to!int,shape.height.to!int);
        break;

        case ShapeType.circle:
            int x = 0;
            int y = cast(int) shape.radious;

            int X1 = shape.begin.intX();
            int Y1 = shape.begin.intY();

            int delta = 1 - 2 * cast(int) shape.radious;
            int error = 0;

            while (y >= 0)
            {
                foreach(ix,iy; Line(Vecf(X1 + x, Y1 + y),Vecf(X1 + x, Y1 - y))) {
                    copyImage.setPixel(ix,iy, image.getPixel(ix,iy));
                }

                foreach(ix,iy; Line(Vecf(X1 - x, Y1 + y),Vecf(X1 - x, Y1 - y))) {
                    copyImage.setPixel(ix,iy, image.getPixel(ix,iy));
                }

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
        break;

        case ShapeType.multi:
            foreach(shapef; shape.shapes) {
                shapeCopy!Type(shapef, image, copyImage);
            }
        break;
        
        default: break;
    }

    return copyImage;
}

/++

+/
Image[] strip(Image image,int x,int y,int w,int h) @safe
{
    Image[] result;

    foreach(ix; x .. x + w)
    {
        result ~= image.copy(ix,y,w,h);
    }

    return result;
}

import tida.vector;

/++
    Combines two pictures, for example, if they are both of low transparency, you can create a single picture.

    Params:
        a = First image.
        b = Second image.
        posA = Position combines first image.
        posB = Position combines second image.

    Returns: Unites images
+/
Image uniteWP(Image a,Image b,Vecf posA = Vecf(0,0),Vecf posB = Vecf(0,0)) @safe
{ 
    import std.algorithm, std.conv;
    import tida.color;

    Image result = new Image();

    int width = max(posA.x,posB.y).to!int + max(a.width,b.width);
    int height = max(posA.y,posB.y).to!int + max(a.height,b.height);

    result.create(width,height);
    result.fill(rgba(0,0,0,0));

    for(int x = posA.x.to!int; x < posA.x.to!int + a.width; x++) {
        for(int y = posA.y.to!int; y < posA.y.to!int + a.height; y++) {
            Color!ubyte color = a.getPixel(x - posA.x.to!int, y - posA.y.to!int);
            result.setPixel(x,y,color);
        }
    }

    for(int x = posB.x.to!int; x < posB.x.to!int + b.width; x++) {
        for(int y = posB.y.to!int; y < posB.y.to!int + b.height; y++) {
            Color!ubyte color = b.getPixel(x - posB.x.to!int, y - posB.y.to!int);
            Color!ubyte backColor = result.getPixel(x,y);
            color.colorize!Alpha(backColor);
            result.setPixel(x,y,color);
        }
    }

    return result;
}

/// ditto
Image uniteParallel(Image a,Image b,Vecf posA = Vecf(0,0),Vecf posB = Vecf(0,0)) @trusted
{
    import std.algorithm, std.conv, std.range, std.parallelism;
    import tida.color;

    Image result = new Image();

    int width = max(posA.x,posB.y).to!int + max(a.width,b.width);
    int height = max(posA.y,posB.y).to!int + max(a.height,b.height);

    result.create(width,height);
    result.fill(rgba(0,0,0,0));

    foreach(x; parallel(iota(posA.x.to!int, posA.x.to!int + a.width))) {
        foreach(y; parallel(iota(posA.y.to!int, posA.y.to!int + a.height))) {
            Color!ubyte color = a.getPixel(x - posA.x.to!int, y - posA.y.to!int);
            result.setPixel(x,y,color);
        }
    }

    foreach(x; parallel(iota(posB.x.to!int, posB.x.to!int + b.width))) {
        foreach(y; parallel(iota(posB.y.to!int, posB.y.to!int + b.height))) {
            Color!ubyte color = b.getPixel(x - posB.x.to!int, y - posB.y.to!int);
            Color!ubyte backColor = result.getPixel(x,y);
            color.colorize!Alpha(backColor);
            result.setPixel(x,y,color);
        }
    }

    return result;
}

/++
    Generates a gauss matrix.

    Params:
        width = Matrix width.
        height = Matrix height.
        sigma = Radious gaus.

    Return: Matrix
+/
float[][] gausKernel(int width,int height,float sigma) @safe
{
    import std.math : exp;

    float[][] result = new float[][](width,height);

    float sum = 0f;

    foreach(i; 0 .. height)
    {
        foreach(j; 0 .. width)
        {
            result[i][j] = exp(-(i * i + j * j) / (2 * sigma * sigma) / (2 * M_PI * sigma * sigma));
            sum += result[i][j];
        }
    }

    foreach(i; 0 .. height)
    {
        foreach(j; 0 .. width)
        {
            result[i][j] /= sum;
        }
    }

    return result;
}

/++
    Generates a gauss matrix.

    Params:
        r = Radiuos gaus.
+/
float[][] gausKernel(float r) @safe
{
    return gausKernel(cast(int) (r * 2), cast(int) (r * 2), r);
}

/++
    Blurs the picture by the specified factor.

    Params:
        image = Blurse image.
        otherKernel = Matrix.
+/
Image blurWP(Image image,float[][] otherKernel) @safe
{
    import tida.color;
    import tida.graph.each;

    auto kernel = otherKernel; 
    
    int width = image.width;
    int height = image.height;

    int kernelWidth = cast(int) kernel.length;
    int kernelHeight = cast(int) kernel[0].length;

    Image result = new Image(width,height);
    result.fill(rgba(0,0,0,0));

    foreach(x,y; Coord(width, height))
    {
        Color!ubyte color = rgb(0,0,0);

        foreach(ix,iy; Coord(kernelWidth, kernelHeight))
        {
            color.add(image.getPixel(x - kernelWidth / 2 + ix,y - kernelHeight / 2 + iy).mul(kernel[ix][iy]));
        }

        color.a = image.getPixel(x,y).a;
        result.setPixel(x,y,color);
    }

    return result;
}

/++
    Blurs the picture by the specified factor.

    Params:
        image = Blurse image.
        k = Factor.
+/
Image blurWP(Image image,float k) @safe
{
    return blur(image, gausKernel(k));
}

/++
    Applies blur using parallel computation.

    Params:
        image = Image.
        otherKernel = Filter kernel.
+/
Image blurParallel(Image image,float[][] otherKernel) @trusted
{
    import tida.color;
    import tida.graph.each;
    import std.parallelism, std.range;

    auto kernel = otherKernel; 
    
    int width = image.width;
    int height = image.height;

    int kernelWidth = cast(int) kernel.length;
    int kernelHeight = cast(int) kernel[0].length;

    Image result = new Image(width,height);
    result.fill(rgba(0,0,0,0));

    foreach(x; parallel(iota(0,width)))
    {
        foreach(y; parallel(iota(0,height)))
        {
            Color!ubyte color = rgb(0,0,0);

            foreach(ix,iy; Coord(kernelWidth, kernelHeight))
            {
                color.add(image.getPixel(x - kernelWidth / 2 + ix,y - kernelHeight / 2 + iy).mul(kernel[ix][iy]));
            }

            color.a = image.getPixel(x,y).a;
            result.setPixel(x,y,color);
        }
    }

    return result;
}

/++
    Applies blur using parallel computation.

    Params:
        image = Image.
        k = Factor.
+/
Image blurParallel(Image image,float k) @safe
{
    return blurParallel(image, gausKernel(k));
}

/++
    Applies blur in image.

    Params:
        Type = Is parallel operation? (Parallel/NoParallel)
+/
template blur(int Type = DefaultOperation)
{
    static if(Type == Parallel)
        alias blur = blurParallel;
    else
    static if(Type == NoParallel)
        alias blur = blurWP;
}

/++
    Combines two pictures, for example, if they are both of low transparency, you can create a single picture.

    Params:
        Type = Is parallel operation? (Parallel/NoParallel)
+/
template unite(int Type = DefaultOperation)
{
    static if(Type == Parallel)
        alias unite = uniteParallel;
    else
    static if(Type == NoParallel)
        alias unite = uniteWP;
}