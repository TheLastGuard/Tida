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

bool validateImageData(int format)(int w, int h, ubyte[] data) @safe nothrow pure
{
    return validateBytes!(format)(data) && (w * h * BytesPerColor!(format) == data.length);
}

/// Image.
class Image : IDrawable, IDrawableEx, IDrawableColor
{
    import tida.color, tida.vector, tida.graph.gl, tida.graph.render, tida.graph.each, tida.graph.texture;
    import imagefmt;
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
    this() @safe nothrow pure
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
    this(uint newWidth,uint newHeight) @safe nothrow pure
    {
        _pixels = new Color!ubyte[](newWidth * newHeight);

        _pixels.fill(rgba(0,0,0,0));

        _width = newWidth;
        _height = newHeight;
    }

    /// A sequence of pixels.
    Color!ubyte[] pixels() @safe @property nothrow pure
    {
        return _pixels;
    }

    /// ditto
    void pixels(Color!ubyte[] otherPixels) @safe @property nothrow pure
    in(otherPixels.length == _pixels.length)
    do
    {
        _pixels = otherPixels;
    }

    /++
        Returns a sequence of pixels in the format `0xRRGGBBAA` (Depending on the format).

        Params:
            format = Pixel format.
    +/
    ubyte[] bytes(int format = PixelFormat.RGBA)() @safe nothrow pure
    in(isCorrectFormat!format)
    do
    {
        ubyte[] tryBytes;

        foreach(pixel; _pixels) {
            tryBytes ~= pixel.fromBytes!format;
        }

        return tryBytes;
    }

    /// Whether the picture is empty for the data.
    bool empty() @safe nothrow pure
    {
        return _pixels.length == 0;
    }

    /++
        Fills the entire picture with color.
        
        Params:
            color = Color fill.
    +/
    Image fill(Color!ubyte color) @safe nothrow pure
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
    void bytes(int format = PixelFormat.RGBA)(ubyte[] bt) @safe nothrow pure
    in
    {
        static assert(isCorrectFormat!format, "You cannot find out the format on the fly.");
        assert(validateImageData!format(_width, _height, bt), "The size of the picture is much larger than this one!");
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
    void setPixel(int x,int y,Color!ubyte color) @safe nothrow pure
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
    Color!ubyte getPixel(int x,int y) @safe nothrow pure
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
        foreach(x,y; Coord!Type(pos.intX + otherImage.width,pos.intY + otherImage.height,pos.intX,pos.intY))
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
    Image copy(int Type = DefaultOperation)(int x,int y,int cWidth,int cHeight) @trusted
    {
        Image image = new Image();

        image.create(cWidth,cHeight);

        foreach(ix,iy; Coord!Type(x + cWidth,y + cHeight,x,y))
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
    Image create(uint newWidth,uint newHeight) @safe nothrow pure
    {
        _pixels = new Color!ubyte[](newWidth * newHeight);

        _pixels.fill(rgb(0,0,0));

        _width = newWidth;
        _height = newHeight;

        return this;
    }

    /++
        Loads a surface from a file. Supported formats are described here:
        `https://code.dlang.org/packages/imageformats`

        Params:
            path = Relative or full path to the image file.
    +/
    Image load(string path) @trusted
    {
        import std.file : exists;

        if(!exists(path))
            throw new Exception("Not find file `"~path~"`!");

        IFImage temp = read_image(path, 4);
        scope(exit) temp.free();

        _width = temp.w;
        _height = temp.h;

        create(_width,_height);

        this.bytes!(PixelFormat.RGBA)(temp.buf8);

        return this;
    }

    /// Whether the picture is a texture.
    bool isTexture() @safe nothrow pure
    {
        return texture !is null;
    }

    /++
        Convert to a texture for rendering to the window.
    +/
    Image fromTexture() @safe
    {
        if(GL.isInitialize)
        {
            import tida.graph.vertgen;

            _texture = new Texture();

            _texture.width = _width;
            _texture.height = _height;

            _texture.initFromBytes!(PixelFormat.RGBA)(bytes!(PixelFormat.RGBA));

            _texture.vertexInfo = generateVertex(Shape.Rectangle(Vecf(0,0), Vecf(_width, _height)),
                                                 Vecf(_width, _height));
        }

        return this;
    }

    Image fromTextureWithoutShape() @safe
    {
        if(GL.isInitialize)
        {
            import tida.graph.vertgen;

            _texture = new Texture();

            _texture.width = _width;
            _texture.height = _height;

            _texture.initFromBytes!(PixelFormat.RGBA)(bytes!(PixelFormat.RGBA));
        }

        return this;
    }

    Texture texture() @safe @property nothrow pure
    {
        return _texture;
    }

    void texture(Texture tex) @safe @property nothrow pure
    {
        this._texture = tex;
    }

    /++
        Resizes the image.

        Params:
            newWidth = Image new width.
            newHeight = Image new height.
    +/
    Image resize(uint newWidth,uint newHeight) @safe nothrow pure
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
    Image scale(float k) @safe nothrow pure
    {
        uint newWidth = cast(uint) ((cast(float) _width) * k);
        uint newHeight = cast(uint) ((cast(float) _height) * k);

        return resize(newWidth,newHeight);
    }

    /// The widht of the picture.
    uint width() @safe @property nothrow pure
    {
        return _width;
    }

    /// The height of the picture.
    uint height() @safe @property nothrow pure
    {
        return _height;
    }

    /// Creates a copy of the picture. Doesn't create a copy of the texture.
    Image dup() @safe @property nothrow pure
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

    import tida.graph.shader;

    override string toString()
    {
        import std.conv : to;

        return "Image(width: "~width.to!string~", height: "~height.to!string~")";
    }

    override void draw(IRenderer renderer,Vecf position) @trusted
    {
        import tida.graph.vertgen, tida.graph.matrix, std.exception;

        if(renderer.type == RenderType.OpenGL)
        {
            enforce(texture, "Texture is not create!");
            texture.draw(renderer, position);
        }else
        if(renderer.type == RenderType.Soft)
        {
            foreach(x,y; Coord(_width,_height))
                renderer.point(Vecf(x + position.intX,y + position.intY), getPixel(x,y));
        }
    }

    override void drawEx(IRenderer renderer,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha,Color!ubyte color) @trusted
    {
        import std.exception, tida.graph.vertgen, tida.graph.matrix, tida.angle;

        if(renderer.type == RenderType.OpenGL)
        {
            enforce(texture, "Texture is not create!");
            texture.drawEx(renderer, position, angle, center, size, alpha, color);
        }else
        if(renderer.type == RenderType.Soft)
        {
            import std.math;

            if(size.x == 0 || size.x.isNaN) size.x = _width;
            if(size.y == 0 || size.y.isNaN) size.y = _height;

            if( size.x.to!int != _width || size.y.to!int != _height) {
                Image cp = this.dup();

                cp.resize(size.x.to!int,size.y.to!int);

                renderer.drawEx(cp, position, angle, center, size, alpha);

                return;
            }

            if(angle == 0)
            {
                foreach(x,y; Coord(_width,_height))
                {
                    auto colorpos = getPixel(x,y);
                    if(colorpos.a != 0) colorpos.a = alpha;

                    renderer.point(Vecf(x,y) + position,colorpos);
                }
            }else
            {
                import tida.angle;

                foreach(x,y; Coord(_width,_height))
                {
                    auto pos = Vecf(position.intX + x,position.intY + y)
                        .rotate(angle, position + center);

                    auto colorpos = getPixel(x,y);
                    if(colorpos.a != 0) colorpos.a = alpha;

                    renderer.point(pos,colorpos);
                }
            }
        }
    }

    override void drawColor(IRenderer renderer,Vecf position,Color!ubyte color) @trusted
    {
        import std.exception, tida.graph.vertgen, tida.graph.matrix, tida.angle;

        if(renderer.type == RenderType.OpenGL)
        {
            enforce(texture, "Texture is not create!");
            texture.drawColor(renderer, position, color);
        }else
        if(renderer.type == RenderType.Soft)
        {
            foreach(x,y; Coord(_width,_height))
            {
                auto pixel = getPixel(x,y);

                pixel = pixel.mix(color);

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
    Rotate the picture by the specified angle from the specified center.

    Params:
        image = The picture to be rotated.
        angle = Angle of rotation.
        center =    Center of rotation.
                    (If the vector is empty (non-zero `VecfNan`), then the
                    center is determined automatically).
+/
Image rotateImage(int Type = DefaultOperation)(Image image,float angle,Vecf center = VecfNan) @safe
{
    import tida.angle;

    Image rotated = new Image(image.width, image.height).fill(rgba(0,0,0,0));

    if(center.isVecfNan)
        center = Vecf(image.width / 2, image.height / 2);

    foreach(x,y; Coord!Type(image.width,image.height))
    {
        auto pos = Vecf(x,y)
            .rotate(angle, center);

        auto colorpos = image.getPixel(x,y);

        rotated.setPixel(pos.intX, pos.intY, colorpos);
    }

    return rotated;
}

/++
    Reverses the picture along the specified axis.

    Params:
        FlipType = Axis.
        img = Image.

    Example:
    ---
    image
        .flip!XAxis
        .flip!YAxis;
    ---
+/
Image flip(int FlipType)(Image img) @safe
in(isCorrectAxis!FlipType)
do
{
    Image image = img.dup();

    static if(FlipType == XAxis) {
        foreach(x,y; Coord(img.width,img.height)) {
            image.setPixel(img.width - x,y, img.getPixel(x,y));
        }
    }else
    static if(FlipType == YAxis)
    {
        foreach(x,y; Coord(img.width,img.height)) {
            image.setPixel(x, img.height - y, img.getPixel(x,y));
        }
    }

    return image;
}
/++
    Save image in file.

    Params:
        image = Image.
        path = Path to the file.
+/
void saveImageInFile(Image image,string path) @trusted
{
    import imagefmt;
    import tida.color;

    write_image(path, image.width, image.height, image.bytes!(PixelFormat.RGBA), 4);
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
Image shapeCopy(int Type = DefaultOperation)(Image image,Shape shape,Image outImage = null) @safe
in(shape.type != ShapeType.unknown && shape.type != ShapeType.triangle && shape.type != ShapeType.polygon,
"This shape is not a croppeared!")
do
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
            copyImage = image.copy(shape.x.to!int, shape.y.to!int, shape.width.to!int, shape.height.to!int);
        break;

        case ShapeType.circle:
            int x = 0;
            int y = cast(int) shape.radius;

            int X1 = shape.begin.intX();
            int Y1 = shape.begin.intY();

            int delta = 1 - 2 * cast(int) shape.radius;
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
                shapeCopy!Type(image, shapef, copyImage);
            }
        break;
        
        default: break;
    }

    return copyImage;
}

/++
    Divides the picture into frames.

    Params:
        image = Atlas.
        x = Begin x-axis position divide.
        y = Begin y-axis position divide.
        w = Frame width.
        h = Frame height.
+/
Image[] strip(Image image,int x,int y,int w,int h) @safe
{
    Image[] result;

    for(int i = 0; i < image.width; i += w)
    {
        result ~= image.copy(i,y,w,h);
    }

    return result;
}

import tida.vector;

/++
    Combining two paintings into one using color mixing.

    Params:
        a = First image.
        b = Second image.
        posA = First image position.
        posB = Second image position.
+/
Image unite(int Type = DefaultOperation)(Image a,Image b,Vecf posA = Vecf(0,0),Vecf posB = Vecf(0,0)) @trusted
{
    import std.algorithm, std.conv;
    import tida.color;

    Image result = new Image();

    int width = int.init,
        height = int.init;

    width = (posA.x + a.width > posB.x + b.width) ? posA.x.to!int + a.width : posB.x.to!int + b.width;
    height = (posA.y + a.height > posB.y + b.height) ? posA.y.to!int + a.height : posB.x.to!int + b.height;

    result.create(width, height);
    result.fill(rgba(0,0,0,0));

    foreach(x, y; Coord!Type(posA.x.to!int + a.width, posA.y.to!int + a.height,
                             posA.x.to!int, posA.y.to!int))
    {
        Color!ubyte color = a.getPixel(x - posA.x.to!int, y - posA.y.to!int);
        result.setPixel(x,y,color);
    }

    foreach(x, y; Coord!Type(posB.x.to!int + b.width, posB.y.to!int + b.height,
                             posB.x.to!int, posB.y.to!int))
    {
        Color!ubyte color = b.getPixel(x - posB.x.to!int, y - posB.y.to!int);
        Color!ubyte backColor = result.getPixel(x, y);
        color.BlendAlpha!ubyte(backColor);
        result.setPixel(x,y,color);
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
float[][] gausKernel(int width,int height,float sigma) @safe nothrow pure
{
    import std.math : exp;

    float[][] result = new float[][](width, height);

    float sum = 0f;

    foreach(i; 0 .. height)
    {
        foreach(j; 0 .. width)
        {
            result[j][i] = exp(-(i * i + j * j) / (2 * sigma * sigma) / (2 * M_PI * sigma * sigma));
            sum += result[j][i];
        }
    }

    foreach(i; 0 .. height)
    {
        foreach(j; 0 .. width)
        {
            result[j][i] /= sum;
        }
    }

    return result;
}

/++
    Generates a gauss matrix.

    Params:
        r = Radiuos gaus.
+/
float[][] gausKernel(float r) @safe nothrow pure
{
    return gausKernel(cast(int) (r * 2), cast(int) (r * 2), r);
}

/++
    Applies blur.

    Params:
        Type = Operation type.
        image = Image.
        r = radius gaus kernel.
+/
Image blur(int Type = DefaultOperation)(Image image,float r) @safe
{
    return blur!Type(image, gausKernel(r));
}

/++
    Apolies blur.

    Params:
        Type = Operation type.
        image = Image.
        width = gaus kernel width.
        height = gaus kernel height.
        r = radius gaus kernel.
+/
Image blur(int Type = DefaultOperation)(Image image,int width,int height,float r) @trusted
{
    return blur!Type(image,gausKernel(width,height,r));
}

/++
    Applies blur.

    Params:
        Type = Operation type.
        image = Image.
        otherKernel = Filter kernel.
+/
Image blur(int Type = DefaultOperation)(Image image,float[][] otherKernel) @trusted
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

    foreach(x, y; Coord!Type(width, height))
    {
        Color!ubyte color = rgb(0,0,0);

        foreach(ix,iy; Coord(kernelWidth, kernelHeight))
        {
            color = color + (image.getPixel(x - kernelWidth / 2 + ix,y - kernelHeight / 2 + iy).mul(kernel[ix][iy]));
        }

        color.a = image.getPixel(x,y).a;
        result.setPixel(x,y,color);
    }

    return result;
}

import tida.color, tida.graph.each;

/++
    Image processing process. The function traverses the picture, giving the
    input delegate a pointer to the color and traversal position in the form
    of a vector.

    Params:
        image = Image processing.
        func = Function processing.

    Example:
    ---
    // Darkening the picture in the corners.
    myImage.process((ref e, position) {
        e = e * (position.x / myImage.width * position.y / myImage.height);
    });
    ---
+/
Image process(int Type = DefaultOperation)(Image image, void delegate(ref Color!ubyte,const Vecf) @safe func) @safe
{
    foreach(x, y; Coord!Type(image.width, image.height)) 
    {
        Color!ubyte color = image.getPixel(x, y);
        func(color, Vecf(x, y));
        image.setPixel(x, y, color);
    }

    return image;
}
