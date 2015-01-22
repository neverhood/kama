class CreateRecipients < ActiveRecord::Migration
  def change
    create_table :recipients do |t|
      t.string :name
      t.string :email, unique: true

      t.timestamps null: false
    end

    add_index :recipients, :email, unique: true
  end
end
