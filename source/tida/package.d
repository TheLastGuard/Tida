/++
$(TOOLS
    <a href="https://github.com/TodNaz/Tida/issues/new/choose" class="bugraf" title="Submit a bug to the list of problems in the official repository.">Report bug</a>
)

<center><img src="https://code.dlang.org/packages/tida/logo?s=6141da3aa33a2f9463017230" width=128 height=128 /></center>

Tida is a library for building 2D games in D language with an OOP system in 
the form of Scene-Instance-Component (where Instance is equivalent to Entity).

This page lists some modules according to the categories to which the modules 
belong. Please note that addons are not included in the default documentation.
$(TABLE
    $(TSTR
        $(TNAM Modules),
        $(TNAM Description)
    )

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
            $(HREF tida/localevent.html, tida.localevent)<br/>
            $(HREF tida/game.html, tida.game)<br/>
            $(HREF tida/listener.html, tida.listener)
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
    $(STRNAME Game auxiliary modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/algorithm.html, tida.algorithm)<br/>
            $(HREF tida/animation.html, tida.animation)<br/>
            $(HREF tida/collision.html, tida.collision)<br/>
            $(HREF tida/loader.html, tida.loader)<br/>
            $(HREF tida/text.html, tida.text)
        )
        $(ITEM Such modules help in building a two-dimensional game, such as 
        collision detection, animation, pathfinding algorithms, 
        resource allocation object and others.)
    )

    $(STRNAME Fundamental elements.)
    $(TSTR
        $(ITEM
            $(HREF tida/window.html, tida.window)<br/>
            $(HREF tida/event.html, tida.event)
        )
        $(ITEM Such modules are necessary when building a two-dimensional game, 
        such as creating and managing a window and an object to track events 
        such as input from devices.)
    )
)

Macros:
    LREF = <a href="#$1">$1</ a>
    HREF = <a href="$1">$2</ a>
    B = <b>$0</b>
    TABLE = <table class="def">$0</ table>
    TABLENAME = <caption class="defcap">$0</ caption>
    STRNAME = <tr class="leadingrow"><td colspan="2"><b><em>$(NBSP)$(NBSP)$(NBSP)$(NBSP)$0</em></b></td></tr>
    TSTR = <tr class="deftr">$0</tr>
    TNAM = <th class="defth">$0</th>
    ITEM = <td class="deftd">$0</td>
    TOOLS = <div class="tools">$0</div>
    
Authors: $(HREF https://github.com/TodNaz, TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE, MIT)
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
