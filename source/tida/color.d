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
}