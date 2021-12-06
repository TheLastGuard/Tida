/++
A module for manipulating pictures, processing and transforming them.

Using the $(HREF https://code.dlang.org/packages/imagefmt, imagefmt) library,
you can load images directly from files with a certain limitation in types
(see imagefmt). Also, the image can be manipulated: $(LREF blur),
$(HREF image/Image.copy.html, copy), $(HREF #process, apply loop processing).

Blur can be applied simply by calling the function with the picture as an
argument. At the exit, it will render the image with blur. Example:
---
Image image = new Image().load("test.png");
image = image.blur!WithParallel(4);
// `WithParallel` means that parallel computation is used
// (more precisely, application, the generation of a Gaussian kernel
// will be without it).
---

Also, you can set a custom kernel to use, let's say:
---
// Generating a gaussian kernel. In fact, you can make your own kernel.
auto kernel = gausKernel(4, 4, 4);

image = image.blur!WithParallel(kernel);
---

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.image;

import tida.color;
import tida.each;
import tida.drawable;
import tida.vector;
import std.range : isInputRange, isBidirectionalRange, ElementType;

/++
Checks if the data for the image is valid.

Params:
    format = Pixel format.
    data = Image data (in fact, it only learns the length from it).
    w = Image width.
    h = Image height.
+/
bool validateImageData(int format)(ubyte[] data, uint w, uint h) @safe nothrow pure
{
    return data.length == (w * h * bytesPerColor!format);
}

/// Let's check the performance:
unittest
{
    immutable simpleImageWidth  = 32;
    immutable simpleImageHeight = 32;
    ubyte[] data = new ubyte[](simpleImageWidth * simpleImageHeight * bytesPerColor!(PixelFormat.RGBA));

    assert(validateImageData!(PixelFormat.RGBA)(data, simpleImageWidth, simpleImageHeight));
}

auto reversed(Range)(Range range) @trusted nothrow pure
if (isBidirectionalRange!Range)
{
    import std.traits : isArray;

    ElementType!Range[] elements;

    foreach_reverse (e; range)
    {
        elements ~= e;
    }

    static if (is(Range == class))
        return new Range(elements);
    else
    static if (isArray!Range)
        return elements;
    else
        static assert(null, "It is unknown how to return the result.");
}

Image imageFrom(Range)(Range range, uint width, uint height) @trusted nothrow pure
if (isInputRange!Range)
{
    import std.range : array;

    Image image = new Image(width, height);
    image.pixels = range.array;

    return image;
}

/++
Image description structure. (Colors are in RGBA format.)
+/
class Image : IDrawable, IDrawableEx
{
    import std.algorithm : fill, map;
    import std.range : iota, array;
    import tida.vector;
    import tida.render;
    import tida.texture;

private:
    Color!ubyte[] pixeldata;
    uint _width;
    uint _height;
    Texture _texture;

public:
    /++
    Loads a surface from a file. Supported formats are described here:
    `https://code.dlang.org/packages/imageformats`

    Params:
        path = Relative or full path to the image file.
    +/
    Image load(string path) @trusted
    {
        import imagefmt;
        import std.file : exists;
        import std.exception : enforce;

        enforce!Exception(exists(path), "Not find file `"~path~"`!");

        IFImage temp = read_image(path, 4);
        scope(exit) temp.free();

        _width = temp.w;
        _height = temp.h;

        allocatePlace(_width, _height);

        bytes!(PixelFormat.RGBA)(temp.buf8);

        return this;
    }

    /++
    Merges two images (no alpha blending).

    Params:
        otherImage = Other image for merge.
        position = Image place position.
    +/
    void blit(int Type = WithoutParallel)(Image otherImage, Vecf position) @trusted
    {
        import std.conv : to;

        foreach (x, y; Coord!Type(  position.x.to!int + otherImage.width, 
                                    position.y.to!int+ otherImage.height,
                                    position.x.to!int, position.y.to!int))
        {
            this.setPixel(x, y, otherImage.getPixel(x - position.x.to!int,
                                                    y - position.y.to!int));
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
    Image copy(int x, int y, int cWidth, int cHeight) @trusted
    {
        import std.algorithm : map, joiner;

        return this.scanlines[y .. y + cHeight]
            .map!(e => e[x .. x + cWidth])
            .joiner
            .imageFrom(cWidth, cHeight);
    }

    /++
    Converts an image to a texture (i.e. for rendering an image with hardware
    acceleration). At the same time, now, when the image is called, the texture
    itself will be drawn. You can get such a texture and change its parameters
    from the $(LREF "texture") property.
    +/
    void toTexture() @trusted
    {
        import tida.shape;
        import tida.vertgen;

        _texture = new Texture();

        Shape!float shape = Shape!float.Rectangle(vecf(0, 0), vecf(width, height));

        TextureInfo info;
        info.width = _width;
        info.height = _height;
        info.params = DefaultParams;
        info.data = bytes!(PixelFormat.RGBA)();

        _texture.initializeFromData!(PixelFormat.RGBA)(info);
        _texture.vertexInfo = generateVertex!(float)(shape, vecf(_width, _height));
    }

    /++
    Converts an image to a texture (i.e. for rendering an image with hardware
    acceleration). At the same time, now, when the image is called, the texture
    itself will be drawn. You can get such a texture and change its parameters
    from the $(LREF "texture") property.
    +/
    void toTextureWithoutShape() @trusted
    {
        import tida.shape;
        import tida.vertgen;

        _texture = new Texture();

        Shape!float shape = Shape!float.Rectangle(vecf(0, 0), vecf(width, height));

        TextureInfo info;
        info.width = _width;
        info.height = _height;
        info.params = DefaultParams;
        info.data = bytes!(PixelFormat.RGBA)();

        _texture.initializeFromData!(PixelFormat.RGBA)(info);
    }

    /++
    The texture that was generated by the $(LREF "toTexture") function.
    Using the field, you can set the shape of the texture and its other parameters.
    +/
    @property Texture texture() nothrow pure @safe => _texture;

    override void draw(IRenderer renderer, Vecf position) @trusted
    {
        import std.conv : to;

        if (_texture !is null && renderer.type == RenderType.opengl)
        {
            _texture.draw(renderer, position);
            return;
        }

        foreach (x; position.x .. position.x + _width)
        {
            foreach (y; position.y .. position.y + _height)
            {
                renderer.point(vecf(x, y),
                                getPixel(x.to!int - position.x.to!int,
                                        y.to!int - position.y.to!int));
            }
        }
    }

    override void drawEx(   IRenderer renderer,
                            Vecf position,
                            float angle,
                            Vecf center,
                            Vecf size,
                            ubyte alpha,
                            Color!ubyte color) @trusted
    {
        import std.conv : to;
        import tida.angle : rotate;

        if (texture !is null && renderer.type == RenderType.opengl)
        {
            texture.drawEx(renderer, position, angle, center, size, alpha, color);
            return;
        }

        if (!size.isVecfNaN)
        {
            Image scaled = this.dup.resize(size.x.to!int, size.y.to!int);
            scaled.drawEx(renderer, position, angle, center, vecfNaN, alpha, color);
            return;
        }

        if (center.isVecfNaN)
            center = vecf(width, height) / 2;

        center += position;

        foreach (x; position.x .. position.x + _width)
        {
            foreach (y; position.y .. position.y + _height)
            {
                Vecf pos = vecf(x,y);
                pos = rotate(pos, angle, center);

                renderer.point(pos,
                                getPixel(x.to!int - position.x.to!int,
                                         y.to!int - position.y.to!int));
            }
        }
    }

@safe nothrow pure:
    /// Empty constructor image.
    this() @safe
    {
        pixeldata = null;
    }

    /++
    Allocates space for image data.

    Params:
        w = Image width.
        h = Image heght.
    +/
    this(uint w, uint h)
    {
        this.allocatePlace(w, h);
    }

    ref Color!ubyte opIndex(size_t x, size_t y) => pixeldata[(width * y) + x];

    /// Image width.
    @property uint width() => _width;

    /// Image height.
    @property uint height() => _height;

    /++
    Allocates space for image data.

    Params:
        w = Image width.
        h = Image heght.
    +/
    void allocatePlace(uint w, uint h)
    {
        pixeldata = new Color!ubyte[](w * h);

        _width = w;
        _height = h;
    }

    /// Image dataset.
    @property Color!ubyte[] pixels() => pixeldata;

    /// ditto
    @property Color!ubyte[] pixels(Color!ubyte[] data)
    in(pixeldata.length == (_width * _height))
    do
    {
        return pixeldata = data;
    }

    Color!ubyte[] scanline(uint y)
    in(y >= 0 && y < height)
    {
        return pixeldata[(width * y) .. (width * y) + width];
    }

    Color!ubyte[][] scanlines() => iota(0, height).map!(e => scanline(e)).array;

    /++
    Gives away bytes as data for an image.
    +/
    ubyte[] bytes(int format = PixelFormat.RGBA)()
    {
        static assert(isValidFormat!format, CannotDetectAuto);

        ubyte[] data;

        foreach (e; pixels)
            data ~= e.toBytes!format;

        return data;
    }

    /++
    Accepts bytes as data for an image.

    Params:
        data = Image data.
    +/
    void bytes(int format = PixelFormat.RGBA)(ubyte[] data)
    in(validateBytes!format(data), 
    "The number of bytes is not a multiple of the sample of bytes in a pixel.")
    in(validateImageData!format(data, _width, _height),
    "The number of bytes is not a multiple of the image size.")
    do
    {
        pixels = data.fromColors!(format);
    }

    /++
    Whether the data has the current image.
    +/
    bool empty() => pixeldata.length == 0;

    /++
    Fills the data with color.

    Params:
        color = The color that will fill the plane of the picture.
    +/
    void fill(Color!ubyte color)
    {
        pixeldata.fill(color);
    }

    /++
    Sets the pixel to the specified position.

    Params:
        x = Pixel x-axis position.
        y = Pixel y-axis position.
        color = Pixel color.
    +/
    void setPixel(int x, int y, Color!ubyte color)
    {
        if (x >= width || y >= height || x < 0 || y < 0)
            return;

        pixeldata   [
                        (width * y) + x
                    ] = color;  
    }

    /++
    Returns the pixel at the specified location.

    Params:
        x = The x-axis position pixel.
        y = The y-axis position pixel.
    +/
    Color!ubyte getPixel(int x,int y)
    {
        if (x >= width || y >= height || x < 0 || y < 0) 
            return Color!ubyte(0, 0, 0, 0);

        return pixeldata[(width * y) + x];
    }

    /++
    Resizes the image.

    Params:
        newWidth = Image new width.
        newHeight = Image new height.
    +/
    Image resize(uint newWidth,uint newHeight)
    {
        uint oldWidth = _width;
        uint oldHeight = _height;

        _width = newWidth;
        _height = newHeight;

        double scaleWidth = cast(double) newWidth / cast(double) oldWidth;
        double scaleHeight = cast(double) newHeight / cast(double) oldHeight;

        Color!ubyte[] npixels = new Color!ubyte[](newWidth * newHeight);

        foreach (cy; 0 .. newHeight)
        {
            foreach (cx; 0 .. newWidth)
            {
                uint pixel = (cy * (newWidth)) + (cx);
                uint nearestMatch = (cast(uint) (cy / scaleHeight)) * (oldWidth) + (cast(uint) ((cx / scaleWidth)));

                npixels[pixel] = pixeldata[nearestMatch];
            }
        }

        pixeldata = npixels;

        return this;
    }

    /++
    Enlarges the image by a factor.

    Params:
        k = factor.
    +/
    Image scale(float k)
    {
        uint newWidth = cast(uint) ((cast(float) _width) * k);
        uint newHeight = cast(uint) ((cast(float) _height) * k);

        return resize(newWidth,newHeight);
    }

    /// Dynamic copy of the image.
    @property Image dup() => imageFrom(this.pixels.dup, _width, _height);
    
    /// Free image data.
    void freeData() @trusted
    {
        import core.memory;

        destroy(pixeldata);
        pixeldata = null;
        _width = 0;
        _height = 0;
    }

    ~this()
    {
        this.freeData();
    }
}

unittest
{
    Image image = new Image(32, 32);

    assert(image.bytes!(PixelFormat.RGBA)
        .validateImageData!(PixelFormat.RGBA)(image.width, image.height));
}

alias invert = (x, y, ref e) => e = e.inverted;
alias grayscaled = (x, y, ref e) => e = e.toGrayscale;
alias changeLightness(float factor) = (x, y, ref e) 
{ 
    immutable alpha = e.alpha;
    e = (e * factor);
    e.a = alpha;
};

template process(alias fun)
{
    void process(Image image) @safe nothrow pure
    {
        foreach (size_t index, ref Color!ubyte pixel; image.pixels)
        {
            immutable y = index / image.width;
            immutable x = index - (y * image.width);

            fun(x, y, pixel);
        }
    }
}

/++
Rotate the picture by the specified angle from the specified center.

Params:
    image = The picture to be rotated.
    angle = Angle of rotation.
    center =    Center of rotation.
                (If the vector is empty (non-zero `vecfNan`), then the
                center is determined automatically).
+/
Image rotateImage(int Type = WithoutParallel)(Image image, float angle, Vecf center = vecfNaN) @safe
{
    import tida.angle;
    import std.conv : to;

    Image rotated = new Image(image.width, image.height);
    rotated.fill(rgba(0, 0, 0, 0));

    if (center.isVecfNaN)
        center = Vecf(image.width / 2, image.height / 2);

    foreach (x, y; Coord!Type(image.width, image.height))
    {
        auto pos = Vecf(x,y)
            .rotate(angle, center);

        auto colorpos = image.getPixel(x,y);

        rotated.setPixel(pos.x.to!int, pos.y.to!int, colorpos);
    }

    return rotated;
}

enum XAxis = 0; /// X-Axis operation.
enum YAxis = 1; /// Y-Axis operation.

/++
Checks the axis for correctness.
+/
template isValidAxis(int axistype)
{
    enum isValidAxis = axistype == XAxis || axistype == YAxis;
}

/++
Reverses the picture along the specified axis.

Example:
---
image
    .flip!XAxis
    .flip!YAxis;
---
+/
template flipImpl(int axis)
{
    static if (axis == XAxis)
    {
        Image flipImpl(Image image) @trusted nothrow pure
        {
            import std.algorithm : joiner, map;

            return image.scanlines
                .map!(e => e.reversed)
                .joiner
                .imageFrom(image.width, image.height);

        }
    } else
    static if (axis == YAxis)
    {
        Image flipImpl(Image image) @trusted nothrow pure
        {
            import std.algorithm : reverse, joiner;

            return image
                .scanlines
                .reversed
                .joiner
                .imageFrom(image.width, image.height);
        }   
    }
}

alias flip = flipImpl;

alias flipX = flipImpl!XAxis;
alias flipY = flipImpl!YAxis;

/++
Save image in file.

Params:
    image = Image.
    path = Path to the file.
+/
void saveImageInFile(Image image, string path) @trusted
in(!image.empty, "The image can not be empty!")
do
{
    import imagefmt;
    import tida.color;

    write_image(path, image.width, image.height, image.bytes!(PixelFormat.RGBA), 4);
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
Image[] strip(Image image, int x, int y, int w, int h) @safe
{
    import std.algorithm : map;
    import std.range : iota, array;

    return iota(0, image.width / w)
        .map!(e => image.copy(e * w, y, w, h))
        .array;
}

/++
Combining two paintings into one using color mixing.

Params:
    a = First image.
    b = Second image.
    posA = First image position.
    posB = Second image position.
+/
Image unite(int Type = WithoutParallel)(Image a,
                                        Image b,
                                        Vecf posA = vecf(0, 0),
                                        Vecf posB = vecf(0, 0)) @trusted
{
    import std.conv : to;
    import tida.color;

    Image result = new Image();

    int width = int.init,
        height = int.init;

    width = (posA.x + a.width > posB.x + b.width) ? posA.x.to!int + a.width : posB.x.to!int + b.width;
    height = (posA.y + a.height > posB.y + b.height) ? posA.y.to!int + a.height : posB.x.to!int + b.height;

    result.allocatePlace(width, height);
    result.fill(rgba(0, 0, 0, 0));

    foreach (x, y; Coord!Type(  posA.x.to!int + a.width, posA.y.to!int + a.height,
                                posA.x.to!int, posA.y.to!int))
    {
        Color!ubyte color = a.getPixel(x - posA.x.to!int, y - posA.y.to!int);
        result.setPixel(x,y,color);
    }

    foreach (x, y; Coord!Type(  posB.x.to!int + b.width, posB.y.to!int + b.height,
                                posB.x.to!int, posB.y.to!int))
    {
        Color!ubyte color = b.getPixel(x - posB.x.to!int, y - posB.y.to!int);
        Color!ubyte backColor = result.getPixel(x, y);
        color = color.BlendAlpha!ubyte(backColor);
        result.setPixel(x, y, color);
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
float[][] gausKernel(int width, int height, float sigma) @safe nothrow pure
{
    import std.math : exp, PI;

    float[][] result = new float[][](width, height);

    float sum = 0f;

    foreach (i; 0 .. height)
    {
        foreach (j; 0 .. width)
        {
            result[j][i] = exp(-(i * i + j * j) / (2 * sigma * sigma) / (2 * PI * sigma * sigma));
            sum += result[j][i];
        }
    }

    foreach (i; 0 .. height)
    {
        foreach (j; 0 .. width)
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
Image blur(int Type = WithoutParallel)(Image image, float r) @safe
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
Image blur(int Type = WithoutParallel)(Image image, int width, int height, float r) @safe
{
    return blur!Type(image, gausKernel(width, height, r));
}

/++
Applies blur.

Params:
    Type = Operation type.
    image = Image.
    otherKernel = Filter kernel.
+/
Image blur(int Type = WithoutParallel)(Image image, float[][] otherKernel) @trusted
{
    import tida.color;

    auto kernel = otherKernel; 
    
    int width = image.width;
    int height = image.height;

    int kernelWidth = cast(int) kernel.length;
    int kernelHeight = cast(int) kernel[0].length;

    Image result = new Image(width,height);
    result.fill(rgba(0,0,0,0));

    foreach (x, y; Coord!Type(width, height))
    {
        Color!ubyte color = rgb(0,0,0);

        foreach (ix,iy; Coord(kernelWidth, kernelHeight))
        {
            color = color + (image.getPixel(x - kernelWidth / 2 + ix,y - kernelHeight / 2 + iy) * (kernel[ix][iy]));
        }

        color.a = image.getPixel(x,y).a;
        result.setPixel(x,y,color);
    }

    return result;
}