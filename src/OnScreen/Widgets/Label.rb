require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::Label < OnScreen::Widget


  include OnScreen::TextHelper


  attr_accessor :value
  alias_method :text, :value
  # TODO: allow View.tooltip on :move
  def initialize(text="", hash={})
    hash = hash.dup
    # The label should be at least as wide that the label fits on it
    # (assuming average character width is 10px), so multiply the longest text line by 10.
    hash[:width] ||= text_width(label)
    hash[:height] ||= text_height(label)
    super(hash)
    @value = text
  end


  def draw(view, pos, size)
    style = @style
    draw_text(view, pos+[10,4,0], @value, style)
  end


end


end
