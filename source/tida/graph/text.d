/++
    Module for rendering text using the `FreeType` library.

    Authors: TodNaz
    License: MIT
+/
module tida.graph.text;

import bindbc.freetype;

enum EncodingMode
{
	None = FT_ENCODING_NONE,
	Unicode = FT_ENCODING_UNICODE,
	MSSymbol = FT_ENCODING_MS_SYMBOL,
	PRC = FT_ENCODING_PRC,
	Big5 = FT_ENCODING_BIG5,
	Wansung = FT_ENCODING_WANSUNG
}

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

    public
    {
        string path, name;
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
    public void load(string path,size_t size,EncodingMode encode = EncodingMode.Unicode) @trusted
    {
        import std.file : exists;
        import std.string : toStringz;
        import tida.exception;

        if(!exists(path))
            throw new Exception("Not find `"~path~"`!");

        this.path = path;

        if(auto ret = FT_New_Face(FTlibrary,path.toStringz,0,&_face)) {
            throw new FontException(ret,"Error load font!");
        }

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

/++
    Returns the size of the rendered text for the given font.   
+/
public size_t widthText(T)(T text,Font font) @safe
{
    int width;

    auto ss = new Text(font).renderSymbols!T(text);
    foreach(s; ss) {
        width += (s.advance.intX) + s.position.intX;
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

template TypeChar(TypeString)
{
	static if(is(TypeString : string))
		alias Type = char;
	else
	static if(is(TypeString : wstring))
		alias Type = wchar;
	else
	static if(is(TypeString : dstring))
		alias Type = dchar;
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
    public Symbol[] renderSymbols(T)(T symbols,Color!ubyte color = rgba(255,255,255,255)) @trusted
    {
        Symbol[] chars;

        for(size_t j = 0; j < symbols.length; ++j)
        {
            TypeChar!T.Type s = symbols[j];

            TypeChar!T.Type ns;
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
