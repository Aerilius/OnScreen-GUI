require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class OnScreen::ToggleButton < OnScreen::Button


  @@default_style[:togglebutton] = {
    :pressed => {
      :backgroundColor => @@color[:ThreeDDarkShadow],
      :borderColor => @@color[:ThreeDLightShadow], #[ @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow], @@color[:ThreeDHighlight], @@color[:ThreeDShadow] ],
    },
  }


  attr_accessor :checked
  def initialize(pressed=true, label="", hash={}, &block)
    hash = hash.dup
    # The togglebutton should be at least as wide that the label fits on it,
    # (assuming average character width is 10px), so multiply the longest text line by 10px (changed to 9).
    hash[:width] ||= label.split(/\n/).inject(0){|s,l| l.length>s ? l.length : s} * 9 + 20
    hash[:height] ||= (label.scan(/\n/).length+1) * 15 + 10
    super(label, hash)
    @data[:label] = label
    self.on(:click, &block) if block_given?
    @checked = pressed
    @state = (@checked)? :pressed : :normal
  end


  def trigger(type, data)
    super
    # No need to check pos since the whole checkbox is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    if type == :move && @checked
      @state = :pressed
    elsif type == :mouseup && @checked
      @checked = false
      @state = :hover
    elsif type == :mouseup && !@checked
      @checked = true
      @state = :pressed
    end
  end


  def checked=(bool)
    @checked = bool
    @state = bool ? :pressed : :normal
  end


end


end
