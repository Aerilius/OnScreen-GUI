=begin

Copyright 2011, Aerilius
All Rights Reserved

Permission to use, copy, modify, and distribute this software for 
any purpose and without fee is hereby granted, provided that the above
copyright notice appear in all copies.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Description:  OnScreen GUI for SketchUp
Usage:        * Create a Tool (for input events and the ability to draw on screen)
                (Probably the window widget could theoretically be used as tool)
              * Create an instance of the window:
                window = AE::GUI::OnScreen::Window.new
              * Add widgets to it:
                button = AE::GUI::OnScreen::Button.new()
                window.add(button)
              * Call the window.draw method from within the Tool's draw method,
                and call the window.event method from within the Tool's event methods.
              
Version:      0.1
Date:         07.08.2012

=end


module AE
  module GUI
    module OnScreen
    end
  end
end



# The main class of the OnScreen toolkit. Everything is a widget.
# Do not use this class directly, only for subclassing.
#
class AE::GUI::OnScreen::Widget


  # Detect if SketchUp supports transparent color drawing:
  @@supportsAlpha = Sketchup.version.to_i >= 8
  @@transparent = Sketchup::Color.new([255,255,255,0])
  @@white = Sketchup::Color.new("white")
  @@gray = Sketchup::Color.new("gray")
  @@black = Sketchup::Color.new("black")
  @@theme = {
    :box => {
      :backgroundColor => @@white,
      :borderRadius => 0,
      :borderColor => @@gray,
      :borderWidth => 1,
      :borderStyle => "",
      :shadowColor => Sketchup::Color.new([0,0,0,50]),
      :shadowWidth => 0
    }
  }
  @@default_layout = {
    :position => :relative,
    :point => ORIGIN,
    :align => :left,
    :valign => :top,
    :flow => :horizontal,
    :width => 100,
    :minWidth => nil,
    :maxWidth => nil,
    :height => 40,
    :minHeight => nil,
    :maxHeight => nil
  }
  attr_accessor :layout, :contains

  def initialize(hash={})
    # List of widgets that are contained in this one (children).
    @contains = []
    # Cached value of the width and height. Only for method size().
    @currentsize = nil
    # The layout includes properties for positioning and sizing.
    @layout = @@default_layout.merge(hash)
  end


  def add(w)
    @contains << w
  end


  # Respond to an event.
  # Check if the event occured in a sensitive area and call the event handler.
  #
  # @param [Symbol] +Type+ of the event. Will be something like click, hover...
  #                                      Or LButtonDown etc.?
  # @param [Array] +Position+ where the event occured on the widget.
  #   This is relative to the widget's top left corner.
  #   The widget does not (need to) know its absolute position on screen.
  #
  # @return Probably a callback, or Boolean whether event handler has been triggered.
  # TODO: additional view param necessary?
  def trigger(type, pos)
    # Example: Check if the widget has a sensitive area that includes pos.
    # Then set the widget state for styling or call an action.
  end


  # Calculate the widget's +size+. Essential for doing the positioning.
  #
  # @return [Array] +Width+ and +Height+ of the widget.
  def size
    return @currentsize unless currentsize.nil?
    # Get the size caused by contained widgets
    csize = @contains.inject([0,0]){|cs, widget|
      ws = widget.size
      if @layout[:flow] == :vertical
        w = [cs[0], ws[0]].max
        h = cs[1] + ws[1]
      else # if @layout[:flow] == :horizontal
        w = cs[0] + ws[0]
        h = [cs[1], ws[1]].max
      end
      [w, h]
    }
    csize[0] = @layout[:width] if csize[0] < @layout[:width]
    csize[1] = @layout[:height] if csize[1] < @layout[:height]
    # Consider min/max limits
    # TODO: At the moment, minWidth/minHeight is redundant.
    csize[0] = @layout[:minWidth] if @layout[:minWidth] && csize[0] < @layout[:minWidth]
    csize[0] = @layout[:maxWidth] if @layout[:maxWidth] && csize[0] > @layout[:maxWidth]
    csize[1] = @layout[:minHeight] if @layout[:minHeight] && csize[1] < @layout[:minHeight]
    csize[1] = @layout[:maxHeight] if @layout[:maxHeight] && csize[1] > @layout[:maxHeight]
    return @currentsize = csize
  end


  # Fit the widget into a container.
  # This calculates the +positions+ of subcontainers and will be called from outside.
  #
  # @param [Sketchup::View]
  # @param [Array] (absolute) +Position+ where to draw the widget on the screen.
  # @param [Array] +Width+ and +Height+ of space to fill.
  # @param [Hash] (optional) +Style+ with CSS-like properties.
  #
  # @return [Sketchup::View]
  def compile_layout(cpos, csize, flow = :horizontal)
    layouted_widgets = {self => [cpos, self.size]} # TODO: changed from csize to self.size, correct?
    relpos = [0, 0] # relative position
    cx, cy = *cpos
    cw, ch = *csize
    @contains.each{|w|
      wsize = w.size
      ww, wh = *wsize
      wpos = cpos + w.layout[:point]
      # absolute layout can have:
      # width, height = :max  stretched to the full width of the parent container
      # align, valign: alignment in the parent container
      if w.layout[:position] == :absolute
        ww = cw if w.layout[:width] == :max
        wh = ch if w.layout[:height] == :max
        if w.layout[:align] == :center
          wpos += [0.5*cw - 0.5*ww, 0]
        elsif w.layout[:align] == :right
          wpos += [cw - ww, 0]
        end
        if w.layout[:valign] == :middle
          wpos += [0, 0.5*ch - 0.5*wh]
        elsif w.layout[:valign] == :bottom
          wpos += [0, ch - wh]
        end
      # relative layout sets the widget right or below a previous sibling
      else # if w.layout[:position] == :relative
        wpos += relpos
        relpos += (flow == :horizontal)? [ww, 0] : [0, wh]
      end
      layouted_widgets.merge!(w.compile_layout(wpos, [ww, wh], w.layout[:flow]))
    }
    return layouted_widgets
  end


  # Draw the widget. This will be subclassed and contain the logic for different widget states.
  # It will be called by AE::GUI::OnScreen::Window.
  #
  # @param [Sketchup::View]
  def draw(view, pos, size)
  end


  private


  # Draw a styled box.
  # This is a geometric primitive that can be used to build most widgets.
  #
  # @param [Sketchup::View]
  # @param [Array] (absolute) +Position+ where to draw the widget on the screen.
  # @param [Array] +Width+ and +Height+ of space to fill.
  # @param [Hash] (optional) +Style+ with CSS-like properties.
  #   Style supports these properties:
  #   * +backgroundColor+ [Sketchup::Color]
  #   * +borderRadius+    [Numeric|Array]
  #   * +borderColor+     [Sketchup::Color]
  #   * +borderWidth+     [Numeric] 0..10
  #   * +borderStyle+     [String] of view.line_stipple
  #   * +shadowColor+     [Sketchup::Color]
  #   * +shadowWidth+     [Numeric] 0..10
  #
  # @return [Sketchup::View]
  def draw_box(view, pos, size, style={})
    style = @@theme[:box].merge(style)
    pos = Geom::Point3d.new(pos)
    rectangle = [ pos, pos+[size[0],0], pos+size, pos+[0,size[1]] ]
    # create rounded corners
    if !style[:borderRadius].nil? && style[:borderRadius] != 0
      rectangle, corners = rectangle, []
      radius = style[:borderRadius]
      radius = [radius]*4 if radius.is_a? Numeric
      corners.each_with_index{|c, i|
        # create segments
        segments = [2, radius[i]/3].max
        r = radius[i]
        angle = 0.5*Math::PI/segments
        # offset to move the corner points to the rotation center
        offset = [ (i%3==0?1:-1)*r,  (i<2?1:-1)*r,  0 ]
        # vector to get the start point of the border radius
        vector = [ (i-1).remainder(2)*r,  (i-2).remainder(2)*r,  0  ]
        rectangle << c + offset + vector
        rotation = Geom::Transformation.rotation(c+offset, Z_AXIS, angle)
        segments.times{|s|
          rectangle << rectangle.last.transform(rotation)
        }
      }
    end
    # create shadow behind the box by overlaying transparent polylines
    # Only for SketchUp versions that support transparent color drawing.
    if !style[:shadowWidth].nil? && style[:shadowWidth] != 0 && @@supportsAlpha
      view.drawing_color = style[:shadowColor]
      view.line_stipple = ""
      (style[:shadowWidth]/2).times{|i| 2*i
        view.line_width = 2*i
        view.draw2d(GL_LINE_LOOP, rectangle)
      }
    end
    # draw the background
    if style[:backgroundColor] != @@transparent
      view.drawing_color = style[:backgroundColor]
      view.draw2d(GL_POLYGON, rectangle)
    end
    # draw the border
    if !style[:borderWidth].nil? && style[:borderWidth] > 0
      view.drawing_color = style[:borderColor]
      view.line_width = style[:borderWidth]
      view.line_stipple = style[:borderStyle]
      view.draw2d(GL_LINE_LOOP, rectangle)
    end
  end


end





# The "window" is the root element to which widgets can be added.
# It is itself also a widget.
class AE::GUI::OnScreen::Window < AE::GUI::OnScreen::Widget


  def initialize(model=Sketchup.active_model)
    super
    @model = model # Not sure if this will be needed.
    # The canvas variable keeps track of all absolute positions of all widgets.
    @widgets = {}
    view = @model.active_view
    @canvas = [view.vpwidth, view.vpheight]
    # TODO: add style here, only per instance of window (allows different instances to have different styles)
    # Get default colors here
    # Try UI::WebDialog.new.get_background_color; then delete webdialog
  end


  # Trigger events on widgets.
  # This must be called from the active +Tool+ (which receives input events).
  #
  # @param [Sketchup::View]
  # @param [Symbol] +Type+ of the event. Will be something like :click, :hover...
  #                                      Or LButtonDown etc.?
  # @return [Array] (absolute) +Position+ where to draw the event happened.
  def event(view, type, pos)
    responding_widgets = @widgets.keys.find_all{|w|
      pos > @widgets[w].pos && pos < @widgets[w].pos + @widgets[w].size
    }
    responding_widgets.sort!{|w1,w2|
      w1_area = @widgets[w1].size[0] * @widgets[w1].size[1]
      w2_area = @widgets[w2].size[0] * @widgets[w2].size[1]
      w1_area <=> w2_area
    }
    responding_widgets.each{|widget|
      relpos = pos - @widgets[widget][:pos]
      widget.trigger(type, relpos)
    }
  end


  # Draws all widgets onto the screen.
  # This method must be called from the active Tool.
  #
  # @param [Sketchup::View]
  def draw(view)
    onWindowChange(view) if windowChanged?(view)
    @widgets.each{|w, pos_size|
      w.draw(view, *pos_size)
    }
  end


  private


  # Whether the viewport size has changed.
  #
  # @param [Sketchup::View]
  #
  # @return [Boolean]
  def windowChanged?(view)
    @canvas == [view.vpwidth, view.vpheight]
  end


  # Callback when the viewport size has changed.
  # We need to adjust the positions and sizes of all widgets to the new viewport.
  #
  # @param [Sketchup::View]
  def onWindowChange(view)
    pos = [0, 0]
    @widgets = compile_layout(pos, self.size(view))
  end


  # Returns the size of the viewport.
  # We need to override the superclass method, since this is the toplevel widget.
  #
  # @param [Sketchup::View]
  #
  # @return [Array] +Width+ and +Height+
  def size(view)
    return [view.vpwidth, view.vpheight]
  end


end





# The "window" is the root element to which widgets can be added.
# It is itself also a widget.
class AE::GUI::OnScreen::Button < AE::GUI::OnScreen::Widget

  @@theme[:button] = {
    :normal => {:background => @@white},
    :hover => {:background => Sketchup::Color.new("yellow")}, # only for testing
    :active => {:background => Sketchup::Color.new("green")},
  }

  def initialize(text, hash={})
    super(hash)
    @layout[:width] = text.split(/\n/).inject(0){|l,s| s.length>l ? s.length : l} * 10 + 20
    @layout[:height] = text.scan(/\n/).length * 15 + 10
    @data = {:text => text}
    @state = :normal
  end


  def trigger(type, pos)
    # No need to check pos since the whole button is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    # Eventually call other methods from here:
    @state = :hover if type == :mouseOver
    @state = :active if type == :click
  end


  def draw(view, pos, size)
    draw_box(view, pos, size, @@theme[:button][@state])
    # experiment
    upper_half = @@theme[:button][@state].clone
    upper_half[:height] = 0.5* size[1]
    upper_half[:borderRadius][2] = 0
    upper_half[:borderRadius][3] = 0
    upper_half[:borderWidth] = 0
    upper_half[:backgroundColor] = @@white.blend(@@transparent, 0.9)
    draw_box(view, pos, size, upper_half)
    # /experiment
    view.draw_text( pos+[10,5,0], @data[:text] )
    # TODO: where/when/how is it best to reset the state
    # if the cursor isn't anymore over the element?
    @state = :normal 
  end


end
