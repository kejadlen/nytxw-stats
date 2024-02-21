#!/usr/bin/env ruby

require "date"
require "json"

def data
  return enum_for(__method__) unless block_given?

  Dir["data/*.json"].each do |file|
    yield Date.parse(File.basename(file, ".json")), JSON.parse(File.read(file))
  end
end

solve_times = data.each.with_object(Hash.new {|h,k| h[k] = [] }) {|(date, datum), times|
  next unless solve_time = datum.fetch("calcs", {}).fetch("secondsSpentSolving", nil)
  times[date.year] << solve_time
}

solve_times.each do |year, times|
  total = times.sum

  m, s = total.divmod(60)
  h, m = m.divmod(60)
  [h, m, s]

  puts "%d: %02d:%02d:%02d" % [year, h, m, s]
end
