require File.join(File.dirname(File.dirname(__FILE__)), "Core.rb")


module AE::GUI3


class OnScreen::RadioButtonGroup < OnScreen::Container


  include OnScreen::TextHelper


  # Initialize the radio button group.
  #
  # @param [Hash] style properties and values
  #
  # @return [Hash] the complete style of the widget
  attr_accessor :value
  def initialize(selected=0, labels=[""], hash={}, &block)
    # style overrides
    hash = hash.dup
    if hash[:orientation] == :vertical
      hash[:width] ||= labels.inject(0){|max,label| [text_width(label), max].max }
      hash[:height] ||= labels.inject(0){|sum,label| sum+text_height(label)}
    else
      hash[:width] ||= labels.inject(0){|sum,label| sum+text_width(label)}
      hash[:height] ||= labels.inject(0){|max,label| [text_height(label), max].max }
    end
    hash[:align] = :left
    hash[:padding] = 0
    hash[:borderRadius] = 8
    super(hash)
    @labels = labels
    @block = block if block_given?
    @value = selected

    on(:added_to_window){|window|
      orientation = @style[:orientation]
      width = (orientation==:horizontal)? @style[:width]/@labels.length : nil
      #TODO: @style[:width] should be Numeric here, or convert it; eventually self.size?
      @labels.each_with_index{|label,i|
        # If there is borderRadius, split it to the first and last button and keep the intermediate buttons tightly connected.
        br = @style[:borderRadius]
        br = [br]*4 unless br.is_a?(Array)
        # first
        if i==0
          br = (orientation==:horizontal)? [br[0], 0, 0, br[3]] : [br[0], br[1], 0, 0]
        # last
        elsif i==@labels.length-1
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
          @block.call(i) if @block
        }
      }
      invalidate_size # force a recalculation of the cached size
    }
  end


  def draw(view, pos, size)
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
