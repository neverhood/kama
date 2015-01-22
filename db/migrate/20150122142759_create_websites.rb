class CreateWebsites < ActiveRecord::Migration
  def change
    create_table :websites do |t|
      t.string :url
      t.integer :check_interval

      t.timestamps null: false
    end

    add_index :websites, :url, unique: true
  end
end
