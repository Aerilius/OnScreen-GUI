=begin

Copyright 2012, Aerilius
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
                and call the window.trigger(event, {:pos, :flags, ...}) method from within the Tool's event methods.

Version:      0.3.0
Date:         10.10.2012

License Draft:
- open source code
- free to use
- freedom to modify
- attribution
- what about commercial usage + modification (copy-left?)
- rather BSD/MIT than GPL; What are disadvantages of BSD, are other licenses better?
- Apache like SketchUp opensource projects

module Utilities

  def offset(points, radius)
    vectors = []
    points.each_index{|i|
      vectors << points[i-1].vector_to(points[i])
    }
    vectors.push(vectors.shift)
    n = vectors[0] * vectors.find{|v| !v.collinear?(vectors[0])} # TODO: not good
    points.each_with_index{|i|
      v1, v2 = vectors[i-1], vectors[i]
      v = (v1 + v2) * n
      a = v1.angle_between(v2)/2.0
      v.length = radius/Math.tan(a)
      points[i] += v
    }
    return points
  end

end
=end


require File.join(File.dirname(__FILE__), "Color.rb")
require File.join(File.dirname(__FILE__), "Mixins.rb")
require File.join(File.dirname(__FILE__), "DrawCache.rb")
require File.join(File.dirname(__FILE__), "LayoutCache.rb")
require File.join(File.dirname(__FILE__), "Style.rb")


module AE
  module GUI3
    module OnScreen


DEBUG = true unless defined?(DEBUG)


class Widget

  include Basic
  include Events
  include Drawable

  attr_accessor :window, :parent

  def initialize(hash=nil)
    @parent = nil
    @window = nil
    super()
    style.set(hash) unless hash.nil?
  end

end




# A class for nested widgets. This one does not inherit from Widget because by
# default it does not need to be drawable (only for layout), but you can subclass
# it and mix-in Drawable (to create toolbars or other container widgets).
class Container

  include Basic
  include Events
  include Containable

  attr_accessor :window, :parent, :style

  def initialize(*args)
    @parent = nil
    @window = nil
    @style = Style.new(self) # If it's not a Drawable, we still need a style instance for layout (position/sizes).
    super()
  end

end




# The root element to which all widgets are attached. It receives input events (trigger)
# and sends them to the corresponding widgets and it calls the main drawing method.
#
# TODO: rename it into something more general like Root
# TODO: allow different kinds of "root" elements:
#   * 2d in screen space (draw2d) attached to the ORIGIN (left uper corner of viewport)
#   * 2d in screen space (draw2d) attached to a Geom::Point3d or DrawingElement in the 3d space
#   * 3d in model space (3d buttons, with transformations)
# TODO: make layout engine (LayoutCache) optional to allow more flexible widgets (gizmos in 3d space)
#       if no LayoutCache is used, 3d widgets need to check on their own whether
#       they have been touched by an event.
class Window

  include Basic
  include Events
  include Containable

  attr_accessor :window, :parent, :stylesheet, :style, :dragged_element, :focussed_element
  attr_reader :drawcache, :layoutcache, :viewport

  def initialize(context=nil)
    @model = Sketchup.active_model # TODO: allow setting this with initialization (?)
    @parent = nil # TODO: can I remove this?
    @window = self
    # This is the stylesheet, that all widgets can reference (if they haven't bee assigned a specific style).
    # It is a simple Hash.
    @stylesheet = Style.default_style
    # This is the Window's own style. Not very relevant (if any than only padding, orientation etc.).
    # It is a style instance (only little similar like a hash).
    @style = Style.new(self)
    @model = (context.nil?)? Sketchup.active_model : (context.is_a?(Sketchup::View))? context.model : context
    @view = @model.active_view
    @viewport = [] # [@view.vpwidth, @view.vpheight]
    # The draw cache stores drawing operations so that they don't need to be recalculated when nothing changes.
    # At the moment, this benefits zooming (orbiting/panning resumes the tool).
    # However when one single widget changes, the whole cache is recalculated.
    @drawcache = OnScreen::DrawCache.new(@view)
    # The layout cache stores positions and sizes of widgets. It needs to be recalculated only when the window size changes.
    @layoutcache = OnScreen::LayoutCache.new(self)

    @view.invalidate

    # Holds a reference to the widget that is currently dragged.
    @dragged_element = nil
    # Holds a reference to the widget that has currently focussed (would be required for keyboard input, not implemented yet).
    @focussed_element = nil

    super()

    if DEBUG
      @time_trigger = StopWatch.new("Trigger")
      @time_layout = StopWatch.new("Layout")
      @time_draw = StopWatch.new("Draw")
      @time_render = StopWatch.new("Render")
      def self.report
        @time_trigger.report
        @time_layout.report
        @time_draw.report
        @time_render.report
      end
    end

  end


  # Trigger events on widgets.
  # This must be called from the active +Tool+ (which receives input events).
  #
  # @param [Sketchup::View]
  # @param [Symbol] type +Type+ of the event. Will be something like :click, :hover...
  #                                      Or LButtonDown etc.?
  # @param [Hash] data
  def trigger(type, data={})
    super(type, data)
    # TODO: support the following types: :mousedown, :mouseup, ..., :move, :drag, :dragstart, :dragend, :dragenter, :drop?
    @time_trigger.starts if DEBUG
    # dragging
    if type == :move && !@dragging.nil?
      # Find the widget that is being dragged.
      @layoutcache.each{|widget, pos, size| relpos = data[:pos] - pos if widget == @dragging }
      return @dragging.trigger(:drag, data.merge({:pos=>relpos}))
    elsif type == :mouseup && !@dragging.nil?
      @layoutcache.each{|widget, pos, size| relpos = data[:pos] - pos if widget == @dragging }
      @dragging.trigger(:drop, data.merge({:pos=>relpos}))
      @dragging = nil
    end
    # If the event has a position, filter widgets by position.
    if data.is_a?(Hash) && data.include?(:pos)
      pos = data[:pos]
      # A widget will not be triggered on mouseout, so we don't know when hover ends.
      # Therefore reset hover for all widgets.
      @layoutcache.each{|widget, wpos, wsize| widget.hover = false}
      # Widgets that lay on the event's position:
=begin
      responding_widgets = []
      @layoutcache.each{|widget, wpos, wsize|
        responding_widgets << [widget, wpos, wsize] if
        pos.x > wpos.x && pos.x < wpos.x + wsize.x &&
        pos.y > wpos.y && pos.y < wpos.y + wsize.y
      }
      # Sort them by hierarchy (currently: area size, could also be nesting level == zIndex)
      responding_widgets.sort!{|a1, a2|
        w1_area = a1[2].x * a2[2].y
        w2_area = a1[2].x * a2[2].y
        w1_area <=> w2_area
      }
      # Try to trigger the event on all these widgets.
      # Widgets receive only local coordinates (where inside the widget the event happened).
      responding_widgets.find{|a|
        relpos = pos - a[1]
        a[0].trigger(type, data.merge({:pos=>relpos})) # returns true or false
      }
=end
      target_pos = ORIGIN
      target = nil
      @layoutcache.each{|widget, wpos, wsize|
        # Check if pos is within rectangle wpos..wpos+wsize.
        # Three times faster than Geom.point_in_polygon_2D(pos, [[0,0], [wsize.x,0], wsize, [0,wsize.y]], true)
        if pos.x > wpos.x && pos.x < wpos.x + wsize.x &&
           pos.y > wpos.y && pos.y < wpos.y + wsize.y &&
           (target.nil? || wpos.z >= target_pos.z) then
          target_pos = wpos
          target = widget
        end
      }
      return if target.nil?
      relpos = pos - Geom::Vector3d.new(target_pos.to_a)
      target.trigger(type, data.merge({:pos=>relpos})) # returns true or false
      target
      # returns triggered widget
    # If the event has no position, send it to the focussed widget.
    elsif !@focussed_widget.nil?
      # TODO: if the event does not contain a position, it could be a keyboard event.
      # We would need a variable to keep track on which element has focus.
      @focussed_widget.trigger(type, data)
      @focussed_widget
      # returns triggered widget
    end
    @time_trigger.ends if DEBUG

  end


  # Draws all widgets onto the screen.
  # This method must be called from the active Tool.
  #
  # @param [Sketchup::View]
  def draw(view)
    # Cache the view object and make it accessible
    @view = view
    if viewport_changed?(view)
      @time_layout.starts if DEBUG
      # Invalidate the cached sizes of widgets so that they will definitely be recalculated.
      @layoutcache.each{|widget| widget.style.invalidate }
      puts("layoutcache invalidated")
      # Compile the layout. This arranges all widgets in the viewport, determines sizes and positions.
      @layoutcache.render
      return puts("rendered") # DEBUG
      puts @layoutcache.inspect
      @time_layout.ends if DEBUG
    end
  return # DEBUG

    unless @drawcache.valid?
      @time_draw.starts if DEBUG
      # Redraw the widgets. The widgets' sizes and positions have been cached, the draw methods will only apply the style.
      @layoutcache.each{|widget, pos, size|
        next if widget.is_a?(OnScreen::Window) # Note: actually this is redundant, but be sure we don't call @window.draw inside this method. # TODO: deprecated.
        puts(["drawing",widget].inspect) # DEBUG
        widget.draw(@drawcache, pos, size) if widget.respond_to?(:draw)
      }
      @drawcache.ready
      @time_draw.ends if DEBUG
    end
    # Draw what is in the cache.
    @time_render.starts if DEBUG
    @drawcache.render
    @time_render.ends if DEBUG
  end


  private


  # Whether the viewport size has changed.
  #
  # @param [Sketchup::View]
  #
  # @return [Boolean]
  def viewport_changed?(view)
    changed = (@viewport != [view.vpwidth, view.vpheight])
    if changed
      @viewport = [view.vpwidth, view.vpheight]
      @style[:width] = view.vpwidth
      @style[:height] = view.vpheight
    end
    return changed
  end


end




    end # module OnScreen
  end # module GUI
end # module AE
