# -*- encoding : utf-8 -*-
every 30.minutes do
  root = File.absolute_path("#{File.dirname(__FILE__)}/../")
  command "#{root}/bin/refresh_today_history"
end
