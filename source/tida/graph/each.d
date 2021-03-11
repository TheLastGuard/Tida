module tida.graph.each;

static immutable Parallel = 1;
static immutable NoParallel = 0;

enum DefaultOperation = NoParallel;

auto Coord(int Type = DefaultOperation)(uint width,uint height,int beginX = 0,int beginY = 0) @safe
{
    static if(Type == NoParallel)
    {
        return (int delegate(ref int x,ref int y) @safe dg) @safe {
            for(int ix = beginX; ix < width; ix++)
            {
                for(int iy = beginY; iy < height; iy++)
                {
                    dg(ix,iy);
                }
            }

            return 0;
        };
    }else
    static if(Type == Parallel)
    {
        return (int delegate(ref int x,ref int y) @safe dg) @trusted {
            import std.parallelism, std.range;

            foreach(ix; parallel(iota(beginX, width)))
            {
                foreach(iy; parallel(iota(beginY, height)))
                {
                    int dx = ix;
                    int dy = iy;

                    dg(dx,dy);
                }
            }

            return 0;
        };
    }
}

import tida.vector, std.conv : to;

auto Line(Vecf begin,Vecf end) @safe
{
    import std.math : abs;

    return (int delegate(ref int x,ref int y) @safe dh) @safe {
        int x1 = begin.x.to!int;
        int y1 = begin.y.to!int;
        const x2 = end.x.to!int;
        const y2 = end.y.to!int;

        const deltaX = abs(x2 - x1);
        const deltaY = abs(y2 - y1);
        const signX = x1 < x2 ? 1 : -1;
        const signY = y1 < y2 ? 1 : -1;

        int error = deltaX - deltaY;

        while(x1 != x2 || y1 != y2) {
            dh(x1,y1);

            const error2 = error * 2;

            if(error2 > -deltaY) {
                error -= deltaY;
                x1 += signX;
            }

            if(error2 < deltaX) {
                error += deltaX;
                y1 += signY;
            }
        }

        return 0;
    };
}