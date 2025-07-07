# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_07_090144) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "derivatives", force: :cascade do |t|
    t.bigint "instrument_id", null: false
    t.string "exchange", null: false
    t.string "segment", null: false
    t.string "security_id", null: false
    t.string "symbol_name", null: false
    t.string "display_name"
    t.string "isin"
    t.string "instrument"
    t.string "instrument_type"
    t.string "underlying_security_id"
    t.string "underlying_symbol"
    t.string "series"
    t.date "expiry_date"
    t.decimal "strike_price", precision: 15, scale: 5
    t.string "option_type"
    t.integer "lot_size"
    t.string "expiry_flag"
    t.decimal "tick_size", precision: 10, scale: 5
    t.string "asm_gsm_flag", default: ""
    t.string "asm_gsm_category"
    t.decimal "mtf_leverage", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instrument_id"], name: "index_derivatives_on_instrument_id"
    t.index ["security_id", "symbol_name", "exchange", "segment"], name: "index_derivatives_unique", unique: true
  end

  create_table "instruments", force: :cascade do |t|
    t.string "exchange", null: false
    t.string "segment", null: false
    t.string "security_id", null: false
    t.string "symbol_name"
    t.string "display_name"
    t.string "isin"
    t.string "instrument"
    t.string "instrument_type"
    t.string "underlying_symbol"
    t.string "underlying_security_id"
    t.string "series"
    t.integer "lot_size"
    t.decimal "tick_size", precision: 10, scale: 4
    t.string "asm_gsm_flag"
    t.string "asm_gsm_category"
    t.decimal "mtf_leverage", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instrument"], name: "index_instruments_on_instrument"
    t.index ["security_id", "symbol_name", "exchange", "segment"], name: "index_instruments_unique", unique: true
  end

  create_table "margin_requirements", force: :cascade do |t|
    t.string "requirementable_type", null: false
    t.bigint "requirementable_id", null: false
    t.decimal "buy_co_min_margin_per"
    t.decimal "sell_co_min_margin_per"
    t.decimal "buy_bo_min_margin_per"
    t.decimal "sell_bo_min_margin_per"
    t.decimal "buy_co_sl_range_max_perc"
    t.decimal "sell_co_sl_range_max_perc"
    t.decimal "buy_co_sl_range_min_perc"
    t.decimal "sell_co_sl_range_min_perc"
    t.decimal "buy_bo_sl_range_max_perc"
    t.decimal "sell_bo_sl_range_max_perc"
    t.decimal "buy_bo_sl_range_min_perc"
    t.decimal "sell_bo_sl_min_range"
    t.decimal "buy_bo_profit_range_max_perc"
    t.decimal "sell_bo_profit_range_max_perc"
    t.decimal "buy_bo_profit_range_min_perc"
    t.decimal "sell_bo_profit_range_min_perc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["requirementable_type", "requirementable_id"], name: "idx_margin_requirementable"
    t.index ["requirementable_type", "requirementable_id"], name: "index_margin_requirements_on_requirementable"
  end

  create_table "order_features", force: :cascade do |t|
    t.string "featureable_type", null: false
    t.bigint "featureable_id", null: false
    t.string "bracket_flag"
    t.string "cover_flag"
    t.string "buy_sell_indicator"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["featureable_type", "featureable_id"], name: "idx_order_featureable"
    t.index ["featureable_type", "featureable_id"], name: "index_order_features_on_featureable"
  end

  add_foreign_key "derivatives", "instruments"
end
