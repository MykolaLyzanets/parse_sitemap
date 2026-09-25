# frozen_string_literal: true

class SiteUrl < ApplicationRecord
  belongs_to :site

  validates :url, presence: true
  validates :url_digest, presence: true, uniqueness: { scope: :site_id }

  before_validation :assign_url_digest

  private

  def assign_url_digest
    return if url.blank?

    self.url_digest = SiteUrls::Normalizer.digest(url)
  end
end
