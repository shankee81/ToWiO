class AddUpdatedAtToVariant < ActiveRecord::Migration
  def up
    change_table(:spree_variants) { |t| t.datetime :updated_at }
  end

  def down
    change_table(:spree_variants) { |t| t.remove :updated_at }
  end
end
