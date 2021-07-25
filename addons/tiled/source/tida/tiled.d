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
import std.file : read;
import std.conv : to;
import std.base64;

import tida.graph.drawable;
import tida.graph.render;
import tida.graph.image;
import tida.color;
import tida.vector;
import tida.game.sprite;

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    foreach(i; 0 .. bytes.length) data |= bytes[i] << (8 * i);

    return data;
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
    int x, y; /// Coordinates
    int width, height; /// Size object.
}

/// A group of objects.
class ObjectGroup
{
    string name; /// Name objects group.
    int id; /// Unique udencificator.
    Color!ubyte color; /// Color.
    Property[] properties; /// Object group properties.
    Object[] objects; /// Objects.
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
    void setup() @safe {
        image = new Image().load(imagesource);
        foreach(i; 0 .. meta.columns)
        {
            data ~= image.strip(0, i * meta.tileheight, meta.tilewidth, meta.tileheight);
        }

        foreach(e; data) e.fromTexture();
    }

    /// Loading tileset information from a file.
    void load() @trusted {
        auto xml = parseXML(cast(string) read(source));

        foreach(element; xml) {
            if(	element.type == EntityType.elementStart ||
                element.type == EntityType.elementEmpty)
            {
                if(element.name == "tileset") {
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

                if(element.name == "image") {
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
    int[] datamap; /// Data of the tiles in the layer.

    /// Type recognition or data reading, depending on the information specified in the argument.
    void parse(R)(R data, int compressionlevel = -1) @trusted
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

                ubyte[] decoded = Base64.decode(data.text[4 .. $ - 3]);

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

                    for(int i = 0; i < decoded.length / chunkLen; i++) {
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

/// A layer from a group of tiles.
class TileLayer : IDrawable
{
    public
    {
        int id; /// Unique identificator.
        string name; /// Layer data.
        int width, height; /// Layer size.
        int offsetx, offsety; /// Layer offset
        LayerData data; /// Layer data.
        Property[] properties; /// Layer properties.
    }

    protected
    {
        TileMap tilemap;
        Sprite[] sprites;
    }

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
        int offsetx, offsety; /// Layer offset. (position)
        Image image; /// 
        string imagesource; /// Path to the file.
        int x, y; /// 
        float opacity = 1.0f; /// Opacity.
        bool visible = true; /// Layer is visible?
        Color!ubyte tintcolor; ///
        Property[] properties; /// Layer properties.
    }

    /// Reading data from a document element.
    void parse(R)(R data) @safe
    {
        if(data.name == "imagelayer")
        {
            foreach(attrib; data.attributes)
            {
                if(attrib.name == "id") id = attrib.value.to!int;
                if(attrib.name == "name") name = attrib.value;
                if(attrib.name == "offsetx") offsetx = attrib.value.to!int;
                if(attrib.name == "offsety") offsety = attrib.value.to!int;
                if(attrib.name == "opacity") opacity = attrib.value.to!float;
                if(attrib.name == "visible") visible = attrib.value.to!int == 1;
                if(attrib.name == "tintcolor") tintcolor = HEX(attrib.value);
            }
        }else
        if(data.name == "image")
        {
            image = new Image();
            foreach(attrib; data.attributes) {
                if(attrib.name == "source") imagesource = attrib.value;
            }

            image
                .load(imagesource)
                .fromTexture();
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

    /++
        Loading data from memory.

        Params:
            data = Data (XML/JSON).
    +/
    void loadFromMem(R)(R data) @safe
    {
        auto xml = parseXML(data);

        TileLayer currentLayer = null;
        ObjectGroup currentGroup = null;
        ImageLayer currentImage = null;
        
        bool isprop = false;
        bool dataelement = false;
        bool isimage = false;

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
                        if(attr.name == "backgroundcolor") mapinfo.backgroundColor = HEX(attr.value);
                        if(attr.name == "nextlayerid") mapinfo.nexlayerid = attr.value.to!int;
                        if(attr.name == "nextobjectid") mapinfo.nextobjectid = attr.value.to!int;
                        if(attr.name == "compressionlevel") mapinfo.compressionlevel = attr.value.to!int;
                    }
                }else
                if(element.name == "tileset") {
                    Tileset temp = new Tileset();

                    foreach(attr; element.attributes) {
                        if(attr.name == "firstgid") temp.firstgid = attr.value.to!int;
                        if(attr.name == "source") temp.source = attr.value;
                    }

                    temp.load();
                    tilesets ~= temp;
                }else
                if(element.name == "layer") {
                    TileLayer layer = new TileLayer(this);

                    foreach(attrib; element.attributes) {
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
                    currentLayer.data.parse(element);
                    dataelement = true;
                }else
                if(element.name == "objectgroup") {
                    ObjectGroup temp = new ObjectGroup();
                    foreach(attrib; element.attributes) {
                        if(attrib.name == "color") temp.color = HEX(attrib.value);
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
                        if(attrib.name == "x") obj.x = attrib.value.to!int;
                        if(attrib.name == "y") obj.y = attrib.value.to!int;
                        if(attrib.name == "width") obj.width = attrib.value.to!int;
                        if(attrib.name == "height") obj.height = attrib.value.to!int;
                    }

                    currentGroup.objects ~= obj;
                }else
                if(element.name == "imagelayer") {
                    currentImage = new ImageLayer();
                    currentImage.parse(element);
                }else
                if(element.name == "image") {
                    isimage = true;
                    if(currentImage !is null) currentImage.parse(element);
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
                }
            }else
            if(element.type == EntityType.text) {
                if(dataelement) {
                    currentLayer.data.parse(element, mapinfo.compressionlevel);
                }else
                if(isimage) {
                    currentImage.parse(element);
                }
            }
        }
    }

    /// Load data from file.
    void load(string path) @trusted
    {
        loadFromMem(cast(string) read(path));
    }

    /// Prepare layers for work.
    void setup() @safe
    {
        foreach(e; tilesets) {
            e.setup();
        }

        foreach(e; layers) {
            e.setup();
        }
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

        while(image is null) {
            if(currTileSet == this.tilesets.length) break;

            countPrevious += this.tilesets[currTileSet].data.length;

            if(id > countPrevious) {
                currTileSet++;
            }else
                image = this.tilesets[currTileSet].data[currTileSet != 0 ? id - countPrevious : id];
        }

        return image;
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        foreach(e; layers) 
            render.draw(e, position);

        foreach(e; imagelayers)
            render.draw(e, position);
    }
}
