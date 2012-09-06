require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class OnScreen::RadioButtonGroup < OnScreen::Container


 @@default_style[:radiobuttongroup] = {
    :borderRadius => 8,
  }


  @@default_layout[:radiobuttongroup] = {
    :orientation => :horizontal,
  }


  # Initialize the radio button group.
  #
  # @param [Hash] style properties and values
  #
  # @return [Hash] the complete style of the widget
  attr_accessor :value
  def initialize(selected=0, labels=[""], hash={}, &block)
    # layout overrides
    hash = hash.dup
    if hash[:orientation] == :vertical
      hash[:width] ||= (labels.inject(0){|max,label| [label.split(/\n/).inject(0){|s,l| l.length>s ? l.length : s}, max].max }+1) * 9 + 25
      hash[:height] ||= (labels.inject(0){|sum,label| sum+label.scan(/\n/).length}+1) * 15 + 10
    else
      hash[:width] ||= labels.inject(0){|sum,label| sum+label.split(/\n/).inject(0){|s,l| l.length>s ? l.length : s} } * 9 + 25
      hash[:height] ||= (labels.inject(0){|max,label| [label.scan(/\n/).length, max].max }+1) * 15 + 10
    end
    hash[:align] = :left
    hash[:padding] = 0
    super(hash)
    @data[:labels] = labels
    @data[:block] = block if block_given?
    @value = selected

    on(:added_to_window){|window|
      orientation = @layout[:orientation]
      width = (orientation==:horizontal)? @layout[:width]/@data[:labels].length : nil
      #TODO: @layout[:width] should be Numeric here, or convert it; eventually self.size?
      @data[:labels].each_with_index{|label,i|
        # If there is borderRadius, split it to the first and last button and keep the intermediate buttons tightly connected.
        br = @style[:borderRadius]
        br = [br]*4 unless br.is_a?(Array)
        # first
        if i==0
          br = (orientation==:horizontal)? [br[0], 0, 0, br[3]] : [br[0], br[1], 0, 0]
        # last
        elsif i==@data[:labels].length-1
          br = (orientation==:horizontal)? [0, br[1], br[2], 0] : [0, 0, br[2], br[3]]
        # middle
        else
          br = 0
        end
        # Create a ToggleButton with modified style to make sure it aligns nicely with its neighbours.
        toggle = OnScreen::ToggleButton.new( @value==i, label,
                   @style.merge({:borderRadius=>br,
                     :width=>width, 
                     :left=>0, 
                     :right=>0, 
                     :top=>0, 
                     :bottom=>0, 
                     :marginTop=>0, 
                     :marginRight=>0, 
                     :marginBottom=>0, 
                     :marginLeft=>0
                   })
                 )
        self.add(toggle)
        toggle.on(:click){
          self.value=(i) # the RadioButtonGroup's value
          @data[:block].call(i) if @data.include?(:block)
        }
      }
      invalidate_size # force a recalculation of the cached size
    }
  end


  def draw(view, pos, size)
    super if @@inspect
  end


  # This method makes sure that all ToggleButtons are in sync.
  def value=(index)
    toggles = @children.find_all{|c| c.is_a?(OnScreen::ToggleButton)}
    # Set all to false except <index>.
    toggles.each_with_index{|c, i|
      next if i == index
      c.checked = false
    }
    # Set the one with <index> to true.
    toggles[index].checked = true
    @value = index
  end


end


end
