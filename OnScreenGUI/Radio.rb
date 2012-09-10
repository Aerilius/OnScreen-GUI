require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class AE::GUI::OnScreen::Radio < OnScreen::Widget


  @@default_style[:radio] = {
    :borderColor => [ @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow], @@color[:ThreeDHighlight], @@color[:ThreeDShadow] ],
    :borderRadius => :"50%",
  }


  # Radio buttons are grouped by putting them together into a common container.
  # That implicates that no different (unrelated) radio buttons are within the same container.
  attr_accessor :checked
  def initialize(checkd=true, label="", hash={}, &block)
    hash = hash.dup
    # The widget should be at least as wide that the label fits on it
    # (assuming average character width is 10px), so multiply the longest text line by 10.
    hash[:width] ||= label.split(/\n/).inject(0){|s,l| l.length>s ? l.length : s} * 9 + 25
    hash[:height] ||= (label.scan(/\n/).length+1) * 15 + 10
    super(hash)
    @data[:label] = label
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
    draw_text(view, pos+[radioSize+offset[0],4,0], @data[:label], style) if !@data[:label].empty?
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
