/++

+/
module tida.graph.text;

import bindbc.freetype;

__gshared FT_Library FTlibrary;

static this()
{
    loadFreeType();

    FT_Init_FreeType(&FTlibrary);
}

public class Font
{
    private
    {
        FT_Face _face;
        size_t _size;
    }

    public FT_Face face() @safe @property
    {
        return _face;
    }

    public size_t size() @safe @property
    {
        return _size;
    }

    public void load(string path,size_t size) @trusted
    {
        import std.file : exists;
        import std.string : toStringz;

        if(!exists(path))
            throw new Exception("Not find `"~path~"`!");

        FT_New_Face(FTlibrary,path.toStringz,0,&_face);

        FT_Set_Char_Size(_face,size*64,0,100, 0);
    }
}

import tida.graph.image;

public Image[] imageText(Font font,string text) @trusted
{
    import tida.color;
    import std.stdio;

    Image[] iChars;

    foreach(c; text)
    {
        auto Char = new Image();

        if(FT_Load_Char(font.face, c, FT_LOAD_RENDER))
            throw new Exception("Text render error!");

        auto bitmap = font.face.glyph.bitmap;

        auto relX = font.face.glyph.bitmap_left;
        auto relY = font.face.glyph.bitmap_top;

        Char.create(cast(uint) (bitmap.width + relX),cast(uint) (bitmap.rows + relY));

        writeln(Char);

        auto pixels = Char.pixels;

        for(size_t i = (relY * bitmap.width) + relX, j = 0;
            j < bitmap.width * bitmap.rows; i++,j++)
        {
            pixels[i] = grayscale(bitmap.buffer[j]);
        }

        iChars ~= Char;
    }

    return iChars;
}