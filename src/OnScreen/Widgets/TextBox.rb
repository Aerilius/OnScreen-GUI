require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::TextBox < OnScreen::Widget


  include OnScreen::TextHelper


  attr_accessor :value
  alias :text :value
  alias :text= :value=
  def initialize(text="", hash={})
    hash = hash.dup
    # The textbox should be at least as wide that the label fits on it
    # (assuming average character width is 10px), so multiply the longest text line by 10.
    hash[:width] ||= text_width(text) + 20
    hash[:height] ||= text_height(text) + 10
    super(hash)
    @value = text
    @data = {
      :maxLength => hash[:maxLength]||100,
      :validation => hash[:validation]||/^.*$/,
    }
  end


  def draw(view, pos, size)
    style = @style[@state]
    draw_box(view, pos, size, style)
    draw_text(view, pos+[10,4,0], @value, style)
  end


end


end
