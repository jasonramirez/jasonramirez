class CreateFollowers < ActiveRecord::Migration[4.2]
  def change
    create_table :followers do |t|
      t.string :email

      t.timestamps null: false
    end
  end
end
