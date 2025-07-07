class CreateQuoteCaches < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_caches do |t|
      t.references :instrument, null: false, foreign_key: true
      t.datetime :tick_time
      t.decimal :ltp, precision: 15, scale: 5
      t.jsonb :ohlc

      t.timestamps
    end
  end
end
