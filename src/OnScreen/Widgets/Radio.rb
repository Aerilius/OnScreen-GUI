require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::Radio < OnScreen::Widget


  include OnScreen::TextHelper


  # Radio buttons are grouped by putting them together into a common container.
  # That implicates that no different (unrelated) radio buttons are within the same container.
  attr_accessor :checked
  def initialize(checkd=true, label="", hash={}, &block)
    hash = hash.dup
    hash[:width] ||= text_width(label)
    hash[:height] ||= text_height(label)
    hash[:borderRadius] = "50%"
    super(hash)
    @label = label
    self.on(:click){|data|
      if block_given?
        index = @parent.children.find_all{|c| c.is_a?(OnScreen::Radio)}.index(self)
        block.call(index)
        # block.call(@checked) # TODO: or this?
      end
    }
    @checked = checkd
  end


  def trigger(type, data)
    # No need to check pos since the whole radio is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    if type == :click || type == :mouseup || type == :change
      self.check
      data[:args] = [@checked]
    end
    super(type, data)
  end


  def draw(view, pos, size)
    style = deep_merge(@style, @style[@state]) # TODO: or use multiple_merge???
    radioSize = 25
    radioCircleSize = 17
    margin = (radioSize-radioCircleSize)/2
    offset = [margin, margin, 0]
    draw_box(view, pos+offset, [radioCircleSize,radioCircleSize], style.merge({:borderRadius=>radioCircleSize/2}))
    draw_text(view, pos+[radioSize+offset[0],4,0], @label, style) if !@label.empty?
    if @checked
      # draw inner circle
      draw_box(view, pos+offset+[4,4,0], [radioCircleSize-8,radioCircleSize-8], style.merge({
        :backgroundColor=>style[:textColor],
        :borderWidth=>(style[:textShadow]? style[:textShadowRadius] : 0),
        :borderRadius=>:"50%",
      }) )
    end
  end


  def check
    radios = @parent.children.find_all{|c| c.is_a?(OnScreen::Radio)}
    index = radios.index(self)
    radios.each_with_index{|c, i|
      next if i == index
      c.checked = false
    }
    @checked = true
  end


end


end
