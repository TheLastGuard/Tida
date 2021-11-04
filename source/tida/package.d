/++

next:
$(TABLE
    $(STRNAME Technical modules.)
    $(TSTR
        $(ITEM 
            $(HREF tida/runtime.html, tida.runtime)<br/>
            $(HREF tida/gl.html, tida.gl)<br/>
        )
        $(ITEM Technical modules are intended as fundamental tools in building 
        the logic for creating a window and other interfaced devices, which will
        depend on an object that needs to be transferred to access or obtain 
        important properties during their operation. Also, if such modules are 
        necessary for important operations, they are also marked as technical. 
        Runtime creates an object for addressing the window manager and creates 
        a device for sound, and the open graphics module loads such a library 
        and auxiliary extensions that may not be useful.)
    )

    $(STRNAME Mathematical module.)
    $(TSTR
        $(ITEM 
            $(HREF tida/vector.html, tida.vector)<br/>
            $(HREF tida/angle.html, tida.angle)<br/>
            $(HREF tida/shape.html, tida.shape)<br/>
            $(HREF tida/matrix.html, tida.matrix)
        )
        $(ITEM Math modules are essential for 2D calculations. The emphasis is 
        on two-dimensionality, the framework does not assume that functions 
        will be needed to calculate three-dimensional objects (excluding matrices). 
        A vector, functions for operating with angles, a structure for 
        describing a shape are implemented.)
    )   

    $(STRNAME Renderers module.)
    $(TSTR
        $(ITEM
            $(HREF tida/render.html, tida.render)<br/>
            $(HREF tida/drawable.html, tida.drawable)<br/>
            $(HREF tida/sprite.html, tida.sprite)<br/>
            $(HREF tida/shader.html, tida.shader)<br/>
            $(HREF tida/gl.html, tida.gl)<br/>
            $(HREF tida/vertgen.html, tida.html)
        )
        $(ITEM Such modules implement and help in rendering of primitives and 
        objects, as well as their filling. The renderer is a direct participant 
        in the rendering of objects, controls the camera, is responsible for 
        rendering primitives, indicates the visible part of the port of the 
        rendering plane. Sprite is a structure for specifying rendering parameters. 
        Those. defines a transformation. Analogue of matrices.)
    )

    $(STRNAME Image & color processing modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/color.html, tida.color)<br/>
            $(HREF tida/image.html, tida.image)<br/>
            $(HREF tida/each.html, tida.each)<br/>
            $(HREF tida/softimage.html, tida.softimage)<br/>
            $(HREF tida/texture.html, tida.texture)
        )
        $(ITEM Such modules are responsible for creating, loading and 
        processing textures. Pixel is the basis of textures. Therefore, 
        in the color manipulation module, some functions have been made for 
        color manipulation, their creation and other operations. The images 
        module processes the image plane itself. Like color correction, 
        resizing, or even rendering of any objects on the image. 
        This can be helped by the software rendering 
        for pictures $(B tida.softimage))
    )

    $(STRNAME Sound manipulation modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/sound.html, tida.sound)
        )
        $(ITEM
            Such modules implement loading of sounds and their playback.
        )
    )

    $(STRNAME Behavior manipulation modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/component.html, tida.component)<br/>
            $(HREF tida/instance.html, tida.instance)<br/>
            $(HREF tida/scene.html, tida.scene)<br/>
            $(HREF tida/scenemanager.html, tida.scenemanager)<br/>
            $(HREF tida/game.html, tida.game)<br/>
            $(HREF tida/listener.html, tida.listener)<br/>
        )
        $(ITEM Such modules serve the purpose of providing a way to make the 
        game feel comfortable and well-behaved. With the help of scene modules, 
        you can create separate sections of the game, and with the help of the 
        scene manager, you can move between scenes. Scenes have objects - instances, 
        which are assigned certain behavior, which also assumes communication 
        between instances. An instance can have components to reduce common 
        behavior code between different instances. Also, the game module is 
        responsible for distributing the game life cycle and limiting 
        frames per second.)
    )
)

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    B = <b>$0</b>
    TABLE = <table>$0</table>
    TABLENAME = <caption>$0</caption>
    STRNAME = <tr class="leadingrow"><td colspan="2"><b><em>$(NBSP)$(NBSP)$(NBSP)$(NBSP)$0</em></b></td></tr>
    TSTR = <tr>$0</tr>
    ITEM = <td>$0</td>
+/
module tida;

public:
    import tida.runtime;
    import tida.window;
    import tida.event;
    import tida.vector;
    import tida.color;
    import tida.render;
    import tida.shape;
    import tida.vertgen;
    import tida.image;
    import tida.texture;
    import tida.angle;
    import tida.each;
    import tida.fps;
    import tida.sound;
    import std.datetime;
    import tida.sprite;
    import tida.matrix;
    import tida.animation;
    import tida.text;
    import tida.localevent;
    import tida.scene;
    import tida.instance;
    import tida.scenemanager;
    import tida.game;
    import tida.loader;
    import tida.listener;
    import tida.softimage;
    import tida.drawable;
    import tida.component;
