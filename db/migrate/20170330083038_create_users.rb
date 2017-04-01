class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string   :name
      t.string   :email
      t.string   :phone
      t.text     :address
      t.string   :avatar_url
      t.integer  :status,                       default: 0
      t.string   :password_digest
      t.timestamps
    end
    add_index :users, :email
  end
end
