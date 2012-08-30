require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class OnScreen::TestTool


  attr_accessor :window # DEBUG: This accessor is only for debugging.
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
      :text => {
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
      :text => {
        :backgroundColor => AE::Color["white"],
        :textColor => AE::Color["black"],
        :hover => {},
        :active => {},
      },
    }


    @window = OnScreen::Window.new({:margin => 7})


    button = OnScreen::Button.new("Test (native style)", {:width=>120})
    button2 = OnScreen::Button.new("        Test", {:width=>120})
    toggle = OnScreen::ToggleButton.new(true, "ToggleButton", {:width=>120})
    checkbox1 = OnScreen::Checkbox.new(true, "Checkbox 1")
    checkbox2 = OnScreen::Checkbox.new(false, "Checkbox 2")
    sep1 = OnScreen::Separator.new()
    radio1 = OnScreen::Radio.new(true, "Radio 1")
    radio2 = OnScreen::Radio.new(false, "Radio 2")
    sep2 = OnScreen::Separator.new()
    radiobuttongroup = OnScreen::RadioButtonGroup.new(1, ["Button 1", "Button 2", "Button 3"], {:width=>200})
    text = OnScreen::Text.new("a short text...")
    text2 = OnScreen::Text.new("a longer text...\n...over...\n...multiple lines...")

    vbox = OnScreen::Container.new({:orientation=>:vertical})
    box = OnScreen::Container.new({:position=>:absolute, :align=>:left, :valign=>:top})
    @window.add(box)
    box.add(vbox)
    vbox.add(button, button2, toggle, checkbox1, checkbox2, sep1, radio1, radio2, sep2, radiobuttongroup, text, text2)


    button_ = OnScreen::Button.new("Test (another style)", {:width=>130}.merge(theme1))
    toggle_ = OnScreen::ToggleButton.new(true, "ToggleButton", {:width=>130}.merge(theme1))
    checkbox1_ = OnScreen::Checkbox.new(true, "Checkbox 1", theme1)
    checkbox2_ = OnScreen::Checkbox.new(false, "Checkbox 2", theme1)
    sep1_ = OnScreen::Separator.new(theme1)
    radio1_ = OnScreen::Radio.new(true, "Radio 1", theme1)
    radio2_ = OnScreen::Radio.new(false, "Radio 2", theme1)
    sep2_ = OnScreen::Separator.new(theme1)
    radiobuttongroup_ = OnScreen::RadioButtonGroup.new(1, ["Button 1", "Button 2", "Button 3"], {:width=>200}.merge(theme1))
    text_ = OnScreen::Text.new("a short text...", theme1)
    text2_ = OnScreen::Text.new("a longer text...\n...over...\n...multiple lines...", theme1)

    vbox_ = OnScreen::Container.new({:orientation=>:vertical, :borderWidth=>1})
    box_ = OnScreen::Container.new({:position=>:absolute, :width=>:"100%", :height=>:"100%", :align=>:center, :valign=>:middle})
    @window.add(box_)
    box_.add(vbox_)
    vbox_.add(button_, toggle_, checkbox1_, checkbox2_, sep1_, radio1_, radio2_, sep2_, radiobuttongroup_, text_, text2_)


    button__ = OnScreen::Button.new("Test (another style)", {:width=>130}.merge(theme2))
    toggle__ = OnScreen::ToggleButton.new(true, "ToggleButton", {:width=>130}.merge(theme2))
    checkbox1__ = OnScreen::Checkbox.new(true, "Checkbox 1", theme2)
    checkbox2__ = OnScreen::Checkbox.new(false, "Checkbox 2", theme2)
    sep1__ = OnScreen::Separator.new(theme2)
    radio1__ = OnScreen::Radio.new(true, "Radio 1", theme2)
    radio2__ = OnScreen::Radio.new(false, "Radio 2", theme2)
    sep2__ = OnScreen::Separator.new(theme2)
    radiobuttongroup__ = OnScreen::RadioButtonGroup.new(1, ["Button 1", "Button 2", "Button 3"], {:width=>200}.merge(theme2))
    text__ = OnScreen::Text.new("a short text...", theme2)
    text2__ = OnScreen::Text.new("a longer text...\n...over...\n...multiple lines...", theme2)

    vbox__ = OnScreen::Container.new({:orientation=>:vertical, :align=>:right, :borderWidth=>1})
    box__ = OnScreen::Container.new({:position=>:absolute, :width=>:"100%", :height=>:"100%", :align=>:right, :valign=>:bottom})
    @window.add(box__)
    box__.add(vbox__)
    vbox__.add(button__, toggle__, checkbox1__, checkbox2__, sep1__, radio1__, radio2__, sep2__, radiobuttongroup__, text__, text2__)


    @window.layout=({:align=>:left, :valign=>:top, :orientation=>:horizontal})


    button.on(:click){|data|
      UI.messagebox(data[:pos].to_a[0...2].inspect+" clicked within the button") # This should give relative coordinates within button1.
    }
  end


  def activate(view)
    view.invalidate
  end


  def deactivate(view)
    view.invalidate
  end


  def onMouseMove(flags, x, y, view)
    @window.trigger(:move, {:pos=>[x, y]})
  end


  def onLButtonDown(flags, x, y, view)
    @window.trigger(:mousedown, {:pos=>[x, y]})
  end


  def onLButtonUp(flags, x, y, view)
    @window.trigger(:mouseup, {:pos=>[x, y]})
    @window.trigger(:click, {:pos=>[x, y]})
  end


  def draw(view)
    # Duration ~ 58ms
    # puts "drawing"
    @window.draw(view)
  end


end


end
