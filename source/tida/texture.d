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
import tida.render;

enum MinFilter = GL_TEXTURE_MIN_FILTER; /// Min Filter
enum MagFilter = GL_TEXTURE_MAG_FILTER; /// Mag Filter

enum WrapS = GL_TEXTURE_WRAP_S;
enum WrapT = GL_TEXTURE_WRAP_T;

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
class Texture : IDrawable, IDrawableEx, ITarget
{
    import tida.vertgen;
    import tida.shader;
    import tida.vector;
    import tida.color;
    import tida.matrix;
    import tida.shape;

private:
    uint glid = 0;
    uint _width = 0;
    uint _height = 0;
    uint type = GL_TEXTURE_2D;
    int activeid = GL_TEXTURE0;
    uint fbo;
    uint rbo;

public:
    VertexInfo!float vertexInfo; /++    Information about the vertices of the
                                        texture being drawn. +/
    ShapeType drawType;

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
            glTexParameteri(type, parametrs[i], parametrs[i + 1]);
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

        type = GL_TEXTURE_2D;
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

    void initializeArrayFromData(int format)(TextureInfo[] informations)
    {
        import tida.color : fromFormat;

        _width = informations[0].width;
        _height = informations[1].height;
        type = GL_TEXTURE_2D_ARRAY_EXT;

        ubyte[] data;

        foreach (e; informations)
        {
            data ~= e.data.fromFormat!(format, PixelFormat.RGBA);
        }

        if (glid == 0)
        {
            glGenTextures(1, &glid);
            glBindTexture(type, glid);

            glTexStorage3D(type, 1, GL_RGBA, _width, _height, cast(int) informations.length);
            glPixelStorei(GL_UNPACK_ROW_LENGTH, cast(int) (_width * informations.length));
            glPixelStorei(GL_UNPACK_IMAGE_HEIGHT, cast(int) (_height * informations.length));

            for (size_t i = 0; i < informations.length; ++i)
            {
                glTexSubImage3D(type,
                                0, 0, 0,
                                cast(int) i,
                                _width,
                                _height,
                                1,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                cast(void*) (data.ptr + (i * (_width * _height) * 4)));
            }

            glTexParameteri(type, GL_TEXTURE_BASE_LEVEL, 0);
            editParametrs(informations[0].params);

            glBindTexture(type, 0);
        }
    }

    void inActive(int id)
    {
        activeid = GL_TEXTURE0 + id;
    }

    /// Bind the texture to the current render cycle.
    void bind()
    {
        glActiveTexture(activeid);
        glBindTexture(type, glid);
    }

    /// Unbind the texture to the current render cycle.
    void unbind()
    {
        glBindTexture(type, 0);
    }

    enum deprecatedVertex =
    "#version 130
    in vec2 position;
    in vec2 texCoord;

    uniform mat4 projection;
    uniform mat4 model;

    out vec2 fragTexCoord;

    void main()
    {
        gl_Position = projection * model * vec4(position, 0.0, 1.0);
        fragTexCoord = texCoord;
    }
    ";

    enum deprecatedFragment =
    "#version 130
    in vec2 fragTexCoord;

    uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    uniform sampler2D texture;

    void main()
    {
        gl_FragColor = texture2D(texture, fragTexCoord) * color;
    }
    ";

    enum modernVertex =
    "#version 330 core
    layout(location = 0) in vec2 position;
    layout(location = 1) in vec2 texCoord;

    uniform mat4 projection;
    uniform mat4 model;

    out vec2 fragTexCoord;

    void main()
    {
        gl_Position = projection * model * vec4(position, 0.0, 1.0);
        fragTexCoord = texCoord;
    }
    ";

    enum modernFragment =
    "#version 330 core
    in vec2 fragTexCoord;

    uniform vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
    uniform sampler2D ctexture;

    out vec4 fragColor;

    void main()
    {
        fragColor = texture(ctexture, fragTexCoord) * color;
    }
    ";

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

            string vsource, fsource;
            bool isModern = (cast(GLRender) render).isModern;

            if (isModern)
            {
                vsource = modernVertex;
                fsource = modernFragment;
            } else
            {
                vsource = deprecatedVertex;
                fsource = deprecatedFragment;
            }

            Shader!Vertex vertex = new Shader!Vertex();
            vertex.bindSource(vsource);

            Shader!Fragment fragment = new Shader!Fragment();
            fragment.bindSource(fsource);

            program.attach(vertex);
            program.attach(fragment);
            program.link();

            render.setShader("DefaultImage", program);

            return program;
        }

        return render.getShader("DefaultImage");
    }

    void clear(Color!ubyte color) @trusted
    {
        import std.algorithm : fill;
    
        Color!ubyte[] data = new Color!ubyte[](width * height);
        data.fill(color);
        
        bind();
        glTexSubImage2D(    GL_TEXTURE_2D, 0, 0, 0, _width, _height, GL_RGBA,
                            GL_UNSIGNED_BYTE, cast(void*) data);
        unbind();
    }

    void generateFrameBuffer() @trusted
    {
        glGenFramebuffers(1, &fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo); 
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, glid, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    void destroy()
    {
        glDeleteTextures(1, &glid);
    }

    ~this()
    {
        this.destroy();
    }
    
override:
    void bind(IRenderer render) @trusted
    {
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    }
    
    void unbind(IRenderer render) @trusted
    {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    
    void drawning(IRenderer render) @trusted
    {
        return;
    }

    void draw(IRenderer renderer, Vecf position)
    {
        Shader!Program shader = this.initShader(renderer);

        mat4 proj = (cast(GLRender) renderer).projection;
        mat4 model = identity();

        model = mulmat(model, renderer.currentModelMatrix);
        model = translate(model, position.x, position.y, 0.0f);

        vertexInfo.bind();
        if (vertexInfo.elements !is null)
            vertexInfo.elements.bind();

        shader.using();
        bind();

        shader.enableVertex("position");
        shader.enableVertex("texCoord");

        if (shader.getUniformLocation("projection") != -1)
            shader.setUniform("projection", proj);

        if (shader.getUniformLocation("model") != -1)
            shader.setUniform("model", model);

        if (shader.getUniformLocation("color") != -1)
            shader.setUniform("color", rgba(255, 255, 255, 255));

        vertexInfo.draw (drawType);

        if (vertexInfo.elements !is null)
            vertexInfo.elements.unbind();
        vertexInfo.unbind();
        unbind();

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

        mat4 proj = (cast(GLRender) renderer).projection;
        mat4 model = identity();

        model = mulmat(model, renderer.currentModelMatrix);
        model = scale(model, scaleFactor.x, scaleFactor.y, 1.0f);

        model = translate(model, -center.x, -center.y, 0.0f);
        model = rotateMat(model, -angle, 0.0f, 0.0f, 1.0f);
        model = translate(model, center.x, center.y, 0.0f);

        model = translate(model, position.x, position.y, 0.0f);

        vertexInfo.bind();
        if (vertexInfo.elements !is null)
            vertexInfo.elements.bind();

        shader.using();
        bind();

        shader.enableVertex("position");
        shader.enableVertex("texCoord");

        if (shader.getUniformLocation("projection") != -1)
            shader.setUniform("projection", proj);

        if (shader.getUniformLocation("model") != -1)
            shader.setUniform("model", model);

        if (shader.getUniformLocation("color") != -1)
            shader.setUniform("color", rgba(255, 255, 255, alpha));

        vertexInfo.draw (drawType);

        if (vertexInfo.elements !is null)
            vertexInfo.elements.unbind();
        vertexInfo.unbind();
        unbind();

        renderer.resetShader();
        renderer.resetModelMatrix();
    }
}
