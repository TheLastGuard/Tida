/++
Module for loading maps in TMX format.

> TMX and TSX are Tiled’s own formats for storing tile maps and tilesets, based on XML. 
> TMX provides a flexible way to describe a tile based map. It can describe maps with any tile size, 
> any amount of layers, any number of tile sets and it allows custom properties to be set on most elements. 
> Beside tile layers, it can also contain groups of objects that can be placed freely.

To load and render tile maps, use the following:
---
TimeMap tilemap = new TileMap();
tilemap.load("map.tmx");
...
render.draw(tilemap, Vecf(32, 32)); // Draws the layers at the specified location 
                                    // (including offset, of course).
---

$(HTTP https://doc.mapeditor.org/en/stable/reference/tmx-map-format/, TMX format documentation).

Authors implemetation: $(HTTP https://github.com/TodNaz, TodNaz)
License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.tiled;

import dxml.parser;
import std.json;
import std.file : read;
import std.conv : to;
import std.base64;

import tida.drawable;
import tida.render;
import tida.image;
import tida.color;
import tida.vector;
import tida.sprite;

__gshared Tileset[] _tilesetStorage;

ref Tileset[] tilesetStorage() @trusted
{
    return _tilesetStorage;
}

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    foreach(i; 0 .. bytes.length) data |= bytes[i] << (8 * i);

    return data;
}

private bool isKeyExists(JSONValue json, string key) @trusted {
    try {
        auto item = json[key];
        return true;
    }catch(Exception e) {
        return false;
    }
}

/// Property included in layers.
struct Property
{
    string name; /// Property name.
    string type; /// The data type in the layer property.
    string value; /// Property value.
}

/// Object in ObjectGroup.
struct Object
{
    int id; /// Unique idencificator
    int gid; /// The identifier to the picture in the tile.
    float x, y; /// Coordinates
    float width, height; /// Size object.
}

/// A group of objects.
class ObjectGroup
{
    public
    {
        string name; /// Name objects group.
        int id; /// Unique udencificator.
        Color!ubyte color; /// Color.
        Property[] properties; /// Object group properties.
        Object[] objects; /// Objects.
        bool visible = true; /// Is visible group
        float   x, /// position
                y; /// ditto
    }
}

/// Map information structure
struct MapMeta
{
    string ver; /// The version of the program in which the tile map was exported.
    string tiledver; /// The version of the standard format for describing tile maps.
    string orientation; /++ Tile map orientation (can be orthogonal, isometric 
                            (the latter is not supported at the moment)) +/
    string renderorder; /// Rendering method (right-to-left, etc.)
    int compressionlevel; /// Compression level of these layers.
    int width, height; /// Map size.
    int tilewidth, tileheight; /// Tile unit size.
    int hexsidelength; /++  Only for hexagonal maps. Determines the width or height 
                            (depending on the staggered axis) of the tile’s edge, in pixels. +/
    int staggeraxis; /// For staggered and hexagonal maps, determines which axis (“x” or “y”) is staggered.
    Color!ubyte backgroundColor; /// The background color of the map
    int nexlayerid; /// Stores the next available ID for new layers.
    int nextobjectid; /// Stores the next available ID for new objects.
    bool infinite; /// Whether this map is infinite.
}

/// Tileset information.
struct TilesetMeta
{
    string ver; /// The version of the program in which the tile map was exported.
    string tiledver; /// The version of the standard format for describing tile maps.
    string name; /// Name tileset.
    int tilewidth, tileheight; /// Tile unit size.
    int tilecount; /// Tile count.
    int columns; /// How many lines the map for tiles is split into.
    int spacing; /// 
    string objectalignment; ///
    string imgsource; /// The path to the file image.
}

/// 
class Tileset
{
    public 
    {
        int firstgid; /// First identificator.
        string source; /// Path to the tileset description file.

        TilesetMeta meta; /// Tileset information.
        string imagesource; /// Path to the image file.

        Image image; /// Atlas.
        Image[] data; /// Tiles.
    }

    /// Prepares the atlas for a group of tiles.
    void setup() @safe
    {
        image = new Image().load(imagesource);
        //foreach (i; 0 .. meta.columns)
        //{
        //    data ~= image.strip(0, i * meta.tileheight, meta.tilewidth, meta.tileheight);
        //}

        foreach (i; 0 .. meta.columns)
        {
            data ~= image.strip(0, i * meta.tileheight, meta.tilewidth, meta.tileheight);
        }

        foreach (e; data) e.toTexture();
    }

    void parse(R, int Type)(R element)
    {
        static if (Type == MapType.XML)
        {
            foreach (attrib; element.attributes)
            {
                if(attrib.name == "source") {
                    imagesource = attrib.value;
                }
            }
        }
    }

    /// Loading tileset information from a file.
    void load() @trusted
    {
        auto xml = parseXML(cast(string) read(source));

        foreach(element; xml) {
            if(	element.type == EntityType.elementStart ||
                element.type == EntityType.elementEmpty)
            {
                if(element.name == "tileset")
                {
                    foreach(attrib; element.attributes) {
                        if(attrib.name == "version") meta.ver = attrib.value;
                        if(attrib.name == "tiledversion") meta.tiledver = attrib.value;
                        if(attrib.name == "name") meta.name = attrib.value;
                        if(attrib.name == "tilewidth") meta.tilewidth = attrib.value.to!int;
                        if(attrib.name == "tileheight") meta.tileheight = attrib.value.to!int;
                        if(attrib.name == "tilecount") meta.tilecount = attrib.value.to!int;
                        if(attrib.name == "columns") meta.columns = attrib.value.to!int;
                    }
                }

                if(element.name == "image")
                {
                    foreach(attrib; element.attributes) {
                        if(attrib.name == "source") {
                            imagesource = attrib.value;
                        }
                    }
                }
            }
        }
    }
}

/// The data of the tiles in the layer.
struct LayerData
{
    import std.array, std.string, std.numeric;

    string encoding; /// Encoding type.
    string compression; /// Compression type.
    uint[] datamap; /// Data of the tiles in the layer.

    /++
        Reads data from an input stream with both XML and JSON data.

        Params:
            R = Type data.
            Type = What card format was provided for reading (XML or JSON)
            data = Layer data.
            compressionLevel = Compression level.
    +/
    void parse(R, int Type)(R data, int compressionlevel = -1) @trusted
    {
        static if(Type == MapType.XML)
        {
            if(data.type == EntityType.elementStart)
            {
                foreach(attrib; data.attributes) {
                    if(attrib.name == "encoding") encoding = attrib.value;
                    if(attrib.name == "compression") compression = attrib.value;
                }
            }else
            if(data.type == EntityType.text)
            {
                if(encoding == "csv")
                {
                    string csvdata = data.text;
                    string[] stolbs = csvdata.split('\n');
                    foreach(es; stolbs) {
                        foreach(ei; es.split(',')) {
                            if(ei.isNumeric)
                                datamap ~= ei.to!int;
                        }
                    }
                }else
                if(encoding == "base64")
                {
                    import std.zlib;
                    import zstd;
                    import std.encoding;

                    ubyte[] decoded = Base64.decode(data.text.strip);

                    if(compression == "zlib")
                    {
                        decoded = cast(ubyte[]) std.zlib.uncompress(cast(void[]) decoded);
                    }else
                    if(compression == "gzip")
                    {
                        decoded = cast(ubyte[]) (new std.zlib.UnCompress(HeaderFormat.gzip).uncompress(cast(void[]) decoded));
                    }else
                    if(compression == "zstd")
                    {
                        auto unc = new zstd.Decompressor();
                        ubyte[] swapData;
            
                        immutable chunkLen = decoded.length / compressionlevel;

                        for(int i = 0; i < decoded.length / chunkLen; i++)
                        {
                            swapData ~= unc.decompress(decoded[(i * chunkLen) .. ((i + 1) * chunkLen)]); 
                        }

                        decoded = swapData;
                    }

                    for(int i = 0; i < decoded.length; i += 4)
                    {
                        datamap ~= decoded[i .. i + 4].byteTo!uint;
                    }
                }
            }
        }else
        static if(Type == MapType.JSON) 
        {
            if(data["encoding"].str == "csv")
            {
                string csvdata = data["data"].str;
                string[] stolbs = csvdata.split('\n');
                foreach(es; stolbs) {
                    foreach(ei; es.split(',')) {
                        if(ei.isNumeric)
                            datamap ~= ei.to!int;
                    }
                }
            }else
            if(data["encoding"].str == "base64")
            {
                import std.zlib;
                import zstd;
                import std.encoding;

                ubyte[] decoded = Base64.decode(data["data"].str);

                if(compression == "zlib")
                {
                    decoded = cast(ubyte[]) std.zlib.uncompress(cast(void[]) decoded);
                }else
                if(compression == "gzip")
                {
                    decoded = cast(ubyte[]) (new std.zlib.UnCompress(HeaderFormat.gzip).uncompress(cast(void[]) decoded));
                }else
                if(compression == "zstd")
                {
                    auto unc = new zstd.Decompressor();
                    ubyte[] swapData;

                    immutable chunkLen = decoded.length / compressionlevel;

                    for(int i = 0; i < decoded.length / chunkLen; i++)
                    {
                        swapData ~= unc.decompress(decoded[(i * chunkLen) .. ((i + 1) * chunkLen)]); 
                    }

                    decoded = swapData;
                }

                for(int i = 0; i < decoded.length; i += 4)
                {
                    datamap ~= decoded[i .. i + 4].byteTo!int;
                }
            }
        }
    }
}

/// Map format
enum MapType : int
{
    XML, JSON
}

/// A layer from a group of tiles.
class TileLayer : IDrawable
{
    public
    {
        int id; /// Unique identificator.
        string name; /// Layer data.
        int width, /// Layer size.
            height; /// Layer size.
        int offsetx, /// Layer offset.
            offsety; /// Layer offset.
        LayerData data; /// Layer data.
        Property[] properties; /// Layer properties.
        bool visible = true; /// Is visible layer.
        Color!ubyte transparentcolor; /// Parent color.
    }

    protected
    {
        TileMap tilemap;
        Sprite[] sprites;
    }

    ///
    this(TileMap tilemap) @safe
    {
        this.tilemap = tilemap;
    }

    /// Prepares tiles into a sprite group for lightweight rendering.
    void setup() @safe {
        int y = 0;
        Sprite currSprite = null;
        for(int i = 0; i < this.data.datamap.length; i++) {
            currSprite = new Sprite();
            if((i - (y * this.width)) == this.width) y++;
            immutable index = this.data.datamap[i] - 1;
            if(index != -1)
            {
                currSprite.draws = tilemap.tile(index);
                currSprite.position = Vecf((i - (y * this.width)) * tilemap.mapinfo.tilewidth,
                                            y * tilemap.mapinfo.tileheight) + Vecf(this.offsetx, this.offsety);
                sprites ~= currSprite;
            }

            currSprite = null;
        }
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        foreach(e; sprites)
            render.draw(e, position);
    }
}

/// A layer from a picture.
class ImageLayer : IDrawable
{
    public
    {
        int id; /// Unique identificator.
        string name; /// Layer name
        float   offsetx, /// Layer offset. (position) 
                offsety; /// Layer offset. (position)
        Image image; /// Layer picture.
        string imagesource; /// Path to the file.
        int x, /// x 
            y; /// y
        float opacity = 1.0f; /// Opacity.
        bool visible = true; /// Layer is visible?
        Color!ubyte tintcolor; /// Tint color
        Property[] properties; /// Layer properties.
    }

    /// Reading data from a document element.
    void parse(R, string nameof)(R data) @safe
    {
        static if(nameof == "imagelayer")
        {
            foreach(attrib; data.attributes)
            {
                if(attrib.name == "id") id = attrib.value.to!int;
                if(attrib.name == "name") name = attrib.value;
                if(attrib.name == "offsetx") offsetx = attrib.value.to!float;
                if(attrib.name == "offsety") offsety = attrib.value.to!float;
                if(attrib.name == "opacity") opacity = attrib.value.to!float;
                if(attrib.name == "visible") visible = attrib.value.to!int == 1;
                if(attrib.name == "tintcolor") tintcolor = Color!ubyte(attrib.value);
            }
        }else
        static if(nameof == "image")
        {
            image = new Image();
            foreach(attrib; data.attributes) {
                if(attrib.name == "source") imagesource = attrib.value;
            }

            image
                .load(imagesource)
                .toTexture();
        }
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        render.draw(image, Vecf(offsetx, offsety));
    }
}

/// Tile Map.
class TileMap : IDrawable
{
    public
    {
        MapMeta mapinfo; /// Map information.
        Tileset[] tilesets; /// Tileset's.
        TileLayer[] layers; /// Layer's.
        ObjectGroup[] objgroups; /// Object group's.
        ImageLayer[] imagelayers; /// Image layer's.
    }

    private
    {
        Image _opt_back;
    }

    void bindExistsFrom(Tileset[] tilesets)
    {
        this.tilesets ~= tilesets; 
    }

    /++
        Loading data from memory.

        Params:
            data = Data (XML/JSON).
    +/
    void loadFromMem(R, int Type)(R data) @trusted
    {
        static if(Type == MapType.XML)
        {
            auto xml = parseXML(data);

            TileLayer currentLayer = null;
            ObjectGroup currentGroup = null;
            ImageLayer currentImage = null;
            Tileset tset = null;
            
            bool isprop = false;
            bool dataelement = false;
            bool isimage = false;
            bool istset = false;

            foreach(element; xml)
            {
                if(	element.type == EntityType.elementStart ||
                    element.type == EntityType.elementEmpty)
                {
                    if(element.name == "map") {
                        foreach(attr; element.attributes)
                        {
                            if(attr.name == "version") mapinfo.ver = attr.value;
                            if(attr.name == "tiledversion") mapinfo.tiledver = attr.value;
                            if(attr.name == "orientation") mapinfo.orientation = attr.value;
                            if(attr.name == "renderorder") mapinfo.renderorder = attr.value;
                            if(attr.name == "width") mapinfo.width = attr.value.to!int;
                            if(attr.name == "height") mapinfo.height = attr.value.to!int;
                            if(attr.name == "tilewidth") mapinfo.tilewidth = attr.value.to!int;
                            if(attr.name == "tileheight") mapinfo.tileheight = attr.value.to!int;
                            if(attr.name == "infinite") mapinfo.infinite = attr.value.to!int == 1;
                            if(attr.name == "backgroundcolor") mapinfo.backgroundColor = Color!ubyte(attr.value);
                            if(attr.name == "nextlayerid") mapinfo.nexlayerid = attr.value.to!int;
                            if(attr.name == "nextobjectid") mapinfo.nextobjectid = attr.value.to!int;
                            if(attr.name == "compressionlevel") mapinfo.compressionlevel = attr.value.to!int;
                        }
                    }else
                    if(element.name == "tileset") {
                        Tileset temp = new Tileset();

                        foreach(attr; element.attributes)
                        {
                            if(attr.name == "firstgid") temp.firstgid = attr.value.to!int;
                            if(attr.name == "source") temp.source = attr.value;
                            if(attr.name == "tilewidth") temp.meta.tilewidth = attr.value.to!int;
                            if(attr.name == "tileheight") temp.meta.tileheight = attr.value.to!int;
                            if(attr.name == "tilecount") temp.meta.tilecount = attr.value.to!int;
                            if(attr.name == "columns") temp.meta.columns = attr.value.to!int;
                        }

                        if (temp.source != "")
                        {
                            temp.load();
                        } else
                        {
                            istset = true;
                            tset = temp;
                        }

                        bool needLoad = true;
                        foreach (e; tilesetStorage)
                        {
                            if (e.source == temp.source)
                            {
                                needLoad = false;
                                tilesets ~= e;
                                break;
                            }
                        }
               

                        if (needLoad)
                        {
                            tilesets ~= temp;
                        } else
                        {
                            destroy(temp);
                            tset = null;
                            istset = false;
                        }
                    }else
                    if(element.name == "layer")
                    {
                        TileLayer layer = new TileLayer(this);

                        foreach(attrib; element.attributes)
                        {
                            if(attrib.name == "name") layer.name = attrib.value;
                            if(attrib.name == "id") layer.id = attrib.value.to!int;
                            if(attrib.name == "width") layer.width = attrib.value.to!int;
                            if(attrib.name == "height") layer.height = attrib.value.to!int;
                            if(attrib.name == "offsetx") layer.offsetx = attrib.value.to!int;
                            if(attrib.name == "offsety") layer.offsety = attrib.value.to!int;
                        }

                        currentLayer = layer;
                    }else
                    if(element.name == "data") {
                        currentLayer.data.parse!(typeof(element), MapType.XML)(element);
                        dataelement = true;
                    }else
                    if(element.name == "objectgroup") {
                        ObjectGroup temp = new ObjectGroup();
                        foreach(attrib; element.attributes) {
                            if(attrib.name == "color") temp.color = Color!ubyte(attrib.value);
                            if(attrib.name == "id") temp.id = attrib.value.to!int;
                            if(attrib.name == "name") temp.name = attrib.value;
                        }
                        currentGroup = temp;
                    }else
                    if(element.name == "properties") {
                        isprop = true;
                    }else
                    if(element.name == "property") {
                        Property prop;
                        foreach(attrib; element.attributes) {
                            if(attrib.name == "name") prop.name = attrib.value;
                            if(attrib.name == "type") prop.type = attrib.value;
                            if(attrib.name == "value") prop.value = attrib.value;
                        }

                        if(currentGroup !is null) currentGroup.properties ~= prop; else 
                        if(currentLayer !is null) currentLayer.properties ~= prop; else
                        if(currentImage !is null) currentImage.properties ~= prop;
                    }else
                    if(element.name == "object") {
                        Object obj;
                        foreach(attrib; element.attributes) {
                            if(attrib.name == "id") obj.id = attrib.value.to!int;
                            if(attrib.name == "gid") obj.gid = attrib.value.to!int;
                            if(attrib.name == "x") obj.x = attrib.value.to!float;
                            if(attrib.name == "y") obj.y = attrib.value.to!float;
                            if(attrib.name == "width") obj.width = attrib.value.to!float;
                            if(attrib.name == "height") obj.height = attrib.value.to!float;
                        }

                        currentGroup.objects ~= obj;
                    }else
                    if(element.name == "imagelayer") {
                        currentImage = new ImageLayer();
                        currentImage.parse!(typeof(element), "imagelayer")(element);
                    }else
                    if(element.name == "image") {
                        isimage = true;
                        if(currentImage !is null) currentImage.parse!(typeof(element), "image")(element);
                        else
                            if(tset !is null) tset.parse!(typeof(element), MapType.XML)(element);
                    }
                }else
                if(element.type == EntityType.elementEnd) {
                    if(element.name == "layer") {
                        layers ~= currentLayer;
                        currentLayer = null;
                    }else
                    if(element.name == "data") {
                        dataelement = false;
                    }else
                    if(element.name == "objectgroup") {
                        objgroups ~= currentGroup;
                        currentGroup = null;
                    }else
                    if(element.name == "properties") {
                        isprop = false;
                    }else
                    if(element.name == "imagelayer") {
                        imagelayers ~= currentImage;
                        currentImage = null;
                    }else
                    if(element.name == "image") {
                        isimage = false;
                    }else
                    if(element.name == "tileset") {
                        tset = null;
                        istset = false;
                    }
                }else
                if(element.type == EntityType.text) {
                    if(dataelement) {
                        currentLayer.data.parse!(typeof(element),Type)(element, mapinfo.compressionlevel);
                    }else
                    if(isimage) {
                        if(currentImage !is null)
                            currentImage.parse!(typeof(element),"image")(element);
                    }
                }
            }
        }else
        static if(Type == MapType.JSON)
        {
            auto json = data.parseJSON;

            Property[] propertiesParse(JSONValue elem) @trusted
            {
                Property[] prs;
                foreach(e; elem["properties"].array) {
                    Property temp;
                    temp.name = e["name"].str;
                    temp.type = e["type"].str;
                    if(temp.type == "int") 
                        temp.value = e["value"].get!int.to!string;
                    else
                    if(temp.type == "string")
                        temp.value = e["value"].str;

                    prs ~= temp;
                }

                return prs;
            }

            assert(json.isKeyExists("type"), "It's not a json map!");
            assert(json["type"].str == "map", "It's not a json map!");

            if(json.isKeyExists("backgroundcolor")) mapinfo.backgroundColor = Color!ubyte(json["backgroundcolor"].str);
            mapinfo.compressionlevel = json["compressionlevel"].get!int;
            mapinfo.width = json["width"].get!int;
            mapinfo.height = json["height"].get!int;
            mapinfo.infinite = json["infinite"].get!bool;
            mapinfo.nexlayerid = json["nextlayerid"].get!int;
            if(json.isKeyExists("nextobjectid")) mapinfo.nextobjectid = json["nextobjectid"].get!int;
            mapinfo.orientation = json["orientation"].str;
            mapinfo.tiledver = json["tiledversion"].str;
            mapinfo.ver = json["version"].str;
            mapinfo.tilewidth = json["tilewidth"].get!int;
            mapinfo.tileheight = json["tileheight"].get!int;
            mapinfo.renderorder = json["renderorder"].str;

            foreach(e; json["tilesets"].array) {
                Tileset tileset = new Tileset();
                tileset.firstgid = e["firstgid"].get!int;
                tileset.source = e["source"].str;
                tileset.load();
                tilesets ~= tileset;
            }

            foreach(e; json["layers"].array) {
                if(e["type"].str == "tilelayer") {
                    TileLayer tilelayer = new TileLayer(this);
                    tilelayer.id = e["id"].get!int;
                    tilelayer.visible = e["visible"].get!bool;
                    if(e.isKeyExists("offsetx")) tilelayer.offsetx = e["offsetx"].get!int;
                    if(e.isKeyExists("offsety")) tilelayer.offsety = e["offsety"].get!int;
                    tilelayer.width = e["width"].get!int;
                    tilelayer.height = e["height"].get!int;
                    tilelayer.data.compression = e["compression"].str;
                    tilelayer.data.encoding = e["encoding"].str;
                    if(e.isKeyExists("transparentcolor")) 
                        tilelayer.transparentcolor = Color!ubyte(e["transparentcolor"].str);
                    tilelayer.data.parse!(typeof(e),Type)(e, mapinfo.compressionlevel);
                    if(e.isKeyExists("properties"))
                        tilelayer.properties = propertiesParse(e["properties"]);
                    layers ~= tilelayer;
                }else
                if(e["type"].str == "imagelayer") {
                    ImageLayer imagelayer = new ImageLayer();
                    imagelayer.id = e["id"].get!int;
                    imagelayer.name = e["name"].str;
                    imagelayer.imagesource = e["image"].str;
                    imagelayer.opacity = e["opacity"].get!float;
                    imagelayer.visible = e["visible"].get!bool;
                    imagelayer.offsetx = e["offsetx"].get!int;
                    imagelayer.offsety = e["offsety"].get!int;
                    if(e.isKeyExists("properties")) imagelayer.properties = propertiesParse(e);
                    imagelayer.image = new Image().load(imagelayer.imagesource);
                    imagelayer.image.toTexture();
                    imagelayers ~= imagelayer;
                }else
                if(e["type"].str == "objectgroup") {
                    ObjectGroup group = new ObjectGroup();
                    group.id = e["id"].get!int;
                    group.name = e["name"].str;
                    group.color = Color!ubyte(e["color"].str);
                    group.visible = e["visible"].get!bool;
                    if(e.isKeyExists("offsetx")) group.x = e["offsetx"].get!int;
                    if(e.isKeyExists("offsety")) group.y = e["offsety"].get!int;
                    foreach(elem; e["objects"].array) {
                        Object obj;
                        obj.gid = elem["gid"].get!int;
                        obj.width = elem["width"].get!int;
                        obj.height = elem["height"].get!int;
                        obj.x = elem["x"].get!int;
                        obj.y = elem["y"].get!int;
                        group.objects ~= obj;
                    }
                    if(e.isKeyExists("properties")) group.properties = propertiesParse(e);
                }
            }
        }
    }

    /// Load data from file.
    void load(string path) @trusted
    {
        import std.path;

        if(path.extension == ".tmx")
        {
            loadFromMem!(string, MapType.XML)(cast(string) read(path));
        }else
        if(path.extension == ".json")
        {
            loadFromMem!(string, MapType.JSON)(cast(string) read(path));
        }
    }

    public
    {
        IDrawable[] drawableSort;
    }

    void sort() @safe
    {
        import std.algorithm : sort;

        drawableSort = [];

        struct SortLayerStruct { IDrawable obj; int id; }
        SortLayerStruct[] list;
        foreach(e; layers) list ~= SortLayerStruct(e, e.id);
        foreach(e; imagelayers) list ~= SortLayerStruct(e, e.id);

        sort!((a,b) => a.id < b.id)(list);

        foreach(e; list) drawableSort ~= e.obj;
    }

    /// Prepare layers for work.
    void setup() @safe
    {
        foreach(e; tilesets)
        {
            tilesetStorage ~= e;
            e.setup();
        }

        foreach(e; layers)
        {
            e.setup();
        }

        sort();
    }

    ///
    ObjectGroup objgroupByName(string name) @safe
    {
        foreach(e; objgroups) if(e.name == name) return e;

        return ObjectGroup.init;
    }

    ///
    Image tile(int id) @safe
    {
        Image image = null;
        int currTileSet = 0;
        int countPrevious = 0;

        while (image is null)
        {
            if(currTileSet == this.tilesets.length) break;

            countPrevious += this.tilesets[currTileSet].data.length;

            if(id > countPrevious) {
                currTileSet++;
            }else
                image = this.tilesets[currTileSet].data[currTileSet != 0 ? id - countPrevious : id];
        }

        return image;
    }

    void optimize() @safe
    {
        import tida.softimage;
        import tida.shape;
        import tida.game : renderer;
        import std.algorithm : remove;

        Color!ubyte previous = renderer.background;
        renderer.background = rgba(0, 0, 0, 0);
        renderer.clear();

        foreach (e; drawableSort)
        {
            if ((cast(TileLayer) e) !is null)
            {
                renderer.clear();
                renderer.draw(e, vecf(0, 0));
                layers = layers.remove!(a => a is e);

                TileLayer lobj = cast(TileLayer) e;

                renderer.draw(lobj, vecf(0,0));
                _opt_back = renderRead( renderer, vecf(0, 0), mapinfo.width * mapinfo.tilewidth, 
                                        mapinfo.height * mapinfo.tileheight);

                _opt_back = _opt_back.flip!(YAxis);
                _opt_back.toTexture;

                ImageLayer imglayer = new ImageLayer();
                imglayer.offsetx = lobj.offsetx;
                imglayer.offsety = lobj.offsety;
                imglayer.image = _opt_back;
                imglayer.id = lobj.id;
                imagelayers ~= imglayer;

                _opt_back = null;
            }
        }

        sort();

        renderer.background = previous;
        renderer.clear();
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        foreach(e; drawableSort)
        {
            render.draw(e, position);
        }
    }
}
