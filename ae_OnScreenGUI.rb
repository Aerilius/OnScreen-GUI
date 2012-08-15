=begin

Copyright 2011, Aerilius
All Rights Reserved

Permission to use, copy, modify, and distribute this software for 
any purpose and without fee is hereby granted, provided that the above
copyright notice appear in all copies.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Description:  OnScreen GUI for SketchUp
Usage:        * Create a Tool (for input events and the ability to draw on screen)
                (Probably the window widget could theoretically be used as tool)
              * Create an instance of the window:
                window = AE::GUI::OnScreen::Window.new
              * Add widgets to it:
                button = AE::GUI::OnScreen::Button.new()
                window.add(button)
              * Call the window.draw method from within the Tool's draw method,
                and call the window.event method from within the Tool's event methods.
              
Version:      0.2
Date:         08.08.2012

=end

### LOADER ###

module AE
  module GUI
    module OnScreen
    end
  end
end

dir = File.join(File.dirname(__FILE__), "OnScreenGUI")
Dir.glob( File.join(dir, '*.{rb,rbs}') ).each{|f| load f}
