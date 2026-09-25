# frozen_string_literal: true

class AddScanUrlChangesPaginationIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :scan_url_changes,
              %i[scan_id change_type id],
              name: 'index_scan_url_changes_on_scan_type_id',
              algorithm: :concurrently
  end
end
