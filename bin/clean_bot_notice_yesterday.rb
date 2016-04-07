require File.join(File.dirname(__FILE__), '..', 'slack_bot')

puts 'Start cleaning yesterday bot notice'
obj = SlackBot.new
obj.clean_bot_notice(Date.today.prev_day)
puts 'End cleaning yesterday bot notice'
