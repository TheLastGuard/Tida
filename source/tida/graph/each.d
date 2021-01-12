module tida.graph.each;

public auto Coord(uint width,uint height,int beginX = 0,int beginY = 0) @safe 
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
}