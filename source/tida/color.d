/++
    Color description module. Contains a structure for manipulating colors like RGB, there, 
    and other ways to set colors. Mostly the RGB format is used, and the use of other formats 
    will be converted to RGB.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.color;

/// Pixel representation format.
enum PixelFormat : int
{
    AUTO, /// Determine automatically. Are needed only where it is really defined.
    RGB, /// 
    RGBA, ///
    ARGB, ///
    BGRA, ///
    BGR ///
}

int pixelformatGL(PixelFormat pixelformat) @safe nothrow pure
in(pixelformat != PixelFormat.AUTO, "Incorrect pixel format!")
do
{
    import tida.graph.gl;

    if(pixelformat == PixelFormat.RGB) 
        return GL_RGB;
    else
    if(pixelformat == PixelFormat.RGBA)
        return GL_RGBA;
    else
    if(pixelformat == PixelFormat.ARGB)
        assert(null, "Incorrect pixel format!");
    else
    if(pixelformat == PixelFormat.BGRA)
        return GL_BGRA;
    else
    if(pixelformat == PixelFormat.BGR)
        return GL_BGR;

    assert(null, "Incorrect pixel format!");
}

/++
    Is the pixel format correct? That is, it excludes automatic detection.

    Params:
        format = Pixel format.
+/
template isCorrectFormat(int format)
{
    enum isCorrectFormat = format != PixelFormat.AUTO && format <= PixelFormat.max;
}

/++
    Returns the number of bits per color unit.

    Params:
        format = Pixel format.
+/
template BytesPerColor(int format)
{
    static assert(isCorrectFormat!format, "This pixel format is incorrect!");

    static if(format == PixelFormat.RGB || format == PixelFormat.BGR)
        enum BytesPerColor = 3;
    else
        enum BytesPerColor = 4;
}

enum Alpha = 0; /// With alpha blending applied.
enum NoAlpha = 1; /// No alpha blending applied.

/++
    Converts grayscale to the library's standard color scheme.

    Params:
        value = Grayscale value.

    Example:
    ---
    auto color = grayscale(128);
    ---

    Returns: RGBA
+/
Color!ubyte grayscale(ubyte value) @safe nothrow pure
{
    return rgba(value,value,value,255);
}

/++
    Creates an RGB color.

    Params:
        red = Red.
        green = Green.
        blue = Blue. 

    Returns: RGBA
+/
Color!ubyte rgb(ubyte red,ubyte green,ubyte blue) @safe nothrow pure
{
    return Color!ubyte(red,green,blue,255);
}

/++
    Creates an RGBA color.

    Params:
        red = Red.
        green = Green.
        blue = Blue. 
        alpha = Alpha.

    Returns: RGBA
+/
Color!ubyte rgba(ubyte red,ubyte green,ubyte blue,ubyte alpha) @safe nothrow pure
{
    return Color!ubyte(red,green,blue,alpha);
}

/++
    Recognizes a hex format string, converting it to RGBA representation as a `Color!ubyte` structure.

    Params:
        hex = The same performance. The following formats can be used:
              * `0xRRGGBBAA` / `0xRRGGBB`
              * `#RRGGBBAA` / `#RRGGBB`
        format = Pixel format.

    Returns: `Color!ubyte`
+/
Color!ubyte HEX(int format = PixelFormat.AUTO,T)(T hex) @safe
{
    static if(is(T : string) || is(T : wstring) || is(T : dstring))
    {
        import std.conv : to;
        import std.bigint;

        size_t cv = 0;
        if(hex[0] == '#') cv++;
        else if(hex[0 .. 2] == "0x") cv += 2;

        static if(format == PixelFormat.AUTO) {
            const alpha = hex[cv .. $].length > 6;

            return rgba(
                BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte,
                alpha ? BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte : 255
            );
        }else
        static if(format == PixelFormat.RGB) {
            return rgb(
                BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte
            );
        }else
        static if(format == PixelFormat.RGBA) {
            assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

            return rgba(
                BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte
            );
        }else
        static if(format == PixelFormat.ARGB) {
            assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

            return rgba(
                BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte,
                BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte
            );
        }else
        static if(format == PixelFormat.BGRA) {
            assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

            return rgba(
                BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
                BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte
            );
        }else
        static if(format == PixelFormat.BGR) {
            return rgb(
                BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte,
                BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
                BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte);
        }else
            static assert(null,"Unknown pixel format");
    }else
    static if(is(T : int) || is(T : long) || is(T : uint) || is(T : ulong))
    {
        Color!ubyte result;
	
        static if(format == PixelFormat.RGBA)
        {
            result.r = (hex & 0xFF000000) >> 24;
            result.g = (hex & 0x00FF0000) >> 16;
            result.b = (hex & 0x0000FF00) >> 8;
            result.a = (hex & 0x000000FF);
        	
            return result;
        }else
        static if(format == PixelFormat.RGB)
        {
            result.r = (hex & 0xFF0000) >> 16;
            result.g = (hex & 0x00FF00) >> 8;
            result.b = (hex & 0x0000FF);
            result.a = 255;

            return result;
        }else
        static if(format == PixelFormat.ARGB)
        {
            result.a = (hex & 0xFF000000) >> 24;
            result.r = (hex & 0x00FF0000) >> 16;
            result.g = (hex & 0x0000FF00) >> 8;
            result.b = (hex & 0x000000FF);

            return result;
        }else
        static if(format == PixelFormat.BGRA)
        {
            result.b = (hex & 0xFF000000) >> 24;
            result.g = (hex & 0x00FF0000) >> 16;
            result.r = (hex & 0x0000FF00) >> 8;
            result.a = (hex & 0x000000FF);

            return result;
        }else
        static if(format == PixelFormat.BGR)
        {
            result.b = (hex & 0XFF0000) >> 16;
            result.g = (hex & 0x00FF00) >> 8;
            result.r = (hex & 0x0000FF);
        }else
        static if(format == PixelFormat.AUTO) {
            return HEX!(PixelFormat.RGB, T)(hex);
        }else
            static assert(null, "Unknown pixel format!");
    }else
        static assert(null, "Unknown type hex!");
}

unittest
{
    assert(HEX(0xFFFFFF) == rgb(255, 255, 255));
    assert(HEX("#f9004c") == rgb(249, 0, 76));
}

/// HSL color structure
struct HSL
{
    public
    {
        float hue; ///
        float saturation; ///
        float lightness; ///

        alias h = hue;
        alias s = saturation;
        alias l = lightness;
    }

    T to(T)() @safe nothrow pure
    {
        static if(is(T : Color!ubyte))
        {
            ubyte r = 0;
            ubyte g = 0;
            ubyte b = 0;

            immutable hue = h;
            immutable saturation = s / 100;
            immutable lightness = l / 100;

            if(saturation == 0)
            {
                r = g = b = cast(ubyte) (lightness * ubyte.max);
            }
            else
            {
                float HueToRGB(float v1, float v2, float vH) @safe nothrow pure
                {
                    if (vH < 0)
                        vH += 1;

                    if (vH > 1)
                        vH -= 1;

                    if ((6 * vH) < 1)
                        return (v1 + (v2 - v1) * 6 * vH);

                    if ((2 * vH) < 1)
                        return v2;

                    if ((3 * vH) < 2)
                        return (v1 + (v2 - v1) * ((2.0f / 3) - vH) * 6);

                    return v1;
                }

                float v1, v2;
                float _hue = cast(float) hue / 360;

                v2 = (lightness < 0.5) ? (lightness * (1 + saturation)) : ((lightness + saturation) - (lightness * saturation));
                v1 = 2 * lightness - v2;

                r = cast(ubyte) (255 * HueToRGB(v1, v2, _hue + (1.0f / 3)));
                g = cast(ubyte) (255 * HueToRGB(v1, v2, _hue));
                b = cast(ubyte) (255 * HueToRGB(v1, v2, _hue - (1.0f / 3)));
            }

            return rgb(r, g, b);
        }else
            static assert(null, "Unknown format color!");
    }
}

alias HSV = HSB;

/// HSB color structure 
struct HSB
{
    public
    {
        float hue; /// 
        float saturation; ///
        float brightness; ///
        alias value = brightness;

        alias h = hue;
        alias s = saturation;
        alias b = brightness;
        alias v = value;
    }

    T to(T)() @safe nothrow pure
    {
        static if(is(T : Color!ubyte))
        {
            import std.math : trunc;

            double r = 0, g = 0, b = 0;

            double hue = h;
            immutable saturation = saturation / 100;
            immutable value = v / 100;

            if (saturation == 0)
            {
                r = value;
                g = value;
                b = value;
            }
            else
            {
                int i;
                double f, p, q, t;

                if (hue == 360)
                    hue = 0;
                else
                    hue = hue / 60;

                i = cast(int) trunc(hue);
                f = hue - i;

                p = value * (1.0 - saturation);
                q = value * (1.0 - (saturation * f));
                t = value * (1.0 - (saturation * (1.0 - f)));

                switch (i)
                {
                    case 0:
                        r = value;
                        g = t;
                        b = p;
                    break;

                    case 1:
                        r = q;
                        g = value;
                        b = p;
                    break;

                    case 2:
                        r = p;
                        g = value;
                        b = t;
                    break;

                    case 3:
                        r = p;
                        g = q;
                        b = value;
                    break;

                    case 4:
                        r = t;
                        g = p;
                        b = value;
                    break;

                    default:
                        r = value;
                        g = p;
                        b = q;
                    break;
                }

            }

            return rgb(cast(byte) (r * 255), cast(byte) (g * 255), cast(byte) (b * 255));
        }else
            static assert(null, "Unknown format color!");
    }
}

/++
    Will change the byte sequence to color.

    Params:
        format = Pixel format.
        bytes = byte sequence.
+/
Color!ubyte fromColor(int format)(ubyte[] bytes) @safe nothrow pure
{
    bytes = bytes.fromFormat!(format,PixelFormat.RGBA);

    return rgba(bytes[0],bytes[1],bytes[2],bytes[3]);
}

/++
    Will change the sequence of bytes into a collection of colors.

    Params:
        format = Pixel format.
        bytes = byte sequence.
+/
Color!ubyte[] fromColors(int format)(ubyte[] bytes) @safe nothrow pure
{
    Color!ubyte[] result;

    for(size_t i = 0; i < bytes.length; i += BytesPerColor!format)
    {
        result ~= bytes[i .. i + BytesPerColor!format].fromColor!(format);
    }

    return result;
}

unittest
{
    assert([130, 20, 65, 255].fromColor!(PixelFormat.RGBA) == rgba(130, 20, 65, 255));

    auto result = [130, 20, 65, 255, 45, 50].fromColors!(PixelFormat.RGB);

    assert(result[0] == rgb(130, 20, 65));
    assert(result[1] == rgb(255, 45, 50));

    assert([65, 20, 130, 255].fromColor!(PixelFormat.BGRA) == rgba(130, 20, 65, 255));
}

/// Color description structure.
struct Color(T)
{
    public
    {
        T red; /// Red component
        T green; /// Green component
        T blue; /// Blue component
        T alpha; /// Alpha cpmponent

        alias r = red;
        alias g = green;
        alias b = blue;
        alias a = alpha;
    }

    ///
    this(T red,T green,T blue,T alpha = T.max) @safe nothrow pure
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
    }

    /++
        Converts a color to the specified type and format.

        Params:
            T = Type.
            format = Pixel format.
    +/
    R to(R,int format = PixelFormat.RGBA)() @safe nothrow pure inout
    {
        static if(is(R : ulong) || is(R : uint))
        {
            static if(!isInterim!T)
            {
                static if(format == PixelFormat.RGBA)
                    return cast(R) (((r & 0xff) << 24) + ((g & 0xff) << 16) + ((b & 0xff) << 8) + (a & 0xff));
                else
                static if(format == PixelFormat.RGB)
                    return cast(R) ((r & 0xff) << 16) + ((g & 0xff) << 8) + ((b & 0xff));
                else
                static if(format == PixelFormat.ARGB)
                    return cast(R) (((a & 0xff) << 24) + ((r & 0xff) << 16) + ((g & 0xff) << 8) + (b & 0xff));
                else
                static if(format == PixelFormat.BGRA)
                    return cast(R) (((b & 0xff) << 24) + ((g & 0xff) << 16) + ((r & 0xff) << 8) + (a & 0xff));
                else
                static if(format == PixelFormat.BGR)
                    return cast(R) (((b & 0xff) << 16) + ((g & 0xff) << 8) + ((r & 0xff)));
                else
                    return 0;
            }else
                return 0;
        }else
        static if(is(R : string))
        {
            import std.conv : to;
            import std.digest : toHexString;
            
            static if(!isInterim!T)
                return cast(R) this.fromBytes!format.toHexString;
            else
                return stringComponents();
        }else
        static if(is(R : HSL))
        {
            import std.algorithm : max, min;
            import std.math : abs;

            HSL hsl;

            float rd = rf();
            float gd = gf();
            float bd = bf();

            float fmax = max(rd, gd, bd);
            float fmin = min(rd, gd, bd);

            hsl.l = abs(50 * (fmin - fmax));

            if(fmin == fmax) {
                hsl.s = 0;
                hsl.h = 0;
            }else
            if(hsl.l < 50) {
                hsl.s = 100 * (fmax - fmin) / (fmax + fmin);
            }else
            {
                hsl.s = 100 * (fmax - fmin) / (2.0 - fmax - fmin);
            }

            if(fmax == rd) {
                hsl.h = 60 * (gd - bd) / (fmax - fmin);
            }
            if(fmax == gd) {
                hsl.h = 60 * (gd - rd) / (fmax - fmin) + 120;
            }
            if(fmax == bd) {
                hsl.h = 60 * (rd - gd) / (fmax - fmin) + 240;
            }

            if(hsl.h < 0) {
                hsl.h = hsl.h + 360;
            }

            return hsl;
        }
    }

    /// Converts color to monochrome. In particular, it will return the luminance number.
    T toGrayscale() @safe nothrow pure inout
    {
        return cast(T) (this.toGrayscalef() * T.max);
    }

    ///Converts color to monochrome. In particular, it will return a luminance number between 0 and 1.
    float toGrayscalef() @safe nothrow pure inout
    {
        return (rf * 0.299 + gf * 0.587 + bf * 0.144);
    }

    /// Whether the color is dark.
    bool isDark() @safe nothrow pure inout
    {
        return (toGrayscalef < 0.5f);
    }

    /// Whether the color is light.
    bool isLight() @safe nothrow pure inout
    {
        return (toGrayscalef > 0.5f);
    }

    /++
        Returns a string with color components as:
        `rgba(%r,%g,%b,%a)`
    +/
    string stringComponents() @safe
    {
        import std.conv : to;

        return "rgba("~r.to!string~","~g.to!string~","~b.to!string~","~a.to!string~")";
    }

    /++
        Returns a string with color components as:
        `rgba(%r,%g,%b,%a)`, 
        but with coloring in the appropriate text color.
    +/
    string formatString() @safe
    {
        import std.conv : to;
    
        return "\x1b[38;2;"~red.to!string~";"~green.to!string~";"~blue.to!string~"m" ~ stringComponents() ~ "\u001b[0m";
    }
    
    ///
    string toString() @safe
    {
        return stringComponents();
    }

    ///
    T[] fromBytes(int format)() @safe nothrow pure inout
    {
        static if(format == PixelFormat.RGBA)
            return [r,g,b,a];
        else
        static if(format == PixelFormat.RGB)
            return [r,g,b];
        else
        static if(format == PixelFormat.ARGB)
            return [a,r,g,b];
        else
        static if(format == PixelFormat.BGRA)
            return [b,g,r,a];
        else
        static if(format == PixelFormat.BGR)
            return [b,g,r];
        else
            return [];
    }

    auto mulf(float koe) @safe nothrow pure
    {
        r = cast(T) ((rf * koe) * T.max);
        g = cast(T) ((gf * koe) * T.max);
        b = cast(T) ((bf * koe) * T.max);

        return this;
    }

    auto mul(float koe) @safe nothrow pure
    {
        import std.conv : to;

        r = cast(T) ((r.to!float * koe)); 
        g = cast(T) ((g.to!float * koe)); 
        b = cast(T) ((b.to!float * koe)); 

        return this;
    }

    /// Clone structure
    Color!T dup() @safe nothrow pure inout
    {
        return Color!T(r, g, b, a);
    }

    Color!T opBinary(string op)(float koe) @safe nothrow pure
    {
        import std.conv : to;

        static if(op == "+")
            return Color!T( cast(T) (r + koe),
                            cast(T) (g + koe),
                            cast(T) (b + koe),
                            cast(T) (a + koe));
        else
        static if(op == "-")
            return Color!T( cast(T) (r - koe),
                            cast(T) (g - koe),
                            cast(T) (b - koe),
                            cast(T) (a - koe));
        else
        static if(op == "*")
            return Color!T( cast(T) (r * koe),
                            cast(T) (g * koe),
                            cast(T) (b * koe),
                            cast(T) (a * koe));
        else
        static if(op == "/")
            return Color!T( cast(T) (r / koe),
                            cast(T) (g / koe),
                            cast(T) (b / koe),
                            cast(T) (a / koe));
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    Color!T opBinary(string op)(Color!T color) @safe nothrow pure
    {
        static if(op == "+") {
            return Color!T( cast(T) (r + color.r),
                            cast(T) (g + color.g),
                            cast(T) (b + color.b),
                            cast(T) (a + color.a));
        }
        else
        static if(op == "-")
            return Color!T( cast(T) (r - color.r),
                            cast(T) (g - color.g),
                            cast(T) (b - color.b),
                            cast(T) (a - color.a));
        else
        static if(op == "*")
            return Color!T( cast(T) r * color.r,
                                    g * color.g,
                                    b * color.b,
                                    a * color.a);
        else
        static if(op == "/")
            return Color!T( cast(T) r / color.r,
                                    g / color.g,
                                    b / color.b,
                                    a / color.a);
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    /// Will return the color opposite to itself.
    Color!T inverted() @safe nothrow pure
    {
        return Color!T(T.max - r, T.max - g, T.max - b, a);
    }

    T invertAlpha() @safe nothrow pure inout
    {
        return T.max - alpha;
    }

    /// Returns a red value in the form of a range from 0 to 1.
    float rf() @safe @property nothrow pure inout
    {
        return cast(float) r / cast(float) T.max;
    }

    void rf(float value) @safe @property nothrow pure
    {
        this.r = cast(T) (T.max * value);
    }

    /// Returns a green value in the form of a range from 0 to 1.
    float gf() @safe @property nothrow pure inout
    {
        return cast(float) g / cast(float) T.max;
    }

    void gf(float value) @safe @property nothrow pure
    {
        this.g = cast(T) (T.max * value);
    }

    /// Returns a alpha value in the form of a range from 0 to 1.
    float bf() @safe @property nothrow pure inout
    {
        return cast(float) b / cast(float) T.max;
    }

    void bf(float value) @safe @property nothrow pure
    {
        this.b = cast(T) (T.max * value);
    }

    /// Returns a alpha value in the form of a range from 0 to 1.
    float af() @safe @property nothrow pure inout
    {
        return cast(float) a / cast(float) T.max;
    }

    void af(float value) @safe @property nothrow pure
    {
        this.a = cast(T) (T.max * value);
    }
}

alias FInterim = float;

template isInterim(T)
{
    enum isInterim = is(T : FInterim);
}

Color!FInterim toInterim(T)(Color!T color) @safe nothrow pure
{
    return Color!FInterim(color.rf, color.gf, color.bf, color.af);
}

Color!T fromInterim(T)(Color!FInterim color) @safe nothrow pure
{
    return Color!T  (
                        cast(T) (color.r * T.max),
                        cast(T) (color.g * T.max),
                        cast(T) (color.b * T.max),
                        cast(T) (color.a * T.max)
                    );
}

Color!T mix(T)(Color!T orig, Color!T color) @safe nothrow pure
{
    Color!T result;

    result.rf = (color.rf * orig.rf * T.max);
    result.gf = (color.gf * orig.gf * T.max);
    result.bf = (color.bf * orig.bf * T.max);

    return result;
}

enum BlendFactor
{
    Zero,
    One,
    SrcColor,
    OneMinusSrcColor,
    DstColor,
    OneMinusDstColor,
    SrcAlpha,
    OneMinusSrcAlpha,
    DstAlpha,
    OneMinusDstAlpha,
    ConstantColor,
    OneMinusConstantColor,
    ConstantAlpha,
    OneMinusConstanceAlpha
}

int factorGL(BlendFactor factor) @safe nothrow pure
{
    import tida.graph.gl;

    if(factor == BlendFactor.Zero) 
        return GL_ZERO;
    else
    if(factor == BlendFactor.One)
        return GL_ONE;
    else
    if(factor == BlendFactor.SrcColor)
        return GL_SRC_COLOR;
    else
    if(factor == BlendFactor.OneMinusSrcColor)
        return GL_ONE_MINUS_SRC_COLOR;
    else
    if(factor == BlendFactor.DstColor)
        return GL_DST_COLOR;
    else
    if(factor == BlendFactor.OneMinusDstColor)
        return GL_ONE_MINUS_DST_COLOR;
    else
    if(factor == BlendFactor.SrcAlpha)
        return GL_SRC_ALPHA;
    else
    if(factor == BlendFactor.OneMinusSrcAlpha)
        return GL_ONE_MINUS_SRC_ALPHA;
    else
    if(factor == BlendFactor.DstAlpha)
        return GL_DST_ALPHA;
    else
    if(factor == BlendFactor.OneMinusDstAlpha)
        return GL_ONE_MINUS_DST_ALPHA;

    assert(0, "Unknown blend factor!");
}

Color!T BlendImpl(int fac1, int fac2, T)(Color!T orig, Color!T color) @safe nothrow pure
{
    if(orig.a == 0) return color;
    if(orig.a == T.max) return orig;

    Color!FInterim origf = orig.toInterim;
    Color!FInterim colorf = color.toInterim;

    Color!FInterim srcf, drtf;

    // Factory 1
    static if(fac1 == BlendFactor.Zero)
        srcf = Color!FInterim(0.0f, 0.0f, 0.0f, 0.0f);
    else
    static if(fac1 == BlendFactor.One)
        srcf = Color!FInterim(1.0f, 1.0f, 1.0f, 1.0f);
    else
    static if(fac1 == BlendFactor.SrcColor)
        srcf = Color!FInterim(origf.r, origf.g, origf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.OneMinusSrcAlpha)
        srcf = Color!FInterim(1.0f - origf.r, 1.0f - origf.g, 1.0f - origf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.DstColor)
        srcf = Color!FInterim(colorf.r, colorf.g, colorf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.OneMinusDstColor)
        srcf = Color!FInterim(1.0f - colorf.r, 1.0f - colorf.g, 1.0f - colorf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.SrcAlpha)
        srcf = Color!FInterim(origf.a, origf.a, origf.a, origf.a);
    else
    static if(fac1 == BlendFactor.OneMinusSrcAlpha)
        srcf = Color!FInterim(1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a);
    else
    static if(fac1 == BlendFactor.DstAlpha)
        srcf = Color!FInterim(colorf.a, colorf.a, colorf.a, colorf.a);
    else
    static if(fac1 == BlendFactor.OneMinusDstAlpha)
        srcf = Color!FInterim(1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a);

    // Factory 2
    static if(fac2 == BlendFactor.Zero)
        drtf = Color!FInterim(0.0f, 0.0f, 0.0f, 0.0f);
    else
    static if(fac2 == BlendFactor.One)
        drtf = Color!FInterim(1.0f, 1.0f, 1.0f, 1.0f);
    else
    static if(fac2 == BlendFactor.SrcColor)
        drtf = Color!FInterim(origf.r, origf.g, origf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.OneMinusSrcAlpha)
        drtf = Color!FInterim(1.0f - origf.r, 1.0f - origf.g, 1.0f - origf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.DstColor)
        drtf = Color!FInterim(colorf.r, colorf.g, colorf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.OneMinusDstColor)
        drtf = Color!FInterim(1.0f - colorf.r, 1.0f - colorf.g, 1.0f - colorf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.SrcAlpha)
        drtf = Color!FInterim(origf.a, origf.a, origf.a, origf.a);
    else
    static if(fac2 == BlendFactor.OneMinusSrcAlpha)
        drtf = Color!FInterim(1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a);
    else
    static if(fac2 == BlendFactor.DstAlpha)
        drtf = Color!FInterim(colorf.a, colorf.a, colorf.a, colorf.a);
    else
    static if(fac2 == BlendFactor.OneMinusDstAlpha)
        drtf = Color!FInterim(1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a);

    return fromInterim!T ((origf * srcf) + (colorf * drtf));
}

alias BlendAlpha(T) = BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, T);
alias BlendAdd(T) = BlendImpl!(BlendFactor.One, BlendFactor.One, T);
alias BlendMultiply(T) = BlendImpl!(BlendFactor.DstColor, BlendFactor.Zero, T);
alias BlendSrc2DST(T) = BlendImpl!(BlendFactor.SrcColor, BlendFactor.One, T);
alias BlendAddMul(T) = BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.One, T);
alias BlendAddAlpha(T) = BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.One, T);

alias FuncBlend(T) = Color!T function(Color!T,Color!T) @safe nothrow pure;

FuncBlend!T BlendFunc(T)(int fac1, int fac2) @trusted nothrow pure
{
    if(fac1 == BlendFactor.Zero) {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.One)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.One, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.One, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.SrcColor)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.OneMinusSrcColor)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.DstColor)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.OneMinusDstColor)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.SrcAlpha)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.OneMinusSrcAlpha)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.DstAlpha)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.OneMinusDstAlpha)
    {
        if(fac2 == BlendFactor.Zero) 
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.Zero, T);
        else
        if(fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.One, T);
        else
        if(fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.SrcColor, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if(fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.DstColor, T);
        else
        if(fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if(fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.SrcAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if(fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.DstAlpha, T);
        else
        if(fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusDstAlpha, T);
    }

    assert(null, "Unknown blend factor's!");
}

unittest
{
    assert(rgb(255, 0, 0).to!int == 0xFF0000FF);
}

bool validateBytes(int format)(inout(ubyte[]) pixels) @safe nothrow pure
{
    return (pixels.length % BytesPerColor!format) == 0;
}

/++
    Converts the format of a sequence of color bytes.
	
    Params:
        format1 = What is the original format.
        format2 = What format should be converted.
        pixels = Sequence of color bytes.
+/
ubyte[] fromFormat(int format1,int format2)(ubyte[] pixels) @safe nothrow pure
in
{
    static assert(isCorrectFormat!format1,"The format cannot be detected automatically!");
    static assert(isCorrectFormat!format2,"The format cannot be detected automatically!");
    assert(validateBytes!format1(pixels),"The input pixels data is incorrect!");
}
out(r; validateBytes!format2(r), "The out pixels data is incorrect!")
do
{
    static if(format1 == format2) return pixels;

    static if(format1 == PixelFormat.RGB)
    {
        static if(format2 == PixelFormat.RGBA)
        {
            ubyte[] result;

            for(size_t i = 3; i <= pixels.length; i += 3)
            {
                result ~= pixels[0 .. i] ~ 255;
            }

            return result;
        }else
        static if(format2 == PixelFormat.ARGB)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 3)
            {
                result ~= pixels[0 .. i] ~ 255;
            }

            return result;
        }else
        static if(format2 == PixelFormat.BGRA)
        {
            import std.algorithm : reverse;

            size_t count = 0;
            ubyte[] result;

            for(size_t i = 3; i <= pixels.length; i += 3)
            {
                result ~= pixels[i - 3 .. i].reverse ~ 255;
            }

            return result;
        }
    }else
    static if(format1 == PixelFormat.RGBA)
    {
        static if(format2 == PixelFormat.RGB)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3];
            }

            return result;
        }else
        static if(format2 == PixelFormat.ARGB)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 3] ~ pixels[i .. i + 3];
            }

            return result;
        }else
        static if(format2 == PixelFormat.BGRA)
        {
            import std.algorithm : reverse;

            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3].reverse ~ pixels[i + 3];
            }

            return result;
        }
    }else
    static if(format1 == PixelFormat.ARGB)
    {
        static if(format2 == PixelFormat.RGB)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 1 .. i + 4];
            }

            return result;
        }else
        static if(format2 == PixelFormat.RGBA)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 3] ~ pixels[i .. i + 3];
            }

            return result;
        }else
        static if(format2 == PixelFormat.BGRA)
        {
            import std.algorithm : reverse;

            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result = pixels[i + 3] ~ pixels[i .. i + 3].reverse;
            }

            return result;
        }
    }else
    static if(format1 == PixelFormat.BGRA)
    {
        import std.algorithm : reverse;

        static if(format2 == PixelFormat.RGB)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3].reverse;
            }

            return result;
        }else
        static if(format2 == PixelFormat.RGBA)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3].reverse ~ pixels[i + 3];
            }

            return result;
        }else
        static if(format2 == PixelFormat.ARGB)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 1 .. i + 4].reverse ~ pixels[i];
            }

            return result;
        }
    }
}
