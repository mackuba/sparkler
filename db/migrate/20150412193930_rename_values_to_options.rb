class RenameValuesToOptions < ActiveRecord::Migration
  def change
    rename_table :values, :options
    rename_column :statistics, :value_id, :option_id
  end
end
