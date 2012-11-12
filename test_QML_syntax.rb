# This is an experiment of a QML-like syntax.
# 
# At the moment, the usage is a bit like classic toolkit:
# b1 = Button.new("OK")
# b2 = Button.new("Cancel")
# h = HBox.new
# h.add(b1,b2)
# window.add(h)
#
# QML (from QT) has a different approach, more like CSS:
#
# Window{
#   HBox{
#     Button("OK")
#     Button("Cancel")
#   }
# }
#
# Is this desired for our toolkit? Would it be feasible in Ruby?
#


class MyQMLTool


  include AE::GUI::OnScreen


  def initialize

    Window{

      Dialog{
        position = :absolute
        left = 200
        top = 200
        width = 300
        height = 250
        # or better:
        # layout={:position => :absolute}

        Button{
          text = "Cancel"
          onClick{ UI.messagebox("Cancel clicked") }
        }

        Button{
          text = "OK"
          onClick{ UI.messagebox("OK clicked") }
        }

      }

    }

  end


end



=begin

Advantages:
  easier nesting
  easier to learn/read etc.
Disadvantages: no references to specific widgets; alternative: add "id=" method and window.get_widget(id)
Issues:
  many methods necessary
  eventhandlers predefined ( on(:event){} works with any signal, also custom signals )
  calling widget name creates new instance (and executes block to set properties), but are Uppercase method names allowed? (no?) works with brackets: Button()
  longer syntax for things that would be passed as argument (text...)

Realization:
  accessor methods for: position, left, top, width, height ...
  widget-specific accessor methods: text
  eventhandler methods: onClick...
  methods to create new instance (WidgetName): Button{}, Dialog{}


  class Widget # For this test, this one allows nesting

    def initialize
      puts "Widget created #{self}"
      super
      @children = []
    end

    def add(*ws)
      ws.each{|w| @children << w }
    end

    # (It needs to have access/include methods for all Widget subclasses)
    # OnScreen.constants.find_all{|c| c.is_a? Class}
    def Widget(&block)
      w = Widget.new()
      puts self
      w.instance_eval(&block)
      self.add(w)
    end

  end



  def Widget(&block)
    parent = caller[2][/`([^']*)'/, 1]
    w = Widget.new()
    w.instance_eval(&block)
    return w
  end


  w = Widget{
        Widget{}
      }


=end
