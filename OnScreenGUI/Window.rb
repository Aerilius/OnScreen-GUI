require File.join(File.dirname(__FILE__), "Core.rb")


# The "window" is the root element to which widgets can be added.
# It is itself also a widget.
class AE::GUI::OnScreen::Window < AE::GUI::OnScreen::Container


  attr_accessor :style, :changed, :widgets, :model # TODO widgets only for debug
  alias_method :changed?, :changed


  def initialize(context=Sketchup.active_model, hash={})
    super(hash)
    @model = (context.nil?)? Sketchup.active_model : (context.is_a?(Sketchup::View))? context.model : context
    @window = self
    @@color[:foregroundColor] = @model.rendering_options["ForegroundColor"] # the edge color
    # whether the viewport size has changed
    @changed = true
    # The canvas variable keeps track of all absolute positions of all widgets.
    @widgets = {}
    view = @model.active_view
    @viewport = [view.vpwidth, view.vpheight]
  end


  # Trigger events on widgets.
  # This must be called from the active +Tool+ (which receives input events).
  #
  # @param [Sketchup::View]
  # @param [Symbol] +Type+ of the event. Will be something like :click, :hover...
  #                                      Or LButtonDown etc.?
  # @return [Array] (absolute) +Position+ where to draw the event happened.
  def trigger(type, pos)
    pos = Geom::Point3d.new(pos.to_a) unless pos.is_a?(Geom::Point3d)
    responding_widgets = @widgets.keys.find_all{|w|
      pos.x > @widgets[w][:pos].x && pos.x < @widgets[w][:pos].x + @widgets[w][:size].x &&
      pos.y > @widgets[w][:pos].y && pos.y < @widgets[w][:pos].y + @widgets[w][:size].y
    }
    responding_widgets.sort!{|w1,w2|
      w1_area = @widgets[w1][:size].x * @widgets[w1][:size].y
      w2_area = @widgets[w2][:size].x * @widgets[w2][:size].y
      w1_area <=> w2_area
    }
    responding_widgets.each{|widget|
      relpos = pos - @widgets[widget][:pos]
      #widget.trigger(type, relpos) # TODO
    }
  end


  # Draws all widgets onto the screen.
  # This method must be called from the active Tool.
  #
  # @param [Sketchup::View]
  def draw(view)
    check_window_changed(view)
    @widgets.each{|w, pos_size|
      next if w.is_a? AE::GUI::OnScreen::Window
      w.draw(view, pos_size[:pos], pos_size[:size])
    }
  end


  #protected # TODO


  # Set style properties for the visual appearance of the widget.
  # If incomplete, it inherits the style that has been passed to the window widget,
  # and if that was incomplete it takes default properties.
  #
  # @param [Hash] style properties and values
  #
  # @return [Hash] the complete style of the widget
  def style=(hash)
    @style = hash # @@default_style.merge(hash) # TODO
  end


  # Set layout properties for the positioning and size of the widget.
  # If incomplete, it inherits the layout that has been passed to the window widget,
  # and if that was incomplete it takes default properties.
  #
  # @param [Hash] layout properties and values
  #
  # @return [Hash] the complete layout of the widget
  def layout=(hash)
    @layout = hash # @@default_layout.merge(hash) # TODO
  end


  # A callback when the widget has been included in a window.
  #
  # @param [OnScreen::Container] the new window
  def on_added_to_window(window)
    super
    self.widgets.each_key{|w|
      w.on_added_to_window(window)
    }
  end


  # A callback when the widget has been removed from a window.
  #
  # @param [OnScreen::Container] the old window
  def on_removed_from_window(old_window)
    super
    self.widgets.each_key{|w|
      w.on_removed_from_window(window)
    }
  end


  # Returns the size of the viewport.
  # We need to override the superclass method, since this is the toplevel widget.
  #
  # @param [Sketchup::View]
  #
  # @return [Array] +Width+ and +Height+
  def size
    return @viewport
  end


  private


  # Whether the viewport size has changed.
  #
  # @param [Sketchup::View]
  #
  # @return [Boolean]
  def check_window_changed(view)
    @changed = (@viewport == [view.vpwidth, view.vpheight])
    on_window_change(view) if @changed
    return @changed
  end


  # Callback when the viewport size has changed.
  # We need to adjust the positions and sizes of all widgets to the new viewport.
  #
  # @param [Sketchup::View]
  def on_window_change(view)
    pos = ORIGIN
    @widgets = compile_layout(pos, size)
    @viewport = [view.vpwidth, view.vpheight]
  end


end

