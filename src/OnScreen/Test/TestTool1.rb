require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::TestTool1


  include AE::GUI3::OnScreen


  def initialize
    theme1 = {
      :backgroundColor => Sketchup::Color.new(0,0,0,100),
      :borderColor => Sketchup::Color.new(0,0,0,100),
      :borderWidth => 2,
      :borderRadius => 12,
      :textColor => Sketchup::Color.new(255,255,255,200),
      :textShadow => true,
      :textShadowColor => Sketchup::Color.new(0,0,0,50),
      :textShadowOffset => [0,0,0],
      :textShadowRadius => 1,
      :textbox => {
        :backgroundColor => Sketchup::Color.new(255,255,255,100),
        :textColor => Sketchup::Color.new(0,0,0,200),
        :textShadow => false,
        :hover => {:backgroundColor => Sketchup::Color.new(255,255,255,160)},
        :active => {:backgroundColor => Sketchup::Color.new(255,255,255,160)},
      },
      :hover => {
        :backgroundColor => Sketchup::Color.new(20,20,20,150),
        :borderWidth => 2,
      },
      :active => {
        :backgroundColor => Sketchup::Color.new(40,40,40,175),
        :borderWidth => 3,
        :borderColor => Sketchup::Color.new(0,0,0,160),
      },
      :pressed => {
        :backgroundColor => Sketchup::Color.new(0,0,0,175),
        :borderWidth => [3,2,2,2],
        :borderColor => Sketchup::Color.new(0,0,0,160),
      },
    }


    theme2color = AE::Color.new(70,80,255)
    theme2 = {
      :backgroundColor => theme2color,
      :borderRadius => 2,
      :borderColor => [ theme2color.contrast(0.8).gamma(1.4), theme2color.contrast(0.8).gamma(0.6), theme2color.contrast(0.8).gamma(0.4), theme2color.contrast(0.8).gamma(1.2) ],
      :borderWidth => 2,
      :borderStyle => "",
      :shadowWidth => 0,
      :textColor => theme2color.inverse_brightness.gamma(0.8).contrast(2.5),
      :textShadow => false,
      :hover => {
        :backgroundColor => theme2color.contrast(0.8).gamma(1.2),
      },
      :active => {
        :backgroundColor => theme2color.contrast(0.8).gamma(0.6),
        :borderColor => [ theme2color.contrast(0.8).gamma(0.4), theme2color.contrast(0.8).gamma(1.2), theme2color.contrast(0.8).gamma(1.4), theme2color.contrast(0.8).gamma(0.6) ],
      },
      :pressed => {
        :backgroundColor => theme2color.contrast(0.8).gamma(0.6),
        :borderColor => [ theme2color.contrast(0.8).gamma(0.4), theme2color.contrast(0.8).gamma(1.2), theme2color.contrast(0.8).gamma(1.4), theme2color.contrast(0.8).gamma(0.6) ],
      },
      :checkbox => {
        :borderRadius => 0,
        :active => {
          :backgroundColor => theme2color.contrast(0.8).gamma(0.6),
          :borderColor => [ theme2color.contrast(0.8).gamma(1.4), theme2color.contrast(0.8).gamma(0.6), theme2color.contrast(0.8).gamma(0.4), theme2color.contrast(0.8).gamma(1.2) ],
        },
      },
      :radio => {
        :active => {
          :backgroundColor => theme2color.contrast(0.8).gamma(0.6),
          :borderColor => [ theme2color.contrast(0.8).gamma(1.4), theme2color.contrast(0.8).gamma(0.6), theme2color.contrast(0.8).gamma(0.4), theme2color.contrast(0.8).gamma(1.2) ],
        },
      },
      :textbox => {
        :backgroundColor => AE::Color["white"],
        :textColor => AE::Color["black"],
        :hover => {},
        :active => {},
      },
    }


    window.style[:margin] = 5


    button = OnScreen::Button.new("Test (native style)", {:width=>120}){|d| puts d.inspect}

=begin
    button2 = OnScreen::Button.new("        Test", {:width=>120})
    toggle = OnScreen::ToggleButton.new(true, "ToggleButton", {:width=>120}){|d| puts d.inspect}
    checkbox1 = OnScreen::Checkbox.new(true, "Checkbox 1"){|d| puts d.inspect}
    checkbox2 = OnScreen::Checkbox.new(false, "Checkbox 2"){|d| puts d.inspect}
    sep1 = OnScreen::Separator.new()
    radio1 = OnScreen::Radio.new(true, "Radio 1"){|d| puts d.inspect}
    radio2 = OnScreen::Radio.new(false, "Radio 2"){|d| puts d.inspect}
    sep2 = OnScreen::Separator.new()
    radiobuttongroup = OnScreen::RadioButtonGroup.new(1, ["Button 1", "Button 2", "Button 3"], {:width=>200}){|d| puts d.inspect}
    slider = OnScreen::Slider.new("Slider", [0,45,100], {:width=>250}){|d| puts d.inspect}
    text = OnScreen::TextBox.new("a short text...")
    text2 = OnScreen::TextBox.new("a longer text...\n...over...\n...multiple lines...")
    vbox = OnScreen::Container.new({:orientation=>:vertical})
    box = OnScreen::Container.new({:position=>:absolute, :align=>:left, :valign=>:top})
    window.add(box)
    box.add(vbox)
    vbox.add(button, button2, toggle, checkbox1, checkbox2, sep1, radio1, radio2, sep2, radiobuttongroup, slider, text, text2)
=end
    box = OnScreen::Container.new({:position=>:absolute, :align=>:left, :valign=>:top})
    window.add(box)
    box.add(button)
=begin


    button_ = OnScreen::Button.new("Test (another style)", {:width=>130}.merge(theme1))
    toggle_ = OnScreen::ToggleButton.new(true, "ToggleButton", {:width=>130}.merge(theme1))
    checkbox1_ = OnScreen::Checkbox.new(true, "Checkbox 1", theme1)
    checkbox2_ = OnScreen::Checkbox.new(false, "Checkbox 2", theme1)
    sep1_ = OnScreen::Separator.new(theme1)
    radio1_ = OnScreen::Radio.new(true, "Radio 1", theme1)
    radio2_ = OnScreen::Radio.new(false, "Radio 2", theme1)
    sep2_ = OnScreen::Separator.new(theme1)
    radiobuttongroup_ = OnScreen::RadioButtonGroup.new(1, ["Button 1", "Button 2", "Button 3"], {:width=>200}.merge(theme1))
    slider_ = OnScreen::Slider.new("Slider", [0,45,100], theme1.merge({:width=>250}))
    text_ = OnScreen::TextBox.new("a short text...", theme1)
    text2_ = OnScreen::TextBox.new("a longer text...\n...over...\n...multiple lines...", theme1)
    vbox_ = OnScreen::Container.new({:orientation=>:vertical, :borderWidth=>1})
    box_ = OnScreen::Container.new({:position=>:absolute, :width=>:"100%", :height=>:"100%", :align=>:center, :valign=>:middle})
    window.add(box_)
    box_.add(vbox_)
    vbox_.add(button_, toggle_, checkbox1_, checkbox2_, sep1_, radio1_, radio2_, sep2_, radiobuttongroup_, slider_, text_, text2_)


    button__ = OnScreen::Button.new("Test (another style)", {:width=>130}.merge(theme2))
    toggle__ = OnScreen::ToggleButton.new(true, "ToggleButton", {:width=>130}.merge(theme2))
    checkbox1__ = OnScreen::Checkbox.new(true, "Checkbox 1", theme2)
    checkbox2__ = OnScreen::Checkbox.new(false, "Checkbox 2", theme2)
    sep1__ = OnScreen::Separator.new(theme2)
    radio1__ = OnScreen::Radio.new(true, "Radio 1", theme2)
    radio2__ = OnScreen::Radio.new(false, "Radio 2", theme2)
    sep2__ = OnScreen::Separator.new(theme2)
    radiobuttongroup__ = OnScreen::RadioButtonGroup.new(1, ["Button 1", "Button 2", "Button 3"], {:width=>200}.merge(theme2))
    slider__ = OnScreen::Slider.new("Slider", [0,65,100], {:orientation=>:vertical, :height=>250}.merge(theme2))
    text__ = OnScreen::TextBox.new("a short text...", theme2)
    text2__ = OnScreen::TextBox.new("a longer text...\n...over...\n...multiple lines...", theme2)
    vbox__ = OnScreen::Container.new({:orientation=>:vertical, :align=>:right, :borderWidth=>1, :width=>320, :maxWidth=>320})
    box__ = OnScreen::Container.new({:position=>:absolute, :width=>:"100%", :height=>:"100%", :align=>:right, :valign=>:bottom})
    window.add(box__)
    box__.add(vbox__)
    vbox__.add(button__, toggle__, checkbox1__, checkbox2__, sep1__, radio1__, radio2__, sep2__, radiobuttongroup__, slider__, text__, text2__)
=end

    #button.on(:click){|data|
    #  UI.messagebox(data[:pos].to_a[0...2].inspect+" clicked within the button.") # This gives relative coordinates within button1.
    #}
  end


end


Toolbar = UI::Toolbar.new("OnScreen Test")  unless defined?(Toolbar)
cmd = UI::Command.new("TestTool1"){ Sketchup.active_model.select_tool(AE::GUI3::OnScreen::TestTool1.new)}
cmd.large_icon = File.join(File.dirname(__FILE__), "icon1.png")
cmd.small_icon = File.join(File.dirname(__FILE__), "icon1.png")
Toolbar.add_item(cmd)


end
