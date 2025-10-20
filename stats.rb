#!/usr/bin/env ruby

require "date"
require "json"

require "rake/ext/string"

def format_time(seconds)
  return "0s" if seconds == 0
  
  minutes = seconds.to_i / 60
  remaining_seconds = seconds.to_i % 60
  
  if minutes > 0
    "#{minutes}m#{remaining_seconds}s"
  else
    "#{remaining_seconds}s"
  end
end

def data
  return enum_for(__method__) unless block_given?

  Dir["data/**/*.json"].each do |file|
    yield Date.parse(file.pathmap("%d-%n")), JSON.parse(File.read(file))
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

puts "%-9s %8s %8s" % ["Day", "Mean", "StdDev"]
[*(1..6), 0].each do |wday|
  puts "%-9s %8s %8s" %
    [Date::DAYNAMES.fetch(wday), format_time(means.fetch(wday)), format_time(stddevs.fetch(wday))]
end

z_scores = last_year.to_h {|date, secs|
  mean = means.fetch(date.wday)
  stddev = stddevs.fetch(date.wday)
  [date, (secs - mean) / stddev]
}

puts
puts "%-21s %6s" % ["Date", "Z-Score"]
z_scores
  .sort_by { -_2 }[0,10]
  .each do |date, x|
    puts "%-22s %6.2f" % ["#{date} (#{Date::DAYNAMES.fetch(date.wday)})", x]
  end

puts
puts Date.today
puts z_scores.fetch(Date.today).round(2)
puts z_scores.fetch(Date.today - 7).round(2)

puts
puts "2025-10-18"
puts z_scores.fetch(Date.new(2025, 10, 18)).round(2)

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


