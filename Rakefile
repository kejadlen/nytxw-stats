require "date"
require "json"
require "logger"
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

desc "Fetch the crossword data for a given date"
task :fetch, [:date] do |t, args|
  date = Date.iso8601(args.fetch(:date))
  LOGGER.info("Fetching #{date}")

  nyt = NYT.new(ENV.fetch("NYT_S"))
  updated = nyt.fetch(date)
  return if updated.nil?
  fail if ["status"] == "ERROR"

  filename = "data/#{date.strftime("%Y/%m-%d")}.json"
  File.write(filename, JSON.dump(updated))
end
