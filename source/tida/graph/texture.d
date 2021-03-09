/++
    

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.texture;

struct TextureInfo
{
    public 
    {
        int[] params;
        int width;
        int height;
        ubyte[] bytes;
    }
}

class Texture
{
    import tida.graph.gl, tida.color, tida.graph.vertgen;

    private
    {
        uint _width;
        uint _height;
        uint glTextureID;
        ubyte[] data;

        VertexInfo vinfo;
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

    void initFromBytes(int format)(ubyte[] bytes) @safe @property
    {
        TextureInfo info;
        info.width = _width;
        info.height = _height;
        info.bytes = bytes;
        info.params = [ GL_TEXTURE_MIN_FILTER, GL_LINEAR,
                        GL_TEXTURE_MAG_FILTER, GL_LINEAR];

        initFromInfo!format(info);
    }

    void initFromInfo(int format)(TextureInfo info) @safe @property
    {
        _width = info.width;
        _height = info.height;

        ubyte[] bytes = info.bytes.fromFormat!(format, PixelFormat.RGBA);
        data = bytes;

        GL.genTextures(1, glTextureID);
        GL.bindTexture(glTextureID);

        for(int i = 0; i < info.params.length; i += 2)
        {
            GL.texParameteri(info.params[i], info.params[i + 1]);
        }

        GL.texImage2D(_width, _height, bytes);
        //GL.generateMipmap(GL_TEXTURE_2D);

        GL.bindTexture(0);

        float[] buffer =    [
                                _width, 0,        0.0f,     1.0f, 0.0f,
                                _width, _height,  0.0f,     1.0f, 1.0f,
                                0,      _height,  0.0f,     0.0f, 1.0f,
                                0,      0,        0.0f,     0.0f, 0.0f
                            ];

        uint[] elem =   [
            0, 1, 3,
            1, 2, 3
        ];

        vinfo = new VertexInfo().generateFromElemBuff(buffer, elem);
    }

    VertexInfo vertexInfo() @safe @property
    {
        return vinfo;
    }

    uint glID() @safe @property nothrow
    {
        return glTextureID;
    }

    void bind() @safe nothrow
    {
        GL.bindTexture(glID);
    }

    void destroy() @trusted @property 
    {
        if(glTextureID != 0)
        {
            glDeleteTextures(1,&glTextureID);
            glTextureID = 0;
        }
    }

    ~this() @safe
    {
        this.destroy();
    }
}
