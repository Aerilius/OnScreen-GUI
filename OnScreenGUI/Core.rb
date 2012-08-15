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
  # Colors
  @@transparent = Sketchup::Color.new([255,255,255,0])
  @@white = Sketchup::Color.new("white")
  @@gray = Sketchup::Color.new("gray")
  @@black = Sketchup::Color.new("black")


  @@default_style = {
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

  def initialize(hash={})
    @parent = nil
    @window = nil
    @layout = {}
    # Cached value of the width and height. Only for method size().
    @currentsize = nil
    # The style includes properties for the visual appearance.
    @remembered_style = nil
    self.style=(hash) # TODO: filter unnecessary elements out of hash
    # The layout includes properties for positioning and sizing.
    @remembered_layout = {}
    self.layout=(hash) # TODO: filter unnecessary elements out of hash
    @events = {}
  end


  # Set style properties for the visual appearance of the widget.
  # If incomplete, it inherits the style that has been passed to the window widget,
  # and if that was incomplete it takes default properties.
  #
  # @param [Hash] style properties and values
  #
  # @return [Hash] the complete style of the widget
  def style=(hash={})
    return @remembered_style = hash if @window.nil?
    type = self.class.name[/[^\:]+$/].downcase.to_sym
    widget_style = deep_merge(@window.style[type]||{}, hash)
    puts "type: #{type.inspect}\n@@default_style: #{@@default_style.inspect}\n window_style: #{@window.style.inspect}"
    @style = deep_merge(@@default_style[type]||{}, widget_style)
  end


  # Set layout properties for the positioning and size of the widget.
  # If incomplete, it inherits the layout that has been passed to the window widget,
  # and if that was incomplete it takes default properties.
  #
  # @param [Hash] layout properties and values
  #
  # @return [Hash] the complete layout of the widget
  def layout=(hash={})
    return @remembered_layout = hash if @window.nil?
    type = self.class.name[/[^\:]+$/].downcase.to_sym
    widget_layout = deep_merge(@window.layout, hash)
    @layout = deep_merge(@@default_layout, widget_layout)
  end


  # Attach an event.
  #
  # @param [Symbol] +Type+ of the event.
  # @param [Proc] code +Block+ to execute when the event is triggered.
  #
  # @return Probably a callback, or Boolean whether event handler has been triggered.
  # TODO: additional view param necessary?
  def on(eventname, &block)
    @events[eventname] = block
  end


  #protected # TODO


  attr_accessor :parent, :window


  def style
    return @style
  end


  def layout
    return @layout
  end


  # A callback when the widget has been included in a container widget.
  #
  # @param [OnScreen::Container] the new parent container
  def on_added(new_parent)
  end


  # A callback when the widget has been removed from a container widget.
  #
  # @param [OnScreen::Container] the old parent container
  def on_removed(old_parent)
  end


  # A callback when the widget has been included in a window.
  #
  # @param [OnScreen::Container] the new window
  def on_added_to_window(window)
    self.style=(@remembered_style)
    self.layout=(@remembered_layout)
  end


  # A callback when the widget has been removed from a window.
  #
  # @param [OnScreen::Container] the old window
  def on_removed_from_window(old_window)
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
    @events[type].call
  end


  # Calculate the widget's +size+. Essential for doing the positioning.
  #
  # @return [Array] +Width+ and +Height+ of the widget.
  def size
    return @currentsize unless @currentsize.nil? || @window && !@window.changed?
    csize = [ @layout[:width], @layout[:height] ]
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
  def compile_layout(cpos, csize)
    layouted_widgets = {self => {:pos=>cpos, :size=>self.size}} # TODO: changed from csize to self.size, correct?
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
    style = deep_merge(@@default_style[:box], style)
    pos = Geom::Point3d.new(pos.to_a) # TODO: make sure that pos has no more than 2...3 values
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



  # Merge two hashes and all Hashes inside.
  # In contrast, Hash.merge does not support nested hashes,
  # but would replace Hashes in <oldhash> by ones of the <newhash>.
  #
  # @param [Hash] oldhash the hash whose keys' values should be updated.
  # @param [Hash] newhash the hash whose key/values should be added to the oldhash
  #   or replace the ones of the oldhash.
  #
  # @return [Hash]
  def deep_merge(oldhash, newhash)
    r = {}
    block = Proc.new{|key, oldval, newval| 
      r[key] = oldval.class == Hash ? oldval.merge(newval, &block) : newval
    }
    oldhash.merge(newhash, &block)
  end



end





class AE::GUI::OnScreen::Container < AE::GUI::OnScreen::Widget

  attr_accessor :children

  def initialize(hash={})
    # List of widgets that are contained in this one (children).
    @children = []
    super
  end


  def add(widget)
    @children << widget
    widget.on_removed(widget.parent) unless widget.parent.nil?
    widget.on_added(self)
    widget.parent = self
    widget.window = self.window unless self.window.nil?
    widget.on_added_to_window(self.window) unless self.window.nil?
    return widget
  end


  def remove(widget)
    @children.delete(widget)
    widget.parent = nil
    widget.on_removed(self)
    widget.window = nil
    widget.on_removed_from_window(self.window) unless self.window.nil? # TODO: conditional necessary?
    return widget
  end


  # Calculate the widget's +size+. Essential for doing the positioning.
  #
  # @return [Array] +Width+ and +Height+ of the widget.
  def size
    return @currentsize unless @currentsize.nil? || @window && !@window.changed?
    # Get the size caused by contained widgets
    csize = @children.inject([0,0]){|cs, widget|
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
  def compile_layout(cpos, csize)
    layouted_widgets = {self => {:pos=>cpos, :size=>size}} # TODO: changed from csize to self.size, correct?
    cpos = Geom::Point3d.new(cpos)
    relpos = [0, 0, 0] # relative position
    # container position and size
    cx, cy = *cpos
    cw, ch = *csize
    # loop over all contained widgets and set their position
    @children.each{|w|
      # widget position and size
      wsize = w.size
      ww, wh = *wsize
      # puts "widget: #{w}" # TODO
      # puts "layout: #{w.layout.inspect}" # TODO
      wpos = cpos + w.layout[:point].to_a
#puts wpos.inspect+"is now a vector?" if wpos.is_a?(Geom::Vector3d)
      # relative layout sets the widget right or below a previous sibling
      if w.layout[:position] == :relative
        wpos += relpos
        # TODO: this behaves not exactly like relative top/left in CSS, but more like margin
        relpos += (w.parent.layout[:flow] == :horizontal)? [wpos[0]+ww, 0, 0] : [0, wpos[1]+wh, 0]
        # == # relpos += (self.layout[:flow] == :horizontal)? [wpos[0]+ww, 0] : [0, wpos[1]+wh, 0]
      # absolute layout can have:
      # width, height = :max  stretched to the full width of the parent container
      # align, valign: alignment in the parent container
      else # if w.layout[:position] == nil or :absolute
        if w.layout[:position] == :absolute
          ww = cw if w.layout[:width] == :max
          wh = ch if w.layout[:height] == :max
        end
        if w.layout[:align] == :center
          wpos += [0.5*cw - 0.5*ww, 0, 0]
        elsif w.layout[:align] == :right
          wpos += [cw - ww, 0, 0]
        end
        if w.layout[:valign] == :middle
          wpos += [0, 0.5*ch - 0.5*wh]
        elsif w.layout[:valign] == :bottom
          wpos += [0, ch - wh]
        end
      end
      wsize = [ww, wh, 0]
      layouted_widgets.merge!(w.compile_layout(wpos, wsize))
    }
    return layouted_widgets
  end


end

