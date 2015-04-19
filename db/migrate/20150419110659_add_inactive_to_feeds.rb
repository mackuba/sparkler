class AddInactiveToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :inactive, :boolean, null: false, default: false
  end
end
