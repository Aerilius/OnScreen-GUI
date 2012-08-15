require File.join(File.dirname(__FILE__), "Core.rb")




# A button widget
class AE::GUI::OnScreen::TestTool


  def initialize
    @window = AE::GUI::OnScreen::Window.new
    button = AE::GUI::OnScreen::Button.new
    @window.add(button)
    button.on(:click){|x,y|
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
