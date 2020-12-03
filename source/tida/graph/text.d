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

        if(!exists(path))
            throw new Exception("Not find `"~path~"`!");

        FT_New_Face(FTlibrary,path.toStringz,0,&_face);

        FT_Set_Char_Size(_face,cast(int) size*32,0,300,300);

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
        Symbol[] fSymbols;

        foreach(s; symbols)
        {
            FT_Load_Char(_font.face, s, FT_LOAD_RENDER);

            auto glyph = _font.face.glyph;
            auto bitmap = _font.face.glyph.bitmap;

            auto Char = new Image();

            Char.create(bitmap.width,bitmap.rows);

            auto pixels = Char.pixels;

            foreach(i; 0 .. bitmap.width * bitmap.rows)
            {
                pixels[i] = bitmap.buffer[i] > 128 ? grayscale(bitmap.buffer[i]) : Color!ubyte(0,0,0,0);
            }

            fSymbols ~= new Symbol(Char,
                Vecf(glyph.bitmap_left,glyph.bitmap_top),
                Vecf(glyph.advance.x,glyph.advance.y),
            _font.size,color); 
        }

        return fSymbols;
    }
}
