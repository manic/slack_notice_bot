dirname = File.dirname(File.absolute_path(__FILE__))

msg = <<MSG
0,30 * * * * /bin/bash -l -c '#{dirname}/bin/refresh_today_history' >> #{dirname}/log/bot.log 2>&1
0 6 * * 2-6 /bin/bash -l -c '#{dirname}/bin/report_yesterday' >> #{dirname}/log/bot.log 2>&1
0 5 * * 2-6 /bin/bash -l -c '#{dirname}/bin/clean_bot_notice_yesterday' >> #{dirname}/log/bot.log 2>&1
MSG

puts msg
