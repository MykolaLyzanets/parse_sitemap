# frozen_string_literal: true

module Dashboard
  class SitesController < BaseController
    def index
      @sites = SitesRepository.all
    end

    def show
      @site = SitesRepository.find(params[:id])
      return render_not_found unless @site

      @scans = ScansRepository.for_site(@site.id)
      @last_scan = ScansRepository.find(@site.id, @site.last_scan_id)
      @scan_running = Site.find(@site.id).scans.running.exists?
    end

    def start_scan
      site = Site.find_by(id: params[:id])
      return render_not_found unless site

      if site.scans.running.exists?
        redirect_to dashboard_site_path(site), alert: 'Сканування вже виконується.'
        return
      end

      Scans::RunJob.perform_later(site.id)
      Rails.logger.info("[Scan] site=#{site.domain} Сканування поставлено в чергу (user=#{current_user&.id})")
      redirect_to dashboard_site_path(site), notice: 'Сканування додано в чергу.'
    end

    def removed_urls
      @site = SitesRepository.find(params[:id])
      return render_not_found unless @site

      @removed_page = RemovedUrlsRepository.for_site(@site.id, page: params[:page])
    end

    private

    def render_not_found
      render 'dashboard/shared/not_found', status: :not_found
    end
  end
end
