require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


# The "window" is the root element to which widgets can be added.
# It is itself also a widget.
class OnScreen::Window < OnScreen::Container


  attr_accessor :style, :changed, :model, :widgets, :view
  alias_method :changed?, :changed


  def initialize(hash={}, context=Sketchup.active_model)
    super(hash)
    @model = (context.nil?)? Sketchup.active_model : (context.is_a?(Sketchup::View))? context.model : context
    @window = self
    @@color[:foregroundColor] = @model.rendering_options["ForegroundColor"] # the edge color
    # whether the viewport size has changed
    @changed = true
    # The @widgets variable caches all absolute positions of all widgets.
    @widgets = []
    @view = @model.active_view
    @viewport = nil
  end


  # Accessor for named colors
  def color
    return @@color
  end


  # Trigger events on widgets.
  # This must be called from the active +Tool+ (which receives input events).
  #
  # @param [Sketchup::View]
  # @param [Symbol] type +Type+ of the event. Will be something like :click, :hover...
  #                                      Or LButtonDown etc.?
  # @param [Hash] data
  def trigger(type, data)
    if data.include?(:pos)
      pos = Geom::Point3d.new(data[:pos].to_a) unless pos.is_a?(Geom::Point3d)
      # We will not be triggered on mouseout, so we don't know when :hover ends.
      # Therefore set :hover back into :normal before. TODO: is that the best solution here? 
      @widgets.each{|hash| hash[:widget].state = :normal if hash[:widget].state==:hover}
      # Widgets that lay on the event's position:
      responding_widgets = @widgets.find_all{|hash|
        pos.x > hash[:pos].x && pos.x < hash[:pos].x + hash[:size].x &&
        pos.y > hash[:pos].y && pos.y < hash[:pos].y + hash[:size].y
      }
      # Sort them by priority (currently: area size, could also be nesting level)
      responding_widgets.sort!{|hash1, hash2|
        w1_area = hash1[:size].x * hash1[:size].y
        w2_area = hash2[:size].x * hash2[:size].y
        w1_area <=> w2_area
      }
      # Try to trigger the event on all these widgets.
      # Widgets receive only local coordinates (where inside the widget the event happened).
      responding_widgets.each{|hash|
        relpos = pos - hash[:pos]
        hash[:widget].trigger(type, data.merge({:pos=>relpos}))
      }
    # else # TODO: if the event does not contain a position, it could be a keyboard event. 
    # We would need a variable to keep track on which element has focus.
    end
  end


  # Draws all widgets onto the screen.
  # This method must be called from the active Tool.
  #
  # @param [Sketchup::View]
  def draw(view)
    # Cache the view object and make it accessible
    @view = view
    check_window_changed(view)
    # Draw the widgets. The widgets' sizes and positions have been cached, the draw methods will only apply the style.
    @widgets.each{|hash|
      w = hash[:widget]
      next if w.is_a? OnScreen::Window # Note: actually this is redundant, but be sure we don't call @window.draw inside this method.
      w.draw(view, hash[:pos], hash[:size])
    }
  end


  # Set a "stylesheet" for the visual appearance of all widget in the window.
  # If incomplete, it takes default properties defined in @@default_style (Core.rb).
  #
  # @param [Hash] style properties and values
  #
  # @return [Hash] the complete style of the widget
  def style=(hash)
    @style = hash
  end


  # Set layout properties for the positioning and size of all widget in the window.
  # If incomplete, it takes default properties defined in @@default_layout (Core.rb).
  #
  # @param [Hash] layout properties and values
  #
  # @return [Hash] the complete layout of the widget
  def layout=(hash)
    @layout = hash
  end


  protected


  # This can not be called on the window (the window cannot be added from itself).
  # @private # TODO: or better "undefine" the method?
  def on_added_to_window(window)
  end


  # This can not be called on the window (the window cannot be removed from itself).
  # @private # TODO: or better "undefine" the method?
  def on_removed_from_window(old_window)
  end


  # Returns the size of the viewport.
  # We need to override the superclass method, since this is the toplevel widget.
  #
  # @param [Array] not needed (only in other superclass's subclasses)
  #
  # @return [Array] +Width+ and +Height+
  def size(psize=nil)
    return @viewport
  end


  private


  # Whether the viewport size has changed.
  #
  # @param [Sketchup::View]
  #
  # @return [Boolean]
  def check_window_changed(view)
    @changed = (@viewport != [view.vpwidth, view.vpheight])
    on_window_change(view) if @changed
    return @changed
  end


  # Callback when the viewport size has changed.
  # We need to adjust the positions and sizes of all widgets to the new viewport.
  #
  # @param [Sketchup::View]
  def on_window_change(view)
    pos = ORIGIN
    @viewport = [view.vpwidth, view.vpheight]
    # Invalidate the cached sizes of widgets so that they will definitely be recalculated.
    @widgets.each{|hash| hash[:widget].invalidate_size }
    # Compile the layout. This arranges all widgets in the viewport, determines sizes and positions.
    @widgets = compile_layout(pos, @viewport).sort{|hash1, hash2| hash1[:pos].z <=> hash2[:pos].z}
    # self (=window) is a container and gets thus added,
    # but we don't don't need it, it would cause an endless drawing loop.
    @widgets.delete_if{|hash| hash[:widget]==self}
  end


end


end
