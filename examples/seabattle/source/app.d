/++
    Implementation of the "Sea Battle" game on the "Tida" framework using the OOP structure.
    
    At the moment, only one game can be played alone with a bot. The bot can make moves, 
    and if it finds a ship, it finds adjacent decks until it completely destroys it.
    
    Win or lose is determined by the background. If green - the player won, red - the computer.
    
    To restart the game, press the "R" button and the game will clear the field and randomly generate both cards.
    
    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module seabattle;

import tida;

immutable CellStateSize = 16;

enum CellState
{
    Empty,
    Missed,
    Wounded,
    ShipUnite
}

void generateFieldGrid(ref CellState[10][10] grid) @safe
{
    import 	std.random,
            std.algorithm : canFind;

    bool isEmptyUnite(int x, int y) {
        bool[] trace;

        trace ~= grid[x][y] == CellState.Empty;
        if(x - 1 >= 0) trace ~= grid[x - 1][y] == CellState.Empty;
        if(x + 1 < 10) trace ~= grid[x + 1][y] == CellState.Empty;
        if(y - 1 >= 0) trace ~= grid[x][y - 1] == CellState.Empty;
        if(y + 1 < 10) trace ~= grid[x][y + 1] == CellState.Empty;

        return !trace.canFind(false);
    }

    void genShip(int size)
    {
        if(uniform(0, 2) == 1)
        {
            int posX = uniform(0, 10 - size);
            int posY = uniform(0, 10);
 
            for(int i = posX; i < posX + size; i++) { 
                 if(!isEmptyUnite(i, posY)) {
                    genShip(size);
                    return;
                }
            }
 
            for(int i = posX; i < posX + size; i++) grid[i][posY] = CellState.ShipUnite;
        }else
        {
            int posX = uniform(0, 10);
            int posY = uniform(0, 10 - size);
 
            for(int i = posY; i < posY + size; i++) {
                if(!isEmptyUnite(posX, i)) {
                    genShip(size);
                    return;
                }
            }
 
            for(int i = posY; i < posY + size; i++) grid[posX][i] = CellState.ShipUnite;
        }
    }
 
    foreach(_; 0 .. 2) genShip(4);
    foreach(_; 0 .. 3) genShip(3);
    foreach(_; 0 .. 4) genShip(2);
    foreach(_; 0 .. 5) genShip(1);
}

void clearFieldGrid(ref CellState[10][10] grid) @safe
{
    for(int y = 0; y < grid.length; y++)
    {
        for(int x; x < grid[0].length; x++)
        {
            grid[x][y] = CellState.Empty;
        }
    }
}

class PlayingField : Instance
{
    public
    {
        CellState[10][10] grid;
        Symbol[] numerateVertical;
        Symbol[] numerateHorizontal;
        bool isVisibleShip = true;
        Vecf mousePosition = vecfNaN;
    }

    this(Font font) @safe
    {
        numerateVertical = new Text(font).toSymbols("0123456789", rgb(0, 0, 0));
        numerateHorizontal = new Text(font).toSymbols("abcdefghij", rgb(0, 0, 0));
        generateFieldGrid(grid);
    }

    @event(Input)
    void onEvent(EventHandler event) @safe
    {
        mousePosition = vecf(event.mousePosition[0], event.mousePosition[1]);
    }

    CellState mark(int posX, int posY) @safe
    {
        auto state = grid[posX][posY];
        if(state == CellState.Empty) {
            grid[posX][posY] = CellState.Missed;
            return CellState.Missed;
        } else
        if(state == CellState.ShipUnite) {
            grid[posX][posY] = CellState.Wounded;
            return CellState.Wounded;
        } else
            return grid[posX][posY];
    }

    bool isMouseHoverUniteGrid(int x, int y) @safe
    {
        return  mousePosition.x > position.x + (x * CellStateSize) &&
                mousePosition.y > position.y + (y * CellStateSize) &&
                mousePosition.x < position.x + (x * CellStateSize) + CellStateSize &&
                mousePosition.y < position.y + (y * CellStateSize) + CellStateSize;   
    }

    @event(Draw)
    void draw(IRenderer render) @safe
    {	
        for(int y = 0; y < grid.length; y++)
        {
            render.drawEx(	numerateVertical[y].image, 
            				position + Vecf(-12, y * CellStateSize),
            				0.0f,
            				vecfNaN,
            				vecfNaN,
            				255,
            				rgb(0, 0, 0)); 
            render.drawEx(	numerateHorizontal[y].image, 
            				position + Vecf(y * CellStateSize, -6) - numerateHorizontal[y].position,
            				0.0f,
            				vecfNaN,
            				vecfNaN,
            				255,
            				rgb(0, 0, 0));
            for(int x; x < grid[0].length; x++)
            {
                
                if(isMouseHoverUniteGrid(x, y)) {
                    render.rectangle(position + Vecf(x * CellStateSize, y * CellStateSize),
                         CellStateSize, CellStateSize, rgb(200, 200, 200), true);
                    render.rectangle(position + Vecf(x * CellStateSize, y * CellStateSize),
                         CellStateSize, CellStateSize, rgb(255, 0, 0), false);
                } else
                {
                    render.rectangle(position + Vecf(x * CellStateSize, y * CellStateSize),
                         CellStateSize, CellStateSize, rgb(0, 0, 0), false);
                }

                if(grid[x][y] != CellState.Empty) {
                    auto state = grid[x][y];
                    if(grid[x][y] == CellState.Missed) {
                        render.circle(	position + Vecf(x * CellStateSize + (CellStateSize / 2), y * CellStateSize + (CellStateSize / 2)),
                                CellStateSize / 2, rgb(0, 0, 0), true);
                    } else
                    if(grid[x][y] == CellState.Wounded) {
                        render.line( [	position + Vecf(x * CellStateSize, y * CellStateSize),
                                position + Vecf(x * CellStateSize + CellStateSize, y * CellStateSize + CellStateSize) ],
                                rgb(0,0,0));
                        render.line( [	position + Vecf(x * CellStateSize + CellStateSize, y * CellStateSize),
                                position + Vecf(x * CellStateSize, y * CellStateSize + CellStateSize) ],
                                rgb(0,0,0));
                    } else
                    if(grid[x][y] == CellState.ShipUnite && isVisibleShip) {
                        render.rectangle(	position + Vecf(x * CellStateSize, y * CellStateSize),
                                    CellStateSize, CellStateSize, rgb(0, 0, 0), true);
                    }
                }
            }
        }
    }
}

class Bot
{
    public
    {
        PlayingField playerField;
        PlayingField selfField;

        CellState[10][10] marked;
    }

    this(PlayingField playerField, PlayingField selfField) @safe
    {
        this.playerField = playerField;
        this.selfField = selfField;
    }

    enum Side { none, left, right, up, down };

    private
    {
        Side currentSide = Side.none; 
        int lastPosX = 0;
        int lastPosY = 0;
        bool lastSucces = false;

        int wordedX = -1;
        int wordedY = -1;

        Side[4] lastSides;
        int currSideI = 0;
    }

    void clear() @safe
    {
        currentSide = Side.none;
        lastPosX = 0;
        lastPosY = 0;
        lastSucces = false;
        wordedX = -1;
        wordedY = -1;
        lastSides[0 .. 4] = Side.none;
        currSideI = 0;
        clearFieldGrid(marked);
    }

    void makeAMove() @safe
    {
        import std.random : uniform;
        import std.algorithm : canFind;

        int posX, posY;

        bool isMarkedEmpty(int x, int y) { 
            if(x >= 0 && x < 10 && y >= 0 && y < 10) 
                return marked[x][y] == CellState.Empty; 
            else 
                return false; 
        }

        if(currentSide == Side.none) {
            posX = uniform(0, 10);
            posY = uniform(0, 10);
        } else
        if(currentSide == Side.up) {
            posX = lastPosX;
            posY = lastPosY - 1;
        } else
        if(currentSide == Side.down) {
            posX = lastPosX;
            posY = lastPosY + 1;
        } else
        if(currentSide == Side.left) {
            posX = lastPosX - 1;
            posY = lastPosY;
        } else
        if(currentSide == Side.right) {
            posX = lastPosX + 1;
            posY = lastPosY;
        }

        if(isMarkedEmpty(posX, posY))
        {
            auto last = playerField.mark(posX, posY);
            marked[posX][posY] = last;

            if(last == CellState.Wounded) {
                if(!lastSucces)
                {
                    if(isMarkedEmpty(posX, posY - 1))
                    {
                        currentSide = Side.up;
                        lastPosX = posX;
                        lastPosY = posY;
                        lastSides[++currSideI] = currentSide;
                    }else
                    if(isMarkedEmpty(posX, posY + 1))
                    {
                        currentSide = Side.down;
                        lastPosX = posX;
                        lastPosY = posY;
                        lastSides[++currSideI] = currentSide;
                    }else
                    if(isMarkedEmpty(posX - 1, posY))
                    {
                        currentSide = Side.left;
                        lastPosX = posX;
                        lastPosY = posY;
                        lastSides[++currSideI] = currentSide;
                    }else
                    if(isMarkedEmpty(posX + 1, posY))
                    {
                        currentSide = Side.right;
                        lastPosX = posX;
                        lastPosY = posY;
                        lastSides[++currSideI] = currentSide;
                    }

                    wordedX = posX;
                    wordedY = posY;

                    lastSucces = true;
                }else
                {
                    switch(currentSide)
                    {
                        case Side.left:
                            if(!isMarkedEmpty(posX - 1, posY)) {
                                lastPosX = wordedX;
                                lastPosY = wordedY;
                                lastSucces = false;
                                goto default;
                            }
                            break;

                        case Side.right:
                            if(!isMarkedEmpty(posX + 1, posY)) {
                                lastPosX = wordedX;
                                lastPosY = wordedY;
                                lastSucces = false;
                                goto default;
                            }
                            break;

                        case Side.up:
                            if(!isMarkedEmpty(posX, posY - 1)) {
                                lastPosX = wordedX;
                                lastPosY = wordedY;
                                lastSucces = false;
                                goto default;
                            }
                            break;

                        case Side.down:
                            if(!isMarkedEmpty(posX, posY + 1)) {
                                lastPosX = wordedX;
                                lastPosY = wordedY;
                                lastSucces = false;
                                goto default;
                            }
                            break;

                        default:
                            lastPosX = 0;
                            lastPosY = 0;
                            wordedX = -1;
                            wordedY = -1;
                            lastSucces = false;
                            currentSide = Side.none;
                            return;
                    }

                    lastPosX = posX;
                    lastPosY = posY;
                }
            }else
            {
                if(wordedX != -1) {
                    bool ll = 0, lr = 0, lu = 0, ld = 0;
                    foreach(i; 0 .. currSideI) {
                        if(lastSides[i] == Side.up) lu = 1; else
                        if(lastSides[i] == Side.down) ld = 1; else
                        if(lastSides[i] == Side.left) ll = 1; else
                        if(lastSides[i] == Side.right) lr = 1; 
                    }

                    if(!ll && isMarkedEmpty(wordedX - 1, wordedY)) { 
                        currentSide = Side.left;
                        lastPosX = wordedX;
                        lastPosX = wordedY;
                        return;
                    }else
                    if(!lr && isMarkedEmpty(wordedX + 1, wordedY)) {
                        currentSide = Side.right;
                        lastPosX = wordedX;
                        lastPosX = wordedY;
                        return;
                    }else
                    if(!lu && isMarkedEmpty(wordedX, wordedY - 1)) {
                        currentSide = Side.up;
                        lastPosX = wordedX;
                        lastPosX = wordedY;
                        return;
                    }else
                    if(!ld && isMarkedEmpty(wordedX, wordedY + 1)) {
                        currentSide = Side.down;
                        lastPosX = wordedX;
                        lastPosX = wordedY;
                        return;
                    }else
                    {
                        currentSide = Side.none;
                        wordedX = -1;
                        wordedY = -1;
                        lastSucces = 0;
                        currSideI = 0;
                        return;
                    }
                }else {
                    currentSide = Side.none;
                    currSideI = 0;
                }
            }
        }else {
            currentSide = Side.none;
            wordedX = -1;
            wordedY = -1;
            lastSucces = 0;
            currSideI = 0;
            makeAMove();
        }
    }
}

class SeaBattleMainScene : Scene
{
    public
    {
        PlayingField playerField;
        PlayingField targetField;
        Font font;

        Bot bot;
        bool isPlayerTurn = true;
    }

    this() @safe
    {
        font = new Font().load("sans.ttf", 8);

        add(playerField = new PlayingField(font));
        add(targetField = new PlayingField(font));

        playerField.position = vecf(128 - 32, 128 + 32);
        targetField.position = vecf(320 + 64, 128 + 32);

        targetField.isVisibleShip = false;

        bot = new Bot(playerField, targetField);
    }

    bool isWin(PlayingField field) @safe
    {
        for(int x = 0; x < 10; x++) {
            for(int y = 0; y < 10; y++) {
                if(field.grid[x][y] == CellState.ShipUnite) return false;
            }
        } 

        return true;
    }

    void checkWin() @safe
    {
        if(isWin(playerField)) {
            renderer.background = rgb(255, 64, 64);
        }
        
        if(isWin(targetField)) {
            renderer.background = rgb(64, 255, 64);
        }
    }

    @event(Input)
    void onEvent(EventHandler event) @safe
    {
        import std.random : uniform;
        
        if(isPlayerTurn) {
            Vecf mousePosition = vecf(event.mousePosition[0], event.mousePosition[1]);
            
            if(event.mouseDownButton == MouseButton.left)
            {
                if( mousePosition.x > targetField.position.x &&
                    mousePosition.y > targetField.position.y)
                {
                    for(int x = 0; x < 10; x++)
                    {
                        for(int y = 0; y < 10; y++)
                        {
                            if( mousePosition.x > targetField.position.x + x * CellStateSize &&
                                mousePosition.y > targetField.position.y + y * CellStateSize &&
                                mousePosition.x < targetField.position.x + x * CellStateSize + CellStateSize &&
                                mousePosition.y < targetField.position.y + y * CellStateSize + CellStateSize)
                            {
                                targetField.mark(x, y);
                                isPlayerTurn = false;
                                checkWin();
                                
                                listener.timer({
                                    bot.makeAMove();
                                    isPlayerTurn = true;
                                    checkWin();
                                }, dur!"msecs"(uniform(500, 2000)));
                            }
                        }
                    }
                }
            }
        }
        
        if(event.keyDown == Key.R)
        {
            clearFieldGrid(playerField.grid);
            clearFieldGrid(targetField.grid);
            generateFieldGrid(playerField.grid);
            generateFieldGrid(targetField.grid);
            
            bot.clear();
        }
    }

    debug @event(Draw)
    void debugDraw(IRenderer render) @safe
    {
        import std.conv : to;

        render.draw(new Text(font).renderSymbols(fps.deltatime.to!string, rgb(0,0,0)), vecf(0,0));
    }
}

mixin GameRun!(GameConfig(640, 480, "Sea Battle"), SeaBattleMainScene);
