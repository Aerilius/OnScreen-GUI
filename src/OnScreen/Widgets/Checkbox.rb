require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::Checkbox < OnScreen::Widget


  include OnScreen::TextHelper


  attr_accessor :checked
  def initialize(checkd=true, label="", hash={}, &block)
    hash = hash.dup
    # The widget should be at least as wide that the label fits on it
    # (assuming average character width is 10px), so multiply the longest text line by 10.
    hash[:width] ||= text_width(label)
    hash[:height] ||= text_height(label)
    hash[:borderRadius] ||= 0
    super(hash)
    @label = label
    self.on(:click){|data| block.call(@checked)} if block_given?
    @checked = checkd
  end


  def trigger(type, data)
    # No need to check pos since the whole checkbox is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    if type == :mouseup || type == :change
      @checked = !@checked
      data[:args] = [@checked]
    end
    super(type, data)
  end


  def draw(view, pos, size)
    style = @style
    checkboxSize = 25
    checkmarkSize = 17
    margin = (checkboxSize-checkmarkSize)/2
    offset = [margin, margin, 0]
    draw_box(view, pos+offset, [checkmarkSize,checkmarkSize], style)
    draw_text(view, pos+[checkboxSize+offset[0],4,0], @label, style) if !@label.empty?
    if @checked
      # draw checkmark
      view.drawing_color = style[:textColor]
      view.line_width = 3
      view.line_stipple = ""
      view.draw2d(GL_LINE_STRIP, pos+offset+[4,checkmarkSize-8,0], pos+offset+[8,checkmarkSize-4,0], pos+offset+[checkmarkSize-5,3,0])
    end
  end


end


end
