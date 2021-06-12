/++
    The module for describing the work with texture.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.texture;

import tida.graph.drawable;

/++
    Description structure for creating texture.
+/
struct TextureInfo
{
    public 
    {
        /++
            Texture parameters when creating.

            Example:
            ---
            TextureInfo info.
            info.params =   [
                                GL_TEXTURE_MIN_FILTER, GL_LINEAR,
                                GL_TEXTURE_MAG_FILTER, GL_LINEAR
                            ];
            ...
            ---
        +/
        int[] params;
        int width; /// Texture width.
        int height; /// Texture height
        ubyte[] bytes; /// Sequence of colors in RGBA format.
    }
}

/// Texture description class.
class Texture : IDrawable, IDrawableEx, IDrawableColor
{
    import tida.graph.gl, tida.color, tida.graph.vertgen;

    private
    {
        uint _width;
        uint _height;
        uint glTextureID;

        VertexInfo vinfo;
    }

    /// The width of the texture.
    void width(uint newWidth) @safe @property nothrow
    {
        _width = newWidth;
    }

    /// ditto
    uint width() @safe @property nothrow
    {
        return _width;
    }

    /// The height of the texture.
    void height(uint newHeight) @safe @property nothrow
    {
        _height = newHeight;
    }

    /// ditto
    uint height() @safe @property nothrow
    {
        return _height;
    }

    /++


        Params:
            format = The pixel format that you put into the argument.
            bytes = An array of pixels.
    +/
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

    /++
        Initializes the texture using an initialization structure.

        Params:
            format = The pixel format that you put into the structure.
            info = Texture initialization structure.
    +/
    void initFromInfo(int format)(TextureInfo info) @safe @property
    {
        _width = info.width;
        _height = info.height;

        ubyte[] bytes = info.bytes.fromFormat!(format, PixelFormat.RGBA);

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

    /// Information about the vertices of the texture.
    VertexInfo vertexInfo() @safe @property
    {
        return vinfo;
    }

    /// Texture identifier.
    uint glID() @safe @property nothrow
    {
        return glTextureID;
    }

    /++
        Bind the texture to the current render cycle.
    +/
    void bind() @safe nothrow
    {
        GL.bindTexture(glID);
    }

    /// Destroys a texture from memory.
    void destroy() @trusted @property 
    {
        if(glTextureID != 0)
        {
            glDeleteTextures(1,&glTextureID);
            glTextureID = 0;
        }
    }

    ///
    Shader!Program initShader(IRenderer renderer) @safe
    {
        Shader!Program shader;

        if(renderer.currentShader is null)
        {
            if((shader = renderer.getShader("DefaultImage")) is null) {
                Shader!Vertex vertex = new Shader!Vertex()
                    .bindSource(
                    `
                    #version 130
                    in vec3 position;
                    in vec2 aTexCoord;
                    uniform mat4 projection;
                    uniform mat4 model;

                    out vec2 TexCoord;

                    void main() {
                        gl_Position = projection * model * vec4(position.xy, 0.0f, 1.0f);
                        TexCoord = aTexCoord;
                    }
                    `);

                Shader!Fragment fragment = new Shader!Fragment()
                    .bindSource(
                    `
                    #version 130
                    in vec2 TexCoord;
                    uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);

                    uniform sampler2D ourTexture;

                    void main() {
                        gl_FragColor = texture(ourTexture, TexCoord) * color;
                    }
                    `
                    );

                shader = new Shader!Program()
                    .attach(vertex)
                    .attach(fragment)
                    .link();

                renderer.setShader("DefaultImage", shader);
            }
        } else {
            shader = renderer.currentShader;
        }

        return shader;
    }

    import tida.graph.render, tida.color, tida.graph.matrix, tida.vector, tida.graph.shader;

    override void draw(IRenderer renderer,Vecf position) @trusted
    {
        Shader!Program shader = this.initShader(renderer);
        VertexInfo vinfo = this.vertexInfo;

        vinfo.bindVertexArray();
        GL3.bindBuffer(GL_ARRAY_BUFFER, vinfo.idBufferArray);
        GL3.bindBuffer(GL_ELEMENT_ARRAY_BUFFER, vinfo.idElementArray);

        GL3.enableVertexAttribArray(shader.getAttribLocation("position"));
        GL3.vertexAttribPointer(shader.getAttribLocation("position"), 3, GL_FLOAT, false, 5 * float.sizeof, null);

        GL3.enableVertexAttribArray(shader.getAttribLocation("aTexCoord"));
        GL3.vertexAttribPointer(shader.getAttribLocation("aTexCoord"), 2, GL_FLOAT, false, 5 * float.sizeof,
            cast(void*) (3 * float.sizeof));

        float[4][4] proj = (cast(GLRender) renderer).projection();
        float[4][4] model = identity();

        model = translate(model, position.x, position.y, 0.0f);

        shader.using();

        GL3.activeTexture(GL_TEXTURE0);
        bind();

        if(shader.getUniformLocation("projection") != -1)
        shader.setUniform("projection", proj);

        if(shader.getUniformLocation("model") != -1)
        shader.setUniform("model", model);

        if(shader.getUniformLocation("color") != -1)
        shader.setUniform("color", rgb(255, 255, 255));

        GL3.drawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);
        GL.bindTexture(0);

        renderer.resetShader();
    }

    override void drawEx(IRenderer renderer,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha,Color!ubyte color) @trusted
    {
        Shader!Program shader = this.initShader(renderer);
        VertexInfo vinfo = this.vertexInfo;

        vinfo.bindVertexArray();
        GL3.bindBuffer(GL_ARRAY_BUFFER, vinfo.idBufferArray);
        GL3.bindBuffer(GL_ELEMENT_ARRAY_BUFFER, vinfo.idElementArray);

        GL3.enableVertexAttribArray(shader.getAttribLocation("position"));
        GL3.vertexAttribPointer(shader.getAttribLocation("position"), 3, GL_FLOAT, false, 5 * float.sizeof, null);

        GL3.enableVertexAttribArray(shader.getAttribLocation("aTexCoord"));
        GL3.vertexAttribPointer(shader.getAttribLocation("aTexCoord"), 2, GL_FLOAT, false, 5 * float.sizeof,
            cast(void*) (3 * float.sizeof));

        float[4][4] proj = (cast(GLRender) renderer).projection();
        float[4][4] model = identity();

        model = tida.graph.matrix.scale(model,  size.x / cast(float) width,
                                                size.y / cast(float) height);

        model = translate(model, -center.x, -center.y, 0.0f);
        model = rotateMat(model, -angle, 0.0, 0.0, 1.0);
        model = translate(model, center.x, center.y, 0.0f);

        model = translate(model, position.x, position.y, 0.0f);

        shader.using();

        GL3.activeTexture(GL_TEXTURE0);
        bind();

        if(shader.getUniformLocation("projection") != -1)
        shader.setUniform("projection", proj);

        if(shader.getUniformLocation("model") != -1)
        shader.setUniform("model", model);

        color.a = alpha;

        if(shader.getUniformLocation("color") != -1)
        shader.setUniform("color", color);

        GL3.drawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);
        GL.bindTexture(0);

        renderer.resetShader();
    }

    override void drawColor(IRenderer renderer,Vecf position,Color!ubyte color) @trusted
    {
        Shader!Program shader = this.initShader(renderer);
        VertexInfo vinfo = this.vertexInfo;

        vinfo.bindVertexArray();
        GL3.bindBuffer(GL_ARRAY_BUFFER, vinfo.idBufferArray);
        GL3.bindBuffer(GL_ELEMENT_ARRAY_BUFFER, vinfo.idElementArray);

        GL3.enableVertexAttribArray(shader.getAttribLocation("position"));
        GL3.vertexAttribPointer(shader.getAttribLocation("position"), 3, GL_FLOAT, false, 5 * float.sizeof, null);

        GL3.enableVertexAttribArray(shader.getAttribLocation("aTexCoord"));
        GL3.vertexAttribPointer(shader.getAttribLocation("aTexCoord"), 2, GL_FLOAT, false, 5 * float.sizeof,
            cast(void*) (3 * float.sizeof));

        float[4][4] proj = (cast(GLRender) renderer).projection();
        float[4][4] model = identity();

        model = translate(model, position.x, position.y, 0.0f);

        shader.using();

        GL3.activeTexture(GL_TEXTURE0);
        bind();

        if(shader.getUniformLocation("projection") != -1)
        shader.setUniform("projection", proj);

        if(shader.getUniformLocation("model") != -1)
        shader.setUniform("model", model);

        if(shader.getUniformLocation("color") != -1)
        shader.setUniform("color", color);

        GL3.drawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);
        GL.bindTexture(0);

        renderer.resetShader();
    }

    ~this() @safe
    {
        this.destroy();
    }
}
