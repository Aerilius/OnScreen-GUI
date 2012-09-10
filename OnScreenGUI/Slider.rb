require File.join(File.dirname(__FILE__), "Core.rb")


module AE::GUI


class OnScreen::Slider < OnScreen::Widget


  @@default_style[:slider] = {
  }

  attr_accessor :value

# TODO: allow non-linear scale, option to show ruler
  def initialize(label="", minmax=[0,50,100], hash={}, &block)
    hash = hash.dup
    label_size = [
      label.split(/\n/).inject(0){|s,l| l.length>s ? l.length : s} * 9,
      (label.scan(/\n/).length+1) * 15
    ]
    hash[:width] ||= (hash[:orientation]!=:vertical)? 200 : [label_size[0], 25].max
    hash[:height] ||= (hash[:orientation]!=:vertical)? [label_size[1], 25].max : 200
    super(hash)
    @data = {
      :label => label,
      :min => minmax.min,
      :max => minmax.max,
      :gripper_size => 15,
      :label_size => label_size,
      :min_size => [minmax.min.to_s.length*10, 15],
      :max_size => [minmax.max.to_s.length*10, 15],
    }
    @value = minmax.length>2 ? minmax.sort[1] : (minmax[0]+minmax[1])/2.0
    self.on(:mousedown)
    self.on(:move)
    self.on(:mouseup){|data| block.call(@value)} if block_given?
  end


  def trigger(type, data)
    if type == :mousedown || type == :move || type == :mouseup
      o = @layout[:orientation]==:horizontal
      s = (self.size)[o ? 0 : 1]
      l = 0 # distance between begin of widget and start of the slider
      slider_length = s
      if o
        l += @data[:min_size][0]
        slider_length -= @data[:min_size][0] + @data[:max_size][0]
        if @layout[:align] != :center
          l += @data[:label_size][0]
          slider_length -= @data[:label_size][0]
        elsif @layout[:align] == :right
          slider_length -= @data[:label_size][0]
        end
      else # !o
        l += @data[:min_size][1]
        slider_length -= @data[:min_size][1] + @data[:max_size][1]
        if @layout[:valign] != :bottom
          l += @data[:label_size][1]
          slider_length -= @data[:label_size][1]
        end
      end
      case type
      when :mousedown then
        g = @value/(@data[:max]-@data[:min]).to_f * slider_length
        @window.dragging = self if -@data[:gripper_size]/2..@data[:gripper_size]/2 === data[:pos][o ? 0 : 1] - l - g
      when :move then
        if @window.dragging == self
          g = (data[:pos][o ? 0 : 1] - l)/slider_length.to_f * (@data[:max]-@data[:min])
          @value = [[@data[:min], g].max, @data[:max]].min
        end
      when :mouseup then # TODO: redundant?
        if @window.dragging == self
          g = (data[:pos][o ? 0 : 1] - l)/slider_length.to_f * (@data[:max]-@data[:min])
          @value = [[@data[:min], g].max, @data[:max]].min
        end
      end
    end
    super
  end


  def draw(view, pos, size)
    style = deep_merge(@style, @style[@state]) # TODO: or use multiple_merge???
    o = @layout[:orientation]==:horizontal
    pos += o ? [0, size[1]/2+10] : [size[0]/2, 0]
    # label
    _pos = pos.clone
    if o
      _pos += [0, -@data[:label_size][1]/2]
      if @layout[:align] == :center
        _pos +=  [size[0]/2-@data[:label_size][0]/2, 15]
      elsif @layout[:align] == :right
        _pos += [size[0]-@data[:label_size][0], 0]
      end
    else # !o
      _pos += [-@data[:label_size][0]/2, 0]
      if @layout[:valign] == :bottom
        _pos += [0, size[1]-@data[:label_size][1]]
      end
    end
    draw_text(view, _pos, @data[:label], style) unless @data[:label].empty?
    pos += o ? [@data[:label_size][0], 0] : [0, @data[:label_size][1]] if o && @layout[:align]==:left || !o && @layout[:valign]!=:bottom
    # label min
    _pos = pos + (o ? [0, -@data[:min_size][1]/2] : [-@data[:min_size][0]/2, 0])
    draw_text(view, _pos, sprintf("%1.3g", @data[:min]), style)
    # If there is borderRadius, split it to the first and last button and keep the intermediate buttons tightly connected.
    br = style[:borderRadius]
    br = [br]*4 unless br.is_a?(Array)
    bw = style[:borderWidth]
    bw = [bw]*4 unless bw.is_a?(Array)
    pos += o ? [@data[:min_size][0], 0] : [0, @data[:min_size][1]]
    # slider start
    _pos = pos + (o ? [0, -2] : [-2, 0])
    l12 = o ? @data[:min_size][0] + @data[:max_size][0] : @data[:min_size][1] + @data[:max_size][1]
    if o
      slider_length = size[0] - l12
      slider_length -= @data[:label_size][0] if @layout[:align] != :center
    else
      slider_length = size[1] - l12 - @data[:label_size][1]
    end
    slider_start_length = @value/(@data[:max]-@data[:min]).to_f * slider_length - 0.5*@data[:gripper_size]
    slider_start_size = o ? [slider_start_length, 4] : [4, slider_start_length]
    br_s = o ? [br[0], 0, 0, br[3]] : [br[0], br[1], 0, 0]
    bw_s = o ? [bw[0], 0, bw[2], bw[3]] : [bw[0], bw[1], 0, bw[2]]
    draw_box(view, _pos, slider_start_size, style.merge({:borderWidth=>bw_s, :borderRadius=>br_s})) if slider_start_length > 0
    pos += o ? [slider_start_length, 0] : [0, slider_start_length]
    # gripper text
    _pos = pos + (o ? [0, -@data[:gripper_size]/2-15] : [-@data[:gripper_size]/2-28, 0])
    draw_text(view, _pos, sprintf("%1.3g", @value), style)
    # gripper
    _pos = pos + (o ? [0, -@data[:gripper_size]/2] : [-@data[:gripper_size]/2, 0])
    gripper_size = [@data[:gripper_size], @data[:gripper_size]]
    draw_box(view, _pos, gripper_size, style)
    pos += o ? [gripper_size[0], 0] : [0, gripper_size[1]]
    # slider end
    _pos = pos + (o ? [0, -2] : [-2, 0])
    slider_end_length = slider_length - @data[:gripper_size] - slider_start_length
    slider_end_size = o ? [slider_end_length, 4] : [4, slider_end_length]
    br_e = o ? [0, br[1], br[2], 0] : [0, 0, br[2], br[3]]
    bw_e = o ? [bw[0], bw[1], bw[2], 0] : [0, bw[1], bw[2], bw[3]]
    draw_box(view, _pos, slider_end_size, style.merge({:borderWidth=>bw_e, :borderRadius=>br_e})) if slider_end_length > 0
    pos += o ? [slider_end_length, 0] : [0, slider_end_length]
    # label max
    _pos = pos + (o ? [0, -@data[:max_size][1]/2] : [-@data[:max_size][0]/2, 0])
    draw_text(view, _pos, sprintf("%1.3g", @data[:max]), style)
  end


end


end
