# frozen_string_literal: true

module Dashboard
  module Pagination
    module_function

    def normalize_page(page)
      page = page.to_i
      page.positive? ? page : 1
    end

    def per_page
      Rails.application.config.x.dashboard.urls_per_page
    end

    def offset_for(page)
      (normalize_page(page) - 1) * per_page
    end

    def total_pages(total_count)
      return 0 if total_count.zero?

      (total_count.to_f / per_page).ceil
    end
  end
end
