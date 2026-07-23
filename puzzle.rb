require "json"

# A saved crossword record. Two on-disk formats exist: puzzles saved before the
# 2026 NYT endpoint change hold the legacy v6/game response, which nests the
# solve time under `calcs`; puzzles saved after hold the crossword_daily game
# state, which exposes it as `playTimeSeconds`. The two are mutually exclusive
# (only the legacy shape has `calcs`, only the game state has
# `completionFraction`), so `Puzzle.from` can pick the class that understands a
# record from its schema alone, and raise on anything it doesn't recognize.
module Puzzle
  def self.load(path)
    from(JSON.parse(File.read(path)))
  end

  def self.from(data)
    if data.key?("calcs")
      Legacy.new(data)
    elsif data.key?("completionFraction")
      GameState.new(data)
    else
      raise ArgumentError, "unrecognized puzzle schema: #{data.keys.inspect}"
    end
  end

  # The legacy v6/game response, retired mid-2026.
  class Legacy
    def initialize(data)
      @data = data
    end

    # Seconds spent solving, or nil if the puzzle has no recorded solve time.
    def solve_seconds
      @data.dig("calcs", "secondsSpentSolving")
    end
  end

  # The crossword_daily game state that replaced the v6/game response.
  class GameState
    def initialize(data)
      @data = data
    end

    # Seconds spent solving, or nil if the puzzle has no recorded solve time.
    def solve_seconds
      @data.fetch("playTimeSeconds", nil)
    end
  end
end
