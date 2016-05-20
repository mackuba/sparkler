class AddUniqueIndexes < ActiveRecord::Migration
  def change
    add_index :properties, :name, unique: true
    add_index :options, [:property_id, :name], unique: true
  end
end
