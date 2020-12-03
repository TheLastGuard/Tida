/++
    Module for rendering text using the `FreeType` library.

    Authors: TodNaz
    License: MIT
+/
module tida.graph.text;

import bindbc.freetype;

/// 
__gshared FT_Library FTlibrary;

/++
    Loads the `FreeType` library.
+/
public void FreeTypeLoad() @trusted
{
    immutable retBind = loadFreeType();

    if(retBind == FTSupport.noLibrary)
        throw new Exception("Not find FreeType library!");

    immutable ret = FT_Init_FreeType(&FTlibrary);

    if(ret)
        throw new Exception("Not load FreeType library!");
}

/++
    Font object.
+/
public class Font
{
    private
    {
        FT_Face _face;
        size_t _size;
    }

    /++
        Returns a font object loaded from another library.
    +/
    public FT_Face face() @safe @property
    {
        return _face;
    }

    /++
        Font size
    +/
    public size_t size() @safe @property
    {
        return _size;
    }

    /++
        Loads a font.

        Params:
            path = The path to the font.
            size = Font size.
    +/
    public void load(string path,size_t size) @trusted
    {
        import std.file : exists;
        import std.string : toStringz;
        import tida.exception;

        if(!exists(path))
            throw new Exception("Not find `"~path~"`!");

        if(auto ret = FT_New_Face(FTlibrary,path.toStringz,0,&_face)) {
            throw new FontException(ret,"Error load font!");
        }

        FT_Set_Char_Size(_face,cast(int) size*32,0,300,300);
        FT_Select_Charmap(_face, FT_ENCODING_UNICODE);

        FT_Matrix matrix;

        this._size = size;
    }

    /++
        Free face.
    +/
    public void free() @trusted
    {
        FT_Done_Face(_face);
    }

    ~this() @safe
    {
        free();
    }
}

public size_t widthText(string text,Font font) @safe
{
    int width;

    auto ss = new Text(font).renderSymbols(text);
    foreach(s; ss) {
        width += (s.advance.intX >> 6) + s.position.intX;
    }

    return width;
}

/++
    Symbol object. Needed for rendering.
+/
public class Symbol
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

/++
    Object for rendering text. Use the `renderSymbol` function to render symbols.
+/
public class Text
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
    public Symbol[] renderSymbols(string symbols,Color!ubyte color = rgba(255,255,255,255)) @trusted
    {
        Symbol[] chars;

        for(size_t j = 0; j < symbols.length; ++j)
        {
            char s = symbols[j];

            char ns;
            if(j != symbols.length-1) 
                ns = symbols[j+1];

            Image image;

            FT_GlyphSlot glyph;

            if(s != ' ')
            {
                image = new Image();

                uint glyphIndex = FT_Get_Char_Index(_font.face, s);

                FT_Load_Glyph(_font.face, glyphIndex, FT_LOAD_DEFAULT);
                FT_Render_Glyph(_font.face.glyph, FT_RENDER_MODE_NORMAL);

                glyph = _font.face.glyph;
                auto bitmap = glyph.bitmap;

                image.create(bitmap.width,bitmap.rows);

                auto pixels = image.pixels;

                foreach(i; 0 .. bitmap.width * bitmap.rows)
                {
                    pixels[i] = bitmap.buffer[i] > 128 ? grayscale(bitmap.buffer[i]) : Color!ubyte();
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
