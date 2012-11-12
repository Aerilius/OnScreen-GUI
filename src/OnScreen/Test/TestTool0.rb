require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::TestTool0


  include AE::GUI3::OnScreen


  def initialize

    window.style.set({:margin=>5})

    button = OnScreen::Button.new("Test Button", {:width=>120}){|d| puts d.inspect}
    window.add(button)
    button.on(:click){|data|
      UI.messagebox(data[:pos].to_a[0...2].inspect+" clicked within the button.") # This gives relative coordinates within button1.
    }
  end


end


Toolbar = UI::Toolbar.new("OnScreen Test")  unless defined?(Toolbar)
cmd = UI::Command.new("TestTool0"){ Sketchup.active_model.select_tool(AE::GUI3::OnScreen::TestTool0.new)}
cmd.large_icon = File.join(File.dirname(__FILE__), "icon0.png")
cmd.small_icon = File.join(File.dirname(__FILE__), "icon0.png")
Toolbar.add_item(cmd)


end
