# frozen_string_literal: true

module Dashboard
  class SitesRepository
    def self.all
      Site.order(:domain).map { |site| SiteMapper.to_dto(site) }
    end

    def self.find(id)
      site = Site.find_by(id: id)
      return unless site

      SiteMapper.to_dto(site)
    end
  end
end
