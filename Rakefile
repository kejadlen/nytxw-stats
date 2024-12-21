require "date"
require "json"
require "logger"
require_relative "crosswords"

@logger = Logger.new(STDOUT)
@logger.level = Logger::INFO
@nyt = NYT.new(ENV.fetch("NYT_S"))

def fetch(date)
  @logger.info("Fetching #{date}")
  @nyt.fetch(date)
end

def update(date)
  updated = fetch(date)
  return if updated.nil?
  fail if ["status"] == "ERROR"

  filename = "data/#{date.strftime("%Y/%m-%d")}.json"
  File.write(filename, JSON.dump(updated))
end

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
      update(date)
    end
  end
end

task :backfill, [:delta] do |t, args|
  args.with_defaults(delta: 7)
  delta = args.delta.to_i

  from = Date.today - delta
  to = Date.today
  (from..to).each do |date|
    update(date)
  end
end

raw = FileList["data/*.json"]
file "crosswords.json" => raw do |t|
  data = raw.each.with_object({}) {|path, data|
    date = File.basename(path, ".json")
    date_data = JSON.parse(File.read(path))
    data[date] = date_data
  }.map {|date, data|
    {
      date: date,
      revealedCount: data.fetch("board", {}).fetch("cells", []).count {|cell| cell.has_key?("revealed") },
      secondsSpentSolving: data.fetch("calcs", {}).fetch("secondsSpentSolving", nil),
      solved: data.fetch("calcs", {}).fetch("solved", false),
    }
  }

  File.write(t.name, JSON.dump(data))
end
