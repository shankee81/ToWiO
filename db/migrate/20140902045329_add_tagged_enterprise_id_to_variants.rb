class AddTaggedEnterpriseIdToVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :tagged_enterprise_id, :integer

    add_index :spree_variants, :tagged_enterprise_id
    add_foreign_key :spree_variants, :enterprises, column: :tagged_enterprise_id
  end
end
