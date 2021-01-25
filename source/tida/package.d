/++
    Tida is a library for developing 2D games on operating systems such as Windows and Linux. 
    Currently it supports:
    * Window creation and management. 
    * Create a graphics pipeline for a window for the Open Graphics Library.
    * Rendering objects through the processor.
    * Object rendering through hardware acceleration with OpenGL API 2.
    * Getting information about the monitor.
    * Support for audio playback via OpenAL, using Wav, MP3 formats.
    * Working with the image, namely blurring, copying parts, etc.
    * Working with color and angles, 2D vectors.
    * Scene-instance-component logic implementation.
    * Rendering text using FreeType.
    * Collision check.
    * Timer (Only via Scene-Instance-Component Logic)
    * Resource loader.

    # 1. Game creation.
    ## 1.1 Creating an instance of the game.
    The library provides an automatic implementation of the game loop in the form of scene-instance logic. 
    It simplifies game writing by representing objects as objects. To implement this logic, you first need 
    to initialize the framework:
    ---
    import tida;

    void main() {
        TidaRuntime.initialize(args);
    }
    ---

    Thus, we prepared a library for creating a window and loaded the necessary libraries for working with text, 
    sound, and more. The next step is to create a game instance. It is the game instance that implements the game loop, 
    creating a window, a render for drawing objects, a scene manager, a resource loader so that the programmer does not 
    fool his head, imitating the work of the scene manager, processing all requests for scenes and its instances. 
    The constructor contains parameters: height and width of the window, and its title. However, you can write a 
    complete creation configuration if you need, for example, not to have hardware support. First, let's create a 
    simple instance:
    ---
    import tida;

    void main(string[] args) {
        TidaRuntime.initialize(args);

        Game game = new Game(640, 480, "My first game.");
    }
    ---

    Thus, everything is initialized. Now, let's create with the configuration:
    ---
    import tida;

    void main(string[] args) {
        TidaRuntime.initialize(args);

        GameConfig config;
        config.width = 640;
        config.height = 480;
        config.caption = "My first game";
        config.icon = new Image().load("icon.bmp"); // Load the game icon.
        config.contextType = Simple; // Graphics need to be processed through the processor.
        
        Game game = new Game(config);
    }
    ---

    The next step is to create the scene. The scene should bring logic, using instances and event handling. 
    To begin with, you can simply handle the event when the game starts, for this, you first need to inherit 
    all the scene properties, and later create a processing function:
    ---
    class MyScene : Scene
    {
        override void gameStart()
        {
            writeln("Game start event!");
        }
    }
    ---

    Now, let's add a scene to the scene manager to handle its events:
    ---
    sceneManager.add!MyScene;
    ---

    Such a function is a template. It will automatically allocate memory with a constructor call. 
    If the constructor has arguments, call with memory allocation:
    ---
    sceneManager.add(new MyScene(args...));
    ---

    Now, let's set it to go to it, for this you can do it in two ways, the first is to go to the 
    first added, and the second is to go to the class or name:
    ---
    sceneManager.inbegin(); // Goto in first added scene.
    //or
    sceneManager.gotoin!MyScene; // Go to the scene by its class name.
    sceneManager.gotoin("MyScene"); // Transition of name by property `name`.
    ---

    Now let's start the game and see the result of the work:
    ---
    import tida;
    import std.stdio;

    class MyScene : Scene
    {
        override void gameStart()
        {
            writeln("Game start event!");
        }
    }

    void main(string[] args) {
        TidaRuntime.initialize(args);

        GameConfig config;
        config.width = 640;
        config.height = 480;
        config.caption = "My first game";
        config.contextType = Simple; // Graphics need to be processed through the processor.
        
        Game game = new Game(config);

        sceneManager.add!MyScene;
        sceneManager.gotoin!MyScene;

        game.run(); // Run game instance.
    }
    ---

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida;

public
{
    import tida.runtime;
    import tida.window;
    import tida.event;
    import tida.vector;
    import tida.color;
    import tida.shape;
    import tida.fps;
    import tida.angle;

    import tida.graph.camera;
    import tida.graph.drawable;
    import tida.graph.image;
    import tida.graph.render;
    import tida.graph.text;
    import tida.graph.softimage;

    import tida.sound.al;

    import tida.scene;
    import tida.game;
}