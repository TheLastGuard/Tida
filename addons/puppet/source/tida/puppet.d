/++
    Add-on module for loading 2D puppets and displaying them in the game.
    <$(HTTP https://github.com/Inochi2D/inochi2d/wiki, INP Format information)

    Currently supported:
    - Loading .inp format including JSON data and textures.
    - Displays nodes of type Part (the rest are ignored)
    - Reading the transformation of the node, identifier, type, Mesh data, transparency.
    - Setting the 'part' texture.
    - Saving to an .inp file.
    - Sorting zoffset.

    Not implemented:
    - Mask mod.
    - Path Deform.
    - JointBindingData.

    There are some modifications that are not described in the reference:
    - It is not necessary to specify the index data.

    For rendering, you need a context. The format is loaded in the following way:
    ---
    Puppet puppet = new Puppet();
    puppet.load("data.inp"); // or puppet.loadFromMem(...);
    ---

    The function `render.draw` is used for displaying, since this is an IDrawable object:
    ---
    render.draw(puppet, Vecf(32, 32));
    ---

    Authors implementations for Tida: $(HTTP https://github.com/TodNaz, TodNaz)
    Authors INP format: $(HTTP https://github.com/LunaTheFoxgirl, LunaTheFoxgirl)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.puppet;

import std.json;

import tida.gl;
import tida.drawable;
import tida.vertgen;
import tida.matrix;
import tida.render;
import tida.image;
import tida.texture;
import tida.shader;
import tida.vector;
import tida.angle;
import tida.shape;
import tida.color;

private bool isKeyExists(JSONValue json, string key) @trusted {
    try {
        auto item = json[key];
        return true;
    }catch(Exception e) {
        return false;
    }
}

alias UUID = int;

enum MaskMode : string{
    Mask = "Mask", DodgeMask = "DodgeMask"
}

/// Node type
enum PuppetNodeType : string {
    Node = "Node",
    Drawable = "Drawable",
    PathDeform = "PathDeform",
    Part = "Part",
    Mask = "Mask"
}

/// Transformation structure for the matrix.
struct Transform
{
    public
    {
        float[3] trans; /// Translate vector
        bool[3] transLock; /// Translate lock
        float[3] rot; /// Rotate vector
        bool[3] rotLock; /// Rotate lock
        Vecf scaling; /// Scale vector
        bool[2] scaleLock; // Scale lock
    }

    void parseJSON(JSONValue json) @trusted
    {
        trans[0] = json["trans"][0].get!float;
        trans[1] = json["trans"][1].get!float;
        trans[2] = json["trans"][2].get!float;

        if(json.isKeyExists("trans_lock"))
        {
            transLock[0] = json["trans_lock"][0].get!bool;
            transLock[1] = json["trans_lock"][1].get!bool;
            transLock[2] = json["trans_lock"][2].get!bool;
        }

        rot[0] = json["rot"][0].get!float;
        rot[1] = json["rot"][1].get!float;
        rot[2] = json["rot"][2].get!float;

        if(json.isKeyExists("rot_lock"))
        {
            rotLock[0] = json["rot_lock"][0].get!bool;
            rotLock[1] = json["rot_lock"][1].get!bool;
            rotLock[2] = json["rot_lock"][2].get!bool;
        }

        scaling.x = json["scale"][0].get!float;
        scaling.y = json["scale"][1].get!float;

        if(json.isKeyExists("scale_lock"))
        {
            scaleLock[0] = json["scale_lock"][0].get!bool;
            scaleLock[1] = json["scale_lock"][1].get!bool;
        }
    }

    JSONValue toJSON() @trusted
    {
        JSONValue json;

        json["trans"] = JSONValue(trans);
        if(json.isKeyExists("trans_lock")) json["trans_lock"] = JSONValue(transLock);
        json["rot"] = JSONValue(rot);
        if(json.isKeyExists("rot_lock")) json["rot_lock"] = JSONValue(rotLock);
        json["scale"] = JSONValue(scaling.array);
        if(json.isKeyExists("scale_lock")) json["scale_lock"] = JSONValue(scaleLock);

        return json;
    }

    /// Returns the model of the matrix by the parameters of the structure.
    float[4][4] modelMatrix() @safe @property nothrow pure
    {
        float[4][4] mat = identity();

        mat = translate(mat,    this.transLock[0] ? 0.0 : trans[0],
                                this.transLock[1] ? 0.0 : trans[1],
                                this.transLock[2] ? 0.0 : trans[2]);
        mat = eulerRotate(mat,  this.rotLock[0] ? 0.0 : -rot[0],
                                this.rotLock[1] ? 0.0 : -rot[1],
                                this.rotLock[2] ? 0.0 : -rot[2]);
        mat = scale(mat,    this.scaleLock[0] ? 1.0 : scaling.x,
                            this.scaleLock[1] ? 1.0 : scaling.y);

        return mat;
    }
}

/// Information about the puppet.
struct PuppetMeta
{
    public
    {
        string name; /// 
        string ver = "v1.0.0-alpha"; ///
        string[] authors; ///
        string copyright; ///
        string contact; /// Mail / address / website.
        string reference = "https://github.com/Inochi2D/inochi2d/"; ///
        uint thumbnailID; /// Puppet thumbnail.
    }

    void parseJSON(JSONValue json) @trusted
    {
        name = json["name"].str;
        ver = json["version"].str;
        if(json.isKeyExists("thumbnail_id")) thumbnailID = cast(uint) json["thumbnail_id"].integer;
    }

    JSONValue toJSON() @trusted
    {
        JSONValue json;

        json["name"] = JSONValue(name);
        json["version"] = JSONValue(ver);
        json["thumbnail_id"] = JSONValue(thumbnailID);

        return json;
    }
}

class PuppetNode : IDrawable
{
    import std.random;

    public
    {
        PuppetNodeType type; ///
        UUID uuid; /// identificator
        string name = "Unnamed"; ///
        bool enabled = true; /// Do I need to display the node.
        float zsort = 0.0; /// zsort value
        Transform transform; ///
        PuppetNode[] children; ////

        float[4][4] transformMatrix;
        PuppetNode parent;
    }

    protected
    {
        Puppet puppet;
    }

    float zSort() @safe @property {
        return parent !is null ? parent.zSort + zsort : zsort;
    }

    this(PuppetNode parent = null) @safe {
        type = PuppetNodeType.Node;
        uuid = uniform!UUID;
        this.parent = parent;
    }

    this(Puppet puppet, PuppetNode parent = null) @safe {
        this.puppet = puppet;
        type = PuppetNodeType.Node;
        uuid = uniform!UUID;
        this.parent = parent;
    }

    void parseJSON(JSONValue json, Puppet puppet) @trusted
    {
        this.puppet = puppet;

        uuid = cast(UUID) json["uuid"].integer;
        if(json.isKeyExists("name")) name = json["name"].str;
        enabled = json["enabled"].get!bool;
        zsort = json["zsort"].get!float;
        transform.parseJSON(json["transform"]);

        if(parent is null)
            transformMatrix = transform.modelMatrix();
        else
            transformMatrix = mulmat(transform.modelMatrix(), parent.transformMatrix);

        if(json.isKeyExists("children"))
        foreach(e; json["children"].array) {
            PuppetNode node = jsonToNode(e, puppet, this);
            children ~= node;
        }
    }

    JSONValue toJSON() @trusted
    {
        JSONValue json;

        json["type"] = JSONValue(cast(string) type);
        json["uuid"] = JSONValue(uuid);
        if(name != []) json["name"] = JSONValue(name);
        json["enabled"] = JSONValue(enabled);
        json["transform"] = transform.toJSON();
        json["zsort"] = JSONValue(zsort);

        json["children"] = [null];

        foreach(e; children) {
            json["children"].array ~= e.toJSON();
        }

        json["children"].array = json["children"].array[1 .. $];

        return json;
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        if(!enabled) return;
    }
}

PuppetNode jsonToNode(JSONValue json, Puppet puppet, PuppetNode parent = null) @trusted
{
    PuppetNodeType type = cast(PuppetNodeType) json["type"].str;

    switch(type)
    {
        case PuppetNodeType.Node:
            PuppetNode node = new PuppetNode(parent);
            node.type = type;
            node.parseJSON(json, puppet);

            return node;

        case PuppetNodeType.Drawable:
            goto default;

        case PuppetNodeType.PathDeform:
            PuppetPathDeform node = new PuppetPathDeform(parent);
            node.type = type;
            node.parseJSON(json, puppet);

            return node;

        case PuppetNodeType.Part:
            PuppetPart node = new PuppetPart(parent);
            node.type = type;
            node.parseJSON(json, puppet);

            return node;

        case PuppetNodeType.Mask:
            PuppetMask node = new PuppetMask(parent);
            node.type = type;
            node.parseJSON(json, puppet);

            return node;

        default:
            return null;
    }
}

/// Geometry information.
struct MeshData
{
    public
    {
        float[] vertsOld; 
        float[] verts; /// 
        float[] uvs; ///
        uint[] indices; // is not a ushort
    }

    private
    {
        bool textureCoordinatePut = false;
    }

    void parseJSON(JSONValue json) @trusted
    {
        foreach(e; json["verts"].array) 
            verts ~= e.get!float;

        if(json.isKeyExists("uvs"))
        foreach(e; json["uvs"].array)
            uvs ~= e.get!float;

        if(json.isKeyExists("indices"))
        foreach(e; json["indices"].array)
            indices ~= cast(uint) e.integer;

        this.textured();
    }

    void textured() @safe {
        vertsOld = verts.dup;

        Vecf[] vertxs;
        for(int i = 0; i < verts.length; i += 2) {
            vertxs ~= Vecf(verts[i], verts[i + 1]);
        }

        auto vertDump = vertxs;
        vertxs.length = 0;

        if(uvs.length == 0)
        {
            const clip = rectVertexs(vertDump);

            foreach(e; vertDump) {
                vertxs ~= [e,
                            Vecf((e.x - clip.x) / clip.width,
                                 (e.y - clip.y) / clip.height)];
            }

            verts = vertxs.generateArray;
        }else
        {
            Vecf[] uvvs;
            for(int i = 0; i < uvs.length; i += 2) {
                uvvs ~= Vecf(uvs[i], uvs[i + 1]);
            }

            foreach(i; 0 .. vertDump.length) {
                vertxs ~= [vertDump[i], uvvs[i]];
            }

            verts = vertxs.generateArray;
        }

        textureCoordinatePut = true;
    }

    JSONValue toJSON() @trusted
    {
        JSONValue json;

        json["verts"] = textureCoordinatePut ? JSONValue(vertsOld) : JSONValue(verts);
        json["uvs"] = JSONValue(uvs);
        json["indices"] = JSONValue(indices);

        return json;
    }
}

abstract class PuppetDrawable : PuppetNode
{
    public
    {
        MeshData mesh; ///

        VertexInfo!float vertInfo; ///
    }

    override void parseJSON(JSONValue json, Puppet puppet) @trusted
    {
        super.parseJSON(json, puppet);

        mesh.parseJSON(json["mesh"]);
        generateVertexInfo();
    }

    override JSONValue toJSON() @trusted
    {
        auto json = super.toJSON();

        json["mesh"] = mesh.toJSON();

        return json;
    }

    void generateVertexInfo() @safe
    {
        vertInfo = new VertexInfo!float();
        
        if(mesh.indices != []) {
            vertInfo.bindFromBufferAndElem(mesh.verts, mesh.indices);
        } else {
            vertInfo.bindFromBuffer(mesh.verts);
        }
    }
}

/// Texture display node
class PuppetPart : PuppetDrawable
{
    import std.random;

    public
    {
        uint[] textures; ///
        float opacity; ///
        MaskMode maskMode; ///
        float maskThreshold; ///
        UUID[] maskedBy; ///
    }

    this(PuppetNode parent = null) @safe {
        type = PuppetNodeType.Part;
        uuid = uniform!uint;
        this.parent = parent;
    }

    this(Puppet puppet, PuppetNode parent = null) @safe 
    {
        type = PuppetNodeType.Part;
        this.puppet = puppet;
        uuid = uniform!uint;
        this.parent = parent;
    }

    override void parseJSON(JSONValue json, Puppet puppet) @trusted
    {
        super.parseJSON(json, puppet);

        foreach(e; json["textures"].array)
            textures ~= cast(uint) e.integer;

        opacity = json["opacity"].get!float;
        maskMode = cast(MaskMode) json["mask_mode"].str;
        maskThreshold = json["mask_threshold"].get!float;

        if(json.isKeyExists("masked_by"))
        foreach(e; json["masked_by"].array)
            maskedBy ~= cast(UUID) e.integer;
    }

    override JSONValue toJSON() @trusted
    {
        auto json = super.toJSON();

        json["textures"] = JSONValue(textures);
        json["opacity"] = JSONValue(opacity);
        json["mask_mode"] = JSONValue(maskMode);
        json["mask_threshold"] = JSONValue(maskThreshold);
        json["masked_by"] = JSONValue(maskedBy);

        return json;
    }

    void drawTexture(IRenderer render, Texture texture, Vecf position) @trusted 
    {
        Shader!Program shader = texture.initShader(render);
        VertexInfo!float vinfo = vertInfo;

        vinfo.bindVertexArray();
        glBindBuffer(GL_ARRAY_BUFFER, vinfo.idBufferArray);
       	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vinfo.idElementArray);

        glEnableVertexAttribArray(shader.getAttribLocation("position"));
       	glVertexAttribPointer(shader.getAttribLocation("position"), 2, GL_FLOAT, false, 4 * float.sizeof, null);

        glEnableVertexAttribArray(shader.getAttribLocation("aTexCoord"));
        glVertexAttribPointer(shader.getAttribLocation("aTexCoord"), 2, GL_FLOAT, false, 4 * float.sizeof,
            cast(void*) (2 * float.sizeof));

        float[4][4] proj = (cast(GLRender) render).projection();
        float[4][4] model = transformMatrix;

        model = translate(model, position.x, position.y, 0.0f);

        shader.using();

        glActiveTexture(GL_TEXTURE0);
        texture.bind();

        if(shader.getUniformLocation("projection") != -1)
        shader.setUniform("projection", proj);

        if(shader.getUniformLocation("model") != -1)
        shader.setUniform("model", model);

        if(shader.getUniformLocation("color") != -1)
        shader.setUniform("color", rgba(255, 255, 255, cast(ubyte) (ubyte.max * opacity)));

        if(vinfo.elementLength != 0)
            glDrawElements(GL_TRIANGLES, cast(uint) vinfo.elementLength, GL_UNSIGNED_INT, null);
        else
            glDrawArrays(GL_TRIANGLES, 0, cast(uint) vinfo.length / 4);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
       	glBindTexture(GL_TEXTURE_2D, 0);

        render.resetShader();
    }

    override void draw(IRenderer render, Vecf position) @safe {
        foreach(e; textures) {
            drawTexture(render, puppet.dataTexture[e].texture, position);
        }
    }
}

///
class PuppetMask : PuppetDrawable 
{
    this(PuppetNode parent = null) @safe
    {
        this.parent = parent;
    }

    this(Puppet puppet, PuppetNode parent) @safe
    {
        this.parent = parent;
        this.puppet = puppet;
    }
}

///
struct PuppetJointBindingData
{
    public
    {
        UUID boundTo;
        size_t[][] bindData;
    }
}

///
class PuppetPathDeform : PuppetNode
{
    public
    {
        Vecf[] joints;
        PuppetJointBindingData[] bindings;
    }

    this(PuppetNode parent = null) @safe
    {
        this.parent = parent;
    }

    this(Puppet puppet, PuppetNode parent) @safe
    {
        this.parent = parent;
        this.puppet = puppet;
    }
}

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    data =  bytes[0] << 24 |
            bytes[1] << 16 |
            bytes[2] << 8  |
            bytes[3];

    return data;
}


private ubyte[4] toByte(T)(T value) @trusted
{
    ubyte[4] ab;
    for (int i = 0; i < 4; i++)
        ab[3 - i] = cast(ubyte) (value >> (i * 8));

    return ab;
}

///
class Puppet : IDrawable
{
    import std.file : read;
    import imagefmt;

    public
    {
        PuppetMeta meta; /// Puppet information
        PuppetNode node; ///
        Image[] dataTexture; ///
    }

    protected
    {
        PuppetNode[] nodesDraw;
    }

    /++
        Loads a puppet from a mem.

        Params:
            data = Raw data.

        Throws: 'Exception' if the file header is not found / damaged, 
                as well as if there is no image data. If you only need to 
                load JSON data, then just use the 'parseJSON' function.
    +/
    void loadFromMem(ubyte[] data) @trusted 
    {
        import std.stdio;

        struct TextureBlob {
            ubyte encode;
            ubyte[] data;
        }

        TextureBlob[] blobs;

        if(data[0 .. 8] != ['T','R','N','S','R','T','S','\0'])
            throw new Exception("It's a not a INP file!");

        immutable len = byteTo!int(data[8 .. 8 + 4]);
        string jsonString = cast(string) data[8 + 4 .. 8 + 4 + len];

        if(data[len + 8 + 4 .. len + 8 + 4 + 8] != ['T','E','X','_','S','E','C','T'])
            throw new Exception("Not find \"TEX_SECT\"!");

        int offset = len + 16 + 4;
        immutable texcount = byteTo!int(data[offset .. offset += 4]);

        foreach(_; 0 .. texcount) {
            immutable texLeng = byteTo!int(data[offset .. offset += 4]);
            immutable texType = data[offset++];
            blobs ~= TextureBlob(texType, data[offset .. offset += texLeng]);
        }

        Image[] images;
        foreach(e; blobs) {
            Image image = new Image();

            IFImage temp = read_image(e.data, 4);
            scope(exit) temp.free();
            assert(temp.e == 0, IF_ERROR[temp.e]);

            image.allocatePlace(temp.w,temp.h);
            image.bytes!(PixelFormat.RGBA)(temp.buf8);

            image.toTexture();

            dataTexture ~= image;
        }

        this.parseJSON(jsonString.parseJSON);
    }

    /++
        Loads a puppet from a file.

        Params:
            file = path to the file.

        Throws: 'Exception' if the file header is not found / damaged, 
                as well as if there is no image data. If you only need to 
                load JSON data, then just use the 'parseJSON' function.
    +/
    void load(string file) @trusted {
        loadFromMem(cast(ubyte[]) read(file));
    }

    ///
    ubyte[] toRaw() @trusted
    {
        ubyte[] data = cast(ubyte[]) "TRNSRTS\0";

        string jsonString = this.toJSON().toString();
        data ~= toByte!int(cast(int) jsonString.length);
        data ~= cast(ubyte[]) jsonString;

        data ~= cast(ubyte[]) "TEX_SECT";
        data ~= toByte!int(cast(int) dataTexture.length);

        foreach(e; dataTexture) {
            int err;
            ubyte[] textData = write_image_mem(4, e.width, e.height, e.bytes!(PixelFormat.RGBA), 2, err);
            data ~= toByte!int(cast(int) textData.length);
            data ~= 0;
            data ~= textData;
        }

        return data;
    }

    void scan(PuppetNode node) @safe {
        if(node is null) return;
        if(!node.enabled) return;

        if(node.type == PuppetNodeType.Part) this.nodesDraw ~= node;
        foreach(e; node.children)
            scan(e);
    }

    void sortNodeDraw() @safe {
        import std.algorithm : sort;

        sort!((a, b) => a.zSort > b.zSort)(nodesDraw);
    }

    void update() @safe
    {
        scan(node);
        sortNodeDraw();
    }

    ///
    void parseJSON(JSONValue json) @trusted {
        meta.parseJSON(json["meta"]);
        node = jsonToNode(json["nodes"], this);

        update();
    }

    string nodesDrawsToString() @trusted {
        string str = "[";
        foreach(PuppetNode e; nodesDraw) {
            str ~= e.toJSON().toString() ~ ",";
        }
        return str[0 .. $ - 1] ~ "]";
    }

    ///
    JSONValue toJSON() @trusted {
        JSONValue json;
        json["meta"] = meta.toJSON();
        json["nodes"] = node.toJSON();

        return json;
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        foreach(e; nodesDraw) e.draw(render, position);
    }
}

/// Find a node by name.
PuppetNode nodeByName(PuppetNode node, string name) @trusted {
    if(node.name == name) return node;

    foreach(e; node.children) if(nodeByName(e, name) !is null) return e;

    return null;
}

/// Find a node by identificator.
PuppetNode nodeByUUID(PuppetNode node, UUID uuid) @trusted {
    if(node.uuid == uuid) return node;

    foreach(e; node.children) if(nodeByUUID(e, uuid) !is null) return e;

    return null;
}
