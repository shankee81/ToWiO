class RemoveProductDistributionsOohYeah < ActiveRecord::Migration
  def up
    drop_table :product_distributions
  end

  def down
    create_table :product_distributions do |t|
      t.integer  :product_id
      t.integer  :distributor_id
      t.integer  :enterprise_fee_id
      t.timestamp
    end

    add_index :product_distributions, :product_id
    add_index :product_distributions, :distributor_id
    add_index :product_distributions, :enterprise_fee_id

    add_foreign_key :product_distributions, :spree_products, column: :product_id
    add_foreign_key :product_distributions, :enterprises, column: :distributor_id
    add_foreign_key :product_distributions, :enterprise_fees, column: :enterprise_fee_id
  end
end
