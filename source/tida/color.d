/++
    Color description module. Contains a structure for manipulating colors like RGB, there, 
    and other ways to set colors. Mostly the RGB format is used, and the use of other formats 
    will be converted to RGB.

    Authors: TodNaz
    License: MIT
+/
module tida.color;

static immutable NoAlpha = 0;
static immutable Alpha = 1;

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
        format = Pixel format.

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
            this.red = bytes[0];
            this.green = bytes[1];
            this.blue = bytes[2];
            this.alpha = T.max;
        }else
        if(format == PixelFormat.RGBA) {
            this.red = bytes[0];
            this.green = bytes[1];
            this.blue = bytes[2];
            this.alpha = bytes[3];
        }
        else
        if(format == PixelFormat.ARGB) {
            this.alpha = bytes[0];
            this.red = bytes[1];
            this.green = bytes[2];
            this.blue = bytes[3];
        }
        else 
        if(format == PixelFormat.BGRA) {
            this.blue = bytes[0];
            this.green = bytes[1];
            this.red = bytes[2];
            this.alpha = bytes[3];
        }
    }

    this(uint color,PixelFormat format = PixelFormat.RGBA) @safe
    {
        if(format == PixelFormat.RGBA) {
            this.red = cast(T) ((color & 0xFF000000) >> 24);
            this.green = cast(T) ((color & 0x00FF0000) >> 16);
            this.blue = cast(T) ((color & 0x0000FF00) >> 8);
            this.alpha = cast(T) (color & 0x000000FF);
        }else
        if(format == PixelFormat.RGB) {
            this.red = cast(T) ((color & 0xFF0000) >> 16);
            this.green = cast(T) ((color & 0x00FF00) >> 8);
            this.blue = cast(T) ((color & 0x0000FF));
            this.alpha = T.max;
        }else
        if(format == PixelFormat.ARGB) {
            this.red = cast(T) ((color & 0x00FF0000) >> 16);
            this.green = cast(T) ((color & 0x0000FF00) >> 8);
            this.blue = cast(T) (color & 0x000000FF);
            this.alpha = cast(T) ((color & 0xFF000000) >> 24);
        }else
        if(format == PixelFormat.BGRA) {
            this.blue = cast(T) ((color & 0xFF000000) >> 24);
            this.green = cast(T) ((color & 0x00FF0000) >> 16);
            this.red = cast(T) ((color & 0x0000FF00) >> 8);
            this.alpha = cast(T) (color & 0x000000FF);
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
        }else
        static if(is(T : string))
        {
        	import std.conv : to;
        	import std.digest : toHexString;
        	
        	return this.fromBytes!ubyte(format).toHexString;
        }else
        static if(is(T : HSL))
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
        }else
        static if(is(T : string))
        {
        	import std.conv : to;
        	import std.digest : toHexString;
        	
        	return this.fromBytes!ubyte(format).toHexString;
        }else
        static if(is(T : HSL))
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
            if(max == bd) {
                hsl.h = 60 * (rd - rg) / (fmax - fmin) + 240;
            }

            if(h < 0) {
                hsl.h = hsl.h + 360;
            }

            return hsl;
        }
    }
    
    public string stringComponents() @safe
    {
        import std.conv : to;

        return "rgba("~r.to!string~","~g.to!string~","~b.to!string~","~a.to!string~")";
    }

    ///
    public string formatString() @safe
    {
    	import std.conv : to;
    
    	return "\x1b[38;2;"~red.to!string~";"~green.to!string~";"~blue.to!string~"m" ~ this.conv!string ~ "\u001b[0m";
    }
    
    ///
    public string toString() @safe
    {
    	return this.conv!string;
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
    public immutable(R[]) fromBytes(R)(PixelFormat format) @safe immutable
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

    public auto colorize(ubyte blending)(Color!T color) @safe
    {
        import std.math : abs;

        static if(blending == NoAlpha)
        {
            r = cast(T) (color.rf * this.rf * T.max);
            g = cast(T) (color.gf * this.gf * T.max);
            b = cast(T) (color.bf * this.bf * T.max);
        }else
        static if(blending == Alpha)
        {
            r = cast(T) (((r * a) + (color.r * (T.max - a))) / T.max);
            g = cast(T) (((g * a) + (color.g * (T.max - a))) / T.max);
            b = cast(T) (((b * a) + (color.b * (T.max - a))) / T.max);

            a = T.max;
        }

        return this;
    }

    public auto invert() @safe
    {
        r = r ^ 0xff;
        g = g ^ 0xff;
        b = b ^ 0xff;

        return this;
    }

    public auto clearRed() @safe
    {
        r = 0;

        return this;
    }

    public auto clearGreen() @safe
    {
        g = 0;

        return this;
    }

    public auto clearBlue() @safe
    {
        b = 0;

        return this;
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

unittest
{
	assert(HEX("#FF0000") == rgb(255,0,0));
}

/// Colors
enum Colour : Color!ubyte
{
    White = rgb(255,255,255),
    Black = rgb(0,0,0),
    Red = rgb(255,0,0),
    Green = rgb(0,255,0),
    Blue = rgb(0,0,255),
    Yellow = rgb(255,255,0),
    Aqua = rgb(0,255,255),
    Magenta = rgb(255,0,255),
    Silver = rgb(192,192,192),
    Gray = rgb(128,128,128),
    Maroon = rgb(128,0,0),
    Olive = rgb(128,128,0),
    Purple = rgb(128,0,128),
    Tomato = rgb(255,99,71),
    Orange = rgb(255,165,0),
    Gold = rgb(255,215,0),
    YellowGreen = rgb(154,205,50),
    PaleGreen = rgb(152,251,152),
    SteelBlue = rgb(70,130,180),
    SlateBlue = rgb(106,90,205),
    Tida = rgb(64,64,255),
    DarkViolet = rgb(148,0,211),
    Chocolate = rgb(210,105,30)
}