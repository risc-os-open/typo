class DropSessionsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :sessions
  end
end
