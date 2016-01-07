module Spree
  module Admin
    ShipmentsController.class_eval do
      after_filter :set_order_ship_address, only: :create


      private

      # When creating a shipment on an order for pick-up, set the order's ship address to that of
      # the distributor, since this is where it will be picked up from
      def set_order_ship_address
        if !shipment.shipping_method.require_ship_address && order.shipments.count == 1
          order.ship_address = order.distributor.address.dup
          order.save!
        end
      end

    end
  end
end
