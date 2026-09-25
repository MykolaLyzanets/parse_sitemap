# frozen_string_literal: true

class CreateSitemapMonitoringTables < ActiveRecord::Migration[7.0]
  def change
    create_table :sites do |t|
      t.string :domain, null: false
      t.string :name
      t.string :sitemap_url
      t.text :notes

      t.timestamps
    end

    add_index :sites, :domain, unique: true

    create_table :scans do |t|
      t.references :site, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :total_count, null: false, default: 0
      t.integer :added_count, null: false, default: 0
      t.integer :removed_count, null: false, default: 0
      t.integer :unchanged_count, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :scans, %i[site_id finished_at]
    add_index :scans, %i[site_id status]

    create_table :site_urls do |t|
      t.references :site, null: false, foreign_key: true
      t.text :url, null: false
      t.string :url_digest, null: false, limit: 64
      t.datetime :first_seen_at
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :site_urls, %i[site_id url_digest], unique: true

    create_table :scan_url_changes do |t|
      t.references :scan, null: false, foreign_key: true
      t.references :site_url, null: false, foreign_key: true
      t.string :change_type, null: false

      t.timestamps
    end

    add_index :scan_url_changes, %i[scan_id site_url_id], unique: true
    add_index :scan_url_changes, %i[scan_id change_type]
    add_index :scan_url_changes, %i[site_url_id change_type]
  end
end
