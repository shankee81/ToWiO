class RemoveCarts < ActiveRecord::Migration
  def up
    remove_column :spree_orders, :cart_id
    drop_table :carts
  end

  def down
    create_table :carts do |t|
      t.integer :user_id
    end

    add_column :spree_orders, :cart_id, :integer
  end
end
