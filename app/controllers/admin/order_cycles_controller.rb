require 'open_food_network/permissions'
require 'open_food_network/order_cycle_form_applicator'

module Admin
  class OrderCyclesController < ResourceController
    include OrderCyclesHelper

    prepend_before_filter :load_data_for_index, :only => :index
    before_filter :require_coordinator, only: :new
    before_filter :remove_protected_attrs, only: [:update]
    before_filter :remove_unauthorized_bulk_attrs, only: [:bulk_update]
    before_filter :check_editable_schedule_ids, only: [:create, :update]
    around_filter :protect_invalid_destroy, only: :destroy

    def index
      respond_to do |format|
        format.html
        format.json do
          render_as_json @collection, ams_prefix: params[:ams_prefix], current_user: spree_current_user
        end
      end
    end

    def show
      respond_to do |format|
        format.html
        format.json do
          render_as_json @order_cycle, current_user: spree_current_user
        end
      end
    end

    def new
      respond_to do |format|
        format.html
        format.json do
          render_as_json @order_cycle, current_user: spree_current_user
        end
      end
    end

    def create
      @order_cycle = OrderCycle.new(params[:order_cycle])

      respond_to do |format|
        if @order_cycle.save
          OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle, spree_current_user).go!

          flash[:notice] = 'Your order cycle has been created.'
          format.html { redirect_to admin_order_cycles_path }
          format.json { render :json => {:success => true} }
        else
          format.html
          format.json { render :json => {:success => false} }
        end
      end
    end

    def update
      @order_cycle = OrderCycle.find params[:id]

      respond_to do |format|
        if @order_cycle.update_attributes(params[:order_cycle])
          unless params[:order_cycle][:incoming_exchanges].nil? && params[:order_cycle][:outgoing_exchanges].nil?
            # Only update apply exchange information if it is actually submmitted
            OpenFoodNetwork::OrderCycleFormApplicator.new(@order_cycle, spree_current_user).go!
          end
          flash[:notice] = 'Your order cycle has been updated.' if params[:reloading] == '1'
          format.html { redirect_to main_app.edit_admin_order_cycle_path(@order_cycle) }
          format.json { render :json => {:success => true}  }
        else
          format.json { render :json => {:success => false} }
        end
      end
    end

    def bulk_update
      @order_cycle_set = params[:order_cycle_set] && OrderCycleSet.new(params[:order_cycle_set])
      if @order_cycle_set.andand.save
        respond_to do |format|
          order_cycles = OrderCycle.where(id: params[:order_cycle_set][:collection_attributes].map{ |k,v| v[:id] })
          format.json { render_as_json order_cycles, ams_prefix: 'index', current_user: spree_current_user }
        end
      else
        respond_to do |format|
          format.json { render :json => {:success => false}  }
        end
      end
    end

    def clone
      @order_cycle = OrderCycle.find params[:id]
      @order_cycle.clone!
      redirect_to main_app.admin_order_cycles_path, :notice => "Your order cycle #{@order_cycle.name} has been cloned."
    end

    # Send notifications to all producers who are part of the order cycle
    def notify_producers
      Delayed::Job.enqueue OrderCycleNotificationJob.new(params[:id].to_i)

      redirect_to main_app.admin_order_cycles_path, :notice => 'Emails to be sent to producers have been queued for sending.'
    end


    protected
    def collection
      return Enterprise.where("1=0") unless json_request?
      ocs = if params[:as] == "distributor"
        OrderCycle.preload(:schedules).ransack(params[:q]).result.
        involving_managed_distributors_of(spree_current_user).order('updated_at DESC')
      elsif params[:as] == "producer"
        OrderCycle.preload(:schedules).ransack(params[:q]).result.
        involving_managed_producers_of(spree_current_user).order('updated_at DESC')
      else
        OrderCycle.preload(:schedules).ransack(params[:q]).result.accessible_by(spree_current_user)
      end

      ocs.undated +
        ocs.soonest_closing +
        ocs.soonest_opening +
        ocs.closed
    end

    private
    def load_data_for_index
      if json_request?
        # Split ransack params into all those that currently exist and new ones to limit returned ocs to recent or undated
        orders_close_at_gt = params[:q].andand.delete(:orders_close_at_gt) || 31.days.ago
        params[:q] = {
          g: [ params.delete(:q) || {}, { m: 'or', orders_close_at_gt: orders_close_at_gt, orders_close_at_null: true } ]
        }
        @collection = collection
      end
    end

    def require_coordinator
      if params[:coordinator_id] && @order_cycle.coordinator = permitted_coordinating_enterprises_for(@order_cycle).find_by_id(params[:coordinator_id])
        return
      end

      available_coordinators = permitted_coordinating_enterprises_for(@order_cycle).select(&:confirmed?)
      case available_coordinators.count
      when 0
        flash[:error] = "None of your enterprises have permission to coordinate an order cycle"
        redirect_to main_app.admin_order_cycles_path
      when 1
        @order_cycle.coordinator = available_coordinators.first
      else
        flash[:error] = "You don't have permission to create an order cycle coordinated by that enterprise" if params[:coordinator_id]
        render :set_coordinator
      end
    end

    def protect_invalid_destroy
      begin
        yield
      rescue ActiveRecord::InvalidForeignKey
        redirect_to main_app.admin_order_cycles_url
        flash[:error] = "That order cycle has been selected by a customer and cannot be deleted. To prevent customers from accessing it, please close it instead."
      end
    end

    def remove_protected_attrs
      params[:order_cycle].delete :coordinator_id

      unless Enterprise.managed_by(spree_current_user).include?(@order_cycle.coordinator)
        params[:order_cycle].delete_if{ |k,v| [:name, :orders_open_at, :orders_close_at].include? k.to_sym }
      end
    end

    def remove_unauthorized_bulk_attrs
      if params.key? :order_cycle_set
        params[:order_cycle_set][:collection_attributes].each do |i, hash|
          order_cycle = OrderCycle.find(hash[:id])
          unless Enterprise.managed_by(spree_current_user).include?(order_cycle.andand.coordinator)
            params[:order_cycle_set][:collection_attributes].delete i
          end
        end
      end
    end

    def check_editable_schedule_ids
      return unless params[:order_cycle][:schedule_ids]
      requested = params[:order_cycle][:schedule_ids].map(&:to_i)
      existing = @order_cycle.schedule_ids
      permitted = Schedule.where(id: requested | existing).merge(OpenFoodNetwork::Permissions.new(spree_current_user).editable_schedules).pluck(:id)
      result = existing
      result |= (requested & permitted) # add any requested & permitted ids
      result -= ((result & permitted) - requested) # remove any existing and permitted ids that were not specifically requested
      params[:order_cycle][:schedule_ids] = result
    end

    def ams_prefix_whitelist
      [:basic, :index]
    end

    def collection_actions
      [:index, :bulk_update]
    end
  end
end
