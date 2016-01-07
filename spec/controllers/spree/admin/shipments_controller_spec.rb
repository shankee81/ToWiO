require 'spec_helper'

module Spree
  module Admin
    describe ShipmentsController do
      include AuthenticationWorkflow
      before { login_as_admin }

      describe "creating the first shipment on an incomplete order" do
        let(:shop_address) { create(:address, address1: 'shop') }
        let(:order_address) { create(:address, address1: 'order') }
        let(:shop) { create(:distributor_enterprise, address: shop_address) }
        let(:order) { create(:order, distributor: shop, ship_address: order_address) }

        describe "when the shipping method is for pick-up" do
          let(:pickup) { create(:shipping_method, require_ship_address: false) }

          it "sets the shipping address on the order to the order's distributor" do
            spree_post :create, {order_id: order.number, shipment: {shipping_method_id: pickup.id}}
            expect(order.reload.ship_address.address1).to eql 'shop'
          end

          it "does nothing when there's already another shipment" do
            order.shipments.create! shipping_method_id: pickup.id
            spree_post :create, {order_id: order.number, shipment: {shipping_method_id: pickup.id}}
            expect(order.reload.ship_address.address1).to eql 'order'
          end
        end

        describe "when the shipping method is for delivery" do
          let(:delivery) { create(:shipping_method, require_ship_address: true) }

          it "does not change the order's shipping address" do
            spree_post :create, {order_id: order.number, shipment: {shipping_method_id: delivery.id}}
            expect(order.reload.ship_address.address1).to eql 'order'
          end
        end
      end
    end
  end
end
