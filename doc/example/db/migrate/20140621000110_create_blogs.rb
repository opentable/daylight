class CreateBlogs < ActiveRecord::Migration[4.2]
  def change
    create_table :blogs do |t|
      t.string  :name
      t.text    :description
      t.integer :company_id
    end
  end
end
