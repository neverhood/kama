class CreateWebsites < ActiveRecord::Migration
  def change
    create_table :websites do |t|
      t.string :url
      t.integer :check_interval
      t.integer :recent_failures_count, default: 0
      t.boolean :active, default: true

      t.timestamps null: false
    end

    add_index :websites, :url, unique: true
  end
end
