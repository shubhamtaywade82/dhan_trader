class CreateOrderFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :order_features do |t|
      t.references :featureable, polymorphic: true, null: false
      t.string :bracket_flag   # Y / N
      t.string :cover_flag     # Y / N
      t.string :buy_sell_indicator
      t.timestamps
    end

    add_index :order_features,
              %i[featureable_type featureable_id],
              name: 'idx_order_featureable'
  end
end
