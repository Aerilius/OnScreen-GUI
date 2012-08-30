require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class OnScreen::Text < OnScreen::Widget


  @@default_style[:text] = {
    :backgroundColor => @@color[:white],
    :borderColor => @@color[:ThreeDDarkShadow],
    :textColor => @@color[:black],
    :hover => {},
    :active => {},
  }


  def initialize(text="", hash={})
    hash = hash.dup
    # The button should be at least as wide that the label fits on it
    # (assuming average character widht is 10px), so multiply the longest text line by 10.
    hash[:width] ||= text.split(/\n/).inject(0){|s,t| t.length>s ? t.length : s} * 9 + 20
    hash[:height] ||= (text.scan(/\n/).length+1) * 15 + 10
    super(hash)
    @data = {
      :maxLength => hash[:maxLength]||100,
      :validation => hash[:validation]||/^.*$/,
      :text => text
    }
  end


  def trigger(type, data)
    super
    # No need to check pos since the whole button is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
  end


  def draw(view, pos, size)
    style = deep_merge(@style, @style[@state])
    draw_box(view, pos, size, style)
    draw_text(view, pos+[10,4,0], @data[:text], style)
  end


end


end
