require File.join(File.dirname(__FILE__), '..', 'slack_bot')

puts 'Start SlackBot'
obj = SlackBot.new(debug: true)
puts 'End SlackBot'
