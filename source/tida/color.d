/++
    Color description module. Contains a structure for manipulating colors like RGB, there, 
    and other ways to set colors. Mostly the RGB format is used, and the use of other formats 
    will be converted to RGB.

    Authors: TodNaz
    License: MIT
+/
module tida.color;

/++
    Pixel format. Needed for conversion.
+/
public enum PixelFormat
{
    AUTO,
    RGB,
    RGBA,
    ARGB,
    BGRA
}

/++
    Converts grayscale to the library's standard color scheme.

    Params:
        gsc = Grayscale value.

    Example:
    ---
    auto color = grayscale(128);
    ---

    Returns: RGBA
+/
public Color!ubyte grayscale(ubyte gsc) @safe
{
    return rgb(gsc,gsc,gsc);
}

/++
    Creates an RGB color.

    Params:
        r = Red.
        g = Green.
        b = Blue. 

    Returns: RGBA
+/
public Color!ubyte rgb(ubyte r,ubyte g,ubyte b) @safe
{
    return Color!ubyte(r,g,b,255);
}

/++
    Creates an RGBA color.

    Params:
        r = Red.
        g = Green.
        b = Blue. 
        a = Alpha.

    Returns: RGBA
+/
public Color!ubyte rgba(ubyte r,ubyte g,ubyte b,ubyte a) @safe
{
    return Color!ubyte(r,g,b,a);
}

/++
    Convert HSL to RGBA color.

    Params:
        str = HSL color.

    Returns: RGBA
+/
public Color!ubyte toRGB(HSL str) @safe
{
    ubyte r = 0;
    ubyte g = 0;
    ubyte b = 0;

    immutable hue = str.h;
    immutable saturation = str.s / 100;
    immutable lightness = str.l / 100;

    if(saturation == 0)
    {
        r = g = b = cast(ubyte) (lightness * ubyte.max);
    }
    else
    {
        float HueToRGB(float v1, float v2, float vH) @safe nothrow
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
}

/++
    Convert HSB to RGBA color.

    Params:
        str = HSB color.

    Returns: RGBA
+/
public Color!ubyte toRGB(HSB str) @safe
{
    import std.math : trunc;

    double r = 0, g = 0, b = 0;

    double hue = str.h;
    immutable saturation = str.saturation / 100;
    immutable value = str.v / 100;

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
}

/++
    Recognizes a hex format string, converting it to RGBA representation as a `Color!ubyte` structure.

    Params:
        hex = The same performance. The following formats can be used:
              * `0xRRGGBBAA` / `0xRRGGBB`
              * `#RRGGBBAA` / `#RRGGBB`

    Returns: `Color!ubyte`
+/
public Color!ubyte HEX(string hex,PixelFormat format = PixelFormat.AUTO) @safe
{
    import std.conv : to;
    import std.bigint;

    size_t cv = 0;
    if(hex[0] == '#') cv++;
    else if(hex[0 .. 2] == "0x") cv += 2;

    if(format == PixelFormat.AUTO) {
        const alpha = hex[cv .. $].length > 6;

        return rgba(
            BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte,
            alpha ? BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte : 255
        );
    }else
    if(format == PixelFormat.RGB) {
        return rgb(
            BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte
        );
    }else
    if(format == PixelFormat.RGBA) {
        assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

        return rgba(
            BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte
        );
    }else
    if(format == PixelFormat.ARGB) {
        assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

        return rgba(
            BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 4 .. cv + 6]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte,
            BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte
        );
    }else
    if(format == PixelFormat.BGRA) {
        assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

        return rgba(
            BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 2 .. cv + 4]).toInt().to!ubyte,
            BigInt("0x"~hex[cv .. cv + 2]).toInt().to!ubyte,
            BigInt("0x"~hex[cv + 6 .. cv + 8]).toInt().to!ubyte
        );
    }

    assert(null,"Unknown pixel format");
}

/// HSL color structure
public struct HSL
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
}

alias HSV = HSB;

/// HSB color structure 
public struct HSB
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
}

///
public struct CMYK
{
    public
    {
        float c; ///
        float m; ///
        float y; ///
        float k; ///
    }
}

/++
    Color description structure.
+/
public struct Color(T)
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
    this(T red,T green,T blue,T alpha = T.max) @safe
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
    }

    ///
    this(T[] bytes,PixelFormat format = PixelFormat.RGBA) @safe
    {
        if(format == PixelFormat.RGB) {
            red = bytes[0];
            green = bytes[1];
            blue = bytes[2];
            alpha = T.max;
        }else
        if(format == PixelFormat.RGBA) {
            red = bytes[0];
            green = bytes[1];
            blue = bytes[2];
            alpha = bytes[3];
        }
        else
        if(format == PixelFormat.ARGB) {
            alpha = bytes[0];
            red = bytes[1];
            green = bytes[2];
            blue = bytes[3];
        }
        else 
        if(format == PixelFormat.BGRA) {
            blue = bytes[0];
            green = bytes[1];
            red = bytes[2];
            alpha = bytes[3];
        }
    }

    ///
    this(string hex,PixelFormat format = PixelFormat.AUTO) @safe
    {
        this = HEX(hex,format);
    }

    /++
        Converts a color to the specified type and format.

        Params:
            T = Type.
            format = Pixel format.
    +/
    public T conv(T)(PixelFormat format = PixelFormat.RGBA) @safe
    {
        static if(is(T : ulong) || is(T : uint))
        {
            if(format == PixelFormat.RGBA)
                return ((r & 0xff) << 24) + ((g & 0xff) << 16) + ((b & 0xff) << 8) + (a & 0xff);
            else
            if(format == PixelFormat.RGB)
                return ((r & 0xff) << 16) + ((g & 0xff) << 8) + ((b & 0xff));
            else
            if(format == PixelFormat.ARGB)
                return ((a & 0xff) << 24) + ((r & 0xff) << 16) + ((g & 0xff) << 8) + (b & 0xff);
            else
            if(format == PixelFormat.BGRA)
                return ((b & 0xff) << 24) + ((g & 0xff) << 16) + ((r & 0xff) << 8) + (a & 0xff);
            else
                return 0;
        }
    }

    /// ditto
    public immutable(T) conv(T)(PixelFormat format = PixelFormat.RGBA) @safe immutable
    {
        static if(is(T : ulong) || is(T : uint))
        {
            if(format == PixelFormat.RGBA)
                return ((r & 0xff) << 24) + ((g & 0xff) << 16) + ((b & 0xff) << 8) + (a & 0xff);
            else
            if(format == PixelFormat.RGB)
                return ((r & 0xff) << 16) + ((g & 0xff) << 8) + ((b & 0xff));
            else
            if(format == PixelFormat.ARGB)
                return ((a & 0xff) << 24) + ((r & 0xff) << 16) + ((g & 0xff) << 8) + (b & 0xff);
            else
            if(format == PixelFormat.BGRA)
                return ((b & 0xff) << 24) + ((g & 0xff) << 16) + ((r & 0xff) << 8) + (a & 0xff);
            else
                return 0;
        }
    }

    /++
        Converts a color to a sequence of bytes in the specified format.

        Params:
            format = Pixel format.

        Returns: Sequence of bytes. 
    +/
    public R[] fromBytes(R)(PixelFormat format) @safe
    {
        if(format == PixelFormat.RGBA)
            return [r,g,b,a];
        else
        if(format == PixelFormat.RGB)
            return [r,g,b];
        else
        if(format == PixelFormat.ARGB)
            return [a,r,g,b];
        else
        if(format == PixelFormat.BGRA)
            return [b,g,r,a];

        return [];
    }

    /// ditto
    public immutable(T[]) fromBytes(PixelFormat format) @safe immutable
    {
        if(format == PixelFormat.RGBA)
            return [r,g,b,a];
        else
        if(format == PixelFormat.RGB)
            return [r,g,b];
        else
        if(format == PixelFormat.ARGB)
            return [a,r,g,b];
        else
        if(format == PixelFormat.BGRA)
            return [b,g,r,a];

        return [];
    }

    ///
    public float rf() @safe
    {
        return cast(float) r / cast(float) T.max;
    }

    ///
    public float gf() @safe
    {
        return cast(float) g / cast(float) T.max;
    }

    ///
    public float bf() @safe
    {
        return cast(float) b / cast(float) T.max;
    }

    ///
    public float af() @safe
    {
        return cast(float) a / cast(float) T.max;
    }

    ///
    public float rf() @safe immutable
    {
        return cast(float) r / cast(float) T.max;
    }

    ///
    public float gf() @safe immutable
    {
        return cast(float) g / cast(float) T.max;
    }

    ///
    public float bf() @safe immutable
    {
        return cast(float) b / cast(float) T.max;
    }

    ///
    public float af() @safe immutable
    {
        return cast(float) a / cast(float) T.max;
    }

    public
    {
        static Color!ubyte White = rgb(255,255,255);
        static Color!ubyte Black = rgb(0,0,0);
        static Color!ubyte Red = rgb(255,0,0);
        static Color!ubyte Green = rgb(0,255,0);
        static Color!ubyte Blue = rgb(0,0,255);
        static Color!ubyte Yellow = rgb(255,255,0);
        static Color!ubyte Aqua = rgb(0,255,255);
        static Color!ubyte Magenta = rgb(255,0,255);
        static Color!ubyte Silver = rgb(192,192,192);
        static Color!ubyte Gray = rgb(128,128,128);
        static Color!ubyte Maroon = rgb(128,0,0);
        static Color!ubyte Olive = rgb(128,128,0);
        static Color!ubyte Purple = rgb(128,0,128);
        static Color!ubyte Tomato = rgb(255,99,71);
        static Color!ubyte Orange = rgb(255,165,0);
        static Color!ubyte Gold = rgb(255,215,0);
        static Color!ubyte YellowGreen = rgb(154,205,50);
        static Color!ubyte PaleGreen = rgb(152,251,152);
        static Color!ubyte SteelBlue = rgb(70,130,180);
        static Color!ubyte SlateBlue = rgb(106,90,205);
        static Color!ubyte Tida = rgb(64,64,255);
        static Color!ubyte DarkViolet = rgb(148,0,211);
        static Color!ubyte Chocolate = rgb(210,105,30);
    }
}