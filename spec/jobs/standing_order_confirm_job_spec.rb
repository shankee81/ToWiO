require 'spec_helper'

describe StandingOrderConfirmJob do
  let(:job) { StandingOrderConfirmJob.new }

  describe "finding proxy_orders that are ready to be confirmed" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_close_at: 59.minutes.ago, updated_at: 1.day.ago) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop, orders_close_at: 61.minutes.ago, updated_at: 1.day.ago) }
    let(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order1) { create(:standing_order, shop: shop, schedule: schedule) }
    let(:standing_order2) { create(:standing_order, shop: shop, schedule: schedule, paused_at: 1.minute.ago) }
    let(:standing_order3) { create(:standing_order, shop: shop, schedule: schedule, canceled_at: 1.minute.ago) }
    let!(:proxy_order1) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle2, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # OC Closed > 1 hour ago
    let!(:proxy_order2) { create(:proxy_order, standing_order: standing_order2, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Standing Order Paused
    let!(:proxy_order3) { create(:proxy_order, standing_order: standing_order3, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Standing Order Cancelled
    let!(:proxy_order4) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago), canceled_at: 1.minute.ago) } # Cancelled
    let!(:proxy_order5) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order)) } # Order Incomplete
    let!(:proxy_order6) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: nil) } # No Order
    let!(:proxy_order7) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: nil, order: create(:order, completed_at: 1.minute.ago)) } # Not Placed
    let!(:proxy_order8) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, confirmed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # Already Confirmed
    let!(:proxy_order9) { create(:proxy_order, standing_order: standing_order1, order_cycle: order_cycle1, placed_at: 5.minutes.ago, order: create(:order, completed_at: 1.minute.ago)) } # OK

    it "returns proxy orders that meet the criteria" do
      proxy_orders = job.send(:proxy_orders)
      expect(proxy_orders).to include proxy_order9
      expect(proxy_orders).to_not include proxy_order1, proxy_order2, proxy_order3, proxy_order4
      expect(proxy_orders).to_not include proxy_order5, proxy_order6, proxy_order7, proxy_order8
    end
  end

  describe "performing the job" do
    context "when unconfirmed proxy_orders exist" do
      let!(:proxy_order) { create(:proxy_order) }

      before do
        proxy_order.initialise_order!
        allow(job).to receive(:proxy_orders) { ProxyOrder.where(id: proxy_order.id) }
        allow(job).to receive(:process)
      end

      it "marks confirmable proxy_orders as processed by setting confirmed_at" do
        expect{job.perform}.to change{proxy_order.reload.confirmed_at}
        expect(proxy_order.confirmed_at).to be_within(5.seconds).of Time.now
      end

      it "processes confirmable proxy_orders" do
        job.perform
        expect(job).to have_received(:process).with(proxy_order.reload.order)
      end
    end
  end

  describe "finding recently closed order cycles" do
    let!(:order_cycle1) { create(:simple_order_cycle, orders_close_at: 61.minutes.ago, updated_at: 61.minutes.ago) }
    let!(:order_cycle2) { create(:simple_order_cycle, orders_close_at: nil, updated_at: 59.minutes.ago) }
    let!(:order_cycle3) { create(:simple_order_cycle, orders_close_at: 61.minutes.ago, updated_at: 59.minutes.ago) }
    let!(:order_cycle4) { create(:simple_order_cycle, orders_close_at: 59.minutes.ago, updated_at: 61.minutes.ago) }
    let!(:order_cycle5) { create(:simple_order_cycle, orders_close_at: 1.minute.from_now) }

    it "returns closed order cycles whose orders_close_at or updated_at date is within the last hour" do
      order_cycles = job.send(:recently_closed_order_cycles)
      expect(order_cycles).to include order_cycle3, order_cycle4
      expect(order_cycles).to_not include order_cycle1, order_cycle2, order_cycle5
    end
  end

  describe "processing an order" do
    let(:shop) { create(:distributor_enterprise) }
    let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
    let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
    let(:schedule1) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
    let(:standing_order1) { create(:standing_order, shop: shop, schedule: schedule1, with_items: true) }
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order1) }
    let(:order) { proxy_order.initialise_order! }

    before do
      while !order.completed? do break unless order.next! end
      allow(job).to receive(:send_confirm_email).and_call_original
    end

    it "sends only a standing order confirm email, no regular confirmation emails" do
      ActionMailer::Base.deliveries.clear
      expect{job.send(:process, order)}.to_not enqueue_job ConfirmOrderJob
      expect(job).to have_received(:send_confirm_email).with(order).once
      expect(ActionMailer::Base.deliveries.count).to be 1
    end
  end
end
