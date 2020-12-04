import tida;
import std.random;

int main(string[] args)
{
	TidaRuntime.initialize(args);
	Window window = new Window(640,480,"RGP.");
	window.initialize!ContextIn;

	EventHandler event = new EventHandler(window);
	Renderer render = new Renderer(window);

	Camera camera;
	camera.port = Shape.Rectangle(Vecf(-4,-4),Vecf(window.width,window.height));

	render.camera = camera;

	bool isGame = true;
	while(isGame) {
		event.handle = {
			if(event.isQuit) isGame = false;
		};

		render.drawning = {
			render.rectangle(Vecf(32,32),32,32,rgb(64,64,255),!true);
		};
	}

	return 0;
}