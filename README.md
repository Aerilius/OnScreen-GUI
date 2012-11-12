This is a framework for defining GUI elements using the SketchUp OpenGL drawing methods.
It allows placing widgets in a nested, dynamic layout and styling them with CSS-like properties.
An example implementation can be found in TestTool.rb / AE::GUI::OnScreen::TestTool.
![some widgets shown by TestTool.rb](../raw/b2823ab688cd/wiki/TestTool_screenshot1.png "some widgets shown by TestTool.rb")


Public Methods
==============

`OnScreen::Widget.new(hash)`
`OnScreen::Container.new(hash)`
`OnScreen::Button.new(label, hash, block)`
`OnScreen::ToggleButton.new(pressed, label, hash, block)`
`OnScreen::Checkbox.new(checked, label, hash, block)`
`OnScreen::Radio.new(checked, label, hash, block)`
`OnScreen::RadioButtonGroup.new(selected, labels, hash, block)`
`OnScreen::Text.new(text, hash)`
`OnScreen::Separator.new(hash)`

This creates various widgets. A block could be attached to some widgets.

**label** [ _String_ ] The label of the widget.

**checked**, **pressed** [ _Boolean_ ] The checked status of a checkbox / radio button.

**selected** [ _Fixnum_ ] The index of the selected item of an options group.

**labels**, **options** [ _Array(String)_ ] An array of labels for an options group

**text** [ _String_ ] The text of a text element.

**hash** [Hash] Optionally CSS-properties for layout and style. 
  If incomplete or not given, properties of the window or default properties will be taken.

**block** [ _Proc_ ] A block that is called on change. 
  Here, the block's argument is the new value (Checkbox/ToggleButton: Boolean, Radio/RadioButtonGroup: Integer, Slider: Float).




`OnScreen::Widget.style.set(hash)`

This also sets a style to a widget.

**hash** [ _Hash_ ] Optionally CSS-properties for style. 
  If incomplete or not given, properties of the window or default properties will be taken.




`OnScreen::Widget.style[prop]`

This gets a property of a widget's style.

**prop** [ _Symbol_ ] CSS-property for the style. 
**returns** [ _Numeric_ , _Symbol_ ] value of the property. 




`OnScreen::Widget.style[prop]=(value)`

This sets a property of a widget's style.

**prop** [ _Symbol_ ] CSS-property for the style. 
**value** [ _Numeric_ , _Symbol_ ] value of the property. 




`OnScreen::Widget.on=(type, &block)`

This sets an event handler for a widget.

**type** [Symbol] a Symbol indicating the type of event (_:move_, _:mousedown_, _:mouseup_, ...).

**block** [Proc] a code block to execute when the event is triggered. 
  The block's argument is a hash containing the event's raw data:
  * :pos the relative position to the widget's upper left corner [ _Geom::Point3d_ ]
  * :flags
  * :key ...




`OnScreen::Window.new(hash, context)`

This is the root element for any widgets to be drawn on the screen. It would be created inside a Tool.

**hash** [Hash] Optionally CSS-properties for layout and style. These properties attached to the Window
  serve as a template for all other widgets.

**context** [ _Sketchup::Model, Sketchup::View_ ] Optionally a model or view to which the Window belongs (Multi-document interface etc.).




`OnScreen::Window.add(*widgets)`
`OnScreen::Container.add(*widgets)`

Attaches widgets to a container element (or to the window).

**widgets** [ _OnScreen::Widget_ ] One or several widget instances.




`OnScreen::Window.remove(*widgets)`
`OnScreen::Container.remove(*widgets)`

Removes widgets from their container and from the window.

**widgets** [ _OnScreen::Widget_ ] One or several widget instances.




`OnScreen::Window.trigger(type, data)`

Triggers an event on the window, which will forwarded the event to the contained elements.
  As for now, this must be called from a Tool's event handler method.

**type** [ _Symbol_ ] a Symbol indicating the type of event (_:move_, _:mousedown_, _:mouseup_, ...).

**data** [ _Hash_ ] a hash containing the event's data:
  * :pos the relative position to the window's upper left corner [ _Geom::Point3d_ ]
  * :flags
  * :key ...




`OnScreen::Window.draw(view)`

Draws the window and all contained widgets onto the screen. 
  As for now, this must be called from a Tool's draw handler method.

**type** [ _Sketchup::View_ ] a view object.




Layout and Style
================

Layout comprises all properties that influence position and size of widgets. If the window is resized, the layout will be recreated.
Style includes all properties for the visual appearance.
Layout and Style can be assigned to individual widgets or to the window where they will serve as theme for specific widget type or for all widgets.

The cascade of priorities is _widget instance: hash[widget_state] **>** hash **>** window instance hash[widget_type] **>** hash **>** default_.

If Symbols (or Strings) are allowed, the will be interpreted as percent of the container's available space and for padding as percent of the element's size. Padding is – different from original CSS – defined as the inner spacing inside width/height, not outside.

The layout properties are as follows:
  * :position [ _:relative, :absolute_ ] Whether the position will be measured as distance from the the previous sibling or from parent element's upper left corner.
  * :top [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :right [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :bottom [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :left [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :marginTop [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :marginRight [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :marginBottom [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :marginLeft [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :paddingTop [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :paddingRight [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :paddingBottom [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :paddingLeft [ _Fixnum, Symbol_ ] The distance from a sibling or parent element.
  * :align [ _:left, :center, :right_ ] Where contained elements should be aligned horizontally (only for Containers).
  * :valign [ _:top, :middle, :bottom_ ] Where contained elements should be aligned vertically (only for Containers).
  * :orientation [ _:horizontal, :vertical_ ] Only for containers, whether contained elements with relative positions should be stacked horizontally or vertically.
  * :width [ _Fixnum, Symbol_ ]
  * :minWidth [ _Fixnum_ ]
  * :maxWidth [ _Fixnum_ ]
  * :height [ _Fixnum, Symbol_ ]
  * :minHeight [ _Fixnum_ ]
  * :maxHeight [ _Fixnum_ ]

The style properties are as follows:
  * :backgroundColor [ _Sketchup::Color_ ]
  * :borderRadius [ _Numeric, Symbol, Array(Numeric*4)_ ] If symbol, it will be interpreted as percent of the element's smaller dimension (width/height).
  * :borderColor [ _Sketchup::Color, Array(Sketchup::Color*4)_ ]
  * :borderWidth [ _Numeric, Array(Numeric*4)_ ] 0..10
  * :borderStyle [ _String, , Array(String*4)_ ] "", ".", "-", "_", "-.-"
  * :shadowColor [ _Sketchup::Color_ ] experimental
  * :shadowWidth [ _Numeric_ ] 0..10 experimental
  * :textColor [ _Sketchup::Color_ ]
    IMPORTANT! Setting :textColor or :textShadow triggers View.draw and thus an endless draw loop! No workaround known yet.
  * :textShadow [ _Boolean_ ]
  * :textShadowColor [ _Sketchup::Color_ ]
  * :textShadowOffset [ _Geom::Vector3d, Array(Numeric*3)_ ]
  * :textShadowRadius [ _0, 1_ ] Allows 1px outlines around the text.

      
      
      
Private Methods 
===============



`OnScreen::Widget.draw_box(view, pos, size, style)`

Draw a styled box.
This is a geometric primitive that can be used to build most widgets.

**view** [ _Sketchup::View_ ]

**pos** [ _Geom::Point3d_ ] (absolute) Position where to draw the widget on the screen.

**size** [ _Array_ ] Width and Height of space to fill.

**style** [ _Hash_ ] (optional) Style with CSS-like properties.




`OnScreen::Widget.draw_text(view, pos, text, style)`

Draw a styled text.
This is mainly a wrapper for View.draw_text which does not accept a text color.

**view** [ _Sketchup::View_ ]

**pos** [ _Geom::Point3d_ ] (absolute) Position where to draw the widget on the screen.

**text** [ _String_ ] the text.

**style** [ _Hash_ ] (optional) Style with CSS-like properties.

