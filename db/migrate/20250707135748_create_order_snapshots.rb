class CreateOrderSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :order_snapshots do |t|
      t.integer :user_id
      t.string :dhan_order_id
      t.string :status
      t.jsonb :raw

      t.timestamps
    end
  end
end
