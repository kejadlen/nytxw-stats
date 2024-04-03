#!/usr/bin/env ruby

require "date"
require "json"

def data
  return enum_for(__method__) unless block_given?

  Dir["data/*.json"].each do |file|
    yield Date.parse(File.basename(file, ".json")), JSON.parse(File.read(file))
  end
end

solve_times = data.to_h
  .transform_values { _1.fetch("calcs", {}).fetch("secondsSpentSolving", nil) }
  .reject { _2.nil? }

# solve_times
#   .group_by {|date,_| date.year }
#   .transform_values { _1.map(&:last) }
#   .each do |year, times|
#     total = times.sum

#     m, s = total.divmod(60)
#     h, m = m.divmod(60)
#     [h, m, s]

#     puts "%d: %02d:%02d:%02d" % [year, h, m, s]
#   end

(0..6).each do |wday|
  puts "SMTWTFS"[wday]
    solve_times
      .select {|date,_| date.wday == wday }
      .group_by {|date,_| date.year }
      .transform_values { _1.map(&:last) }
      .each do |year, times|
        total = times.sum / times.size

        m, s = total.divmod(60)
        h, m = m.divmod(60)
        [h, m, s]

        puts "%d: %02d:%02d:%02d" % [year, h, m, s]
      end
  puts
end

(0..6).each do |wday|
  times = solve_times
    .select {|date,_| date.wday == wday }
    .values
  total = times.sum / times.size
  m, s = total.divmod(60)
  h, m = m.divmod(60)
  [h, m, s]

  puts "%s: %02d:%02d:%02d" % ["SMTWTFS"[wday], h, m, s]
end
