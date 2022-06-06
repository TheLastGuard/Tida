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
import tida.render;
import tida.graphics.gapi;
import std.traits : ReturnType;
import std.range : isInputRange, ElementType;

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

interface InputIterateRange
{
    Color!ubyte index(uint x, uint y) @safe;

    @property uint width() @safe;

    @property uint height() @safe;
}

enum bool isInputIterate(R) =
    is(typeof(R.index(uint.init, uint.init)) == Color!ubyte) &&
    is(ReturnType!((R r) => r.width) == uint) &&
    is(ReturnType!((R r) => r.height) == uint);

void eachedInputIterate(Iterate, alias pred)(
    Iterate iterate
) @safe
if (isInputIterate!Iterate)
{
    foreach (y; 0 .. iterate.height)
    {
        foreach(x; 0 .. iterate.width)
        {
            pred(x, y, iterate.index(x, y));
        }
    }
}

auto dataImageIterate(Iterate)(Iterate iterate) @safe
if (isInputIterate!Iterate)
{
    Color!ubyte[] pixels;
    pixels.length = iterate.width * iterate.height;

    eachedInputIterate!(Iterate, (x, y, e) {
        pixels[(iterate.width * y) + x] = e;
    })(iterate);

    return pixels;
}

auto toImageIterate(Range)(Range range, uint width, uint height) @safe
{
    import std.range : array;

    auto pixels = range.array;

    static struct InputIterate
    {
        Color!ubyte[] pixels;
        uint width;
        uint height;

        Color!ubyte index(uint x, uint y) @safe
        {
            return pixels[(width * y) + x];
        }
    }

    static assert(isInputIterate!InputIterate);

    return InputIterate(pixels, width, height);
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

    return elements;
}

/++
Converts a sequence of colors to a picture from the input range.

Params:
    range = Sequence of colors.
    width = Image width.
    height = Image height.
    
Returns:
    A picture to be converted from a set of colors.
+/
Image imageFrom(Range)(Range range, uint width, uint height) @trusted nothrow pure
if (isInputRange!Range)
{
    import std.range : array;

    Image image = new Image(width, height);

    static if (is(ElementType!Range == ubyte))
        image.bytes!(PixelFormat.RGBA)(range.array);
    else
    static if (is(ElementType!Range == Color!ubyte))
        image.pixeldata = range.array;

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
    import tida.matrix;

private:
    Color!ubyte[] pixeldata;
    uint _width;
    uint _height;

public:
    ITexture texture;

    IBuffer arrayBuffer,
            elementBuffer;
    uint elementCount;
    IVertexInfo vertexInfo;
    ModeDraw mode = ModeDraw.triangle;

    void toTexture() @trusted
    {
        import tida.game : renderer;

        texture = renderer.api.createTexture(TextureType.twoDimensional);
        texture.append(pixeldata, _width, _height);

        texture.filter(TextureFilter.magFilter, TextureFilterValue.nearest);
        texture.filter(TextureFilter.minFilter, TextureFilterValue.nearest);

        texture.wrap(TextureWrap.wrapS, TextureWrapValue.clampToEdge);
        texture.wrap(TextureWrap.wrapT, TextureWrapValue.clampToEdge);

        texture.active(0);

        arrayBuffer = renderer.api.createBuffer(BufferType.array);
        arrayBuffer.bindData([
            0f, 0f,          0f, 0f,
            _width, 0f,      1f, 0f,
            _width, _height, 1f, 1f,
            0f, _height,     0f, 1f
        ]);

        elementBuffer = renderer.api.createBuffer(BufferType.element);
        elementBuffer.bindData([0, 1, 2, 0, 2, 3]);
        elementCount = 6;

        vertexInfo = renderer.api.createVertexInfo();
        vertexInfo.bindBuffer(arrayBuffer);
        vertexInfo.bindBuffer(elementBuffer);
        vertexInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 4 * float.sizeof, 0),
            AttribPointerInfo(1, 2, TypeBind.Float, 4 * float.sizeof, 2 * float.sizeof)
        ]);
    }

    enum vertexShaderSource = "#version 450

    layout(location = 0) in vec2 positions;
    layout(location = 1) in vec2 texCoord;

    uniform mat4 projection;
    uniform mat4 model;

    layout(location = 0) out vec2 outTexCoord;

    void main() {
        gl_Position = projection * model * vec4(positions, 0.0, 1.0);
        outTexCoord = texCoord;
    }";

    enum fragmentShaderSource = "#version 450

    layout(location = 0) in vec2 outTexCoord;

    uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    uniform sampler2D texture0;

    layout(location = 0) out vec4 outColor;

    void main() {
        outColor = texture(texture0, outTexCoord) * color;
    }";

    IShaderProgram initShader(IRenderer render) @safe
    {
        if (render.currentShader !is render.mainShader)
            return render.currentShader;

        if (render.getShader("DefaultTexture") is null)
        {
            IShaderManip vertex = render.api.createShader(StageType.vertex);
            IShaderManip fragment = render.api.createShader(StageType.fragment);

            IShaderProgram program = render.api.createShaderProgram();

            vertex.loadFromSource(vertexShaderSource);
            fragment.loadFromSource(fragmentShaderSource);

            program.attach(vertex);
            program.attach(fragment);
            program.link();

            render.setShader("DefaultTexture", program);

            return program;
        } else
            return render.getShader("DefaultTexture");
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        assert(texture);

        IShaderProgram shader = initShader(render);

        render.api.bindProgram(shader);
        render.api.bindVertexInfo(vertexInfo);
        render.api.bindTexture(texture);

        render.api.begin();

        shader.setUniform(
            shader.getUniformID("projection"),
            (cast(Render) render).projection
        );

        shader.setUniform(
            shader.getUniformID("model"),
            render.currentModelMatrix.translate(position.x, position.y, 0f)
        );

        shader.setUniform(
            shader.getUniformID("texture0"),
            0
        );

        if (elementBuffer !is null)
            render.api.drawIndexed(mode, elementCount);
        else
            render.api.draw(mode, 0, elementCount);

        render.resetShader();
        render.resetModelMatrix();
    }

    override void drawEx(
        IRenderer render,
        Vecf position,
        float angle,
        Vecf center,
        Vecf size,
        ubyte alpha,
        Color!ubyte color = rgb(255, 255, 255)
    ) @safe
    {
        assert(texture);

        IShaderProgram shader = initShader(render);

        color.a = alpha;

        Vecf realSize = size.isVectorNaN!float ?
            vecf(1f, 1f) :
            vecf(
                size.x / _width,
                size.y / _height
            );

        center = center.isVectorNaN!float ?
            vecf(_width / 2, _height / 2) * realSize :
            center;

        render.api.bindProgram(shader);
        render.api.bindVertexInfo(vertexInfo);
        render.api.bindTexture(texture);

        render.api.begin();

        shader.setUniform(
            shader.getUniformID("projection"),
            (cast(Render) render).projection
        );

        shader.setUniform(
            shader.getUniformID("model"),
            render
                .currentModelMatrix
                .scale(realSize.x, realSize.y)
                .translate(-center.x, -center.y, 0f)
                .rotateMat(angle, 0f, 0f, 1f)
                .translate(center.x, center.y, 0f)
                .translate(position.x, position.y, 0f)
        );

        shader.setUniform(
            shader.getUniformID("texture0"),
            0
        );

        shader.setUniform(
            shader.getUniformID("color"),
            [color.rf, color.gf, color.bf, color.af]
        );

        if (elementBuffer !is null)
            render.api.drawIndexed(mode, elementCount);
        else
            render.api.draw(mode, 0, elementCount);

        render.resetShader();
        render.resetModelMatrix();
    }

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
    void blit(Range)(Range otherImage, Vecf position) @trusted
    if(isInputIterateRange!Range)
    {
        import std.conv : to;
        import std.algorithm : each;

        uint x = 0;
        uint y = 0;

        foreach (e; otherImage)
        {
            x++;

            if (x == otherImage.width)
            {
                x = 0;
                y++;
            }

            setPixel(x, y, e);
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
    auto copy(int x, int y, int cWidth, int cHeight) @trusted
    {
        import std.algorithm : map, joiner;

        return this.scanlines[y .. y + cHeight]
            .map!(e => e[x .. x + cWidth])
            .joiner
            .imageFrom(width, height);
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

    ref Color!ubyte opIndex(size_t x, size_t y)
    {
        return pixeldata[(width * y) + x];
    }

    /// Image width.
    @property uint width()
    {
        return _width;
    }

    /// Image height.
    @property uint height()
    {
        return _height;
    }

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
    @property Color!ubyte[] pixels()
    {
        return pixeldata;
    }

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

    Color!ubyte[][] scanlines()
    {
        return iota(0, height)
            .map!(e => scanline(e))
            .array;
    }

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
    bool empty()
    {
        return pixeldata.length == 0;
    }

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
    @property Image dup()
    {
        return imageFrom(this.pixels.dup, _width, _height);
    }
    
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

auto rotateImage(Iterate)(Iterate iterate, float angle, Vector!float center = vecNaN!float) @safe
if (isInputIterate!Iterate)
{
    static struct RotateInputIterage
    {
        Iterate iterate;
        float angle;
        Vector!float center;

        Color!ubyte index(uint x, uint y) @safe
        {
            import tida.angle;

            auto pos = vecf(x, y).rotate(angle, center);

            if (pos.x < 0 || pos.y < 0 ||
                pos.x > width || pos.y > height)
                return Color!ubyte(0, 0, 0, 0);

            return iterate.index(cast(uint) pos.x, cast(uint) pos.y);
        }

        uint width() @safe
        {
            return iterate.width;
        }

        uint height() @safe
        {
            return iterate.height;
        }
    }

    return RotateInputIterage(iterate, angle, center);
}

auto flipX(Iterate)(Iterate iterate) @safe
if(isInputIterate!Iterate)
{
    static struct FlipInputIterate
    {
        Iterate iterate;

        Color!ubyte index(uint x, uint y) @safe
        {
            return iterate.index(width - x, y);
        }

        uint width() @safe
        {
            return iterate.width;
        }

        uint height() @safe
        {
            return iterate.height;
        }
    }

    return FlipInputIterate(iterate);
}

auto flipY(Iterate)(Iterate iterate) @safe
if(isInputIterate!Iterate)
{
    static struct FlipInputIterate
    {
        Iterate iterate;

        Color!ubyte index(uint x, uint y) @safe
        {
            return iterate.index(x, height - y);
        }

        uint width() @safe
        {
            return iterate.width;
        }

        uint height() @safe
        {
            return iterate.height;
        }
    }

    return FlipInputIterate(iterate);
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

auto blur(Iterate)(Iterate iterate, float[][] kernel) @safe
{
    static struct BlurInputIterate
    {
        Iterate iterate;
        float[][] kernel;
        size_t kernelWidth;
        size_t kernelHeight;

        this(Iterate iterate, float[][] kernel) @safe
        {
            this.iterate = iterate;
            this.kernel = kernel;

            kernelWidth = kernel.length;
            kernelHeight = kernel[0].length;
        }

        Color!ubyte index(uint x, uint y) @safe
        {
            Color!ubyte color;

            foreach (iy; 0 .. kernelHeight)
            {
                foreach (ix; 0 .. kernelWidth)
                {
                    immutable xPos = cast(uint) (x - kernelWidth / 2 + ix);

                    immutable yPos = cast(uint) (y - kernelHeight / 2 + iy);

                    if (xPos < 0 || yPos < 0 ||
                        xPos >= width || yPos >= height)
                        continue;

                    color = color + iterate.index(xPos, yPos) * kernel[ix][iy];
                }
            }

            return color;
        }

        uint width() @safe
        {
            return iterate.width;
        }

        uint height() @safe
        {
            return iterate.height;
        }
    }

    return BlurInputIterate(iterate, kernel);
}
