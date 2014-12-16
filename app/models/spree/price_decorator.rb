Spree::Price.class_eval do
  class ProtectedAttributeError < StandardError; end

  def amount
    raise ProtectedAttributeError.new "The amount attribute is protected."
  end
end
