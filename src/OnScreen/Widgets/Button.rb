require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::Button < OnScreen::Widget


  include OnScreen::TextHelper


  def initialize(label="", hash={}, &block)
    hash = hash.dup
    # The button should be at least as wide that the label fits on it
    # (assuming average character width is 10px), so multiply the longest text line by 10.
    hash[:width] ||= text_width(label)
    hash[:height] ||= text_height(label)
    super(hash)
    @label = label
    self.on(:click, &block) if block_given?
  end


  def trigger(type, data)
    super
    # No need to check pos since the whole button is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    # Eventually call other methods from here:
  end


  def draw(view, pos, size)
    draw_box(view, pos, size, @style)
    #br = style[:borderRadius]
    #br = [br]*4 unless br.is_a?(Array)
    #reflection_style = {
    #  :backgroundColor => @@color[:white].alpha(30),
    #  :borderWidth => 0,
    #  :borderRadius => [br[0], br[1], 0, 0],
    #  :shadowWidth => 0,
    #}
    #reflection_style = deep_merge(@style, reflection_style)
    #draw_box(view, pos, [size[0], 0.5*size[1]], reflection_style)
    draw_text(view, pos+[10,4,0], @label, @style)
  end


end


end
