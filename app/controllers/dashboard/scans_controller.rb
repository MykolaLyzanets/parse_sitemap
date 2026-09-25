# frozen_string_literal: true

module Dashboard
  class ScansController < BaseController
    def show
      @site = SitesRepository.find(params[:site_id])
      @scan = ScansRepository.find(params[:site_id], params[:id])

      return render 'dashboard/shared/not_found', status: :not_found unless @site && @scan

      @change_type = params.fetch(:tab, 'added')
      @url_page = ScansRepository.urls_page(
        params[:site_id],
        params[:id],
        change_type: @change_type,
        page: params[:page]
      )
    end
  end
end
