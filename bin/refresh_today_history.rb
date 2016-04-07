require File.join(File.dirname(__FILE__), '..', 'slack_bot')

wday = Date.today.wday
hour = Time.now.hour
puts "#{wday} #{hour}"
exit unless wday >= 1 && wday <= 5
exit unless hour >= 10 && hour <= 18

puts 'Start SlackBot'
obj = SlackBot.new
obj.dump_daily_history!(Date.today)
obj.check_is_away
puts 'End SlackBot'
