# coding: utf-8

require 'forwardable'

module Preflight
  module Rules

    # Some print workflows forbid the use of Separation colours (like
    # Pantones).
    #
    # Arguments: none
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::NoSeparation
    #   end
    #
    class NoSeparation
      extend  Forwardable

      # Graphics State Operators
      def_delegators :@state, :save_graphics_state, :restore_graphics_state

      # Matrix Operators
      def_delegators :@state, :concatenate_matrix

      attr_reader :issues

      # we're about to start a new page, reset state
      #
      def page=(page)
        @page   = page
        @state  = PDF::Reader::PageState.new(page)
        @issues = []
        @resource_labels_seen = []
      end

      # descend into nested form xobjects
      #
      def invoke_xobject(label)
        @state.invoke_xobject(label) do |xobj|
          case xobj
          when PDF::Reader::FormXObject then
            xobj.walk(self)
          end
        end
      end

      def set_stroke_color_space(label)
        check_color_space(label)
      end

      def set_nonstroke_color_space(label)
        check_color_space(label)
      end

      private

      def separation_name(cs)
        if cs.is_a?(Array) && cs[0] == :Separation
          cs[1]
        else
          nil
        end
      end

      def check_color_space(label)
        return if @resource_labels_seen.include?(label)

        spot_name = separation_name(@state.find_color_space(label))
        if spot_name
          @issues << Issue.new("Separation color detected #{spot_name}", self, :page => @page.number,
                                                                               :name => spot_name)
        end

        @resource_labels_seen << label
      end

    end

  end
end
