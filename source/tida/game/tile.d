module tida.game.tile;

/// Tile
struct Tile
{
    import tida.graph.image;
    import tida.vector;

    public
    {
        Image image; /// Tile data
        Vecf position; /// Tile position
        size_t depth = 0; /// Tile depth
    }

    int opCmp(Tile o) 
    {
        return (this.depth > o.depth);
    }
}