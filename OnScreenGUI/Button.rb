require File.join(File.dirname(__FILE__), "Core.rb")




# A button widget
class AE::GUI::OnScreen::Button < AE::GUI::OnScreen::Widget

  @@default_style[:button] = {
    :backgroundColor => @@color[:ButtonFace],
    :borderColor => [ @@color[:ThreeDHighlight], @@color[:ThreeDShadow], @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow] ],
    :borderWidth => 2,
    :borderRadius => [4,4,4,4],
    :normal => {},
    :hover => {
      :backgroundColor => AE::Color["red"],
      :borderColor => [ @@color[:ThreeDDarkShadow], @@color[:ThreeDLightShadow], @@color[:ThreeDHighlight], @@color[:ThreeDShadow] ]
    },
    :active => {:backgroundColor => Sketchup::Color.new("green")},
    :disabled => {:backgroundColor => Sketchup::Color.new("green")}
  }

  def initialize(label="", hash={})
    hash[:width] ||= label.split(/\n/).inject(0){|l,s| s.length>l ? s.length : l} * 10 + 20
    hash[:height] ||= (label.scan(/\n/).length+1) * 15 + 10
    super(hash)
    @data = {:label => label}
    @state = :normal
  end


  def trigger(type, pos)
    #super
    # No need to check pos since the whole button is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    # Eventually call other methods from here:
    @state = :hover if type == :move
    @state = :active if type == :click
  end


  def draw(view, pos, size)
    style = deep_merge(@style, @style[@state])
    draw_box(view, pos, size, style)
    reflection_style = {
      :backgroundColor => @@color[:white].alpha(30),
      :borderWidth => 0,
      :borderRadius => [style[:borderRadius][0], style[:borderRadius][1], 0, 0]
    }
    reflection_style = deep_merge(style, reflection_style)
    draw_box(view, pos, [size[0], 0.5*size[1]], reflection_style)
    draw_text(view, pos+[10,4,0], @data[:label], style)
    # TODO: where/when/how is it best to reset the state
    # if the cursor isn't anymore over the element?
    @state = :normal
  end


end
