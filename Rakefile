require "date"
require "json"
require "logger"
require "open3"
require_relative "crosswords"

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

desc "Bootstrap the crossword data from the given start year"
task :bootstrap, [:start] do |t, args|
  args.with_defaults(start: Date.today.year)
  start = args.start.to_i

  (start..Date.today.year).each do |year|
    from = Date.new(year, 1, 1)
    to = [(from >> 12) - 1, Date.today].min
    dates = (from..to).to_a

    existing_dates = FileList["data/**/*.json"]
      .pathmap("%-1d-%n")
      .map {|d| Date.iso8601(d) }
    (dates - existing_dates).each do |date|
      Rake::Task[:fetch].execute(date: date.iso8601)
    end
  end
end

desc "Backfill the crossword data for the last N days"
task :backfill, [:delta] do |t, args|
  args.with_defaults(delta: 7)
  delta = args.delta.to_i

  from = Date.today - delta
  to = Date.today
  (from..to).each do |date|
    Rake::Task[:fetch].execute(date: date.iso8601)
  end
end

desc "Refresh the NYT-S cookie and store it as the NYT_S GitHub secret"
task :cookie do
  require "ferrum"

  json, status = Open3.capture2("op", "item", "get", "New York Times", "--format", "json")
  raise "op item get failed" unless status.success?

  fields = JSON.parse(json).fetch("fields").to_h {|f| [f["purpose"], f["value"]] }

  # NYT login sits behind DataDome bot protection, so drive a real browser
  # (visible, so a CAPTCHA or 2FA prompt can be solved by hand) rather than
  # posting to the login endpoint directly.
  browser = Ferrum::Browser.new(headless: false, timeout: 120)
  begin
    browser.go_to("https://myaccount.nytimes.com/auth/login")

    (browser.at_css("input[name=email]") or raise "login page has no email field")
      .focus.type(fields.fetch("USERNAME"), :Enter)
    browser.network.wait_for_idle

    (browser.at_css("input[name=password]") or raise "no password field (CAPTCHA or 2FA?)")
      .focus.type(fields.fetch("PASSWORD"), :Enter)
    browser.network.wait_for_idle

    nyt_s = browser.cookies.all.fetch("NYT-S").value
  ensure
    browser.quit
  end

  LOGGER.info("Got cookie; updating NYT_S secret (#{nyt_s})")

  # gh reads the secret value from stdin; sh/system can't feed a child's
  # stdin, so Open3 pipes the cookie straight in — keeping it off the
  # command line (and the process list) and off disk.
  out, status = Open3.capture2("gh", "secret", "set", "NYT_S", stdin_data: nyt_s)
  raise "gh secret set failed: #{out}" unless status.success?

  LOGGER.info("Updated NYT_S secret")
end

desc "Fetch the crossword data for a given date"
task :fetch, [:date] do |t, args|
  date = Date.iso8601(args.fetch(:date))
  LOGGER.info("Fetching #{date}")

  nyt = NYT.new(ENV.fetch("NYT_S"))
  updated = nyt.fetch(date)

  dir = "data/#{date.year}"
  mkdir dir unless Dir.exist?(dir)

  filename = "data/#{date.strftime("%Y/%m-%d")}.json"
  File.write(filename, JSON.dump(updated))
end
