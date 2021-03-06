# coding: utf-8

require 'forwardable'

module Preflight
  module Rules

    # Some print workflows forbid the use of Gray colour.
    #
    # Arguments: none
    #
    # Usage:
    #
    #   class MyPreflight
    #     include Preflight::Profile
    #
    #     rule Preflight::Rules::NoGray
    #   end
    #
    class NoGray
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
          when PDF::Reader::Stream then
            check_xobject(xobj)
          end
        end
      end

      def set_gray_for_stroking(g)
        gray_detected(g)
      end

      def set_gray_for_nonstroking(g)
        gray_detected(g)
      end

      def set_stroke_color_space(label)
        check_color_space(label)
      end

      def set_nonstroke_color_space(label)
        check_color_space(label)
      end

      private

      def color_space_is_gray?(cs)
        case cs
        when Symbol then cs == :DeviceGray
        when Array  then
          cs[0] == :DeviceGray || cs[2] == :DeviceGray
        else
          false
        end
      end

      def check_color_space(label)
        return if @resource_labels_seen.include?(label)

        if color_space_is_gray?(@state.find_color_space(label))
          @issues << Issue.new("Gray color detected", self, :page  => @page.number)
        end

        @resource_labels_seen << label
      end

      def check_xobject(xobject)
        cs = xobject.hash[:ColorSpace]
        if cs == :DeviceGray
          @issues << Issue.new("Gray image detected", self, :page  => @page.number)
        end
      end

      def gray_detected(g)
        @issues << Issue.new("Gray color detected", self, :page  => @page.number,
                                                          :gray  => g)
      end
    end

  end
end
