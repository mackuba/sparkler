class AddInactiveToFeeds < ActiveRecord::Migration[4.2]
  def change
    add_column :feeds, :inactive, :boolean, null: false, default: false
  end
end
