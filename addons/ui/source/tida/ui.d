/++
Small technologies assembly module for building a debug floating interface.

A widget is that fundamental unit of the interface. Other widgets are inherited
from it for interaction with each other. Also, all widgets must inherit from the
instance to control the behavior of the widgets (position, activity, etc.).

In total, the following widgets are available by default:
* Button.
* Scroll widget.
* Text field.
* Mini window (aka context for widgets).
* Widget optional selection. (checkbox).
* Text widget.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.ui;

import tida;

alias Action = void delegate() @safe;
alias ActioncClick = void delegate(MouseButton) @safe;

/++
Information about the color palette of widgets.
+/
struct ThemeInfo
{
public:
    /++
    Widget background.
    +/
    Color!ubyte background = Color!ubyte("ADADAD");

    /++
    The color of the lines of the widget.
    +/
    Color!ubyte line = Color!ubyte("575757");

    /++
    The color of the text of the widget.
    +/
    Color!ubyte text = Color!ubyte("000000");

    /++
    The background color of the widget when the cursor is hovered over it.
    +/
    Color!ubyte backgroundHolder = Color!ubyte("BDBDBD");

    /++
    Widget title color.
    +/
    Color!ubyte title = Color!ubyte("9D9D9D");

    /++
    The color of the progressive line of the widget.
    +/
    Color!ubyte progress = Color!ubyte("EDEDED");

    /++
    A drawing option that indicates whether corners should be rounded.
    +/
    bool isRoundedCorners = false;

    /++
    corner radius.
    +/
    float radiusRounded = 8.0f;
}

/// Default theme widgets.
enum DefaultTheme = ThemeInfo();

/++
Interface for interacting with the widget.
+/
interface UIWidget
{
@safe:
    /++
    Available width of the widget.
    +/
    @property uint width();

    /++
    Available height of the widget.
    +/
    @property uint height();

    /++
    Resize the widget.

    Params:
        w = Available width of the widget.
        h = Available height of the widget.
    +/
    void resize(uint w, uint h);

    /++
    The relative position of the widget. Serves for relative positioning of 
    the widget relative to another or its own object.
    +/
    @property ref Vecf widgetPosition();
}

/++
Button widget. Serves for processing some actions when clicking 
on the widget itself.
+/
class UIButton : Instance, UIWidget
{
private:
    Font font;
    uint _width = 128, _height = 32;
    bool _isHold = false;
    Vecf releative = vecf(0.0f, 0.0f);

public:
    /++
    The text of the widget that will be displayed directly on the 
    button for intuitiveness.
    +/
    string label;

    /++
    The icon that is displayed on the widget. serves for the intuitiveness of the button.
    +/
    Image icon;

    /++
    Action when the mouse cursor is over the button.
    +/
    Action onHolder;

    /++
    Action When Button Was Pressed The mouse button that was pressed at the moment is passed as arguments.
    +/
    ActioncClick onClick;

    /// Widget theme.
    ThemeInfo theme;

@safe:
    this(Font font, ThemeInfo theme = DefaultTheme)
    {
        this.font = font;
        this.theme = theme;

        this.position = vecf(0.0f, 0.0f);
    }

    @Event!Input
    void inputHandle(EventHandler event)
    {
        Vecf mousePosition = vecf(event.mousePosition);

        if (mousePosition.x > releative.x + position.x &&
            mousePosition.y > releative.y + position.y &&
            mousePosition.x < releative.x + position.x + _width &&
            mousePosition.y < releative.y + position.y + _height)
        {
            if (!_isHold && onHolder !is null) onHolder();
            _isHold = true;

            if (event.isMouseDown)
            {
                if (onClick !is null) onClick(event.mouseButton);
            }
        } else
        {
            _isHold = false;
        }
    }

    @Event!Draw
    void selfDraw(IRenderer render)
    {
        Color!ubyte color = _isHold ? theme.backgroundHolder : theme.background;

        Vecf old = position;
        position += releative;

        if (theme.isRoundedCorners)
        {
            float corner = theme.radiusRounded > _height / 2 ? _height / 2 :
                                                                theme.radiusRounded;

            render.roundrect(position, _width, _height, corner, color, true);
        } else
        {
            render.rectangle(position, _width, _height, color, true);
        }

        if (label.length != 0)
        {
            auto syms = new Text(font).toSymbols(label, theme.text);

            immutable ycenter = height / 2;
            immutable h = font.size / 2;
            immutable xcenter = (width / 2) - (syms.widthSymbols / 2) + 
                                (icon !is null ? _height / 2 : 0);

            render.draw(new SymbolRender(syms), position + vecf(xcenter, ycenter - h));
        }

        if (icon !is null)
        {
            if (label.length != 0)
            {
                render.drawEx(icon, position + vecf(2, 2), 0.0f, vecfNaN, 
                    vecf(_height - 4, _height - 4), 255);
            }
            else
            {
                immutable xcenter = (_width / 2) - ((_height - 4) / 2);
                render.drawEx(icon, position + vecf(xcenter, 2), 0.0f, vecfNaN,
                    vecf(_height - 4, _height - 4), 255);
            }
        }

        position = old;
    }

override:
    @property uint width()
    {
        return _width;
    }

    @property uint height()
    {
        return _height;
    }

    void resize(uint w, uint h)
    {
        _width = w;
        _height = h;
    }

    @property ref Vecf widgetPosition()
    {
        return this.releative;
    }
}

/++
Scrolling widget. Widget for managing or showing the approximate value
of any maximum value.
+/
class UIScroll : Instance, UIWidget
{
private:
    alias ActionFactor = void delegate(float) @safe;

    uint _width = 128;
    uint _height = 8;
    Vecf releative = vecfNaN;
    ThemeInfo theme;
    bool _isMove = false;

    float k = 0.0f;

public:
    /++
    Is it possible to change the value of the widget
    +/
    bool isEditable = true;

    /++
    The action when the user changes the value.
    +/
    ActionFactor onMoveScroll;

@safe:
    this(ThemeInfo theme = DefaultTheme)
    {
        this.theme = theme;

        this.position = vecf(0.0f, 0.0f);
    }

    /++
    The value of the factor of the widget.
    +/
    @property float value() inout
    {
        return k;
    }

    @Event!Input
    void onInput(EventHandler event)
    {
        if (!isEditable) return;

        Vecf mousePosition = vecf(event.mousePosition);

        if (mousePosition.x > releative.x + position.x &&
            mousePosition.y > releative.y + position.y &&
            mousePosition.x < releative.x + position.x + _width &&
            mousePosition.y < releative.y + position.y + _height)
        {
            if (event.mouseDownButton == MouseButton.left)
            {
                _isMove = true;
            }            
        }

        if (event.mouseUpButton == MouseButton.left)
            {
                _isMove = false;
            }

        if (_isMove)
        {
            immutable factor = mousePosition.x - (releative.x + position.x);
            k = factor / _width;

            if (k < 0.0f) k = 0.0f;
            if (k > 1.0f) k = 1.0f;

            if (onMoveScroll !is null) onMoveScroll(k);
        }
    }

    @Event!Draw
    void onDraw(IRenderer render)
    {
        Vecf old = position;
        position += releative;

        if (theme.isRoundedCorners)
        {
            float corner = theme.radiusRounded > _height / 2 ? _height / 2 : theme.radiusRounded;

            render.roundrect(position, _width, _height, corner, theme.background, true);
            uint w = cast(uint) ((cast(float) _width) * k);
            render.roundrect(position, w, _height, corner, theme.progress, true);
        } else
        {
            render.rectangle(position, _width, _height, theme.background, true);
            uint w = cast(uint) ((cast(float) _width) * k);
            render.rectangle(position, w, _height, theme.progress, true);
        }

        position = old;
    } 

override:
    @property uint width()
    {
        return _width;
    }

    @property uint height()
    {
        return _height;
    }

    void resize(uint w, uint h)
    {
        _width = w;
        _height = h;
    }

    @property ref Vecf widgetPosition()
    {
        return this.releative;
    }
}

/++
Widget for entering text data.
+/
class UITextBox : Instance, UIWidget
{
private:
    uint _width = 128;
    uint _height = 24;
    Vecf releative = vecf(0, 0);

    string value;
    Font font;
    bool _isFocus = false;

    int cursor = 0;
    size_t viewbegin = 0;
    size_t viewend = 0;

public:
    /++
    Icon for intuition.
    +/
    Image icon;

    /++
    Widget theme.
    +/
    ThemeInfo theme;

@safe:
    this(Font font, ThemeInfo theme)
    {
        this.font = font;
        this.theme = theme;

        this.position = vecf(0.0f, 0.0f);
    }

    /++
    The entered data.
    +/
    @property string text() inout
    {
        return value;
    }

    private bool exceptChar(EventHandler event, char ch)
    {
        return ch > 32;
    }

    @Event!Input
    void onInput(EventHandler event)
    {
        Vecf mousePosition = vecf(event.mousePosition);

        if (_isFocus)
        {
            char ichar = event.inputChar[0];

            if (event.isInputText() && exceptChar(event, ichar))
            {
                value = value[0 .. cursor] ~ ichar ~ value[cursor .. $];
                cursor++;
            }else
            {
                if(event.isKeyDown)
                {
                    if (event.key == Key.Left)
                    {
                        if (cursor != 0) cursor--;
                    }else
                    if (event.key == Key.Right)
                    {
                        if (cursor != value.length) cursor++;
                    }else
                    if (ichar == Key.Backspace)
                    {
                        if (cursor != 0)
                        {
                            value = value[0 .. cursor - 1] ~ value[cursor .. $];
                            cursor--;
                        }
                    }
                }
            }
        }

        if (mousePosition.x > releative.x + position.x &&
            mousePosition.y > releative.y + position.y &&
            mousePosition.x < releative.x + position.x + _width &&
            mousePosition.y < releative.y + position.y + _height)
        {
            if (event.mouseDownButton == MouseButton.left)
            {
                _isFocus = true;
            }
        }else
        {
            if (event.mouseDownButton == MouseButton.left)
            {
                _isFocus = false;
            }
        }
    }

    @Event!Draw
    void selfDraw(IRenderer render)
    {
        Color!ubyte color = _isFocus ? theme.backgroundHolder : theme.background;

        Vecf old = position;
        position += releative;

        if (theme.isRoundedCorners)
        {
            float corner = theme.radiusRounded > _height / 2 ? _height / 2 : theme.radiusRounded;

            render.roundrect(position, _width, _height, corner, color, true);
        } else
        {
            render.rectangle(position, _width, _height, color, true);
        }

        if (value.length != 0)
        {
            auto syms = new Text(font).toSymbols(value, theme.text);

            if (syms.widthSymbols > _width - 8)
            {
                viewbegin = 0;
                viewend = 0;

                for (size_t i = 0; i < syms.length; ++i)
                {
                    if (syms[0 .. i].widthSymbols > _width - 8)
                    {
                        viewend = i - 1;
                        break;
                    }
                }

                if (viewend == 0) viewend = syms.length;

                if (cursor > viewend)
                {
                    for (size_t i = viewend; i < cursor; ++i)
                    {
                        viewend++;
                        viewbegin++;
                    }

                    if (viewend > syms.length) viewbegin = syms.length;
                }else
                if (cursor <= viewbegin && viewbegin != 0)
                {
                    for (size_t i = viewbegin; i <= cursor; ++i)
                    {
                        viewbegin--;
                        viewend--;
                    }
                }
            }else
            {
                viewbegin = 0;
                viewend = syms.length;
            }

            immutable ycenter = height / 2;
            immutable h = font.size / 2;

            render.draw(new SymbolRender(syms[viewbegin .. viewend]), position + vecf(4, ycenter - h));
            render.line([
                            position + vecf(4 + syms[viewbegin .. cursor].widthSymbols, ycenter - h),
                            position + vecf(4 + syms[viewbegin .. cursor].widthSymbols, ycenter - h + (font.size * 2))
                        ], theme.text);
        }

        if (icon !is null)
        {
            if (value.length != 0)
            {
                render.drawEx(icon, position + vecf(2, 2), 0.0f, vecfNaN, vecf(_height - 4, _height - 4), 255);
            }
            else
            {
                immutable xcenter = (_width / 2) - ((_height - 4) / 2);
                render.drawEx(icon, position + vecf(xcenter, 2), 0.0f, vecfNaN, vecf(_height - 4, _height - 4), 255);
            }
        }

        position = old;
    }

override:
    @property uint width()
    {
        return _width;
    }

    @property uint height()
    {
        return _height;
    }

    void resize(uint w, uint h)
    {
        _width = w;
        _height = h;
    }

    @property ref Vecf widgetPosition()
    {
        return this.releative;
    }
}

/++
Mini-window aka the context for widgets with which you can personalize the 
widget panel for the theme and move (or not move) such a panel.
+/
class UIWindow : Instance, UIWidget
{
private:
    struct UIChild
    {
        UIWidget widget;
        Vecf position;
    }

    uint _width = 320;
    uint _height = 240;
    Font font;
    UIChild[] childs;

    bool isMove = false;
    Vecf moveBegin = vecfNaN;

    bool _isTurn = true;

public:
    alias ActionDraw = void delegate(IRenderer, Vecf) @safe;

    /++
    The width of the title bar of the window.
    +/
    uint titleHeight = 16;

    /++
    Window title.
    +/
    string title;

    /++
    The background of the window.
    +/
    Color!ubyte background;

    /++
    Operations for rendering user data, if the widget does not provide such.
    +/
    ActionDraw[] draws;

    /++
    Widget theme.
    +/
    ThemeInfo theme;

    /++
    Whether to show the title of the window to handle the movement of the window.
    +/
    bool isTitleView = true;

@safe:
    this(Font font, ThemeInfo theme = DefaultTheme)
    {
        this.font = font;
        this.theme = theme;

        this.position = vecf(0.0f, 0.0f);

        background = rgb(255, 255, 255);
    }

    @Event!Input
    void onInput(EventHandler event)
    {
        Vecf mousePosition = vecf(event.mousePosition);

        if (isTitleView)
        {
            if (mousePosition.x > position.x &&
                mousePosition.y > position.y &&
                mousePosition.x < position.x + _width &&
                mousePosition.y < position.y + titleHeight)
            {
                if (event.mouseDownButton == MouseButton.left)
                {
                    isMove = true;
                    moveBegin = mousePosition - position;
                }

                if (event.mouseUpButton == MouseButton.left)
                {
                    isMove = false;
                }
            }

            immutable spos = position + vecf(_width - 18, titleHeight / 2 - 4);

            if (mousePosition.x > spos.x &&
                mousePosition.y > spos.y &&
                mousePosition.x < spos.x + 10 &&
                mousePosition.y < spos.y + 8)
            {
                if (event.mouseDownButton == MouseButton.left)
                {
                    _isTurn = !_isTurn;

                    foreach (ref e; childs)
                    {
                        (cast(Instance) e.widget).active = _isTurn;
                    }
                }
            }

            if (isMove)
            {
                position = mousePosition - moveBegin;
            }
        }
    }

    @Event!Step
    void onStep()
    {
        foreach (ref e; childs)
        {
            (cast(Instance) e.widget).depth = depth - 1;
            sceneManager.context.sort();
            e.widget.widgetPosition = this.position + e.position + 
                (isTitleView ? vecf(0, titleHeight) : vecf(0.0f, 0.0f));
        }
    }

    @Event!Draw
    void onDraw(IRenderer render)
    {
        if (theme.isRoundedCorners)
        {
            float corner = theme.radiusRounded > titleHeight / 2 ? titleHeight / 2 : theme.radiusRounded;

            if(isTitleView)
            {
                render.roundrect(position, _width, titleHeight, corner, theme.title, true);
                render.rectangle(position + vecf(0, titleHeight / 2), _width, titleHeight / 2, theme.title, true);
            }

            if (_isTurn)
            {
                immutable vh = isTitleView ? (_height - titleHeight) : _height;

                render.rectangle(position + vecf(0, isTitleView ? titleHeight : 0), 
                    _width, vh, background, true);
                render.rectangle(position + vecf(0, isTitleView ? titleHeight : 0),
                 _width, vh, theme.line, false);
            }
        } else
        {
            if (isTitleView)
            {
                render.rectangle(position, _width, titleHeight, theme.title, true);
            }

            if (_isTurn)
            {
                immutable vh = isTitleView ? (_height - titleHeight) : _height;

                render.rectangle(position + vecf(0, isTitleView ? titleHeight : 0), 
                    _width, vh, background, true);
                render.rectangle(position + vecf(0, isTitleView ? titleHeight : 0), 
                    _width, vh, theme.line, false);
            }
        }

        if (isTitleView)
            render.rectangle(position + vecf(_width - 18, titleHeight / 2 - 2), 8, 4, theme.line, true);

        if (title.length != 0 && isTitleView)
        {
            render.draw(new Text(font).renderSymbols(title, theme.text), position + vecf(4, 2));
        }

        if(_isTurn)
        foreach(e; draws)
            e(render, this.position + vecf(0, isTitleView ? titleHeight : 0));
    }

    /++
    Adds a widget to the inside of the window.
    +/
    void add(UIWidget widget, Vecf pos)
    {
        childs ~= UIChild(widget, pos);
    }

override:
    @property uint width()
    {
        return _width;
    }

    @property uint height()
    {
        return _height;
    }

    void resize(uint w, uint h)
    {
        _width = w;
        _height = h;
    }

    @property ref Vecf widgetPosition()
    {
        return this.position;
    }
}

/++
Optional widget.
+/
class UICheckBox : Instance, UIWidget
{
private:
    uint _width = 16;
    uint _height = 16;
    bool _isCheck = false;
    bool _isHold = false;
    Vecf releative = vecf(0.0f, 0.0f);

public:
    /// Widget theme
    ThemeInfo theme;

    /++
    Shows the status of the option.
    +/
    @property ref bool isCheck() @safe
    {
        return _isCheck;
    }

@safe:
    this(ThemeInfo theme = DefaultTheme)
    {
        this.theme = theme;

        this.position = vecf(0.0f, 0.0f);
    }

    @Event!Input
    void onInput(EventHandler event)
    {
        Vecf mousePosition = vecf(event.mousePosition);

        if (mousePosition.x > releative.x + position.x &&
            mousePosition.y > releative.y + position.y &&
            mousePosition.x < releative.x + position.x + _width &&
            mousePosition.y < releative.y + position.y + _height)
        {
            _isHold = true;

            if (event.mouseDownButton == MouseButton.left)
            {
                _isCheck = !_isCheck;
            }
        } else
        {
            _isHold = false;
        }
    }

    @Event!Draw
    void onDraw(IRenderer render)
    {
        Color!ubyte color = _isHold ? theme.backgroundHolder : theme.background;

        Vecf old = position;
        position += releative;

        if (theme.isRoundedCorners)
        {
            float corner = theme.radiusRounded > _height / 2 ? _height / 2 : theme.radiusRounded;

            render.roundrect(position, _width, _height, corner, color, true);

            if (_isCheck)
            {
                render.roundrect(position + vecf(2, 2), _width - 4, _height - 4, corner, theme.line, true);
            }
        } else
        {
            render.rectangle(position, _width, _height, color, true);

            if (_isCheck)
            {
                render.rectangle(position + vecf(2, 2), _width - 4, _height - 4, theme.line, true);
            }
        }

        position = old;
    }

override:
    @property uint width()
    {
        return _width;
    }

    @property uint height()
    {
        return _height;
    }

    void resize(uint w, uint h)
    {
        _width = w;
        _height = h;
    }

    @property ref Vecf widgetPosition()
    {
        return this.releative;
    } 
}

/++
Label widget. Serves for full interactivity of something.
+/
class UILabel : Instance, UIWidget
{
private:
    uint _width = 128;
    uint _height = 16;
    Font font;
    Vecf releative = vecf(0.0f, 0.0f);

public:
    /// Label text
    string text;

    /// Widget theme
    ThemeInfo theme;

@safe:
    this(Font font, string label = "", ThemeInfo theme = DefaultTheme)
    {
        this.font = font;
        this.theme = theme;

        this.position = vecf(0.0f, 0.0f);
        this.text = label;
    }

    @Event!Draw
    void onDraw(IRenderer render)
    {
        if (text.length == 0) return;

        auto syms = new Text(font).toSymbols(text, theme.text);

        size_t end = syms.length;

        if (syms.widthSymbols > _width)
        {
            for (size_t i = 0; i < syms.length; ++i)
            {
                if (syms[0 .. i].widthSymbols > _width)
                {
                    end = i - 1;
                    break;
                }
            }
        }

        render.draw(new SymbolRender(syms), this.releative + this.position);
    }

override:
    @property uint width()
    {
        return _width;
    }

    @property uint height()
    {
        return _height;
    }

    void resize(uint w, uint h)
    {
        _width = w;
        _height = h;
    }

    @property ref Vecf widgetPosition()
    {
        return this.releative;
    }
}