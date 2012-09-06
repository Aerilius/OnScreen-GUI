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
                and call the window.trigger(event, {:pos, ...}) method from within the Tool's event methods.
        
Version:      0.2.1
Date:         05.09.2012

=end


module AE
  module GUI
    module OnScreen

require File.join(File.dirname(__FILE__), "Color.rb")




# The main class of the OnScreen toolkit. Everything is a widget.
# Do not use this class directly, only for subclassing.
#
class OnScreen::Widget


  # Detect if SketchUp supports transparent color drawing:
  @@supportsAlpha = Sketchup.version.to_i >= 8
  # Detect if SketchUp supports View.drawing_color for text:
  @@supportsTextColor = Sketchup.version.to_i < 7 #|| Sketchup.version.to_i > 8 # Boulder, we have a problem! I hope it get's fixed in version 9.
  # Inspection Mode displays (currently) outlines of containers
  @@inspect = false


  # Colors
  dialog_color = AE::Color.new().from_hex( UI::WebDialog.new.get_default_dialog_color )
  @@color = {
    :foregroundColor => nil, # (Needs to initialize first Sketchup.active_model to get rendering_options)
    :white => AE::Color["white"],
    :gray => AE::Color["gray"],
    :black => AE::Color["black"],
    :red => AE::Color["red"],
    :transparent => AE::Color[255,255,255,0],
    :Window => AE::Color[dialog_color],
    :ThreeDHighlight => AE::Color[dialog_color].contrast(0.8).brighten(20),
    :ThreeDLightShadow => AE::Color[dialog_color].contrast(0.8).brighten(10),
    :ButtonFace => AE::Color[dialog_color].contrast(0.8),
    :ThreeDFace => AE::Color[dialog_color].contrast(0.8),
    :ButtonShadow => AE::Color[dialog_color].contrast(0.8).gamma(0.6),
    :ThreeDShadow => AE::Color[dialog_color].contrast(0.8).gamma(0.6),
    :ThreeDDarkShadow => AE::Color[dialog_color].contrast(0.8).gamma(0.4),
    :WindowText => AE::Color[dialog_color].inverse_brightness.gamma(0.8).contrast(2.5),
  }


  # The default style. This serves as fallback if no style is defined either in window or for individual widgets.
  @@default_style = {} unless defined?(@@default_style)
  @@default_style[:default] = {
    :backgroundColor => @@color[:ButtonFace],
    :borderRadius => 4,
    :borderColor => [ @@color[:ThreeDHighlight], @@color[:ThreeDShadow], @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow] ],
    :borderWidth => 1,
    :borderStyle => "",
    :shadowColor => Sketchup::Color.new([0,0,0,20]),
    :shadowWidth => 0,
    :textColor => @@color[:WindowText],
    # IMPORTANT! Setting :textColor to rendering_options["ForegroundColor"]
    # triggers View.draw and thus an endless draw loop! No workaround known yet.
    :textShadow => false,
    :textShadowColor => @@color[:WindowText].fade(0.2),
    :textShadowOffset => [1,1,0],
    :textShadowRadius => 0,
    :hover => {
      :backgroundColor => @@color[:ThreeDLightShadow],
      :shadowWidth => 7,
    },
    :active => {
      :backgroundColor => @@color[:ThreeDShadow],
      :borderColor => [ @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow], @@color[:ThreeDHighlight], @@color[:ThreeDShadow] ],
      :shadowWidth => 7,
    },
  }


  # The default layout. This serves as fallback if no layout is defined either in window or for individual widgets.
  @@default_layout = {} unless defined?(@@default_layout)
  @@default_layout[:default] = {
    :position => :relative,
    :top => 0,
    :right => 0,
    :bottom => 0,
    :left => 0,
    :zIndex => 0,
    :margin => 0,
    :marginTop => nil,
    :marginRight => nil,
    :marginBottom => nil,
    :marginLeft => nil,
    :padding => 0,
    :paddingTop => nil,
    :paddingRight => nil,
    :paddingBottom => nil,
    :paddingLeft => nil,
    :align => :left,
    :valign => :top,
    :orientation => :horizontal,
    :width => nil,
    :minWidth => nil,
    :maxWidth => nil,
    :height => nil,
    :minHeight => nil,
    :maxHeight => nil,
  }


  def initialize(hash={})
    @parent = nil
    @window = nil
    # Cached value of the width and height. Only for method size().
    @currentsize = []
    @currentoutersize = []
    @currentcontentsize = []
    # Hash where any sort of widget-specific data can be stored, optional.
    @data = {}
    # Hash that stores events :type => [block1, block2, ...]
    @events = {}
    # The style includes properties for the visual appearance.
    @style = {}
    # The layout includes properties for positioning and sizing.
    @layout = {}
    on(:added_to_window){|window|
      self.style = hash
      self.layout = hash
    }
    # Widget status, one of :normal, :hover, :active or any custom term.
    @state = :normal
  end


  # Give a short string for inspection. This does not output instance variables 
  # since these contain a lot of data, references to other objects and self-references.
  #
  # @return [String] the instance's class and object id
  def inspect
    return "#<#{self.class}:0x#{(self.object_id/2).to_s(16)}>"
  end



  # Set style properties for the visual appearance of the widget.
  # If incomplete, it inherits the style that has been passed to the window widget,
  # and if that was incomplete it takes default properties.
  #
  # @param [Hash] style properties and values
  #
  # @return [Hash] the complete style of the widget
  #
  # TODO: Improve inheritance of style and layout.
  # Inherit styles from all superclasses; type = superclasses.pop
  #private
  #def superclasses(object)
  #  result = [object.class]
  #  result << result.last.superclass while result.last.superclass
  #  return result
  #end
  #
  def style=(hash={})
    type = self.class.name[/[^\:]+$/].downcase.to_sym
    default = @@default_style[:default].merge(@@default_style[type]||{})
    @style = multiple_merge(
      default,
      @window.style,
      @window.style[type],
      @style,
      hash,
      hash[type]
    )
  end


  # Set layout properties for the positioning and size of the widget.
  # If incomplete, it inherits the layout that has been passed to the window widget,
  # and if that was incomplete it takes default properties.
  #
  # @param [Hash] layout properties and values
  #
  # @return [Hash] the complete layout of the widget
  def layout=(hash={})
    type = self.class.name[/[^\:]+$/].downcase.to_sym
    default = @@default_layout[:default].merge(@@default_layout[type]||{})
    @layout = multiple_merge(
      default,
      @window.layout,
      @window.layout[type],
      @layout,
      hash,
      hash[type]
    )
  end


  # Attach an event.
  #
  # @param [Symbol] +Type+ of the event.
  # @param [Proc] code +Block+ to execute when the event is triggered.
  #
  # @return Probably a callback, or Boolean whether event handler has been triggered.
  def on(eventname, &block)
    return false unless block_given?
    @events[eventname] ||= []
    @events[eventname] << block
    return true
  end


  protected


  attr_accessor :parent, :window, :state, :data
  attr_reader :style, :layout


  # Respond to an event.
  # Check if the event occured in a sensitive area and call the event handler.
  #
  # @param [Symbol] type Type of the event. Will be something like click, hover...
  #                                      Or LButtonDown etc.?
  # @param [Array] data Data like the position where the event occured on the widget.
  #   Position is relative to the widget's top left corner. # TODO: without padding!
  #   The widget does not (need to) know its absolute position on screen.
  #
  # @return Probably a callback, or Boolean whether event handler has been triggered.
  # TODO: additional view param necessary?
  def trigger(type, data)
    # Example: Check if the widget has a sensitive area that includes pos.
    # Then set the widget state for styling or call an action.
    case type
    when :move then
      invalidate if @state != :hover
      @state = :hover if @state != :active
    when :click then
      #invalidate if @state != :active
      #@state = :active
      #UI.start_timer(0.1, false){@state=:hover;invalidate}
    when :mousedown then
      invalidate if @state != :active
      @state = :active
    when :mouseup then
      invalidate if @state == :active
      @state = :hover
    end
    return false unless @events.include?(type)
    # A widget can specify if it wants to give custom data into the block, otherwise the event's data will be given.
    #args = ( data.respond_to?("include?") && data.include?(:args) )? data[:args] : [data]
    #args = ( data.include?(:args) )? data[:args] : [data] rescue [data]
    #@events[type].each{|b| b.call(*args)}
    @events[type].each{|b| b.call(data)}
    return true
  end


  # Tell the window that this widget (= whole window) needs a redraw.
  #
  # @private
  # TODO: Make it really private
  def invalidate
    self.window.view.invalidate
  end


  # Tell a widget that its cached size needs to be recalculated next time.
  #
  # @private
  def invalidate_size
    @currentsize = []
    @currentoutersize = []
    @currentcontentsize = []
  end


  # Calculate the widget's +size+.
  #
  # @param [Array] psize The size of the parent (optional; needed for children with percent sizes).
  #
  # @return [Array] +Width+ and +Height+ of the widget.
  def size(psize=[0,0]) # TODO or [@model.active_view.vpwidth, @model.active_view.vpheight] or @window.viewport
    return @currentsize unless @currentsize.empty? || @window && !@window.changed?
    w = @layout[:width] || 0
    h = @layout[:height] || 0
    # Resolve percent values (requires container size as argument)
    w = psize[0]*w.to_s.to_f/100.0 if w.is_a?(Symbol) || w.is_a?(String)
    h = psize[1]*h.to_s.to_f/100.0 if h.is_a?(Symbol) || h.is_a?(String)
    # Consider min/max limits
    w = @layout[:minWidth] if @layout[:minWidth] && w < @layout[:minWidth]
    w = @layout[:maxWidth] if @layout[:maxWidth] && w > @layout[:maxWidth]
    h = @layout[:minHeight] if @layout[:minHeight] && h < @layout[:minHeight]
    h = @layout[:maxHeight] if @layout[:maxHeight] && h > @layout[:maxHeight]
    return @currentsize = [w, h]
  end


  # Calculate the widget's required +size+ including margin. Essential for doing the positioning.
  #
  # @param [Array] psize The size of the parent.
  #
  # @return [Array] outer +Width+ and +Height+ of the widget.
  def outersize(psize=[0,0]) # TODO or [@model.active_view.vpwidth, @model.active_view.vpheight] or @window.viewport
    return @currentoutersize unless @currentoutersize.empty? || @window && !@window.changed?
    pw, ph = *psize
    # Margin
    m = @layout[:margin] || 0
    m = [m]*4 unless m.is_a?(Array) && m.length == 4
    mt = @layout[:marginTop] || m[0]
    mr = @layout[:marginRight] || m[1]
    mb = @layout[:marginBottom] || m[2]
    ml = @layout[:marginLeft] || m[3]
    # Resolve percent values of margin (requires container size as argument)
    mt = psize[1] * mt.to_s.to_f/100.0 if mt.is_a?(Symbol) || mt.is_a?(String)
    mr = psize[0] * mr.to_s.to_f/100.0 if mr.is_a?(Symbol) || mr.is_a?(String)
    mb = psize[1] * mb.to_s.to_f/100.0 if mb.is_a?(Symbol) || mb.is_a?(String)
    ml = psize[0] * ml.to_s.to_f/100.0 if ml.is_a?(Symbol) || ml.is_a?(String)
    # The available space is the container's space minus margin
    pw -= ml + mr if pw != 0
    ph -= mt + mb if ph != 0
    w, h = self.size([pw, ph])
    # The required size is the widget's size plus margin
    return @currentoutersize = [w+ml+mr, h+mt+mb]
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
  def compile_layout(ppos, psize)
    layouted_widgets = []
    layouted_widgets << {:widget=>self, :pos=>ppos, :size=>self.size(psize)}
    return layouted_widgets
  end


  # Draw the widget. This will be subclassed and contain the logic for different widget states.
  # It will be called by OnScreen::Window.
  #
  # @param [Sketchup::View]
  def draw(view, pos, size)
  end


  private


  # Draw a styled box.
  # This is a geometric primitive that can be used to build most widgets.
  #
  # @param [Sketchup::View] view
  # @param [Array] pos (absolute) +Position+ where to draw the widget on the screen.
  # @param [Array] size +Width+ and +Height+ of space to fill.
  # @param [Hash] style (optional) +Style+ with CSS-like properties.
  #   Style supports these properties:
  #   * +backgroundColor+ [Sketchup::Color]
  #   * +borderRadius+    [Numeric, Array(Numeric,Numeric,Numeric,Numeric)]
  #   * +borderColor+     [Sketchup::Color, Array(Sketchup::Color,Sketchup::Color,Sketchup::Color,Sketchup::Color)]
  #   * +borderWidth+     [Numeric, Array(Numeric,Numeric,Numeric,Numeric)] 0..10
  #   * +borderStyle+     [String, Array(String,String,String,String)] of view.line_stipple
  #   * +shadowColor+     [Sketchup::Color]
  #   * +shadowWidth+     [Numeric] 0..10
  #
  # @return [Sketchup::View]
  def draw_box(view, pos, size, style=@@default_style[:default])
    pos = Geom::Point3d.new(pos) # make sure that pos has no more than 2...3 values
    rectangle = [ pos, pos+[size[0],0], pos+size, pos+[0,size[1]] ]
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
  #   * +backgroundColor+ [Sketchup::Color]
  #   * +borderRadius+    [Numeric, Array(Numeric,Numeric,Numeric,Numeric)]
  #   * +borderColor+     [Sketchup::Color, Array(Sketchup::Color,Sketchup::Color,Sketchup::Color,Sketchup::Color)]
  #   * +borderWidth+     [Numeric, Array(Numeric,Numeric,Numeric,Numeric)] 0..10
  #   * +borderStyle+     [String, Array(String,String,String,String)] of view.line_stipple
  #   * +shadowColor+     [Sketchup::Color]
  #   * +shadowWidth+     [Numeric] 0..10
  #
  # @return [Sketchup::View]
  def draw_polygon(view, pos, points, style=@@default_style[:default])
    pos = Geom::Point3d.new(pos) # make sure that pos has no more than 2...3 values
    polygons = (points[0].is_a?(Array))? points : [points]
    polygons.each{|polygon| # TODO
      # Create shadow behind the polygon by overlaying transparent polylines.
      # Only for SketchUp versions that support transparent color drawing.
      # TODO: Since we decided to draw a border, curves have gaps and look ugly (like stars).
      #   Alternatively, add an offset to the polygon and draw a filled polygon.
      if !style[:shadowWidth].nil? && style[:shadowWidth] != 0 && @@supportsAlpha
        view.drawing_color = style[:shadowColor]
        view.line_stipple = ""
        (style[:shadowWidth]/2).times{|i| 2*i
          view.line_width = 2*i
          view.draw2d(GL_LINE_LOOP, polygon)
        }
      end
      # Draw the background.
      if !style[:backgroundColor].nil? && style[:backgroundColor] != @@color[:transparent]
        view.drawing_color = style[:backgroundColor]
        view.draw2d(GL_POLYGON, polygon)
      end
      # Draw the border.
      if !style[:borderColor].nil? && style[:borderColor] != @@color[:transparent] && !style[:borderWidth].nil? && (style[:borderWidth].is_a?(Array) ? style[:borderWidth].max : style[:borderWidth]) > 0
        # If all border properties are the same, just draw the polygon.
        unless style[:borderColor].is_a?(Array) || style[:borderWidth].is_a?(Array) || style[:borderStyle].is_a?(Array)
          view.line_width = style[:borderWidth]
          view.line_stipple = style[:borderStyle]
          view.drawing_color = style[:borderColor]
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
            view.drawing_color = border_color[i]
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
  #   * +textColor+  [Sketchup::Color]
  #   * +textShadow+       [Boolean]
  #   * +textShadowColor+  [Sketchup::Color]
  #   * +textShadowOffset+ [Geom::Vector3d, Array(Numeric,Numeric,Numeric)]
  #   * +textShadowRadius+ [Numeric] 0 or 1
  #
  # @return [Sketchup::View]
  def draw_text(view, pos, text, style={})
    # TODO: IMPORTANT! Changing the edge color triggers View.draw and thus an endless draw loop! No workaround known yet.
    force_color = @@supportsTextColor # !@window.nil? && !style[:textColor].nil? && style[:textColor]!=@@color[:foregroundColor]
    # View.draw_text does not allow to set a text color but uses the default edge color.
    # Change the edge color only if necessary.
    if force_color
      if style[:textShadow]
        @window.model.rendering_options["ForegroundColor"] = style[:textShadowColor]
        view.drawing_color = style[:textShadowColor]
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
      @window.model.rendering_options["ForegroundColor"] = style[:textColor]
      view.drawing_color = style[:textColor]
    end

    view.draw_text( pos, text )

    # Reset the edge color and optionally more effects.
    @window.model.rendering_options["ForegroundColor"] = style[:foregroundColor] if force_color
  rescue
    @window.model.rendering_options["ForegroundColor"] = style[:foregroundColor]
  end


  # TODO: This is deprecated. It is not useful here.
  # Merge one or more hashes with nested hashes inside.
  # In contrast, Hash.merge does not support nested hashes,
  # but would replace Hashes in <oldhash> by ones of the <newhash>.
  # This method only updates values, but does not add new keys to the first hash.
  #
  # @param [Hash] hashes a list of hashes of which the first one's values should
  #   be updated with the follwing hashes' values.
  #
  # @return [Hash]
  def deep_merge(*hashes)
    hashes = hashes.find_all{|h| h.is_a?(Hash) && !h.empty?}
    result = hashes.shift.clone
    r = {}
    block = Proc.new{|key, oldval, newval|
      r = {}
      r[key] = oldval.class == Hash ? oldval.merge(newval.reject{|k,v| !oldval.keys.include? k}, &block) : newval
    }
    hashes.length.times{|i|
      new = hashes.shift.
        # This removes keys that are not in the first hash.
        # Applying value=nil allows resetting properties to default.
        reject{|k,v| !result.keys.include? k || v.nil? }
      result.merge!(new, &block)
    }
    return result
  end


  # Merge one or more hashes.
  # This method only updates values or adds Hashes, but does not add new properties to the first hash.
  #
  # @param [Hash] hashes a list of hashes of which the first one's values should
  #   be updated with the follwing hashes' values.
  #
  # @return [Hash]
  def multiple_merge(*hashes)
    hashes = hashes.find_all{|h| h.is_a?(Hash) && !h.empty?}
    result = hashes.shift.clone
    hashes.length.times{|i|
      new = hashes.shift.
        # This removes properties that are not in the first hash, except if the key's value is a Hash (that contains properties).
        # Applying value=nil allows resetting properties to default.
        reject{|k,v| !result.keys.include?(k) && !v.is_a?(Hash)}# || v.nil? } TODO: remove this
      result.merge!(new)
    }
    return result
  end


end




# Containers can include several widgets (as children).
# Default containers serve only for layout and are invisible.
# If you want to make a container visible (toolbar, panel, dialog) then subclass the OnScreen::Container class.
class OnScreen::Container < OnScreen::Widget

  @@default_style[:container] = {
    :backgroundColor => nil,
    :borderColor => nil
  }

  @@default_layout[:container] = {
    :margin => 0
  }


  attr_accessor :children


  def initialize(hash={})
    # List of widgets that are contained in this container (children).
    @children = []
    super(hash)
    on(:added_to_window){
      self.children.each{|widget|
        widget.window = window
        widget.trigger(:added_to_window, self.window)
      }
    }
  end


  # Add the given widget(s) to this container.
  #
  # @param [Array] widgets One or more widgets.
  #
  # @return [OnScreen::Widget, Array] If one widget given, it is returned.
  # If several widgets given, an array of them is returned.
  # TODO: Do all nested widgets get a @window reference?
  # TODO: If a widget has already a parent, remove it, or allow the widget to appear as duplicates?
  # GTK would give a warning. On the other side, it works, and it sounds cool to have clones that behave synchronously.
  def add(*widgets)
    widgets.each{|widget|
      next unless widget.is_a?(Widget)
      @children << widget
      widget.trigger(:removed, widget.parent) unless widget.parent.nil?
      widget.trigger(:added, self)
      widget.parent = self
      widget.window = self.window unless self.window.nil?
      widget.trigger(:added_to_window, self.window) unless self.window.nil?
    }
    return widgets.length==1? widgets[0] : widgets
  end


  # Remove the given widget(s) from this container.
  #
  # @param [Array] widgets One or more widgets.
  #
  # @return [OnScreen::Widget, Array] If one widget given, it is returned.
  # If several widgets given, an array of them is returned.
  def remove(*widgets)
    widgets.each{|widget|
      next unless widget.is_a?(Widget)
      @children.delete(widget)
      widget.parent = nil
      widget.trigger(:removed, self)
      widget.window = nil
      widget.trigger(:removed_from_window, self.window) unless self.window.nil?
    }
    return widgets.length==1? widgets[0] : widgets
  end


  # Calculate the widget's +size+. Essential for doing the positioning.
  # This method is calls the leaves of the children widgets.
  #
  # @param [Array] psize The size of the parent (optional; needed for children with percent sizes).
  #
  # @return [Array] +Width+ and +Height+ of the widget.
  def size(psize=[0,0]) # TODO: or [@model.active_view.vpwidth, @model.active_view.vpheight] or @window.viewport
    return @currentsize unless @currentsize.empty? || @window && !@window.changed?
    w = @layout[:width]
    h = @layout[:height]
    # Resolve percent values (requires container size as argument)
    w = psize[0]*w.to_s.to_f/100.0 if w.is_a?(Symbol) || w.is_a?(String)
    h = psize[1]*h.to_s.to_f/100.0 if h.is_a?(Symbol) || h.is_a?(String)
    # Otherwise get the size caused by contained widgets.
    if w.nil? || h.nil?
      p = @layout[:padding] || 0
      p = [p]*4 unless p.is_a?(Array) && p.length == 4
      pt = @layout[:paddingTop] || p[0]
      pr = @layout[:paddingRight] || p[1]
      pb = @layout[:paddingBottom] || p[2]
      pl = @layout[:paddingLeft] || p[3]
      # Resolve percent values of padding (requires container size as argument)
      pt = ph * pt.to_s.to_f/100.0 if pt.is_a?(Symbol) || pt.is_a?(String)
      pr = pw * pr.to_s.to_f/100.0 if pr.is_a?(Symbol) || pr.is_a?(String)
      pb = ph * pb.to_s.to_f/100.0 if pb.is_a?(Symbol) || pb.is_a?(String)
      pl = pw * pl.to_s.to_f/100.0 if pl.is_a?(Symbol) || pl.is_a?(String)
      psize[0] -= pl + pr
      psize[1] -= pt + pb
      # total size required by content
      tw, th = *self.contentsize(psize)
      w ||= tw + pl + pr
      h ||= th + pt + pb
    end
    # Consider min/max limits
    w = @layout[:minWidth] if @layout[:minWidth] && w < @layout[:minWidth]
    w = @layout[:maxWidth] if @layout[:maxWidth] && w > @layout[:maxWidth]
    h = @layout[:minHeight] if @layout[:minHeight] && h < @layout[:minHeight]
    h = @layout[:maxHeight] if @layout[:maxHeight] && h > @layout[:maxHeight]
    return @currentsize = [w, h]
  end


  # Calculate the size required by th widget's content.
  #
  # @param [Array] psize The size of the parent.
  #
  # @return [Array] +Width+ and +Height+ of the widget.
  def contentsize(psize=[0,0]) # TODO or [@model.active_view.vpwidth, @model.active_view.vpheight] or @window.viewport
    return @currentcontentsize unless @currentcontentsize.empty? || @window && !@window.changed?
    cw, ch = 0, 0
    if @layout[:orientation] == :horizontal
      # total width is sum of children, total height is heighest child
      tw, th = *@children.inject([0,0]){|t, child|
        cw, ch = *child.outersize(psize)
        cw = (child.layout[:position] == :relative)? t[0] + cw : [t[0], cw].max
        ch = [t[1], ch].max
        [cw, ch]
      }
    else # if @layout[:orientation] == :vertical
      # total width is widest child, total height is sum of children
      tw, th = *@children.inject([0,0]){|t, child|
        cw, ch = *child.outersize(psize)
        cw = [t[0], cw].max
        ch = (child.layout[:position] == :relative)? t[1] + ch : [t[1], ch].max
        [cw, ch]
      }
    end
    return @currentcontentsize = [tw, th]
  end


  # Fit the widget (and its children) into a container.
  # This calculates the +positions+ of subcontainers and will be called from outside. 
  # This method is started on the most outer container (the window) and walks towards the leaves of the children widgets.
  #
  # @param [Sketchup::View]
  # @param [Array] ppos +Position+ where to arrange the widget on the screen.
  # @param [Array] psize +Width+ and +Height+ of space to fill.
  #
  # @return [Sketchup::View]
  # @private
  def compile_layout(ppos, psize)
    # Since we start with the window as most outer parent (window), psize has always a size in pixel dimensions.
    # self.size can return :max instead of pixels, because the size method is 
    # oriented towards children (not parent widgets) and does not know the outer dimensions.
    # Parent position and size
    ppos = Geom::Point3d.new(ppos)
    pw, ph = *psize
    # This widget
    s = self.size(psize)
    ppos += [0, 0, @layout[:zIndex].to_i]
    # Layouting finished for this widget:
    layouted_widgets = []
    layouted_widgets << {:widget=>self, :pos=>ppos, :size=>s}
    # Now compile layout for all children.
    # Consider padding. We do not interprete it like in CSS! We use padding inside widht/height, not outside.
    p = @layout[:padding] || 0
    p = [p]*4 unless p.is_a?(Array) && p.length == 4
    pt = @layout[:paddingTop] || p[0]
    pr = @layout[:paddingRight] || p[1]
    pb = @layout[:paddingBottom] || p[2]
    pl = @layout[:paddingLeft] || p[3]
    # Resolve percent values of padding (requires container size as argument)
    pt = ph * pt.to_s.to_f/100.0 if pt.is_a?(Symbol) || pt.is_a?(String)
    pr = pw * pr.to_s.to_f/100.0 if pr.is_a?(Symbol) || pr.is_a?(String)
    pb = ph * pb.to_s.to_f/100.0 if pb.is_a?(Symbol) || pb.is_a?(String)
    pl = pw * pl.to_s.to_f/100.0 if pl.is_a?(Symbol) || pl.is_a?(String)
    # Indent by padding, increase stacking order (which is influenced by zIndex)
    ppos += [pl, pt, 1]
    psize[0] = pw -= pl + pr
    psize[1] = ph -= pt + pb
    # Total width and height of children.
    tw, th = *self.contentsize(psize)
    # Get the insertion point for relatively positioned elements
    relpos = Geom::Vector3d.new(0,0,0)
    case @layout[:align]
      when :center then relpos.x = (@layout[:orientation] == :horizontal)? pw/2-tw/2 : pw/2
      when :right then relpos.x = pw-tw
    end
    case @layout[:valign]
      when :middle then relpos.y = (@layout[:orientation] == :vertical)? ph/2-th/2 : ph/2
      when :bottom then relpos.y = ph-th
    end
    # loop over all contained widgets and set their position
    cw, ch, cpos = 0, 0, []
    @children.each{|child|
      # widget position and size
      cw, ch = *child.size(psize)
      # Position
      ct = child.layout[:top] || 0
      cr = child.layout[:right] || 0
      cb = child.layout[:bottom] || 0
      cl = child.layout[:left] || 0
      # Resolve percent values of position (requires container size as argument)
      ct = ph * ct.to_s.to_f/100.0 if ct.is_a?(Symbol) || ct.is_a?(String)
      cr = pw * cr.to_s.to_f/100.0 if cr.is_a?(Symbol) || cr.is_a?(String)
      cb = ph * cb.to_s.to_f/100.0 if cb.is_a?(Symbol) || cb.is_a?(String)
      cl = pw * cl.to_s.to_f/100.0 if cl.is_a?(Symbol) || cl.is_a?(String)
      # Margin
      m = child.layout[:margin] || 0
      m = [m]*4 unless m.is_a?(Array) && m.length == 4
      mt = child.layout[:marginTop] || m[0]
      mr = child.layout[:marginRight] || m[1]
      mb = child.layout[:marginBottom] || m[2]
      ml = child.layout[:marginLeft] || m[3]
      # Resolve percent values of margin (requires container size as argument)
      mt = ph * mt.to_s.to_f/100.0 if mt.is_a?(Symbol) || mt.is_a?(String)
      mr = pw * mr.to_s.to_f/100.0 if mr.is_a?(Symbol) || mr.is_a?(String)
      mb = ph * mb.to_s.to_f/100.0 if mb.is_a?(Symbol) || mb.is_a?(String)
      ml = pw * ml.to_s.to_f/100.0 if ml.is_a?(Symbol) || ml.is_a?(String)
      cpos = ppos + [ cl + ml, ct + mt, 0 ]
      # Relative layout aligns a widget next to its previous sibling.
      if child.layout[:position] == :relative
        cpos += relpos
        if @layout[:orientation] == :horizontal
          cpos += [0, -ch/2, 0] if @layout[:valign] == :middle # only in that case, relpos is in middle of widget
          relpos += [cl + ml + cw + mr + cr, 0, 0]
        else @layout[:orientation] == :vertical
          cpos += [-cw/2, 0, 0] if @layout[:align] == :center # only in that case, relpos is in center of widget
          relpos += [0, ct + mt + ch + mb + cb, 0]
        end
      end
      layouted_widgets.concat( child.compile_layout(cpos, [cw, ch]) )
    }
    return layouted_widgets
  end


  # This is a place holder. Default containers serve only for layout and are invisible.
  # If you want to make a container visible (toolbar, panel, dialog) then subclass the OnScreen::Container class
  # and this draw method.
  #
  # @param [Sketchup::View]
  # @param [Array] ppos +Position+ where to draw the widget on the screen.
  # @param [Array] psize +Width+ and +Height+ of space to fill.
  #
  # @return [Sketchup::View]
  # @private
  def draw(view, pos, size)
    style = @style.clone
    style.merge!( {:backgroundColor=>@@color[:transparent], :borderColor=>@@color[:red], :borderWidth=>1} ) if @@inspect
    draw_box(view, pos, size, style)
  end


end




# Horizontal box container. All contained widgets will be aligned horizontally.
class OnScreen::HBox < OnScreen::Container

  @@default_style[:hbox] = {
    :backgroundColor => nil,
    :borderColor => nil
  }

  @@default_layout[:hbox] = {
    :position=>:relative,
    :orientation => :horizontal,
  }

  def initialize(hash={})
    hash[:orientation] = :horizontal
    super(hash)
  end

end




# Vertical box container. All contained widgets will be aligned vertically.
class OnScreen::VBox < OnScreen::Container

  @@default_style[:vbox] = {
    :backgroundColor => nil,
    :borderColor => nil
  }

  @@default_layout[:vbox] = {
    :position=>:relative,
    :orientation => :vertical,
  }

  def initialize(hash={})
    hash[:orientation] = :vertical
    super(hash)
  end

end




    end # module OnScreen
  end # module GUI
end # module AE
