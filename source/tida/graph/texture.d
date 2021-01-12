/++
    

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.texture;

class Texture
{
    import tida.graph.gl, tida.color;

    private
    {
        uint _width;
        uint _height;
        uint glTextureID;
    }

    void width(uint newWidth) @safe @property nothrow
    {
        _width = newWidth;
    }

    uint width() @safe @property nothrow
    {
        return _width;
    }

    void height(uint newHeight) @safe @property nothrow
    {
        _height = newHeight;
    }

    uint height() @safe @property nothrow
    {
        return _height;
    }

    void initFromBytes(int format)(ubyte[] bytes) @safe @property nothrow
    {
        bytes = bytes.fromFormat!(format,PixelFormat.RGBA);

        GL.genTextures(1,glTextureID);

        GL.bindTexture(glTextureID);

        GL.texParameteri(GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        GL.texParameteri(GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        GL.texImage2D(_width,_height,bytes);

        GL.bindTexture(0);
    }

    uint glID() @safe @property nothrow
    {
        return glTextureID;
    }

    void destroy() @trusted @property nothrow
    {
        if(glTextureID != 0)
        {
            glDeleteTextures(1,&glTextureID);
            glTextureID = 0;
        }
    }

    ~this() @safe
    {
        destroy();
    }
}