require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class OnScreen::Checkbox < OnScreen::Widget


  @@default_style[:checkbox] = {
    :borderColor => [ @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow], @@color[:ThreeDHighlight], @@color[:ThreeDShadow] ],
    :borderRadius => 0,
  }


  attr_accessor :checked
  def initialize(checkd=true, label="", hash={}, &block)
    hash = hash.dup
    # The widget should be at least as wide that the label fits on it
    # (assuming average character widht is 10px), so multiply the longest text line by 10.
    hash[:width] ||= label.split(/\n/).inject(0){|s,l| l.length>s ? l.length : s} * 9 + 25
    hash[:height] ||= (label.scan(/\n/).length+1) * 15 + 10
    super(hash)
    @data[:label] = label
    self.on(:click, &block) if block_given?
    @checked = checkd
  end


  def trigger(type, data)
    # No need to check pos since the whole checkbox is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    @checked = !@checked if type == :mouseup
    data[:args] = [@checked]
    super(type, data)
  end


  def draw(view, pos, size)
    style = deep_merge(@style, @style[@state])
    checkboxSize = 25
    checkmarkSize = 17
    margin = (checkboxSize-checkmarkSize)/2
    offset = [margin, margin, 0]
    draw_box(view, pos+offset, [checkmarkSize,checkmarkSize], style)
    draw_text(view, pos+[checkboxSize+offset[0],4,0], @data[:label], style) if !@data[:label].empty?
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
