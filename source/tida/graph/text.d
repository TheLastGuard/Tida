/++
    Module for rendering text using the `FreeType` library.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.text;

import bindbc.freetype;
import tida.templates;
import std.exception;

mixin Global!(FT_Library,"FTLibrary");

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
    alias Character = TypeChar!wstring.Type; // It's wchar
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

/++
    Returns the size of the rendered text for the given font.   
    
    Params:
        T = String type.
        text = Text.
        font = Font.
+/
int withText(T)(T text,Font font) @safe
{
    int width = 0;
    auto ss = new Text(font).renderSymbols!T(text);

    foreach(s; ss) width += (s.advance.intX) + s.position.intX;

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
    Symbol[] renderSymbols(T)(T symbols,Color!ubyte color = rgba(255,255,255,255)) @trusted
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

            if(s != ' ')
            {
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
                    pixels[i] = bitmap.buffer[i] > 128 ? grayscale(bitmap.buffer[i]) : rgba(0,0,0,0);
                }
            }

            chars ~= new Symbol(image,
                s == ' ' ? Vecf(0,0) : Vecf(glyph.bitmap_left,
                     glyph.bitmap_top),
                Vecf(
                        s == ' ' ? _font.size / 2 : image.width, 0
                    ),
                _font.size, color);
        }

        return chars;
    }
}
