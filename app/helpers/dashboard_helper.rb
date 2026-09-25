# frozen_string_literal: true

module DashboardHelper
  def dashboard_scan_status_badge(status)
    label = {
      'completed' => 'Завершено',
      'failed' => 'Помилка',
      'pending' => 'Очікує',
      'running' => 'Виконується'
    }[status.to_s] || status.to_s
    css = case status.to_s
          when 'completed' then 'dash-badge--success'
          when 'failed' then 'dash-badge--danger'
          else 'dash-badge--muted'
          end

    content_tag(:span, label, class: "dash-badge #{css}")
  end

  def dashboard_delta_badge(count, kind:)
    return content_tag(:span, '—', class: 'dash-delta dash-delta--muted') if count.zero?

    prefix = kind == :added ? '+' : '−'
    css = kind == :added ? 'dash-delta--added' : 'dash-delta--removed'
    content_tag(:span, "#{prefix}#{number_with_delimiter(count)}", class: "dash-delta #{css}")
  end

  def dashboard_format_time(time)
    return '—' unless time

    l(time, format: :dashboard)
  end

  def dashboard_number(value)
    number_with_delimiter(value)
  end
end
