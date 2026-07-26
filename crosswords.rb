require "date"
require "json"
require "net/http"

class NYT
  API = "https://www.nytimes.com/svc"

  ProbablyNotAuthed = Class.new(StandardError)

  # Raised when there is nothing to save for a date: either the NYT hasn't
  # published a crossword for it, or the crossword is published but unstarted,
  # so it has no solve state yet. Callers that walk a range of dates should
  # treat this as "come back later" rather than as a failure.
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
    if state.nil?
      raise PuzzleNotFound,
        "The #{date} crossword (puzzle #{id}) has no saved state. " \
        "Solve it, then fetch the date again."
    end

    state.fetch("game_data")
  end

  private

  def get(path)
    uri = URI("#{API}/#{path}")
    Net::HTTP.get_response(uri, {cookie: "NYT-S=#@nyt_s"})
  end

  def puzzle_id(date)
    load_puzzles(date) unless @puzzles.has_key?(date)

    puzzle = @puzzles[date]
    id = puzzle && puzzle.fetch("puzzle_id")
    raise PuzzleNotFound, "The NYT hasn't published a crossword for #{date}." if id.nil?

    id
  end

  # Caches every puzzle the NYT lists for the three months starting after the
  # latest date already cached, which covers `date` as long as callers walk
  # forward in time. Dates the NYT doesn't list stay absent from the cache.
  def load_puzzles(date)
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
    results = json.fetch("results") or return

    @puzzles.merge!(results.map {|result|
      [Date.parse(result.fetch("print_date")), result]
    }.to_h)
  end
end
