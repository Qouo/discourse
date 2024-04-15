# frozen_string_literal: true

describe "request tracking", type: :system do
  before do
    ApplicationRequest.enable
    CachedCounting.reset
    CachedCounting.enable
  end

  after do
    CachedCounting.reset
    ApplicationRequest.disable
    CachedCounting.disable
  end

  it "tracks an anonymous visit correctly" do
    visit "/"

    try_until_success do
      CachedCounting.flush
      expect(ApplicationRequest.stats).to include(
        "page_view_anon_total" => 1,
        "page_view_anon_browser_total" => 1,
        "page_view_logged_in_total" => 0,
        "page_view_crawler_total" => 0,
      )
    end

    find(".nav-item_categories a").click

    try_until_success do
      CachedCounting.flush
      expect(ApplicationRequest.stats).to include(
        "page_view_anon_total" => 2,
        "page_view_anon_browser_total" => 2,
        "page_view_logged_in_total" => 0,
        "page_view_crawler_total" => 0,
      )
    end
  end

  it "tracks a crawler visit correctly" do
    # Can't change Selenium's user agent... so change site settings to make Discourse detect chrome as a crawler
    SiteSetting.crawler_user_agents += "|chrome"

    visit "/"

    try_until_success do
      CachedCounting.flush
      expect(ApplicationRequest.stats).to include(
        "page_view_anon_total" => 0,
        "page_view_anon_browser_total" => 0,
        "page_view_logged_in_total" => 0,
        "page_view_crawler_total" => 1,
      )
    end
  end

  it "tracks a logged-in session correctly" do
    sign_in Fabricate(:user)

    visit "/"

    try_until_success do
      CachedCounting.flush
      expect(ApplicationRequest.stats).to include(
        "page_view_anon_total" => 0,
        "page_view_anon_browser_total" => 0,
        "page_view_logged_in_total" => 1,
        "page_view_crawler_total" => 0,
      )
    end

    find(".nav-item_categories a").click

    try_until_success do
      CachedCounting.flush
      expect(ApplicationRequest.stats).to include(
        "page_view_anon_total" => 0,
        "page_view_anon_browser_total" => 0,
        "page_view_logged_in_total" => 2,
        "page_view_crawler_total" => 0,
      )
    end
  end
end
