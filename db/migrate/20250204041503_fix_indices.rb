class FixIndices < ActiveRecord::Migration[8.0]
  def change
    add_index :feedback, [:type, :article_id]

    add_index :articles_tags, :tag_id
    add_index :articles_tags, :article_id

    add_index :categorizations, :category_id
    add_index :contents,        :user_id
    add_index :sidebars,        :blog_id
  end
end
