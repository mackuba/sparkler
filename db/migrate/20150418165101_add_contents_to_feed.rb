class AddContentsToFeed < ActiveRecord::Migration
  def change
    add_column :feeds, :contents, :text
    add_column :feeds, :last_version, :string
    add_column :feeds, :load_error, :string
  end
end
