#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

module AE::GUI3::OnScreen


  # Caches drawing instructions so complex calculations for generating the
  # GL data can be reused.
  #
  # Redirect all Sketchup::View commands to a DrawCache object and call
  # #render in a Tool's #draw event.
  #
  # @since 1.0.0
  class DrawCache


    # @param [Sketchup::View]
    #
    # @since 1.0.0
    def initialize( view )
      @view = view
      @commands = []
      @valid = false # whether the cache is valid
    end


    # Marks the cache for redrawing.
    #
    # @return [Nil]
    # @since 1.1.0
    def invalidate(*args)
      clear
      @valid = false
      @view.invalidate
      nil
    end


    # Returns whether the cache is ready to render.
    #
    # @return [Nil]
    # @since 1.1.0
    def ready
      @valid = true
    end


    # Returns whether it has been drawn to the cache.
    #
    # @return [Nil]
    # @since 1.1.0
    def valid?
      @valid
    end


    # Clears the cache. All drawing instructions are removed.
    #
    # @return [Nil]
    # @since 1.1.0
    def clear
      @commands.clear
      nil
    end


    # Draws the cached drawing instructions.
    #
    # @return [Sketchup::View]
    # @since 1.0.0
    def render
      view = @view
      for command in @commands
        view.send( *command )
      end
      view
    end


    # Cache drawing commands and data. These methods received the finsihed
    # processed drawing data that will be executed when #render is called.
    [
      :draw,
      :draw2d,
      :draw_line,
      :draw_lines,
      :draw_points,
      :draw_polyline,
      :draw_text,
      :drawing_color=,
      :line_stipple=,
      :line_width=,
      :set_color_from_line
    ].each { |symbol|
      define_method( symbol ) { |*args|
        @commands << args.unshift( this_method )
        @commands.size
      }
    }

    # Pass through methods to Sketchup::View so that the drawing cache object
    # can easily replace Sketchup::View objects in existing codes.
    #
    # @since 1.0.0
    def method_missing( *args )
      view = @view
      method = args.first
      if view.respond_to?( method )
        view.send(*args)
      else
        raise NoMethodError, "undefined method `#{method}' for #{self.class.name}"
      end
    end


    private


    # http://www.ruby-forum.com/topic/75258#895569
    def this_method
      ( caller[0] =~ /`([^']*)'/ and $1 ).intern # TODO: How does this string operation impact drawcache.draw calls?
    end


  end # class DrawCache


end # module
