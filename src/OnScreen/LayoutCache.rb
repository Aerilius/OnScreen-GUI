module AE::GUI3::OnScreen


  # Caches positions and sizes of widgets.
  #
  class LayoutCache


    NULLVEC = Geom::Vector3d.new(0,0,0) unless defined?(NULLVEC)


    # @param [Window] window
    #
    def initialize( window )
      @window = window
      @widgets = []
      @data = {}
#      @valid = false
    end


    # Loops over all widgets and calls a block with widget, widget's position and size.
    # @param [Proc] block
    #
    def each(&block)
      @widgets.each{|widget|
        block.call(widget, @data[widget][:pos], @data[widget][:size])
      }
    end


=begin
    # Marks the cache for redrawing.
    #
    # @return [Nil]
    def invalidate(*args)
      clear
      @valid = false
      nil
    end


    # Returns whether the cache is ready to render.
    #
    # @return [Nil]
    def ready
      @valid = true
    end


    # Returns whether it has been drawn to the cache.
    #
    # @return [Nil]
    def valid?
      @valid
    end
=end

    # Clears the cache.
    #
    # @return [Nil]
    def clear
      @widgets.clear
      @data.clear
      nil
    end


    # Calculates the layout of all widgets.
    #
    def render
      puts @window.children.length
      puts("render")
      for child in @window.children
        compile_layout(child, ORIGIN, @window.viewport)
      end
      return
#      @valid = true
      @widgets.sort!{|w1, w2| @data[w1][:pos].z <=> @data[w2][:pos].z }
      nil
    end


    private


    # Fit the widget (and its children) into a container.
    # This calculates the positions of subcontainers.
    # This method is started on the most outer container (the window) and walks towards the leaves of the child widgets.
    #
    # @param [Widget, Container]
    # @param [Geom::Point3d] ppos  Position where to arrange the widget on the screen.
    # @param [Geom::Vector3d] psize  Width and Height of the available space to fill.
    #
    # @private
    def compile_layout(widget, ppos, psize)
      style = widget.style
      return if style[:display] == false # return unless style[:display] == true
      psize = Geom::Vector3d.new(psize.to_a) unless psize.is_a?(Geom::Vector3d)
      # This widget
      # Set Position and increase the drawing order (zIndex)
      pos = style.position
      ppos += [pos[3], pos[0], 1+style[:zIndex].to_i]
      # Margin
      m = style.margin
      ppos += [m[3], m[0]]
      # Size
      psize = widget.style.size
      return puts(widget.inspect+" ok") # DEBUG
      # Layouting finished for this widget:
      @widgets << widget
      @data[widget] = {:pos=>ppos, :size=>psize}
      return unless widget.respond_to?(:children)
      #
      # Now compile layout for all children.
      #
      psize = widget.innersize
      # Total width and height of children.
      tsize = widget.contentsize
      # Get the insertion point for relatively positioned widgets.
      relpos = Geom::Vector3d.new(0,0,0)
      case style[:align]
        when :center then relpos.x = (style[:orientation] == :horizontal)? psize.x/2 - tsize.x/2 : psize.x/2
        when :right then relpos.x = psize.x - tsize.x
      end
      case style[:valign]
        when :middle then relpos.y = (style[:orientation] == :vertical)? psize.y/2 - tsize.y/2 : psize.y/2
        when :bottom then relpos.y = psize.y - tsize.y
      end
      # Loop over all contained widgets and set their position.
      csize, cpos = NULLVEC, ORIGIN # initialize variables before loop
      widget.children.each{|child|
        style = child.style
        # Size
        csize = child.size
        # Position
        cpos = ppos.clone
        # Margin
        m = style.margin
        # Indent the widget by margin.
        cpos += [m[3], m[0]]
        # Relative layout aligns a widget next to its previous sibling, absolute layout to its the beginning of available space.
        if child.style[:position] == :relative
          cpos += relpos
          if style[:orientation] == :horizontal
            cpos.y += -csize[1]/2 if style[:valign] == :middle # Only in that case, relpos is in middle of widget.
            relpos.x += m[3] + csize.x + m[1]
          else style[:orientation] == :vertical
            cpos.x += -csize[0]/2 if style[:align] == :center # Only in that case, relpos is in center of widget.
            relpos.y += m[0] + csize.y + m[2]
          end
        end
        compile_layout(child, cpos, csize)
      }
      return nil
    end


  end # class LayoutCache


end # module
