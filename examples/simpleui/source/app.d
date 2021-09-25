module app;

import tida;
import tida.ui;

class Main : Scene
{
	Color!ubyte color = rgb(255, 255, 255);

	this() @safe
	{
		window.border = false;

		Font font = new Font();
		font.load("sans.ttf", 8);

		Font font2 = new Font();
		font2.load("sans.ttf", 4);

		UIWindow uiwindow = new UIWindow(font);
		uiwindow.title = "Panel";
		uiwindow.resize(128, 240);
		uiwindow.position = vecf(32, 32);
		uiwindow.background = rgb(96, 96, 96);

		UIScroll 	rscroll = new UIScroll(),
					gscroll = new UIScroll(),
					bscroll = new UIScroll();

		rscroll.resize(96, 8);
		gscroll.resize(96, 8);
		bscroll.resize(96, 8);

		UILabel	rlabel = new UILabel(font2, "Red"),
				glabel = new UILabel(font2, "Green"),
				blabel = new UILabel(font2, "Blue");

		add(rscroll); add(rlabel);
		add(gscroll); add(glabel);
		add(bscroll); add(blabel);

		uiwindow.add(rscroll, vecf(8, 48));
		uiwindow.add(gscroll, vecf(8, 64));
		uiwindow.add(bscroll, vecf(8, 80));

		uiwindow.add(rlabel, vecf(8, 48 - 8));
		uiwindow.add(glabel, vecf(8, 64 - 8));
		uiwindow.add(blabel, vecf(8, 80 - 8));

		uiwindow.draws ~= (render, position) @safe
		{
					 color = Color!float(rscroll.value,
											gscroll.value,
											bscroll.value)
									.convert!(float, ubyte);
			render.rectangle(position + vecf(8, 8), 32, 32, color, true);
		};

		add(uiwindow);
	}

	@Event!Input
	void onInput(EventHandler event) @safe
	{
		if (event.keyDown == Key.Escape)
			sceneManager.close();
	}

	@Event!Draw
	void onDraw(IRenderer render) @safe
	{
		render.rectangle(vecf(320 - 64, 240 - 64), 128, 128, color, true);
	}
}

mixin GameRun!(GameConfig(640, 480, "SimpleUI"), Main);