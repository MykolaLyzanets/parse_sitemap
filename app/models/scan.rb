# frozen_string_literal: true

class Scan < ApplicationRecord
  belongs_to :site

  mount_uploader :added_urls_snapshot, SnapshotUploader
  mount_uploader :removed_urls_snapshot, SnapshotUploader

  enum status: {
    pending: 'pending',
    running: 'running',
    completed: 'completed',
    failed: 'failed'
  }

  validates :started_at, presence: true

  scope :chronological, -> { order(finished_at: :desc, started_at: :desc) }
  scope :completed, -> { where(status: :completed) }

  def scanned_at
    finished_at || started_at
  end
end
