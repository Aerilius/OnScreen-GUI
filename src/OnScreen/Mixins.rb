module AE
  module GUI3
    module OnScreen




# Temporary class for benchmarking.
class StopWatch
  def initialize(name="")
    @name = name
    @start, @max, @min, @average, @count = 0,0,1,0,0
  end
  def starts
    @start = Time.now
  end
  def ends
    t = Time.now - @start
    @max = t if t > @max
    @min = t if t < @min && t > 0
    @average = (@average * @count + t) / (@count + 1).to_f
    @count += 1
  end
  def report
    puts "#{@name} min: #{@min} max: #{@max} average: #{@average}"
  end
end




module Basic # TODO: find better name

  # Give a short string for inspection. This does not output instance variables
  # since these contain a lot of data, references to other objects and self-references.
  #
  # @return [String] the instance's class and object id
  def inspect
    return "#<#{self.class}:0x#{(self.object_id/2).to_s(16)}>"
  end

end




module Drawable # TODO: requires (Layout&)Style and (Event)
# TODO: @window


  # Detect if SketchUp supports transparent color drawing:
  @@supportsAlpha = Sketchup.version.to_i >= 8
  # Detect if SketchUp supports View.drawing_color for text:
  @@supportsTextColor = Sketchup.version.to_i < 7 #|| Sketchup.version.to_i > 8 # Boulder, we have a problem! I hope it get's fixed in version 9.


  attr_accessor :style, :focus, :hover, :active, :dragging


  def initialize
    super
    @style = Style.new(self)
    @focus = false
    @hover = false
    @active = false
    @dragging = false
  end


  # Setter methods for instance variables. These also update the style.
  states = ["focus", "hover", "active", "dragging"]
  states.each{ |string|
    inst_var = ("@" + string).to_sym
    method = (string + "=").to_sym
    define_method( method ) { |val|
      instance_variable_set(inst_var, val)
      # Get an Array of all widget states that are currently true.
      @style.set_substyle(*states.find_all{|s| self.send(s)==true })
    }
  }


  # Draw the widget. This will be subclassed and contain the logic for different widget states.
  # It will be called by OnScreen::Window.
  #
  # @param [Sketchup::View]
  def draw(view, pos, size)
  end


  def trigger(type, data)
    # Example: Check if the widget has a sensitive area that includes pos.
    # Then set the widget state for styling or call an action.
    # TODO: support the following states: @focus, @hover, @active, @dragging
    case type
    when :move then
      invalidate if @state != :hover # TODO: invalidate only if there is something to draw, not when hovering invisible containers! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      @state = :hover if @state != :active
    when :mousedown then
      invalidate if @state != :active
      @state = :active
      # UI.start_timer(0.1, false){ invalidate } TODO: remove this
    when :mouseup then
      invalidate if @state == :active
      @state = :hover
    end
    super rescue nil # if self.class.superclass.instance_methods.include?("trigger") # doesn't work
  end


  private


  # Request a redraw of this widget.
  def invalidate
    self.window.drawcache.invalidate(self) unless self.window.nil?
  end


  # Draw a styled box.
  # This is a geometric primitive that can be used to build most widgets.
  #
  # @param [Sketchup::View] view
  # @param [Array] pos  (absolute) Position where to draw the widget on the screen.
  # @param [Array] size  Width and Height of space to fill.
  # @param [Hash] style  (optional) Style with CSS-like properties.
  #   Style supports these properties:
  #   * backgroundColor [Sketchup::Color]
  #   * borderRadius    [Numeric, Array(Numeric,Numeric,Numeric,Numeric)]
  #   * borderColor     [Sketchup::Color, Array(Sketchup::Color,Sketchup::Color,Sketchup::Color,Sketchup::Color)]
  #   * borderWidth     [Numeric, Array(Numeric,Numeric,Numeric,Numeric)] 0..10
  #   * borderStyle     [String, Array(String,String,String,String)] of view.line_stipple
  #   * shadowColor     [Sketchup::Color]
  #   * shadowWidth     [Numeric] 0..10
  #
  # @return [Sketchup::View]
  def draw_box(view, pos, size, style)
    return unless style[:visible] == true
    pos = Geom::Point3d.new(pos) # make sure that pos has no more than 2...3 values
    rectangle = [ ORIGIN, ORIGIN+[size.x,0], ORIGIN+size, ORIGIN+[0,size.y] ]
    # create rounded corners if requested
    if !style[:borderRadius].nil? && style[:borderRadius] != 0
      rectangle, corners = [], rectangle # empty rectangle array so that it can be filled again including rounded corners
      radius = style[:borderRadius]
      radius = [radius]*4 unless radius.is_a?(Array)
      r, segments, angle, offset, vector, rotation = 0, 0, 0, [0,0,0], [0,0,0], nil # declare variables for loop
      corners.each_with_index{|c, i|
        r = radius[i]
        # optionally resolve percent value of radius
        r = size.min * r.to_s.to_f/100.0 if r.is_a?(Symbol) || r.is_a?(String)
        # radius can't be bigger than half the width/height
        r = radius[i] = [size[0]/2, size[1]/2, r].min.to_i
        # create segments
        segments = [2, r/3+2].max.to_i
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
    draw_polygon(view, pos, rectangle, style)
  end


  # Draw a styled polygon or polygons.
  #
  # @param [Sketchup::View] view
  # @param [Array] pos (absolute) +Position+ where to draw the widget on the screen.
  # @param [Array<Geom::Point3d>, Array<Array<Geom::Point3d>>] points An array of points, or arrays containing points.
  # @param [Hash] style (optional) +Style+ with CSS-like properties.
  #   Style supports these properties:
  #   * backgroundColor [Sketchup::Color]
  #   * borderRadius    [Numeric, Array(Numeric,Numeric,Numeric,Numeric)]
  #   * borderColor     [Sketchup::Color, Array(Sketchup::Color,Sketchup::Color,Sketchup::Color,Sketchup::Color)]
  #   * borderWidth     [Numeric, Array(Numeric,Numeric,Numeric,Numeric)] 0..10
  #   * borderStyle     [String, Array(String,String,String,String)] of view.line_stipple
  #   * shadowColor     [Sketchup::Color]
  #   * shadowWidth     [Numeric] 0..10
  #
  # @return [Sketchup::View]
  def draw_polygon(view, pos, points, style=@@default_style[:default])
    return unless style[:visible] == true
    pos = Geom::Point3d.new(pos) # make sure that pos has no more than 2...3 values
    polygons = (points.first.is_a?(Geom::Point3d) || points.first.is_a?(Array) && points.first.first.is_a?(Numeric))? [points] : points
    polygons.each{|polygon| # TODO
      # Offset the polygon to the given position.
      polygon.map!{|p| pos + p.to_a}
      # Create shadow behind the polygon by overlaying transparent polylines.
      # Only for SketchUp versions that support transparent color drawing.
      # TODO: Since we decided to draw a border, curves have gaps and look ugly (like stars).
      #   Alternatively, add an offset to the polygon and draw a filled polygon.
      if !style[:shadowWidth].nil? && style[:shadowWidth] != 0 && @@supportsAlpha
        view.drawing_color = @style.color(style[:shadowColor])
        view.line_stipple = ""
        (style[:shadowWidth]/2).times{|i| 2*i
          view.line_width = 2*i
          view.draw2d(GL_LINE_LOOP, polygon)
        }
      end
      # Draw the background.
      if !style[:backgroundColor].nil? && @style.color(style[:backgroundColor]).alpha != 0
        view.drawing_color = @style.color(style[:backgroundColor])
        view.draw2d(GL_POLYGON, polygon)
      end
      # Draw the border.
      if !style[:borderColor].nil? && @style.color(style[:borderColor]).alpha != 0 && !style[:borderWidth].nil? && (style[:borderWidth].is_a?(Array) ? style[:borderWidth].max : style[:borderWidth]) > 0
        # If all border properties are the same, just draw the polygon.
        unless style[:borderColor].is_a?(Array) || style[:borderWidth].is_a?(Array) || style[:borderStyle].is_a?(Array)
          view.line_width = style[:borderWidth]
          view.line_stipple = style[:borderStyle]
          view.drawing_color = @style.color(style[:borderColor])
          view.draw2d(GL_LINE_LOOP, polygon)
         # If widths/colors/styles are different for top, right, bottom, left,  split the polygon into 4 parts (top, right, bottom, left).
        else
          border_color = style[:borderColor]
          border_color = [border_color]*4 unless border_color.is_a?(Array)
          border_width = style[:borderWidth]
          border_width = [border_width]*4 unless border_width.is_a?(Array)
          border_style = style[:borderStyle]
          border_style = [border_style]*4 unless border_style.is_a?(Array)
          # Get each side of the polygon.
          # Find the most top-left (top-right, bottom-right, bottom-left) corner and split the polygon.
          l = polygon.length
          corners = [Geom::Vector3d.new(1,-1,0), Geom::Vector3d.new(1,1,0), Geom::Vector3d.new(-1,1,0), Geom::Vector3d.new(-1,-1,0)]. # topright, bottomright, bottomleft, topleft
            collect{|d| polygon.index( polygon.max{|a,b| d%a.to_a <=> d%b.to_a} ) }
          corners.each_with_index{|c1,i|
            c0 = corners[i-1]
            side = (c0 < c1)? polygon.slice(c0..c1) : polygon.slice(c0..l).concat(polygon.slice(0..c1))
            view.drawing_color = @style.color(border_color[i])
            view.line_width = border_width[i]
            view.line_stipple = border_style[i]
            view.draw2d(GL_LINE_STRIP, side)
          }
        end
      end
    }
  end


  # Draw a styled text.
  # This is mainly a wrapper for View.draw_text which does not accept a text color.
  #
  # @param [Sketchup::View] view
  # @param [Array] pos the (absolute) +Position+ where to draw the text on the screen.
  # @param [String] text the text to draw.
  # @param [Hash] style an (optional) +Style+ with CSS-like properties.
  #   Style supports these properties:
  #   * textColor  [Sketchup::Color]
  #   * textShadow       [Boolean]
  #   * textShadowColor  [Sketchup::Color]
  #   * textShadowOffset [Geom::Vector3d, Array(Numeric,Numeric,Numeric)]
  #   * textShadowRadius [Numeric] 0 or 1
  #
  # @return [Sketchup::View]
  def draw_text(view, pos, text, style={})
    return unless style[:visible] == true
    # TODO: IMPORTANT! Changing the edge color triggers View.draw and thus an endless draw loop! No workaround known yet.
    force_color = @@supportsTextColor # !@window.nil? && !style[:textColor].nil? && style[:textColor]!=@@color[:foregroundColor]
    # View.draw_text does not allow to set a text color but uses the default edge color.
    # Change the edge color only if necessary.
    if force_color
      if style[:textShadow]
        @window.model.rendering_options["ForegroundColor"] = @style.color(style[:textShadowColor])
        view.drawing_color = @style.color(style[:textShadowColor])
        view.draw_text( pos+style[:textShadowOffset], text )
        if style[:textShadowRadius] > 0 # only 1 supported
          view.draw_text( pos+style[:textShadowOffset]+[-1,-1,0], text )
          view.draw_text( pos+style[:textShadowOffset]+[0,-1,0], text )
          view.draw_text( pos+style[:textShadowOffset]+[1,-1,0], text )
          view.draw_text( pos+style[:textShadowOffset]+[1,0,0], text )
          view.draw_text( pos+style[:textShadowOffset]+[1,1,0], text )
          view.draw_text( pos+style[:textShadowOffset]+[0,1,0], text )
          view.draw_text( pos+style[:textShadowOffset]+[-1,1,0], text )
          view.draw_text( pos+style[:textShadowOffset]+[-1,0,0], text )
        end
      end
      @window.model.rendering_options["ForegroundColor"] = @style.color(style[:textColor])
      view.drawing_color = @style.color(style[:textColor])
    end

    view.draw_text( pos, text )

    # Reset the edge color and optionally more effects.
    @window.model.rendering_options["ForegroundColor"] = @style.color(style[:foregroundColor]) if force_color
  rescue
    @window.model.rendering_options["ForegroundColor"] = @style.color(style[:foregroundColor])
  end


end # module Drawable




module Events


  def initialize
    super # if superclass
    # Hash that stores events :type => [block1, block2, ...]
    @events = {}
  end


  # Attach an event.
  #
  # @param [Symbol] eventname  name of the event.
  # @param [Proc] code Block to execute when the event is triggered.
  #
  # @return Probably a callback, or Boolean whether event handler has been triggered.
  def on(eventname, &block)
    return false unless block_given?
    @events[eventname] ||= []
    @events[eventname] << block
    return true
  end


  # Detach an event.
  #
  # @param [Symbol] eventname  name of the event.
  # @param [Proc] block  reference to the same code block.
  # TODO: Allow another identifier so that events can be easierly removed (by not using a block as identifier).
  #
  # @return Probably a callback, or Boolean whether event handler has been triggered.
  def off(eventname, &block)
    return false unless @events.include?(eventname)
    @events[eventname].delete(block)
    @events.delete(eventname) if @events[eventname].empty?
    return true
  end


  # TODO: protected ?


  # Respond to an event.
  # Check if the event occured in a sensitive area and call the event handler.
  #
  # @param [Symbol] type Type of the event. Will be something like click, hover...
  #                                      Or LButtonDown etc.?
  # @param [Array] data Data like the position where the event occured on the widget.
  #   Position is relative to the widget's top left corner. # TODO: without padding! Remove padding!
  #   The widget does not (need to) know its absolute position on screen.
  #
  # @return Probably a callback, or Boolean whether event handler has been triggered.
  def trigger(type, data={})
    return false unless @events.include?(type)
    @events[type].each{|b| b.call(data)}
    # TODO: maybe implement event bubbling here: @parent.trigger(type, data) if !@parent.nil? && @parent != @window
    return true
  end

  # TEST THIS
  #if self (Class) is_a?(Window)
  #  define specific methods
  #end

end # module Event




module Containable # requires: self.window


  include Events


  attr_reader :children


  def initialize
    super
    # List of widgets that are contained in this container (children).
    @children = []
    unless self.is_a?(Window)
      on(:added_to_window){ # TODO: requires event mixin
        self.children.each{|widget|
          widget.window = window
          widget.trigger(:added_to_window, self.window)
          window.trigger(:descendant_added, widget)
        }
      }
      on(:removed_from_window){ # TODO: requires event mixin
        self.children.each{|widget|
          widget.window = nil
          widget.trigger(:removed_from_window, self.window)
          window.trigger(:descendant_removed, widget)
        }
      }
    end
  end


  # Add the given widget(s) to this container.
  #
  # @param [Array] widgets  One or more widgets.
  #
  # @return [OnScreen::Widget, Array] If one widget given, it is returned.
  # If several widgets given, an array of them is returned.
  # TODO: If a widget has already a parent, remove it, or allow the widget to appear as duplicates?
  #       GTK would give a warning. On the other side, it works, and it sounds cool to have clones that behave synchronously.
  def add(*widgets)
    widgets.each{|widget|
      next unless widget.is_a?(Widget) || widget.is_a?(Container)
      @children << widget
      widget.trigger(:removed, widget.parent) unless widget.parent.nil?
      widget.parent = self
      widget.trigger(:added, self)
      self.trigger(:child_added, widget)
      if !self.window.nil?
        widget.window = self.window
        widget.trigger(:added_to_window, self.window)
        window.trigger(:descendant_added, widget)
      end
    }
    return widgets.length==1? widgets[0] : widgets
  end


  # Remove the given widget(s) from this container.
  #
  # @param [Array] widgets  One or more widgets.
  #
  # @return [OnScreen::Widget, Array] If one widget given, it is returned.
  # If several widgets given, an array of them is returned.
  def remove(*widgets)
    widgets.each{|widget|
      next unless widget.is_a?(Widget) || widget.is_a?(Container)
      @children.delete(widget)
      self.trigger(:child_removed, widget)
      widget.parent = nil
      widget.trigger(:removed, self)
      if !self.window.nil?
        widget.window = nil
        widget.trigger(:removed_from_window, self.window)
        window.trigger(:descendant_removed, widget)
      end
    }
    return widgets.length==1? widgets[0] : widgets
  end


  # TODO: def contentsize


end # module Containable



# Temporary helper methods until better text / dpi features are available.
module TextHelper


   def text_width(text)
     return text.split(/\n/).inject(0){|s,l| l.length>s ? l.length : s} * 9 + 20
   end


   def text_height(text)
     return text.split(/\n/).length * 15 + 20
   end


end




    end # module OnScreen
  end # module GUI
end # module AE
