require 'spec_helper'

describe EnterpriseFee do
  describe "associations" do
    it { should belong_to(:enterprise) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "callbacks" do
    it "removes itself from order cycle coordinator fees when destroyed" do
      ef = create(:enterprise_fee)
      oc = create(:simple_order_cycle, coordinator_fees: [ef])

      ef.destroy
      oc.reload.coordinator_fee_ids.should be_empty
    end

    it "removes itself from order cycle exchange fees when destroyed" do
      ef = create(:enterprise_fee)
      oc = create(:simple_order_cycle)
      ex = create(:exchange, order_cycle: oc, enterprise_fees: [ef])

      ef.destroy
      ex.reload.exchange_fee_ids.should be_empty
    end
  end

  describe "scopes" do
    describe "finding per-item enterprise fees" do
      it "does not return fees with FlatRate and FlexiRate calculators" do
        create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new)
        create(:enterprise_fee, calculator: Spree::Calculator::FlexiRate.new)

        EnterpriseFee.per_item.should be_empty
      end

      it "returns fees with any other calculator" do
        ef1 = create(:enterprise_fee, calculator: Spree::Calculator::DefaultTax.new)
        ef2 = create(:enterprise_fee, calculator: Spree::Calculator::FlatPercentItemTotal.new)
        ef3 = create(:enterprise_fee, calculator: Spree::Calculator::PerItem.new)
        ef4 = create(:enterprise_fee, calculator: Spree::Calculator::PriceSack.new)

        EnterpriseFee.per_item.should match_array [ef1, ef2, ef3, ef4]
      end
    end

    describe "finding per-order enterprise fees" do
      it "returns fees with FlatRate and FlexiRate calculators" do
        ef1 = create(:enterprise_fee, calculator: Spree::Calculator::FlatRate.new)
        ef2 = create(:enterprise_fee, calculator: Spree::Calculator::FlexiRate.new)

        EnterpriseFee.per_order.should match_array [ef1, ef2]
      end

      it "does not return fees with any other calculator" do
        ef1 = create(:enterprise_fee, calculator: Spree::Calculator::DefaultTax.new)
        ef2 = create(:enterprise_fee, calculator: Spree::Calculator::FlatPercentItemTotal.new)
        ef3 = create(:enterprise_fee, calculator: Spree::Calculator::PerItem.new)
        ef4 = create(:enterprise_fee, calculator: Spree::Calculator::PriceSack.new)

        EnterpriseFee.per_order.should be_empty
      end
    end
  end

  describe "clearing all enterprise fee adjustments for a line item" do
    let(:p) { create(:simple_product) }
    let(:line_item) { create(:line_item, product: p) }
    let(:ef1) { create(:enterprise_fee) }
    let(:ef2) { create(:enterprise_fee) }

    it "clears adjustments originating from many different enterprise fees" do
      ef1.create_adjustment('foo1', line_item.order, line_item, true)
      ef2.create_adjustment('foo2', line_item.order, line_item, true)

      expect do
        EnterpriseFee.clear_all_adjustments_for line_item
      end.to change(line_item.order.adjustments, :count).by(-2)
    end

    it "does not clear adjustments originating from another source" do
      tax_rate = create(:tax_rate, calculator: build(:calculator, preferred_amount: 10))
      tax_rate.create_adjustment('foo', line_item.order, line_item)

      expect do
        EnterpriseFee.clear_all_adjustments_for line_item
      end.to change(line_item.order.adjustments, :count).by(0)
    end
  end

  describe "clearing all enterprise fee adjustments on an order" do
    let(:order) { create(:order) }
    let(:line_item1) { create(:line_item, order: order) }
    let(:line_item2) { create(:line_item, order: order) }
    let(:ef1) { create(:enterprise_fee) }
    let(:ef2) { create(:enterprise_fee) }
    let(:ef3) { create(:enterprise_fee) }
    let(:ef4) { create(:enterprise_fee) }
    let(:efa) { OpenFoodNetwork::EnterpriseFeeApplicator.new(ef1, nil, 'coordinator') }
    let(:tax_rate) { create(:tax_rate, calculator: stub_model(Spree::Calculator)) }

    it "clears adjustments from many fees and on all line items" do
      ef1.create_adjustment('foo1', line_item1.order, line_item1, true)
      ef2.create_adjustment('foo2', line_item1.order, line_item1, true)
      ef3.create_adjustment('foo3', line_item2.order, line_item2, true)
      ef4.create_adjustment('foo4', line_item2.order, line_item2, true)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(-4)
    end

    it "clears adjustments from per-order fees" do
      efa.create_order_adjustment(order)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(-1)
    end

    it "does not clear adjustments from another originator" do
      order.adjustments.create({:amount => 12.34,
                                :source => order,
                                :originator => tax_rate,
                                :locked => true,
                                :label => 'hello' }, :without_protection => true)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(0)
    end
  end
end
