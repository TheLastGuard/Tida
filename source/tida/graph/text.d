/++
    Module for rendering text using the `FreeType` library.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.text;

import bindbc.freetype;
import tida.templates;
import std.exception;

__gshared FT_Library _FTLibrary;

/// FTLibrary instance.
FT_Library FTLibrary() @trusted
{
    return _FTLibrary;
}

/++
    Loads the `FreeType` library.
    
    Throws: `Exception` If the library has not been loaded.
+/
void FreeTypeLoad() @trusted
{
    enforce(loadFreeType() != FTSupport.noLibrary, "Not find FreeType library!");
    enforce(!FT_Init_FreeType(&_FTLibrary),"Not initialize FreeType Library!");
}

/// Font object
class Font
{
    import std.file : exists;
    import std.string : toStringz;

    private
    {
        FT_Face _face;
        size_t _size;
    }

    public
    {
        string  path,
                name;
    }

    /// Returns a font object loaded from another library.
    FT_Face face() @safe @property
    {
        return _face;
    }

    /// Font size
    size_t size() @safe @property
    {
        return _size;
    }

    /++
        Loads a font.

        Params:
            path = The path to the font.
            size = Font size.
            
        Throws: `Exception` If the font was not found in the file system, or if the font is damaged.
    +/
    auto load(string path,size_t size) @trusted
    {
        enforce(exists(path),"Not file file `"~path~"`");

        enforce(!FT_New_Face(_FTLibrary,path.toStringz,0,&_face),"Error load font!");

        FT_CharMap found;

        foreach(i; 0 .. _face.num_charmaps)
        {
            FT_CharMap charmap = _face.charmaps[i];
            if ((charmap.platform_id == 3 && charmap.encoding_id == 1) /* Windows Unicode */
             || (charmap.platform_id == 3 && charmap.encoding_id == 0) /* Windows Symbol */
             || (charmap.platform_id == 2 && charmap.encoding_id == 1) /* ISO Unicode */
             || (charmap.platform_id == 0)) { /* Apple Unicode */
                found = charmap;
                break;
            }
        }

        FT_Set_Charmap(_face, found);

        FT_Set_Char_Size(_face, 0, cast(int) size*32, 300, 300);
        FT_Set_Pixel_Sizes(_face, 0, cast(int) size*2);

        this._size = size;

        return this;
    }

    /// Free memory
    void free() @trusted
    {
        FT_Done_Face(_face);
    }

    ~this() @safe
    {
        free();
    }
}

/++
    Determines the type of character by line.
    
    Example:
    ---
    alias Character = TypeChar!wstring; // It's wchar
    ---
+/
template TypeChar(TypeString)
{
    static if(is(TypeString : string))
        alias TypeChar = char;
    else
    static if(is(TypeString : wstring))
        alias TypeChar = wchar;
    else
    static if(is(TypeString : dstring))
        alias TypeChar = dchar;
}

template isText(T)
{
    enum isText = is(T : string) || is(T : wstring) || is(T : dstring);
}

import tida.graph.drawable;

class SymbolRender : IDrawable, IDrawableEx
{
    import tida.graph.render, tida.vector, tida.color;

    private
    {
        Symbol[] symbols;
    }

    this(Symbol[] symbols) @safe
    {
        this.symbols = symbols;
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        import tida.graph.shader;

        Shader!Program currShader;

        if(render.type != RenderType.Soft)
        {
            if(render.currentShader !is null) {
                currShader = render.currentShader;
            }
        }

        position.y += (symbols[0].size + (symbols[0].size / 2));

        foreach(s; symbols)
        {
            if(s.image !is null)
            {
                if(!s.image.isTexture)
                    s.image.fromTexture();

                if(render.type != RenderType.Soft)
                    render.currentShader = currShader;

                render.drawColor(s.image,position - Vecf(0, s.position.y),
                            s.color);
            }

            position.x += s.advance.intX >> 6;

            if(s.image.texture !is null) s.image.texture.destroy();
        }
    }

    override void drawEx(IRenderer render,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha,Color!ubyte color) @safe
    {
        import tida.angle;
        import std.math : isNaN;

        position.y += (symbols[0].size + (symbols[0].size / 2));

        Vecf bpos = position;

        if(center.x.isNaN) center = Vecf(widthSymbols(symbols) / 2, center.y);
        if(center.y.isNaN) center = Vecf(center.x, symbols[0].size / 2);

        foreach(s; symbols)
        {
            if(s.image !is null)
            {
                if(!s.image.isTexture)
                    s.image.fromTexture();

                Vecf tpos = position + s.position - Vecf(0, s.position.y);

                tpos = tpos.rotate(angle.from!(Degrees, Radians), bpos + center);

                render.drawEx(s.image, tpos, angle,
                    Vecf(s.image.width / 2, s.image.height / 2),
                    Vecf(s.image.width, s.image.height), s.color.a, s.color);
            }

            position.x += s.advance.intX >> 6;

            if(s.image.texture !is null) s.image.texture.destroy();
        }
    }
}

///
T cutFormat(T)(T symbols) @safe
in(isText!T)
body
{
    for(int i = 0; i < symbols.length; i++)
    {
        if(symbols[i] == '$')
        {
            if(symbols[i+1] == '<') {
                __symEachCutter: for(int j = i; j < symbols.length; j++)
                {
                    if(symbols[j] == '>')
                    {
                        symbols = symbols[0 .. i] ~ symbols[j .. $];
                        break __symEachCutter;
                    }
                }
            }
        }
    }

    return symbols;
}

/++
    Returns the size of the rendered text for the given font.   
    
    Params:
        T = String type.
        text = Text.
        font = Font.
+/
int widthText(T)(T text,Font font) @safe
in(isText!T)
body
{
    import std.algorithm : reduce;
    text = cutFormat!T(text);

    return new Text(font)
        .fromSymbols!T(text)
        .widthSymbols;
}

///
int widthSymbols(Symbol[] text) @safe
{
    import std.algorithm : reduce;
    int width = int.init;

    foreach(s; text) width += s.advance.intX >> 6;

    return width;
}

/// Symbol object. Needed for rendering.
class Symbol
{
    import tida.graph.image, tida.vector, tida.color;

    public
    {
        Image image; /// Symbol render image
        Vecf position; /// Symbol releative position
        Color!ubyte color; /// Symbol color
        size_t size;
        Vecf advance;
    }

    ///
    this(Image img,Vecf pos,Vecf rel,size_t size,Color!ubyte color = rgb(255,255,255)) @safe
    {
        image = img;
        position = pos;
        this.color = color;
        this.size = size;
        this.advance = rel;
    }
}

/// Object for rendering text. Use the `renderSymbol` function to render symbols.
class Text
{
    import tida.graph.image, tida.color, tida.vector;

    private
    {
        Font _font;
    }

    /++
        Object constructor.

        Params:
            newFont = The font to use.
    +/
    this(Font newFont) @safe
    {
        _font = newFont;
    }

    /++
        A function to render a character and set the position of each of them to form words.

        Params:
            symbols = Text for rendering.
            color = Text color.
    +/
    Symbol[] fromSymbols(T)(T symbols,Color!ubyte color = rgba(255,255,255,255)) @trusted
    in(isText!T)
    body
    {
        Symbol[] chars;

        for(size_t j = 0; j < symbols.length; ++j)
        {
            TypeChar!T s = symbols[j];

            TypeChar!T ns;
            if(j != symbols.length-1) 
                ns = symbols[j+1];

            Image image;

            FT_GlyphSlot glyph;

            image = new Image();

            FT_Load_Char(_font.face, s, FT_LOAD_RENDER);
            const glyphIndex = FT_Get_Char_Index(_font.face, s);

            FT_Load_Glyph(_font.face, glyphIndex, FT_LOAD_DEFAULT);
            FT_Render_Glyph(_font.face.glyph, FT_RENDER_MODE_NORMAL);

            glyph = _font.face.glyph;
            auto bitmap = glyph.bitmap;

            image.create(bitmap.width,bitmap.rows);

            auto pixels = image.pixels;

            foreach(i; 0 .. bitmap.width * bitmap.rows)
            {
                pixels[i] = rgba(255, 255, 255, bitmap.buffer[i]);
            }

            chars ~= new Symbol(image,
                Vecf(glyph.bitmap_left, glyph.bitmap_top),
                Vecf(glyph.advance.x, 0),
                _font.size,
                color);
        }

        return chars;
    }

    SymbolRender renderSymbols(T)(T symbols,Color!ubyte color = rgba(255,255,255,255)) @trusted
    {
        return new SymbolRender(fromSymbols!T(symbols, color));
    }

    /++
        Renders text in color format. Formatting example:
        `Simple text!$<#FF0000>Red text!$<0x00FF00> Green! $<0000FF> Blue Text!`

        Params:
            symbols = Text for renders.
            defaultColor = Default color.
    +/
    SymbolRender renderSymbolsFormat(T)(T symbols,Color!ubyte defaultColor = rgba(255,255,255,255)) @safe
    in(isText!T)
    body
    {
        Symbol[] result;
        int previous = 0;
        int j = 0;

        Color!ubyte color = defaultColor;

        for(int i = 0; i < symbols.length; i++)
        {
            if(symbols[i] == '$')
            {
                if(symbols[i+1] == '<') {
                    T colorText;

                    __symEach: for(j = i; j < symbols.length; j++)
                    {
                        if(symbols[j] == '>')
                        {
                            colorText = symbols[i+2 .. j];
                            break __symEach;
                        }
                    }

                    if(colorText != "") 
                    {
                        result ~= this.fromSymbols(symbols[previous .. i], color);

                        color = HEX!(PixelFormat.AUTO,T)(colorText);
                        i = j + 1;
                        previous = i;
                    }
                }
            }
        }

        result ~= this.fromSymbols(symbols[previous .. $], color);

        return new SymbolRender(result);
    }
}
