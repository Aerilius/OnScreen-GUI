#
# = SketchUp API Extension for Sketchup::Color
#
# This is a Mixin module to extend SketchUp::Color. Returned color objects are also extended.
# (By the way, subclassing Sketchup::Color would return a Sketchup::Color (not a subclass object) and 
# doesn't respond to these subclass methods).
#



if !defined?(AE::Color) || AE::Color::VERSION < 0.2



module AE::Color # < Sketchup::Color


  VERSION = 0.2

  # = CLASS methods


  # Creates a SketchUp color object that is extended with this module's methods.
  # 
  # @param [Sketchup::Color, String, Array<Numeric>] color a color in RGB color space.
  #   (Any color that +Sketchup::Color.new+ accepts.)
  #
  # @return [Sketchup::Color]
  def self.new(*color)
    # We want to get an object with +class=Sketchup::Color+ but with 
    # these additional methods.
    # +extend+ accepts only _module_, not _class_ (thus this is not a subclass).
    return Sketchup::Color.new(*color).extend(self)
  end


  class << self
    alias_method :[], :new
  end


  # Interpolates any amount of given colors with given weights.
  # This method works different from +Sketchup::Color.blend+ in that it interpolates over
  # HSL color space, thus red and green result in yellow (instead of brown).
  #
  # @param [Sketchup::Color, String, Array] color any amount of colors in RGB color space
  # @param [Numeric] weight the same amount of weights between +0..1+ (the sum should be +1+).
  #   Weights will be assigned in the order in which colors are specified.
  #
  # @return [Sketchup::Color]
  def self.interpolate(*weights_and_colors)
    # The instance method already contains the logic.
    # It considers the color instance itself, thus we have to create an instance from one of the colors.
    weights, colors = [], []
    colors << self
    weights_and_colors.flatten.each{|e| (e.is_a?(Numeric)? weights : colors) << e}
    sum = weights.inject(0){|s,i| s+i}.to_f
    first_color = colors.shift
    weights.shift
    weights.collect!{|w| w/sum}
    # The first color's weight will be obtained from the difference from 1.
    self.new(first_color).interpolate(*[colors, weights].flatten)
  end


  # = INSTANCE methods


  protected


  # Internal method to produce a new Sketchup::Color and extend it with this module's methods.
  #
  # @param [Sketchup::Color, String, Array<Numeric>] color a color in RGB color space.
  #   (Any color that +Sketchup::Color.new+ accepts.)
  #
  # @return [Sketchup::Color]
  def new_extended_color(*color)
    Sketchup::Color.new(*color).extend(AE::Color) # TODO: test this, changed from AE::Color
  end


  public


  # Compares a new color with another color.
  #
  # @param [Array<Numeric>] color another color.
  #
  # @return [Boolean]
  def ==(*color)
    color = (color[0].is_a? Sketchup::Color)? color[0].to_a : color.to_a.flatten
    return self.to_a == color
  end


  # == color CONVERSION


  # (see #new_extended_color)
  alias_method :from_rgb, :new_extended_color


  # Creates a new color from HSL color space.
  #
  # @param [Array<Numeric>] color a color in HSL color space with
  #   * hue:          +0..360+
  #   * saturation:   +0..100+
  #   * luminescence: +0..100+
  #   * alpha:        +0..255+
  #
  # @return [Sketchup::Color]
  def from_hsl(*color)
    h, s, l, a = *( (color[0].is_a?(Sketchup::Color))? color[0].to_a : color.to_a.flatten )
    s /= 100.0
    l /= 100.0
    chroma = (1 - (2*l - 1).abs) * s
    m = l - 0.5*chroma
    h1 = (h%360)/60
    x = chroma * (1 - (h1.divmod(2)[1]-1).abs)
    rgb1 = case
      when (0..1) === h1 then [chroma, x, 0]
      when (1..2) === h1 then [x, chroma, 0]
      when (2..3) === h1 then [0, chroma, x]
      when (3..4) === h1 then [0, x, chroma]
      when (4..5) === h1 then [x, 0, chroma]
      else [chroma, 0, x] # when (5..6) === h1
    end
    r, g, b = *(rgb1.collect{|c| (255*(c + m)).to_i})
    return self.new_extended_color([r, g, b, a||255])
  end


  # Creates a new color from HLS color space. Different writing of HSL.
  #
  # @param [Array<Numeric>] color a color in HLS color space with
  #   * hue:          +0..360+
  #   * luminescence: +0..100+
  #   * saturation:   +0..100+
  #   * alpha:        +0..255+
  #
  # @return [Sketchup::Color]
  def from_hls(*color)
    h, l, s, a = *( (color[0].is_a? Sketchup::Color)? color[0].to_a : color.to_a.flatten )
    self.from_hsl([h, s, l, a||255])
  end


  # Creates a new color from HSV color space.
  #
  # @param [Array<Numeric>] color a color in HSV color space with
  #   * hue:          +0..360+
  #   * saturation:   +0..100+
  #   * value:        +0..100+
  #   * alpha:        +0..255+
  #
  # @return [Sketchup::Color]
  def from_hsv(*color)
    h, s, v, a = *( (color[0].is_a? Sketchup::Color)? color[0].to_a : color.to_a.flatten )
    s /= 100.0
    v /= 100.0
    chroma = v * s
    m = v - chroma
    h1 = (h%360)/60
    x = chroma * (1 - (h1.divmod(2)[1]-1).abs)
    rgb1 = case
      when (0..1) === h1 then [chroma, x, 0]
      when (1..2) === h1 then [x, chroma, 0]
      when (2..3) === h1 then [0, chroma, x]
      when (3..4) === h1 then [0, x, chroma]
      when (4..5) === h1 then [x, 0, chroma]
      else [chroma, 0, x] # when (5..6) === h1
    end
    r, g, b = *(rgb1.collect{|c| (255*(c + m)).to_i})
    return self.new_extended_color([r, g, b, 255||a])
  end
  alias_method :from_hsb, :from_hsv


  # Creates a new color from a hexadecimal RGB(A) triple.
  #
  # @param [String] colorstring a RGB color in XHTML notation.
  #   (supports shorthand and longhand, optionally with alpha)
  #
  # @return [Sketchup::Color]
  def from_hex(colorstring)
    string = colorstring[/[0-9a-fA-F]+/]
    l = (3..4) === string.length ? 1 : 2
    f = (255 / (16**l).to_f).round
    hex = string.to_s.scan(/.{#{l}}/)
    rgb = [0, 0, 0, 255]
    hex.each_with_index{|c, i| rgb[i] = c.to_i(16)*f}
    return self.new_extended_color(rgb)
  end


  # Converts a Color to HSL color space.
  #
  # @return [Array] a HSL color array
  #   * hue:          +0..360+
  #   * saturation:   +0..100+
  #   * luminescence: +0..100+
  #   * alpha:        +0..255+
  def to_hsl
    rgba = self.to_a
    rgb = *(rgba[0..2].collect{|c| c/255.0})
    max = rgb.max.to_f
    min = rgb.min.to_f
    r, g, b = *rgb
    a = rgba[3] || 255
    chroma = max - min
    l = 0.5 * (max + min)
      if chroma == 0
        s = 0
        h = 0
      else
        if l < 0.5
          s = chroma/(max + min)
        else
          s = chroma/(2 - max - min)
        end
        if max == r
          h = (g - b)/chroma
        elsif max == g
          h = 2 + (b - r)/chroma
        else # if max == b
          h = 4 + (r - g)/chroma
        end
      end
      s *= 100
      l *= 100
      h *= 60
      h = h%360
    return [h, s, l, a]
  end


  # Converts a Color to HLS color space. Different writing of HSL.
  #
  # @return [Array] a HLS color array
  #   * hue:          +0..360+
  #   * luminescence: +0..100+
  #   * saturation:   +0..100+
  #   * alpha:        +0..255+
  def to_hls
    h, s, l, a = *(self.to_hsl)
    return [h, l, s, a]
  end


  # Converts a Color to HSV color space.
  #
  # @return [Array] a HSV color array
  #   * hue:          +0..360+
  #   * saturation:   +0..100+
  #   * value:        +0..100+
  #   * alpha:        +0..255+
  def to_hsv
    rgba = self.to_a
    rgb = *(rgba[0..2].collect{|c| c/255.0})
    max = rgb.max.to_f
    min = rgb.min.to_f
    r, g, b = *rgb
    a = rgba[3] || 255
    chroma = max - min
    v = max
      if chroma == 0
        s = 0
        h = 0
      else
        s = chroma/v
        if max == r
          h = (g - b)/chroma
        elsif max == g
          h = 2 + (b - r)/chroma
        else # if max == b
          h = 4 + (r - g)/chroma
        end
      end
      s *= 100
      v *= 100
      h *= 60
      h h%360
    return [h, s, v, a]
  end
  alias_method :to_hsb, :to_hsv


  # Converts a Color to a hexadecimal triple.
  #
  # @param [Boolean] with_alpha whether to include the opacity as a forth value.
  #
  # @return [String] a +hexadecimal+ RGB color 
  def to_hex(with_alpha=false)
    rgb = self.to_a
    rgb = rgb[0...3] unless with_alpha
    hex = rgb.inject(""){|hex, c| hex + c.to_s(16).rjust(2,"0")}
    return "#" + hex
  end


  # == color MANIPULATION


  # Mixes to a color any amount of other colors.
  # This method works different Sketchup::Color.blend in that it interpolates over
  # HSL color space, thus red and green result in yellow (instead of brown).
  #
  # @param [Sketchup::Color, String, Array<Numeric>] color any amount of colors in RGB color space.
  # @param [Numeric] weight the same amount (or one more for self) of weights between +0..1+.
  #   The weights will be assigned in the order in which colors are specified.
  #
  # @return [Sketchup::Color]
  def interpolate(*weights_and_colors)
    return self if weights_and_colors.empty?
    weights, colors = [], []
    colors << self
    weights_and_colors.flatten.each{|e| (e.is_a?(Numeric)? weights : colors) << e}
    sum = weights.inject(0){|s,i| s+i}.to_f
    (weights.unshift(1-sum); sum = 1) if weights.length == colors.length - 1
    h, s, l, a = 0, 0, 0, 0
    colors.each_with_index{|c, i|
      c_h, c_s, c_l, c_a = *(self.new_extended_color(c).to_hsl.to_a)
      r = weights[i] / sum
      h += c_h * r
      s += c_s * r
      l += c_l * r
      a += c_a * r
    }
    return self.from_hsl([h, s, l, a])
  end


  # Gets the opacity value alpha of a color, or sets it.
  #
  # @param [Numeric, Sketchup::Color] value optional alpha value between +0..255+
  #   or a color whose alpha should be adopted.
  #
  # @return [Numeric, Sketchup::Color]
  #   If no argument given, returns the current +Alpha+ value. 
  #   If an alpha value is given, returns the modified color.
  def alpha(value=nil)
    if !value.nil?
      value = value.alpha if value.is_a?(Sketchup::Color)
      r, g, b, a = self.to_a
      return self.new_extended_color(r, g, b, value)
    else
      return super()
    end
  end



  # Changes the opacity of a color by the given ratio.
  #
  # @param [Numeric] value a ratio bigger or smaller than 1.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def fade(ratio=0)
    r, g, b, a = self.to_a
    a = [[a*ratio, 255].min, 0].max.to_i
    return self.new_extended_color(r, g, b, a)
  end



  # Gets the brightness (precisely: luminescence) of a color, or sets it.
  #
  # @param [Numeric, Sketchup::Color] value optional brightness value between +0..100+
  #   or a color whose brightness should be adopted.
  #
  # @return [Numeric, Sketchup::Color]
  #   If no argument given, returns the current +brightness+ value. 
  #   If a brightness value is given, returns the modified color.
  def brightness(value=nil)
    h, s, l, a = self.to_hsl
    if !value.nil?
      value = new_extended_color(value).to_hsl[2] if value.is_a?(Sketchup::Color)
      l = [[0, value].max, 100].min
      return self.from_hsl([h, s, l, a])
    else
      return l
    end
  end



  # Sets the brightness of a color.
  # Mimics SketchUp's setter methods and returns the value.
  #
  # @param [Numeric, Sketchup::Color] value brightness value between +0..100+
  #   or a color whose brightness should be adopted.
  #
  # @return [Sketchup::Color] the modified color.
  def brightness=(value)
    self.brightness(value)
    return value
  end


  # Changes the brightness of a color by the given value.
  #
  # @param [Numeric] value a value between +-100..100+.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def brighten(value=0)
    h, s, l, a = self.to_hsl
    l += value.to_f
    l = [[0, l].max, 100].min
    return self.from_hsl([h, s, l, a])
  end


  # Changes the darkness of a color by the given value. (Opposite of brighten)
  #
  # @param [Numeric] value a value between +-100..100+.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def darken(value=0)
    return self.brighten(-value)
  end


  # Changes the gamma of a color.
  #
  # @param [Numeric] value a ratio bigger or smaller than 1.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def gamma(value=1)
    h, s, l, a = self.to_hsl
    l = 100*((l/100.0)**(1/value))
    return self.from_hsl([h, s, l, a])
  end


  # Changes the contrast of a color.
  #
  # @param [Numeric] value a ratio bigger or smaller than 1.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def contrast(value=1)
    h, s, l, a = self.to_hsl
    if value>1
      l = l/value+(1-1/value)*100/(1+Math.exp((value-1)*(8-16*l/100)))
    else
      l = value*l + 50*(1-value)
    end
    return self.from_hsl([h, s, l, a])
  end


  # Inverses a color to produce the complementary color.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def inverse
    rgba = self.to_a
    3.times{|i| rgba[i] = 255 - rgba[i]}
    return self.new_extended_color(rgba)
  end


  # Inverses only the brightness of a color while preserving hue and saturation.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def inverse_brightness
    h, s, l, a = self.to_hsl
    l = 100 - l
    return self.from_hsl([h, s, l, a])
  end


  # Turns a color into black or white depending on its brightness.
  #
  # @return [Sketchup::Color] either black or white.
  def binary
    r, g, b, a = self.to_a
    sum = r + g + b
    return (sum < 382)? self.new_extended_color([0,0,0,a]) : self.new_extended_color([255,255,255,a])
  end


  # Gets the saturation of a color, or sets it.
  #
  # @param [Numeric, Sketchup::Color] value an optional saturation value between +0..100+.
  #   or a color whose saturation should be adopted.
  #
  # @return [Numeric, Sketchup::Color]
  #   If no argument given, returns the current +saturation+ value. 
  #   If a saturation value is given, returns the modified color.
  def saturation(value=nil)
    h, s, l, a = self.to_hsl
    if !value.nil?
      value = new_extended_color(value).to_hsl[1] if value.is_a?(Sketchup::Color)
      s = [[0, value].max, 100].min
      return self.from_hsl([h, s, l, a])
    else
      return s
    end
  end


  # Sets the saturation of a color.
  # Mimics SketchUp's setter methods and returns the value.
  #
  # @param [Numeric, Sketchup::Color] value saturation value between +0..100+
  #   or a color whose saturation should be adopted.
  #
  # @return [Sketchup::Color] the modified color.
  def saturation=(value)
    self.saturation(value)
    return value
  end


  # Changes the saturation of a color by the given value.
  #
  # @param [Numeric] value a value between +-100..100+.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def saturate(value=0)
    h, s, l, a = self.to_hsl
    s += value.to_f
    s = [[0, s].max, 100].min
    return self.from_hsl([h, s, l, a])
  end


  # Changes the saturation of a color by the given value. (Opposite of +saturate+)
  #
  # @param [Numeric] value a value between +-100..100+.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def desaturate(value=0)
    return self.saturate(-value)
  end


  # Gets the hue of a color, or sets it.
  #
  # @param [Numeric, Sketchup::Color] value an optional hue value between +0..360+ .
  #   or a color whose hue should be adopted.
  #
  # @return [Numeric, Sketchup::Color]
  #   If no argument given, returns the current hue value. 
  #   If a hue value is given, returns the modified color.
  def hue(value=nil)
    h, s, l, a = self.to_hsl
    if !value.nil?
      value = new_extended_color(value).to_hsl[0] if value.is_a?(Sketchup::Color)
      h = value%360
      return self.from_hsl([h, s, l, a])
    else
      return h
    end
  end


  # Sets the hue of a color.
  # Mimics SketchUp's setter methods and returns the value.
  #
  # @param [Numeric, Sketchup::Color] value hue value between +-360..360+
  #   or a color whose hue should be adopted.
  #
  # @return [Sketchup::Color] the modified color.
  def hue=(value)
    self.hue(value)
    return value
  end


  # Shifts the hue of a color by the given value.
  #
  # @param [Numeric] value a value between +-360..360+.
  #
  # @return [Sketchup::Color] Returns the modified color.
  def shift_hue(value=0)
    h, s, l, a = self.to_hsl
    h += value.to_f
    h = h%360
    return self.from_hsl([h, s, l, a])
  end


end



# Primitive Tool for testing the methods of the Color module.
# It just draws colored rectangles with labels onto the viewport.
#
# Select the tool via Ruby Console, then 
# +tool.add("test color name", AE::Color[])+.
class AE::ColorTest
  @@instance = nil

  # Add a color to the screen to see how it looks like.
  # @param [Sketchup::Color] color a color to visualize.
  # @param [String] label an optional label/note.
  def self.add(color, label="")
    @@instance.add(label, color) unless @@instance.nil?
  end

  def initialize
    @colors = []
    @@instance = self
  end

  # (see #self.add)
  def add(color, label="")
    @colors << [color, label]
    Sketchup.active_model.active_view.invalidate
  end

  def draw(view)
    rows, cols = 4, 8
    w = view.vpwidth/cols
    h = view.vpheight/rows
    row = 0
    col = 0
    @colors.each{|a|
      color, label = *a
      view.drawing_color = color
      p = Geom::Point3d.new([w*col, h*row, 0])
      view.draw2d(GL_QUADS, [p, p+[w,0,0], p+[w,h,0], p+[0,h,0]])
      text = label+"\n"+color.inspect
      view.draw_text(p+[10,0,0], text)
      col += 1
      (col = 0; row += 1) if col >= cols
    }
  end


end # module


end # unless defined?(AE::Color)
