=begin

Copyright 2012, Aerilius
All Rights Reserved

Permission to use, copy, modify, and distribute this software for
any purpose and without fee is hereby granted, provided that the above
copyright notice appear in all copies.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Description:  OnScreen GUI for SketchUp
Usage:     1) Create a Tool (for input events and the ability to draw on screen).
           2) include AE::GUI::OnScreen03
           3) In the initialize method, add widgets to "window":
              button = AE::GUI::OnScreen03::Button.new()
              window.add(button)
           *  If you use tool methods, then use also super (for all methods below).
      or:  1) Create a Tool (for input events and the ability to draw on screen).
           2) Create an instance of the window:
              window = AE::GUI::OnScreen03::Window.new
           3) Add widgets to it:
              button = AE::GUI::OnScreen03::Button.new()
              window.add(button)
           4) Call the window.draw method from within the Tool's draw method,
              and call the window.event method from within the Tool's event methods.

Version:      0.3.0
Date:         12.11.2012

=end

### LOADER ###

module AE
  module GUI3
    module OnScreen
      def self.reload
        dir = File.join(File.dirname(__FILE__), "OnScreen")
        #Dir.glob( File.join(dir, '*.{rb,rbs}') ).
        #  each{|f| load f }
        load(File.join(dir, "Core.rb"))
        load(File.join(dir, "Mixins.rb"))
        load(File.join(dir, "LayoutCache.rb"))
        load(File.join(dir, "DrawCache.rb"))
        load(File.join(dir, "Style.rb"))
        load(File.join(dir, "Color.rb"))
        load(File.join(dir, "Widgets", "Button.rb"))
        load(File.join(dir, "Test", "TestTool0.rb"))
        load(File.join(dir, "Test", "TestTool1.rb"))
        load(File.join(dir, "Test", "TestTool2.rb"))
      end


      # MIXIN for UI::Tool


      def window
        @window || @window = Window.new
      end


      def onMouseMove(flags, x, y, view)
        @window.trigger(:move, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
      end


      def onLButtonDown(flags, x, y, view) # TODO: or use :LButtonDown instead of :mousedown ?
        @window.trigger(:mousedown, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
      end


      def onLButtonUp(flags, x, y, view) # TODO: deprecate :click, or leave it if it is convenient.
        @window.trigger(:mouseup, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
        @window.trigger(:click, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
      end


      def onLButtonDoubleClick(flags, x, y, view)
        @window.trigger(:doubleclick, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
      end


      def onRButtonDown(flags, x, y, view)
        @window.trigger(:RButtonDown, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
      end


      def onRButtonDown(flags, x, y, view)
        @window.trigger(:RButtonDown, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
      end


      def onRButtonDoubleClick(flags, x, y, view)
        @window.trigger(:RButtonDoubleClick, {:pos=>Geom::Point3d.new(x, y, 0), :flags=>flags})
      end


      def onKeyDown(key, repeat, flags, view)
        @window.trigger(:keyDown, {:key=>key, :flags=>flags})
      end


      def onKeyUp(key, repeat, flags, view)
        @window.trigger(:keyUp, {:key=>key, :flags=>flags})
      end


      def draw(view)
        @window.draw(view)
      end


      def deactivate(view)
        view.invalidate
      end


    end
  end
end



AE::GUI3::OnScreen.reload

