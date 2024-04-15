# frozen_string_literal: true

module Reports::ConsolidatedPageViewsBrowserDetection
  extend ActiveSupport::Concern

  class_methods do
    def report_consolidated_page_views_browser_detection(report)
      filters = %w[page_view_logged_in page_view_anon_browser page_view_anon_non_browser]

      report.modes = [:stacked_chart]

      data =
        DB.query(
          <<~SQL,
            SELECT
              date,
              SUM(CASE WHEN req_type = :page_view_logged_in THEN count ELSE 0 END) AS page_view_logged_in,
              SUM(CASE WHEN req_type = :page_view_anon_browser THEN count ELSE 0 END) AS page_view_anon_browser,
              SUM(
                CASE WHEN req_type = :page_view_anon THEN count
                    WHEN req_type = :page_view_crawler THEN count
                    WHEN req_type = :page_view_anon_browser THEN -count
                    ELSE 0
                END
              ) AS page_view_anon_non_browser
            FROM application_requests
            WHERE date >= :start_date AND date <= :end_date
            GROUP BY date
            ORDER BY date ASC
          SQL
          start_date: report.start_date,
          end_date: report.end_date,
          page_view_anon: ApplicationRequest.req_types[:page_view_anon],
          page_view_crawler: ApplicationRequest.req_types[:page_view_crawler],
          page_view_logged_in: ApplicationRequest.req_types[:page_view_logged_in],
          page_view_anon_browser: ApplicationRequest.req_types[:page_view_anon_browser],
        )

      report.data = [
        {
          req: "page_view_logged_in",
          label:
            I18n.t("reports.consolidated_page_views_browser_detection.xaxis.page_view_logged_in"),
          color: report.colors[0],
          data: data.map { |row| { x: row.date, y: row.page_view_logged_in } },
        },
        {
          req: "page_view_anon_browser",
          label:
            I18n.t(
              "reports.consolidated_page_views_browser_detection.xaxis.page_view_anon_browser",
            ),
          color: report.colors[1],
          data: data.map { |row| { x: row.date, y: row.page_view_anon_browser } },
        },
        {
          req: "page_view_anon_non_browser",
          label:
            I18n.t(
              "reports.consolidated_page_views_browser_detection.xaxis.page_view_anon_non_browser",
            ),
          color: report.colors[2],
          data: data.map { |row| { x: row.date, y: row.page_view_anon_non_browser } },
        },
      ]
    end
  end
end
