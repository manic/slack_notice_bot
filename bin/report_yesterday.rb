require File.join(File.dirname(__FILE__), '..', 'slack_bot')

puts 'Start sending yesterday reports'
obj = SlackBot.new
obj.send_reports(day: Date.today.prev_day)
obj.send_reports(day: Date.today.prev_day, channel: obj.web_team)
puts 'End sending reports'
