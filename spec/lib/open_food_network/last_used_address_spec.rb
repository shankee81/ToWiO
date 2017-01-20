require 'open_food_network/last_used_address'

module OpenFoodNetwork
  describe LastUsedAddress do
    let(:email) { 'test@example.com' }

    describe "initialisation" do
      let(:user) { create(:user) }
      let(:customer) { create(:customer) }

      context "when passed any combination of instances of String, Customer or Spree::User" do
        let(:lua1) { LastUsedAddress.new(email, customer, user) }
        let(:lua2) { LastUsedAddress.new(customer, user, email) }

        it "stores arguments based on their class" do
          expect(lua1.email).to eq email
          expect(lua2.email).to eq email
          expect(lua1.customer).to be customer
          expect(lua2.customer).to be customer
          expect(lua1.user).to be user
          expect(lua2.user).to be user
        end
      end

      context "when passed multiples instances of a class" do
        let(:email2) { 'test2@example.com' }
        let(:user2) { create(:user) }
        let(:customer2) { create(:customer) }
        let(:lua1) { LastUsedAddress.new(user2, email, email2, customer2, user, customer) }
        let(:lua2) { LastUsedAddress.new(email2, customer, user, email, user2, customer2) }

        it "only stores the first encountered instance of a given class" do
          expect(lua1.email).to eq email
          expect(lua2.email).to eq email2
          expect(lua1.customer).to be customer2
          expect(lua2.customer).to be customer
          expect(lua1.user).to be user2
          expect(lua2.user).to be user
        end
      end
    end

    describe "fallback_bill_address" do
      let(:lua) { LastUsedAddress.new(email) }
      let(:address) { double(:address, clone: 'address_clone') }

      context "when a last_used_bill_address is found" do
        before { allow(lua).to receive(:last_used_bill_address) { address } }

        it "returns a clone of the bill_address" do
          expect(lua.send(:fallback_bill_address)).to eq "address_clone"
        end
      end

      context "when no last_used_bill_address is found" do
        before { allow(lua).to receive(:last_used_bill_address) { nil } }

        it "returns a new empty address" do
          expect(lua.send(:fallback_bill_address)).to eq Spree::Address.default
        end
      end
    end

    describe "fallback_ship_address" do
      let(:lua) { LastUsedAddress.new(email) }
      let(:address) { double(:address, clone: 'address_clone') }

      context "when a last_used_ship_address is found" do
        before { allow(lua).to receive(:last_used_ship_address) { address } }

        it "returns a clone of the ship_address" do
          expect(lua.send(:fallback_ship_address)).to eq "address_clone"
        end
      end

      context "when no last_used_ship_address is found" do
        before { allow(lua).to receive(:last_used_ship_address) { nil } }

        it "returns a new empty address" do
          expect(lua.send(:fallback_ship_address)).to eq Spree::Address.default
        end
      end
    end

    describe "last_used_bill_address" do
      let(:distributor) { create(:distributor_enterprise) }
      let(:address) { create(:address) }
      let(:order) { create(:completed_order_with_totals, user: nil, email: email, distributor: distributor) }

      context "when an email has not been provided" do
        let(:lua) { LastUsedAddress.new(nil) }

        context "and an order with a bill address exists" do
          before do
            order.update_attribute(:bill_address_id, address.id)
          end

          it "returns nil" do
            expect(lua.send(:last_used_bill_address)).to eq nil
          end
        end
      end

      context "when an email has been provided" do
        let(:lua) { LastUsedAddress.new(email) }

        context "and an order with a bill address exists" do
          before { order.update_attribute(:bill_address_id, address.id) }

          it "returns the bill_address" do
            expect(lua.send(:last_used_bill_address)).to eq address
          end
        end

        context "and an order without a bill address exists" do
          before { order }

          it "return nil" do
            expect(lua.send(:last_used_bill_address)).to eq nil
          end
        end

        context "when no orders exist" do
          it "returns nil" do
            expect(lua.send(:last_used_bill_address)).to eq nil
          end
        end
      end
    end

    describe "last_used_ship_address" do
      let(:address) { create(:address) }
      let(:distributor) { create(:distributor_enterprise) }
      let!(:pickup) { create(:shipping_method, require_ship_address: false, distributors: [distributor]) }
      let!(:delivery) { create(:shipping_method, require_ship_address: true, distributors: [distributor]) }
      let(:order) { create(:completed_order_with_totals, user: nil, email: email, distributor: distributor) }

      context "when an email has not been provided" do
        let(:lua) { LastUsedAddress.new(nil) }

        context "and an order with a required ship address exists" do
          before do
            order.update_attribute(:ship_address_id, address.id)
            order.update_attribute(:shipping_method_id, delivery.id)
          end

          it "returns nil" do
            expect(lua.send(:last_used_ship_address)).to eq nil
          end
        end
      end

      context "when an email has been provided" do
        let(:lua) { LastUsedAddress.new(email) }

        context "and an order with a ship address exists" do
          before { order.update_attribute(:ship_address_id, address.id) }

          context "and the shipping method requires an address" do
            before { order.update_attribute(:shipping_method_id, delivery.id) }

            it "returns the ship_address" do
              expect(lua.send(:last_used_ship_address)).to eq address
            end
          end

          context "and the shipping method does not require an address" do
            before { order.update_attribute(:shipping_method_id, pickup.id) }

            it "returns nil" do
              expect(lua.send(:last_used_ship_address)).to eq nil
            end
          end
        end

        context "and an order without a ship address exists" do
          before { order }

          it "return nil" do
            expect(lua.send(:last_used_ship_address)).to eq nil
          end
        end

        context "when no orders exist" do
          it "returns nil" do
            expect(lua.send(:last_used_ship_address)).to eq nil
          end
        end
      end
    end
  end
end
