# frozen_string_literal: true

class Site < ApplicationRecord
  mount_uploader :snapshot, SnapshotUploader

  has_many :scans, dependent: :destroy
  has_many :site_urls, dependent: :destroy

  validates :domain, presence: true, uniqueness: true
end
