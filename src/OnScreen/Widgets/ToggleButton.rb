require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::ToggleButton < OnScreen::Button


  include OnScreen::TextHelper


  attr_accessor :checked
  def initialize(pressed=true, label="", hash={}, &block)
    hash = hash.dup
    # The togglebutton should be at least as wide that the label fits on it,
    # (assuming average character width is 10px), so multiply the longest text line by 10px (changed to 9).
    hash[:width] ||= text_width(label) + 20
    hash[:height] ||= text_height(label) + 10
    super(label, hash)
    @label = label
    self.on(:click){|data| block.call(@checked)} if block_given?
    @checked = pressed
    @active = @checked
  end


  def trigger(type, data)
    super
    # No need to check pos since the whole checkbox is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    if type == :move && @checked
      @active = true
    elsif type == :mouseup && @checked
      @checked = false
      @active = false
    elsif type == :mouseup && !@checked
      @checked = true
      @active = true
    end
  end


  def checked=(bool)
    @checked = bool
    @active = bool
  end


end


end
