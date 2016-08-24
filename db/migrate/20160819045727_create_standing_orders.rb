class CreateStandingOrders < ActiveRecord::Migration
  def change
    create_table :standing_orders do |t|
      t.references :shop, null: false, index: true
      t.references :customer, null: false, index: true
      t.references :schedule, null: false, index: true
      t.references :payment_method, null: false, index: true
      t.references :shipping_method, null: false, index: true
      t.datetime :begins_at, :ends_at
      t.timestamps
    end

    add_foreign_key :standing_orders, :enterprises, name: 'oc_standing_orders_shop_id_fk', column: :shop_id
    add_foreign_key :standing_orders, :customers, name: 'oc_standing_orders_customer_id_fk'
    add_foreign_key :standing_orders, :schedules, name: 'oc_standing_orders_schedule_id_fk'
    add_foreign_key :standing_orders, :spree_payment_methods, name: 'oc_standing_orders_payment_method_id_fk', column: :payment_method_id
    add_foreign_key :standing_orders, :spree_shipping_methods, name: 'oc_standing_orders_shipping_method_id_fk', column: :shipping_method_id
  end
end
