module Spree
  class Variant < ActiveRecord::Base
    module ProtectedAttributes
      class ProtectedAttributeError < StandardError; end

      def count_on_hand
        raise ProtectedAttributeError.new "This attribute is protected."
      end

      def count_on_hand=(new_level)
        raise ProtectedAttributeError.new "This attribute is protected."
      end

      def prices
        raise ProtectedAttributeError.new "This attribute is protected."
      end

      def default_price
        raise ProtectedAttributeError.new "This attribute is protected."
      end
    end
  end
end
