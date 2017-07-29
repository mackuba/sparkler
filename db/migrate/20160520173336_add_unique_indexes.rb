class AddUniqueIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :properties, :name, unique: true
    add_index :options, [:property_id, :name], unique: true
  end
end
