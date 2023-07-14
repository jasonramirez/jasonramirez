class CreateInterests < ActiveRecord::Migration[4.2]
  def change
    create_table :interests do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
