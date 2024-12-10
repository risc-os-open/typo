class AddPageTitle < ActiveRecord::Migration[7.1]
  def self.up
    add_column :pages, :title, :string
  end

  def self.down
    remove_column :pages, :title
  end
end
