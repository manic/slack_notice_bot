# 主要功能

1. 每半個小時來提醒 90 分鐘內沒有發動態的人
2. 每天早上6點，產生昨天的工作報表
3. 每天早上會清除前天的提醒訊息

##  Setup

1. 將 `settings.yml.ci` 改名為 `settings.yml` 並填上相關的設定
2. 將 `bin/ruby_source.ci` 改名為 `bin/ruby_source` 並填上你專屬的 rvm path
3. 執行 `ruby crontab.rb` 並把 output 放入自己的 crontab 裡
