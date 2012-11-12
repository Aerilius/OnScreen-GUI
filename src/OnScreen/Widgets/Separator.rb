require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::Separator < OnScreen::Widget


  def initialize(hash={})
    hash = hash.dup
    hash[:width] ||= 2
    hash[:height] ||= 2
    hash[:borderWidth] = 2
    hash[:borderRadius] = 2
    super(hash)
    on(:added_to_window){|window|
    # Match the separator to the biggest width or height of the neighbouring widgets.
      siblings_size = @parent.children.inject([0,0]){|t,w| s=w.size; [ [t[0],s[0]].max, [t[1],s[1]].max ] }
      orientation = @parent.layout[:orientation]
      @style[:minWidth] = (orientation==:horizontal)? 2 : siblings_size[0]
      @style[:minHeight] = (orientation==:vertical)? 2 : siblings_size[1]
      invalidate_size # Force a recalculation of the cached size.
    }
  end


  # A Separator is not interactive.
  # @private
  # TODO: or better "undefine" the method?
  #def trigger(type, data) # TODO: disabled because otherwise :added_to_window does not trigger.
  #end


  def draw(view, pos, size)
    draw_box(view, pos, size, @style)
  end


end


end
