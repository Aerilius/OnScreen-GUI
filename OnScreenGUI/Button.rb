require File.join(File.dirname(__FILE__), "Core.rb")




# A button widget
class AE::GUI::OnScreen::Button < AE::GUI::OnScreen::Widget

  @@default_style[:button] = {
    :normal => {:background => @@white},
    :hover => {:background => Sketchup::Color.new("yellow")}, # only for testing
    :active => {:background => Sketchup::Color.new("green")},
  }

  def initialize(text="", hash={})
    super(hash)
    @layout[:width] = text.split(/\n/).inject(0){|l,s| s.length>l ? s.length : l} * 10 + 20
    @layout[:height] = text.scan(/\n/).length * 15 + 10
    @data = {:text => text}
    @state = :normal
  end


  def trigger(type, pos)
    super
    # No need to check pos since the whole button is sensitive for events.
    # No need to distinguish between several sensitive areas of the widget.
    # Eventually call other methods from here:
    @state = :hover if type == :mouseOver
    @state = :active if type == :click
  end

$xxx=true
  def draw(view, pos, size)
  (puts "button draw: #{@@default_style.inspect}"; $xxx=false) if $xxx==true
    draw_box(view, pos, size, @style[@state]||{})
    # experiment
    upper_half = @style[@state].clone
    upper_half[:height] = 0.5* size[1]
    upper_half[:borderRadius] = [upper_half[:borderRadius]]*4 unless upper_half[:borderRadius].is_a?(Array)
    upper_half[:borderRadius][2] = 0
    upper_half[:borderRadius][3] = 0
    upper_half[:borderWidth] = 0
    upper_half[:backgroundColor] = @@white.blend(@@transparent, 0.9)
    draw_box(view, pos, size, upper_half)
    # /experiment
    view.draw_text( pos+[10,5,0], @data[:text] )
    # TODO: where/when/how is it best to reset the state
    # if the cursor isn't anymore over the element?
    @state = :normal
  end


end
