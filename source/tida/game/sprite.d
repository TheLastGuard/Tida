/++
    A module for describing the rendering of image or animation.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.sprite;

import tida.graph.drawable;

/++
    A object for describing the rendering of image or animation.
+/
class Sprite : IDrawable
{
    import tida.graph.image;
    import tida.game.animation;
    import tida.graph.render;
    import tida.vector;
    import tida.graph.shader;

    public
    {
        // Image
        //deprecated Image image;

        // Animation
        //Animation animation;

        // Whether it is necessary to display animation, or a static picture.
        //bool isAnimation = false;

        IDrawableEx draws = null;

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

        /// Shader
        Shader!Program shader;
    }

    deprecated Image image(Image img) @safe @property
    {
        draws = img;

        return img;
    }

    Image image() @safe @property
    {
        return cast(Image) draws;
    }

    deprecated Animation animation(Animation anim) @safe @property
    {
        draws = anim;

        return anim;
    }

    Animation animation() @safe @property
    {
        return cast(Animation) draws;
    }

    /// No effect
    deprecated bool isAnimation(bool isanim) @safe @property { return isanim; }

    override void draw(IRenderer renderer, Vecf otherPosition) @safe
    {
        //Image ofimage = isAnimation ? (!(animation is null) ? animation.step() : null) : image;

        //if(ofimage !is null)
        //{
        //    if(shader !is null) renderer.currentShader = shader;
        //    renderer.drawEx(ofimage,
        //    this.position + otherPosition,angle,center,Vecf(
        //                                width == 0 ? ofimage.width : width, 
        //                                height == 0 ? ofimage.height : height
        //                                ),alpha);
        //}

        if(draws !is null)
        {
            if(shader !is null) renderer.currentShader = shader;
            renderer.drawEx(draws, this.position + otherPosition, angle, center,
                            Vecf(width, height), alpha);
        }

        if(skelet.length != 0) {
            foreach(spr; skelet) {
                spr.draw(renderer, this.position + otherPosition);
            }
        }
    }
}
