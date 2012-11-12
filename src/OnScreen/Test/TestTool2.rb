require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::TestTool2


  include AE::GUI3::OnScreen


  def initialize
    theme = {
      :backgroundColor => Sketchup::Color.new(0,0,0,100),
      :borderColor => Sketchup::Color.new(0,0,0,100),
      :borderWidth => 2,
      :borderRadius => 12,
      :textColor => Sketchup::Color.new(255,255,255,200),
      :textShadow => true,
      :textShadowColor => Sketchup::Color.new(0,0,0,50),
      :textShadowOffset => [0,0,0],
      :textShadowRadius => 1,
      :label => {
        :textColor => Sketchup::Color.new(0,0,0,200),
        :textShadow => false,
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
      :vbox => {
        :backgroundColor => nil,
        :borderColor => nil,
        :borderWidth => 0,
      }
    }


    window.style=(theme)
    window.layout=({:padding=>5, :orientation=>:horizontal, :align=>:center, :valign=>:top})

    # radius
    slider = Slider.new("Radius", [0,45,100], {:width=>250, :align=>:center}){|v|
      @@radius = v
    }

    # scope
    scope_vbox = VBox.new({:align=>:center, :valign=>:top})
    scope_bgroup = RadioButtonGroup.new(1, ["all connected", "  tool radius", "    tool-tip"], {:width=>280})
    scope_label = Label.new("Scope")
    scope_vbox.add(scope_bgroup, scope_label)

    # label selection border
    border_mode_vbox = VBox.new({:align=>:center, :valign=>:top})
    border_mode_bgroup = RadioButtonGroup.new(0, ["      hard", "smooth outset", "smooth inset"], {:width=>290})
    border_mode_label = Label.new("     Selection border mode")
    border_mode_vbox.add(border_mode_bgroup, border_mode_label)

    window.add(slider, scope_vbox, border_mode_vbox)
  end


end


Toolbar = UI::Toolbar.new("OnScreen Test")  unless defined?(Toolbar)
cmd = UI::Command.new("TestTool2"){ Sketchup.active_model.select_tool(AE::GUI3::OnScreen::TestTool2.new)}
cmd.large_icon = File.join(File.dirname(__FILE__), "icon2.png")
cmd.small_icon = File.join(File.dirname(__FILE__), "icon2.png")
Toolbar.add_item(cmd)
Toolbar.show

end
