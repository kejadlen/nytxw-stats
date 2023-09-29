require "date"
require "json"
require "net/http"

class NYT
  API = "https://www.nytimes.com/svc/crosswords"

  def initialize(nyt_s)
    @nyt_s = nyt_s
    @puzzles = {}
  end

  def fetch(date)
    id = puzzle_id(date)
    return nil if id.nil?

    uri = URI("#{API}/v6/game/#{id}.json")
    JSON.parse(Net::HTTP.get(uri, {cookie: "NYT-S=#@nyt_s"}))
  end

  private

  def puzzle_id(date)
    return @puzzles.fetch(date).fetch("puzzle_id") if @puzzles.has_key?(date)

    last_date = @puzzles.keys.sort.last || date - 1
    date_start = last_date + 1
    date_end = date_start >> 3 # 3 months

    uri = URI("#{API}/v3/55348624/puzzles.json?date_start=#{date_start}&date_end=#{date_end}")
    json = JSON.parse(Net::HTTP.get(uri))
    results = json.fetch("results")
    return nil if results.nil?

    @puzzles.merge!(results.map {|result|
      [Date.parse(result.fetch("print_date")), result]
    }.to_h)

    @puzzles.fetch(date).fetch("puzzle_id")
  end
end
