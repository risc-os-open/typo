class IndexSessions < ActiveRecord::Migration[7.1]
  def self.up
    add_index :sessions, :sessid
  end

  def self.down
    remove_index :sessions, :sessid
  end
end
