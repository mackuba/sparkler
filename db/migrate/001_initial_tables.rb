class InitialTables < ActiveRecord::Migration[4.2]
  def change
    create_table :feeds do |t|
      t.string :title, :name, :url, null: false
    end

    create_table :properties do |t|
      t.string :name, null: false
    end

    create_table :values do |t|
      t.references :property, null: false
      t.string :name, null: false
    end

    create_table :statistics do |t|
      t.references :feed, null: false
      t.integer :year, :month, null: false
      t.references :property, null: false
      t.references :value, null: false
      t.integer :counter, null: false, default: 0
    end

    add_index :statistics, [:feed_id, :year, :month, :property_id, :value_id], unique: true, name: 'stats_index'
  end 
end
