module tida.tiled;

import dxml.parser;
import std.file : read;
import std.conv;
import std.base64;

import tida;

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    foreach(i; 0 .. bytes.length) data = cast(T) (((data & 0xFF) << 8) + bytes[i]);

    return data;
}

struct Property
{
    string name;
    string type;
    string value;

    T get(T)() @safe
    {
        return value.to!T;
    }
}

struct Object
{
    int id;
    int gid;
    int x, y;
    int width, height;
}

class ObjectGroup
{
    string name;
    int id;
    Color!ubyte color;
    Property[] properties;
    Object[] objects;
}

struct MapMeta
{
    string ver;
    string tiledver;
    string orientation;
    string renderorder;
    int compressionlevel;
    int width, height;
    int tilewidth, tileheight;
    int hexsidelength;
    int staggeraxis;
    Color!ubyte backgroundColor;
    int nexlayerid;
    int nextobjectid;
    bool infinite;
}

struct TilesetMeta
{
    string ver;
    string tiledver;
    string name;
    int tilewidth, tileheight;
    int tilecount;
    int columns;
    string imgsource;
}

class Tileset
{
    int firstgid;
    string source;

    TilesetMeta meta;
    string imagesource;

    Image image;
    Image[] data;

    void setup() @safe {
        image = new Image().load(imagesource);
        foreach(i; 0 .. meta.columns)
        {
            data ~= image.strip(0, i * meta.tileheight, meta.tilewidth, meta.tileheight);
        }

        foreach(e; data) e.fromTexture();
    }

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

struct LayerData
{
    import std.array, std.string, std.numeric;

    string encoding;
    string compression;
    int[] datamap;

    void parse(R)(R data) @trusted
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
                debug(tiled_base64)
                {
                    import std.zlib;

                    auto decoded = Base64.decode(data.text);

                    if(compression == "zlib")
                    {
                        datamap = cast(int[]) std.zlib.uncompress(cast(void[]) decoded);
                    }

                    for(int i = 0; i < decoded.length; i += 4)
                    {
                        datamap ~= decoded[i .. i + 4].byteTo!int;
                    }
                }else
                    assert(false, "Base64 is not support!");
            }
        }
    }
}

struct TileLayer
{
    int id;
    string name;
    int width, height;
    int offsetx, offsety;
    LayerData data;
}

class TileMap : IDrawable
{
    MapMeta mapinfo;
    Tileset[] tilesets;
    TileLayer[] layers;
    ObjectGroup[] objgroups;

    void loadFromMem(R)(R data) @trusted
    {
        auto xml = parseXML(data);

        TileLayer* currentLayer = null;
        bool dataelement = false;

        ObjectGroup* currentGroup = null;
        bool isprop = false;

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
                    TileLayer layer;

                    foreach(attrib; element.attributes) {
                        if(attrib.name == "name") layer.name = attrib.value;
                        if(attrib.name == "id") layer.id = attrib.value.to!int;
                        if(attrib.name == "width") layer.width = attrib.value.to!int;
                        if(attrib.name == "height") layer.height = attrib.value.to!int;
                        if(attrib.name == "offsetx") layer.offsetx = attrib.value.to!int;
                        if(attrib.name == "offsety") layer.offsety = attrib.value.to!int;
                    }

                    currentLayer = &layer;
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
                    currentGroup = &temp;
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

                    currentGroup.properties ~= prop;
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
                }
            }else
            if(element.type == EntityType.elementEnd) {
                if(element.name == "layer") {
                    layers ~= *currentLayer;
                    currentLayer = null;
                }else
                if(element.name == "data") {
                    dataelement = false;
                }else
                if(element.name == "objectgroup") {
                    objgroups ~= *currentGroup;
                    currentGroup = null;
                }else
                if(element.name == "properties") {
                    isprop = false;
                }
            }else
            if(element.type == EntityType.text) {
                if(dataelement) {
                    currentLayer.data.parse(element);
                }
            }
        }
    }

    void load(string path) @trusted
    {
        loadFromMem(cast(string) read(path));
    }

    void setup() @safe
    {
        renderer.background = mapinfo.backgroundColor;

        foreach(e; tilesets) {
            e.setup();
        }
    }

    ObjectGroup objgroupByName(string name) @safe
    {
        foreach(e; objgroups) if(e.name == name) return e;

        return ObjectGroup.init;
    }

    Image tile(int id) @safe
    {
        Image image = null;
        int currTileSet = 0;

        while(image is null) {
            if(currTileSet == this.tilesets.length) break;

            int countPrevious = 0;
            foreach(i; 0 .. currTileSet) countPrevious += this.tilesets[i].data.length;

            if(id > countPrevious) {
                currTileSet++;
            }else
                return this.tilesets[currTileSet].data[id - countPrevious];
        }

        return null;
    }

    override void draw(IRenderer render, Vecf position) @safe
    {
        foreach(e; layers) {
            int y = 0;
            for(int i = 0; i < e.data.datamap.length; i++) {
                if((i - (y * e.width)) == e.width) y++;
                immutable index = e.data.datamap[i] - 1;
                if(index != -1)
                render.draw(tile(index),
                            position + Vecf((i - (y * e.width)) * mapinfo.tilewidth,
                                            y * mapinfo.tileheight) + Vecf(e.offsetx, e.offsety));
            }
        }
    }
}
