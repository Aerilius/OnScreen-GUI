require File.join(File.dirname(__FILE__), "Core.rb")




# A button widget
class AE::GUI::OnScreen::TestTool

  attr_accessor :window, :button1, :button2
  def initialize
    custom_style = {
      :backgroundColor => Sketchup::Color.new(0,0,0,160),
      :borderColor => Sketchup::Color.new(0,0,0,100),
      :borderWidth => 2,
      :borderRadius => [10,10,10,10],
      :textColor => Sketchup::Color.new(255,255,255,200),
      :textShadow => true,
      :textShadowColor => Sketchup::Color.new(0,0,0,50),
      :textShadowOffset => [0,0,0],
      :textShadowRadius => 1,
      :normal => {},
      :hover => {
        :backgroundColor => Sketchup::Color.new(20,20,20,200),
        :borderWidth => 2
      },
      :active => {:backgroundColor => Sketchup::Color.new("green")},
      :disabled => {:backgroundColor => Sketchup::Color.new("green")}
    }
    @window = AE::GUI::OnScreen::Window.new(nil)
    hbox = AE::GUI::OnScreen::Container.new({:flow=>:horizontal, :left=>20, :top=> 20, :width=>500, :height=>100, :borderWidth=>1, :borderColor=>Sketchup::Color.new(0)})
    @window.add(hbox)
    @button1 = AE::GUI::OnScreen::Button.new("Test (native style)", {:width=>130})
    @checkbox1 = AE::GUI::OnScreen::Checkbox.new(true, "Checkbox", {:left=>20})
    @button2 = AE::GUI::OnScreen::Button.new("Test (custom style)", {:width=>130, :left=>20}.merge(custom_style))
    @checkbox2 = AE::GUI::OnScreen::Checkbox.new(true, "Checkbox", {:left=>20}.merge(custom_style))
    hbox.add(@button1, @checkbox1, @button2, @checkbox2)
    @button1.on(:click){|x,y|
      UI.messagebox([x,y].inspect+" clicked")
    }
  end


  def onMouseMove(flags, x, y, view)
    @window.trigger(:move, [x, y])
  end


  def onLButtonDown(flags, x, y, view)
    @window.trigger(:click, [x, y])
  end


  def draw(view)
    @window.draw(view)
  end


end
