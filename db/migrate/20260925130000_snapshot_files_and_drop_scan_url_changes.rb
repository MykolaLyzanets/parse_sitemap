# frozen_string_literal: true

class SnapshotFilesAndDropScanUrlChanges < ActiveRecord::Migration[7.0]
  def change
    add_column :sites, :snapshot, :string
    add_column :scans, :added_urls_snapshot, :string
    add_column :scans, :removed_urls_snapshot, :string

    drop_table :scan_url_changes, if_exists: true
  end
end
