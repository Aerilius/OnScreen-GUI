require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class OnScreen::TextBox < OnScreen::Widget


  @@default_style[:textbox] = {
    :backgroundColor => @@color[:white],
    :borderColor => @@color[:ThreeDDarkShadow],
    :textColor => @@color[:black],
    :hover => {},
    :active => {},
  }


  attr_accessor :value
  def initialize(text="", hash={})
    hash = hash.dup
    # The textbox should be at least as wide that the label fits on it
    # (assuming average character width is 10px), so multiply the longest text line by 10.
    hash[:width] ||= text.split(/\n/).inject(0){|s,t| t.length>s ? t.length : s} * 9 + 20
    hash[:height] ||= (text.scan(/\n/).length+1) * 15 + 10
    super(hash)
    @value = text
    @data = {
      :maxLength => hash[:maxLength]||100,
      :validation => hash[:validation]||/^.*$/,
    }
  end


  def draw(view, pos, size)
    style = deep_merge(@style, @style[@state]) # TODO
    draw_box(view, pos, size, style)
    draw_text(view, pos+[10,4,0], @value, style)
  end


end


end
