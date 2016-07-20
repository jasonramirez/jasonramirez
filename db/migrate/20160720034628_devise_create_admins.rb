class DeviseCreateAdmins < ActiveRecord::Migration
  def change
    create_table(:admins) do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :admins, :email,                unique: true
  end
end
