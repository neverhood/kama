class CreateChecks < ActiveRecord::Migration
  def change
    create_table :checks do |t|
      t.integer :website_id
      t.integer :response_code

      t.timestamps null: false
    end
  end
end
