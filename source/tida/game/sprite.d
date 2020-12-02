/++
    A module for describing the rendering of image or animation.
+/
module tida.game.sprite;

import tida.graph.drawable;

/++
    A object for describing the rendering of image or animation.
+/
public class Sprite : IDrawable
{
    import tida.graph.image;
    import tida.game.animation;
    import tida.graph.render;
    import tida.vector;

    public
    {
        /// Image
        Image image;

        /// Animation
        Animation animation;

        /// Whether it is necessary to display animation, or a static picture.
        bool isAnimation = false;

        /// The rotation angle of the sprite.
        float angle = 0.0f;

        /// The width of the sprite. If zero, the value is taken from the rendered image.
        uint width = 0;

        /// The height of the sprite. If zero, the value is taken from the rendered image.
        uint height = 0;

        /// 
        Vecf center = Vecf(0,0);

        /// The pivot point of the sprite.
        Vecf position = Vecf(0,0);

        /// Sprite alpha channel
        ubyte alpha = 255;

        /// An array of other sprites to create a single picture.
        Sprite[] skelet;
    }

    override void draw(Renderer renderer, Vecf otherPosition) @safe
    {
        Image ofimage = isAnimation ? animation.step() : image;

        renderer.drawEx(ofimage,
        this.position + otherPosition,angle,center,Vecf(
                                    width == 0 ? ofimage.width : width, 
                                    height == 0 ? ofimage.height : height
                                    ),alpha);

        if(skelet.length != 0) {
            foreach(spr; skelet) {
                spr.draw(renderer, this.position + otherPosition);
            }
        }
    }
}