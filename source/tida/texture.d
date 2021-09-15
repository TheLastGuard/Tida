/++
A module for managing textures. Not to be confused
with $(HREF image.html#Image, Image), which directly lie in RAM and can always
be changed, unlike textures, which need to initialize or update texture data.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.texture;

import std.traits;
import tida.gl;
import tida.drawable;

enum MinFilter = GL_TEXTURE_MIN_FILTER; /// Min Filter
enum MagFilter = GL_TEXTURE_MAG_FILTER; /// Mag Filter

/// Texture filter method
enum TextureFilter
{
    Nearest = GL_NEAREST, /// Nearest method
    Linear = GL_LINEAR /// Linear method
}

/// Texture wrap method
enum TextureWrap
{
    ClampToEdge = GL_CLAMP_TO_EDGE, /// Clamp to Edge method
    Repeat = GL_REPEAT, /// Repeat method
    MirroredRepeat = GL_MIRRORED_REPEAT /// Mirrored repeat method
}

/// Default texture params filter
enum DefaultParams =    [
                            MinFilter, TextureFilter.Nearest,
                            MagFilter, TextureFilter.Nearest
                        ];

/++
Texture initialization structure.

Example:
---
Image image = new Image().load("default.png");
TextureInfo tinfo;
tinfo.width = image.width;
tinfo.height = image.height;
tinfo.data = image.bytes!(PixelFormat.RGBA);
...
---
+/
struct TextureInfo
{
    uint width; /// Texture width
    uint height; /// Texture height
    ubyte[] data; /// Texture image data
    int[] params = DefaultParams; /// Texture initialization parametr's.
}

/++
A texture object for manipulating its data, properties, and parameters.
+/
class Texture : IDrawable, IDrawableEx
{
    import tida.vertgen;
    import tida.render;
    import tida.shader;
    import tida.vector;
    import tida.color;
    import tida.matrix;

private:
    uint glid = 0;
    uint _width = 0;
    uint _height = 0;

public:
    VertexInfo!float vertexInfo; /++    Information about the vertices of the
                                        texture being drawn. +/

@trusted:
    /// Texture width
    @property uint width() inout
    {
        return _width;
    }

    /// Texture height
    @property uint height() inout
    {
        return _height;
    }

    /// The ID of the texture in the open graphics library.
    @property uint id() inout
    {
        return glid;
    }

    /++
    Edits texture parameters based on an array of parameters.

    Params:
        parametrs = Array of parametrs.
    +/
    void editParametrs(int[] parametrs)
    {
        for (int i = 0; i < parametrs.length; i += 2)
        {
            glTexParameteri(GL_TEXTURE_2D, parametrs[i], parametrs[i + 1]);
        }
    }

    /++
    Initializes the texture from the input data (if the texture was previously
    initialized, the data will be updated).

    Params:
        information = Texture information structure.
    +/
    void initializeFromData(int format)(TextureInfo information)
    {
        import tida.color : fromFormat;

        _width = information.width;
        _height = information.height;

        ubyte[] data = information.data.fromFormat!(format, PixelFormat.RGBA);

        if (glid == 0)
        {
            glGenTextures(1, &glid);
            glBindTexture(GL_TEXTURE_2D, glid);
            editParametrs(information.params);
            glTexImage2D(   GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA,
                            GL_UNSIGNED_BYTE, cast(void*) data);
            glBindTexture(GL_TEXTURE_2D, 0);
        } else
        {
            glBindTexture(GL_TEXTURE_2D, glid);
            editParametrs(information.params);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _width, _height, GL_RGBA,
                            GL_UNSIGNED_BYTE, cast(void*) data);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }

    /// Bind the texture to the current render cycle.
    void bind()
    {
        glBindTexture(GL_TEXTURE_2D, glid);
    }

    /// Unbind the texture to the current render cycle.
    static void unbind()
    {
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    /++
    Initializes the shader for rendering the texture
    (if no shader was specified in the current rendering, then the default
    shader is taken).

    Params:
        render = Renderer object.
    +/
    Shader!Program initShader(IRenderer render)
    {
        if (render.currentShader !is null)
            return render.currentShader;

        if (render.getShader("DefaultImage") is null)
        {
            Shader!Program program = new Shader!Program();

            Shader!Vertex vertex = new Shader!Vertex();
            vertex.bindSource(import("shaders/defaultImage.vert"));

            Shader!Fragment fragment = new Shader!Fragment();
            fragment.bindSource(import("shaders/defaultImage.frag"));

            program.attach(vertex);
            program.attach(fragment);
            program.link();

            render.setShader("DefaultImage", program);

            return program;
        }

        return render.getShader("DefaultImage");
    }

override:
    void draw(IRenderer renderer, Vecf position)
    {
        Shader!Program shader = this.initShader(renderer);

        vertexInfo.bindVertexArray();
        vertexInfo.bindBuffer();
        if(vertexInfo.idElementArray != 0)
            vertexInfo.bindElementBuffer();

        glEnableVertexAttribArray(shader.getAttribLocation("position"));
        glVertexAttribPointer(shader.getAttribLocation("position"), 2, GL_FLOAT, false, 4 * float.sizeof, null);

        glEnableVertexAttribArray(shader.getAttribLocation("texCoord"));
        glVertexAttribPointer(shader.getAttribLocation("texCoord"), 2, GL_FLOAT, false, 4 * float.sizeof,
            cast(void*) (2 * float.sizeof));
        vertexInfo.unbindBuffer();
        vertexInfo.unbindVertexArray();

        float[4][4] proj = (cast(GLRender) renderer).projection();
        float[4][4] model = identity();

        model = mulmat(model, renderer.currentModelMatrix);
        model = translate(model, position.x, position.y, 0.0f);

        vertexInfo.bindVertexArray();
        shader.using();

        glActiveTexture(GL_TEXTURE0);
        bind();

        if(shader.getUniformLocation("projection") != -1)
        shader.setUniform("projection", proj);

        if(shader.getUniformLocation("model") != -1)
        shader.setUniform("model", model);

        if(shader.getUniformLocation("color") != -1)
        shader.setUniform("color", rgba(255, 255, 255, 255));

        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
        glBindTexture(GL_TEXTURE_2D, 0);

        renderer.resetShader();
        renderer.resetModelMatrix();
    }

    void drawEx(IRenderer renderer,
                Vecf position,
                float angle,
                Vecf center,
                Vecf size,
                ubyte alpha,
                Color!ubyte color = rgb(255, 255, 255))
    {
        Shader!Program shader = this.initShader(renderer);

        Vecf scaleFactor;
        if (!size.isVecfNaN)
            scaleFactor = size / vecf(width, height);
        else
            scaleFactor = vecf(1.0f, 1.0f);

        if (center.isVecfNaN)
            center = (vecf(width, height) * scaleFactor) / 2;

        vertexInfo.bindVertexArray();
        vertexInfo.bindBuffer();
        if(vertexInfo.idElementArray != 0)
            vertexInfo.bindElementBuffer();

        glEnableVertexAttribArray(shader.getAttribLocation("position"));
        glVertexAttribPointer(shader.getAttribLocation("position"), 2, GL_FLOAT, false, 4 * float.sizeof, null);

        glEnableVertexAttribArray(shader.getAttribLocation("texCoord"));
        glVertexAttribPointer(shader.getAttribLocation("texCoord"), 2, GL_FLOAT, false, 4 * float.sizeof,
            cast(void*) (2 * float.sizeof));
        vertexInfo.unbindBuffer();
        vertexInfo.unbindVertexArray();

        float[4][4] proj = (cast(GLRender) renderer).projection();
        float[4][4] model = identity();

        model = mulmat(model, renderer.currentModelMatrix);
        model = scale(model, scaleFactor.x, scaleFactor.y);

        model = translate(model, -center.x, -center.y, 0.0f);
        model = rotateMat(model, -angle, 0.0f, 0.0f, 1.0f);
        model = translate(model, center.x, center.y, 0.0f);

        model = translate(model, position.x, position.y, 0.0f);

        vertexInfo.bindVertexArray();
        shader.using();

        glActiveTexture(GL_TEXTURE0);
        bind();

        if(shader.getUniformLocation("projection") != -1)
        shader.setUniform("projection", proj);

        if(shader.getUniformLocation("model") != -1)
        shader.setUniform("model", model);

        if(shader.getUniformLocation("color") != -1)
        shader.setUniform("color", rgba(color.r, color.g, color.b, alpha));

        vertexInfo.draw(vertexInfo.shapeinfo.type);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
        glBindTexture(GL_TEXTURE_2D, 0);

        renderer.resetShader();
        renderer.resetModelMatrix();
    }
}
