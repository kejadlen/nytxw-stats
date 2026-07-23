require "date"
require "json"
require "net/http"

class NYT
  API = "https://www.nytimes.com/svc"

  ProbablyNotAuthed = Class.new(StandardError)
  PuzzleNotFound = Class.new(StandardError)

  def initialize(nyt_s)
    @nyt_s = nyt_s
    @puzzles = {}
  end

  def fetch(date)
    id = puzzle_id(date)

    resp = get("games/state/crossword_daily/latests?puzzle_ids=#{id}")
    raise ProbablyNotAuthed if resp.code == "403"

    states = JSON.parse(resp.body).fetch("states")
    state = states.find {|s| s.fetch("puzzle_id").to_s == id.to_s }
    raise PuzzleNotFound if state.nil?

    state.fetch("game_data")
  end

  private

  def get(path)
    uri = URI("#{API}/#{path}")
    Net::HTTP.get_response(uri, {cookie: "NYT-S=#@nyt_s"})
  end

  def puzzle_id(date)
    return @puzzles.fetch(date).fetch("puzzle_id") if @puzzles.has_key?(date)

    last_date = @puzzles.keys.sort.last || date - 1
    date_start = last_date + 1
    date_end = date_start >> 3 # 3 months

    resp = get("crosswords/v3/55348624/puzzles.json?date_start=#{date_start}&date_end=#{date_end}")
    json = JSON.parse(resp.body)
    unless json.is_a?(Hash)
      raise ProbablyNotAuthed,
        "Expected a JSON object from the NYT puzzles API but got #{json.inspect}. " \
        "The NYT-S cookie is likely invalid or expired; refresh it and try again."
    end
    results = json.fetch("results")
    return nil if results.nil?

    @puzzles.merge!(results.map {|result|
      [Date.parse(result.fetch("print_date")), result]
    }.to_h)

    id = @puzzles.fetch(date).fetch("puzzle_id")
    raise PuzzleNotFound if id.nil?

    id
  end
end
