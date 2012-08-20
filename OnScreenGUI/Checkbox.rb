require File.join(File.dirname(__FILE__), "Core.rb")




# A checkbox widget
class AE::GUI::OnScreen::Checkbox < AE::GUI::OnScreen::Widget

  @@default_style[:checkbox] = {
    :backgroundColor => @@color[:ButtonFace],
    :borderColor => [ @@color[:ThreeDHighlight], @@color[:ThreeDShadow], @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow] ],
    :borderWidth => 2,
    :borderRadius => 0,
    :normal => {},
    :hover => {
      :borderColor => [ @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow], @@color[:ThreeDHighlight], @@color[:ThreeDShadow] ]
    },
    :active => {:backgroundColor => Sketchup::Color.new("green")},
    :disabled => {:backgroundColor => Sketchup::Color.new("green")}
  }

  def initialize(checked=true, label="", hash={})
    hash[:width] ||= label.split(/\n/).inject(0){|l,s| s.length>l ? s.length : l} * 10 + 25
    hash[:height] ||= 25
    super(hash)
    @data = {:checked => checked, :label => label}
    @state = :normal
  end


  def trigger(type, pos)
    #super
    # No need to check pos since the whole checkbox is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    # Eventually call other methods from here:
    @state = :hover if type == :move
    @state = :active if type == :click
  end


  def draw(view, pos, size)
    style = deep_merge(@style, @style[@state])
    draw_box(view, pos+[4,4,0], [size[1]-8,size[1]-8], style)
    offset = [ (size[1]-14)/2.0, (size[1]-14)/2.0, 0]
    draw_text(view, pos+[size[1]+offset[0],4,0], @data[:label], style) if @data[:label]!=""
    if @data[:checked]
      # draw checkmark
      view.drawing_color = style[:textColor]
      view.line_width = 3
      view.line_stipple = ""
      view.draw2d(GL_LINE_STRIP, pos+offset+[3,8,0], pos+offset+[6,12,0], pos+offset+[10,2,0])
    end
    # TODO: where/when/how is it best to reset the state
    # if the cursor isn't anymore over the element?
    @state = :normal
  end


end
