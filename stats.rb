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

last_year = solve_times
  .select {|k,_| k > Date.today.prev_year }

wday_times = last_year
  .group_by {|k,_| k.wday }
  .transform_values { _1.map(&:last) }

means = wday_times.transform_values {|secs| secs.sum / secs.size }
stddevs = wday_times
  .to_h {|wday, secs|
    mean = means.fetch(wday)
    [wday, Math.sqrt(secs.map { (_1 - mean) ** 2 }.sum / secs.size)]
  }

[*(1..6), 0].each do |wday|
  puts "#{wday}: #{means.fetch(wday)} #{stddevs.fetch(wday).round(2)}"
end

z_scores = last_year.to_h {|date, secs|
  mean = means.fetch(date.wday)
  stddev = stddevs.fetch(date.wday)
  [date, (secs - mean) / stddev]
}

z_scores
  .sort_by { -_2 }[0,10]
  .each do |date, x|
    puts "#{date} (#{date.wday}): #{x.round(2)}"
  end

puts z_scores.fetch(Date.today).round(2)
puts z_scores.fetch(Date.today - 7).round(2)

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

# (0..6).each do |wday|
#   puts "SMTWTFS"[wday]
#     solve_times
#       .select {|date,_| date.wday == wday }
#       .group_by {|date,_| date.year }
#       .transform_values { _1.map(&:last) }
#       .each do |year, times|
#         total = times.sum / times.size
#
#         m, s = total.divmod(60)
#         h, m = m.divmod(60)
#         [h, m, s]
#
#         puts "%d: %02d:%02d:%02d" % [year, h, m, s]
#       end
#   puts
# end
#
# (0..6).each do |wday|
#   times = solve_times
#     .select {|date,_| date.wday == wday }
#     .values
#   total = times.sum / times.size
#   m, s = total.divmod(60)
#   h, m = m.divmod(60)
#   [h, m, s]
#
#   puts "%s: %02d:%02d:%02d" % ["SMTWTFS"[wday], h, m, s]
# end


