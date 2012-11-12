require File.join(File.dirname(__FILE__), "Color.rb")


module AE
  module GUI3
    module OnScreen




class Style


  dialog_color = AE::Color.new().from_hex( UI::WebDialog.new.get_default_dialog_color )
  @@color = {
    :white => AE::Color["white"],
    :gray => AE::Color["gray"],
    :black => AE::Color["black"],
    :red => AE::Color["red"],
    :transparent => AE::Color[255,255,255,0],
    :Window => AE::Color[dialog_color],
    :ThreeDHighlight => AE::Color[dialog_color].contrast(0.8).brighten(20),
    :ThreeDLightShadow => AE::Color[dialog_color].contrast(0.8).brighten(10),
    :ButtonFace => AE::Color[dialog_color].contrast(0.8),
    :ThreeDFace => AE::Color[dialog_color].contrast(0.8),
    :ButtonShadow => AE::Color[dialog_color].contrast(0.8).gamma(0.6),
    :ThreeDShadow => AE::Color[dialog_color].contrast(0.8).gamma(0.6),
    :ThreeDDarkShadow => AE::Color[dialog_color].contrast(0.8).gamma(0.4),
    :WindowText => AE::Color[dialog_color].inverse_brightness.gamma(0.8).contrast(2.5),
  }


  @@default_style = {
    :default => {
      :visible => true,
      :backgroundColor => :ButtonFace,
      :borderRadius => 4,
      :borderColor => [ :ThreeDHighlight, :ThreeDShadow, :ThreeDDarkShadow, :ThreeDLightShadow ],
      :borderWidth => 1,
      :borderStyle => "",
      :shadowColor => Sketchup::Color.new([0,0,0,20]),
      :shadowWidth => 0,
      :textColor => :WindowText,
      # IMPORTANT! Setting :textColor to rendering_options["ForegroundColor"]
      # triggers View.draw and thus an endless draw loop! No workaround known yet.
      :textShadow => false,
      :textShadowColor => Sketchup::Color.new([0,0,0,20]),
      :textShadowOffset => [1,1,0],
      :textShadowRadius => 0,
      :hover => {
        :backgroundColor => :ThreeDLightShadow,
        :shadowWidth => 7,
      },
      :active => {
        :backgroundColor => :ThreeDShadow,
        :borderColor => [ :ThreeDDarkShadow, :ThreeDLightShadow, :ThreeDHighlight, :ThreeDShadow ],
        :shadowWidth => 7,
      },
      :position => :relative,
      :top => 0,
      :right => 0,
      :bottom => 0,
      :left => 0,
      :front => 0, # for 3D support
      :back => 0,  # for 3D support
      :display => true,
      :transformation => nil, # a Geom::Transformation object
      :zIndex => 0,
      :margin => 0,
      :marginTop => nil,
      :marginRight => nil,
      :marginBottom => nil,
      :marginLeft => nil,
      :padding => 0,
      :paddingTop => nil,
      :paddingRight => nil,
      :paddingBottom => nil,
      :paddingLeft => nil,
      :align => :left,
      :valign => :top,
      :orientation => :horizontal,
      :width => nil,
      :minWidth => nil,
      :maxWidth => nil,
      :height => nil,
      :minHeight => nil,
      :maxHeight => nil,
      :depth => nil,    # for 3D support
      :minDepth => nil, # for 3D support
      :maxDepth => nil  # for 3D support
    }
  }
  NULLVEC = Geom::Vector3d.new(0,0,0) unless defined?(NULLVEC)
  def self.default_style; return @@default_style; end

  attr_accessor :hover, :active, :focus
  def initialize(widget)
    @widget = widget
    @given_style = {}
    @inherited_style = {}
    @style = {}
    superclasses(@widget).reverse.collect{|c| c = c.name[/[^\:]+$/].to_sym }.
      unshift(:default).each{|c|
      @inherited_style.merge!( @@default_style[c] ){|k,v1,v2| v2.nil? ? v1 : v2} unless @@default_style[c].nil?
    }
    @style = @inherited_style.clone
    @valid = false
    # states of the style
    @hover = false
    @active = false
    @focus = false
    #
    @size = nil
    @innersize = nil
    @outersize = nil
    @contentsize = nil
    @position = nil
    @margin = nil
    @padding = nil
    #@widget.on(:added_to_window){ generate() }
  end


  # Method to set many properties at once.
  def set(hash)
    @given_style = hash
    generate
  end


  # Methods to get/set single properties.
  def [](key)
    generate unless @valid
    return @style[key]
  end


  # Method set a single property. Set it to nil to reset it to default.
  def []=(key, value)
    @given_style[key] = value
    invalidate
  end


  def invalidate # TODO: make this private?
    @valid = false
    @size = nil
    @innersize = nil
    @outersize = nil
    @contentsize = nil
    @position = nil
    @margin = nil
    @padding = nil
  end


  # TODO: deprecate this and solve it differently.
  # Method to set a widget state.
  # @param [Array<Object>] states  any identifier for a substyle in the style hash.
  def set_substyle(*states)
    generate
    states.reverse.each{|s|
      @style.merge!( @style[state] ){|k,v1,v2| v2.nil? ? v1 : v2} unless @style[state].nil?
    }
    return self
  end


  private


  # Merge new style properties with inherited styles.
  # A widget inherits from its base class and its superclasses.
  # A given value of nil will be ignored and inherit.
  #
  # @return [Hash] new style
  def generate
    return if @widget.window.nil?
    @inherited_style.clear
    superclasses(@widget).reverse.collect{|c| c = c.name[/[^\:]+$/].to_sym }.
      unshift(:default).each{|c|
      @inherited_style.merge!( @widget.window.stylesheet[c] ){|k,v1,v2| v2.nil? ? v1 : v2} unless @widget.window.stylesheet[c].nil?
    }
    @style = @inherited_style.merge(@given_style){|k,v1,v2| v2.nil? ? v1 : v2}
    @valid = true
    return self
  end


  def superclasses(object)
    result = [object.class]
    result << result.last.superclass while result.last.superclass
    return result
  end


  public


  # These methods calculate some layout properties:


  def color(name) # TODO: or does this method belong into Drawable?
    return name if name.is_a?(Sketchup::Color)
    #c = @widget.window.colors[name] unless @widget.window.nil? # TODO: look up colors from a color scheme
    # Otherwise lookup color from default color scheme:
    c = @@color[name] || Sketchup::Color.new(name) rescue @@color[:black]
  end


  # These methods calculate some layout properties:


  # Calculate this widget's padding.
  # We do not interprete it like in CSS! We use padding inside width/height, not outside.
  #
  # @return [Array] padding top, top, right, bottom, left
  def padding
    return @padding unless @padding.nil?
    p = @style[:padding] || 0
    p = [p]*4 unless p.is_a?(Array) && p.length == 4
    pt = @style[:paddingTop] || p[0]
    pr = @style[:paddingRight] || p[1]
    pb = @style[:paddingBottom] || p[2]
    pl = @style[:paddingLeft] || p[3]
=begin
# Better don't allow percent values for padding, this causes circular reference.
    _size = self.size # This widget's size.
    # Resolve percent values of padding (requires container size as argument)
    pt = _size.y * pt.to_s.to_f/100.0 if pt.is_a?(Symbol) || pt.is_a?(String)
    pr = _size.x * pr.to_s.to_f/100.0 if pr.is_a?(Symbol) || pr.is_a?(String)
    pb = _size.y * pb.to_s.to_f/100.0 if pb.is_a?(Symbol) || pb.is_a?(String)
    pl = _size.x * pl.to_s.to_f/100.0 if pl.is_a?(Symbol) || pl.is_a?(String)
=end
    return @padding = [pt, pr, pb, pl]
  end


  # Calculate this widget's margin.
  #
  # @return [Array] margin top, top, right, bottom, left
  def margin
    return @margin unless @margin.nil?
    m = @style[:margin] || 0
    m = [m]*4 unless m.is_a?(Array) && m.length == 4
    mt = @style[:marginTop] || m[0]
    mr = @style[:marginRight] || m[1]
    mb = @style[:marginBottom] || m[2]
    ml = @style[:marginLeft] || m[3]
=begin
# Better don't allow percent values for margin, it causes circular reference for
# padding, maybe also for margin.
    # Resolve percent values of margin from parent size.
    psize = NULLVEC # (!@widget.parent.nil?)? @widget.parent.style.innersize : NULLVEC # TODO: this caused infinite loop
    mt = psize.y * mt.to_s.to_f/100.0 if mt.is_a?(Symbol) || mt.is_a?(String)
    mr = psize.x * mr.to_s.to_f/100.0 if mr.is_a?(Symbol) || mr.is_a?(String)
    mb = psize.y * mb.to_s.to_f/100.0 if mb.is_a?(Symbol) || mb.is_a?(String)
    ml = psize.x * ml.to_s.to_f/100.0 if ml.is_a?(Symbol) || ml.is_a?(String)
=end
    return @margin = [mt, mr, mb, ml]
  end


  # Calculate this widget's position (=offset from theoretical position).
  #
  # @return [Array] position top, top, right, bottom, left
  # @note Position from right or bottom may currently not be used.
  def position
    return @position unless @position.nil?
    ct = @style[:top] || 0
    cr = @style[:right] || 0
    cb = @style[:bottom] || 0
    cl = @style[:left] || 0
    # Resolve percent values of position from parent size.
    psize = NULLVEC # (!@widget.parent.nil?)? @widget.parent.style.size : NULLVEC # TODO: this caused infinite loop
    ct = psize.y * ct.to_s.to_f/100.0 if ct.is_a?(Symbol) || ct.is_a?(String)
    cr = psize.x * cr.to_s.to_f/100.0 if cr.is_a?(Symbol) || cr.is_a?(String)
    cb = psize.y * cb.to_s.to_f/100.0 if cb.is_a?(Symbol) || cb.is_a?(String)
    cl = psize.x * cl.to_s.to_f/100.0 if cl.is_a?(Symbol) || cl.is_a?(String)
    return @position = [ct, cr, cb, cl]
  end


  # Calculate the size required by this widget.
  #
  # @return [Geom::Vector3d] Width and Height of the widget.
  def size
    return @size unless @size.nil?
    w = @style[:width]
    h = @style[:height]
    # Resolve percent values from parent size.
    psize = NULLVEC # (!@widget.parent.nil?)? @widget.parent.style.innersize : NULLVEC # TODO: this caused infinite loop
    w = psize.x*w.to_s.to_f/100.0 if w.is_a?(Symbol) || w.is_a?(String)
    h = psize.y*h.to_s.to_f/100.0 if h.is_a?(Symbol) || h.is_a?(String)
    # If no width/height is given, it is either 0 or determined by contained widgets.
    if w.nil? || h.nil?
      # Get the size caused by contained widgets.
      if @widget.respond_to?(:children)
        # total size required by content
        tsize = contentsize #(psize) ######################################## TODO
        p = 0#padding # DEBUG
        w ||= tsize.x + p[3] + p[1]
        h ||= tsize.y + p[0] + p[2]
      # Or fallback to 0.
      else
        w ||= 0
        h ||= 0
      end
    end
    # Consider min/max limits
    w = @style[:minWidth] if @style[:minWidth] && w < @style[:minWidth]
    w = @style[:maxWidth] if @style[:maxWidth] && w > @style[:maxWidth]
    h = @style[:minHeight] if @style[:minHeight] && h < @style[:minHeight]
    h = @style[:maxHeight] if @style[:maxHeight] && h > @style[:maxHeight]
    return @size = Geom::Vector3d.new(w, h)
  end


  # Calculate the size available in this widget.
  # We do not interprete it like in CSS! We use padding inside width/height, not outside.
  #
  # @return [Geom::Vector3d] Width and Height of the widget.
  def innersize
    return @innersize unless @innersize.nil?
    _size = self.size
    p = self.padding
    _size += [-p[3]-p[1], -p[0]-p[2]]
    return @innersize = _size
  end


  # Calculate the size required by this widget plus margin.
  #
  # @return [Geom::Vector3d] Width and Height of the widget.
  def outersize
    return @outersize unless @outersize.nil?
    _size = self.size
    m = self.margin
    _size += [m[3]+m[1], m[0]+m[2]]
    return @outersize = _size
  end


  # Calculate the size required by the containers's content.
  #
  # @return [Geom::Vector3d] Width and Height of the widget's content.
  def contentsize
    return @contentsize unless @contentsize.nil?
    tsize = NULLVEC
    if @widget.respond_to?(:children)
      csize = NULLVEC # define variable before loop
      # return @currentcontentsize unless @currentcontentsize.empty? || @window && !@window.changed? # TODO
      if @style[:orientation] == :horizontal
        # total width is sum of children, total height is heighest child
        @widget.children.each{|child|
          csize = child.style.outersize
          # width
          tsize.x = (child.style[:position] == :relative)? tsize.x + csize.x : [tsize.x, csize.x].max
          # height
          tsize.y = [tsize.y, csize.y].max
        }
      else # if @style[:orientation] == :vertical
        # total width is widest child, total height is sum of children
        @widget.children.each{|child|
          csize = child.style.outersize
          # width
          tsize.x = [tsize.x, csize.x].max
          # height
          tsize.y = (child.style[:position] == :relative)? tsize.y + csize.y : [tsize.y, csize.y].max
        }
      end
    end
    return @contentsize = tsize
  end


end # class Style




    end # module OnScreen
  end # module GUI
end # module AE
