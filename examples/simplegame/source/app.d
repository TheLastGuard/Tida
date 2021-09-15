module app;

import tida;
import tida.vertgen;
import std.stdio;

class Circle : Instance
{
    private
    {
        Image image;
        bool isClick = false;
        bool isCollider = true;
    }

    this(Vecf position, bool isCollider = false) @safe
    {
        this.name = "CirlceShape";

        image = loader.get!Image("CircleShape");

        if(image is null)
        {
            image = new Image();
            image.allocatePlace(128, 128);

            Software imageRender = new Software(new SoftImage(image));
            imageRender.camera.shape = Shapef.Rectangle(vecf(0,0), vecf(128, 128));
            imageRender.camera.port = imageRender.camera.shape;
            imageRender.reshape();
            
            imageRender.background = Color!ubyte("0x00ff00ff");
            imageRender.clear();
            imageRender.rectangle(Vecf(8, 8), 128 - 16, 128 - 16, Color!ubyte("#ff0000ff"), true);
            imageRender.drawning();

            immutable center = Vecf(64, 64);

            image.process((ref e, pos) {
                immutable float k = (pos.x > 64 ? center.x / pos.x : pos.x / center.x) *
                                    (pos.y > 64 ? center.y / pos.y : pos.y / center.y); 

                e = e * (1 - k);
            });

            image.toTexture();
            image.texture.vertexInfo = generateVertex(Shapef.Circle(vecf(0,0), 64), vecf(image.width, image.height));

            Resource res;
            res.init!Image(image);
            res.name = "CirlceShape";
            res.path = "tida.examples.simplegame.app.CircleShape";
            loader.add(res);
        }

        sprite.draws = image;

        this.position = position;
        this.isCollider = isCollider;

        solid = true;
        mask = Shapef.Circle(vecf(0, 0), 64);
    }

    @Event!Input
    void handleEvent(EventHandler event) @safe
    {
        if (isCollider) return;

        if (event.mouseDownButton == MouseButton.left) isClick = true;
        if (event.mouseUpButton == MouseButton.left) isClick = false;

        if (isClick)
            position = vecf(event.mousePosition[0], event.mousePosition[1]);
    }

    @Event!Draw
    void renderYourself(IRenderer render) @safe
    {
        render.circle(position, 64, rgb(255, 0, 0), false);
    }

    @Event!Step
    void offsetBorder() @safe
    {
        if (position.x - 64 < 0) position.x += 0.8f;
        if (position.x + 64 > 640) position.x -= 0.8f;
        if (position.y - 64 < 0) position.y += 0.8f;
        if (position.y + 64 > 480) position.y -= 0.8f;
    }

    @Collision("CirlceShape")
    void onCircleShapeCollision(Instance other) @safe
    {
        if (!isCollider) return;

        Vecf offset = vecfNaN;

        offset.x = position.x > other.position.x ? 1.0f : -1.0f;
        offset.y = position.y > other.position.y ? 1.0f : -1.0f;

        this.position = this.position + offset;
    }
}

class SimpleGame : Scene
{
    this() @safe
    {
        add(new Circle(Vecf(128, 128), false));
        add(new Circle(Vecf(32, 32), true));
        add(new Circle(Vecf(256, 256), true));
    }

    @Event!Input
    void ClickRightHandle(EventHandler event) @safe
    {
        if (event.mouseDownButton == MouseButton.right)
        {
            add(new Circle(Vecf(event.mousePosition[0], event.mousePosition[1]), true));
        }
    }
}

/+
    [1] - Window configuration template
    [2] - Window width
    [3] - Window height
    [4] - Window title
    [5] - The scene that will be added to the play structure of the execution.

               [1]            [2]  [3]      [4]    [5]    
               V              V    V        V      V
+/
mixin GameRun!(GameConfig(640, 480, "Tida."), SimpleGame);
