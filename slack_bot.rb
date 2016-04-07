# -*- encoding : utf-8 -*-
require 'awesome_print'
require 'json'
require 'httparty'
require 'pry'
require 'yaml'

class SlackBot

  attr_reader :channel_id, :token, :members, :web_team

  AWAY_LIMIT = 90 * 60 # 90 分鐘
  ROOT_DIR = File.dirname(__FILE__)
  DATA_DIR = "#{ROOT_DIR}/_data"

  def initialize
    cfg = YAML::load(File.open("#{ROOT_DIR}/settings.yml"))
    settings = cfg['slack_settings']
    @channel_id = settings['channel_id']
    @token = settings['token']
    @members = settings['members']
    @web_team = settings['web_team_channel']
    @history = {}
  end

  def daily_channels_history(day = Date.today.prev_day)
    @history[day.strftime] ||= begin
                                 file = "#{DATA_DIR}/channels_history_#{day.strftime}.json"
                                 dump_daily_history!(day) unless File.exists?(file)
                                 res = File.read("#{DATA_DIR}/channels_history_#{day.strftime}.json")
                                 JSON.parse(res, symbolize_names: true)
                               end
  end

  def users_latest_activities(refresh: false)
    dump_daily_history!(Date.today) if refresh
    return @activities if @activities
    @activities = {}
    daily_channels_history(Date.today).each do |msg|
      user = msg[:user]
      next if @activities[user]
      next unless @members.include?(user)
      @activities[user] = { message: msg[:text], ts: msg[:ts], user: msg[:user] }
    end
    @activities
  end

  def check_is_away
    now = Time.now.to_i
    away_users = users_latest_activities.select { |user, act| (now - act[:ts].to_i) > AWAY_LIMIT }
    offline_users = members - users_latest_activities.keys
    return unless away_users.keys.count > 0 || offline_users.count > 0
    away_users_msg = away_users.values.map do |act|
      time = Time.at(act[:ts].to_i).strftime('%Y-%m-%d %H:%M:%S')
      "使用者 <@#{act[:user]}> 已超過 90 分鐘沒發動態，最後動態時間：#{time}"
    end.join("\n")
    offline_users_msg = offline_users.map do |user|
      "使用者 <@#{user}> 今日尚未上線"
    end.join("\n")
    post(away_users_msg + offline_users_msg)
    # puts(away_users_msg + offline_users_msg)
  end

  def reports(user, day: Date.today.prev_day) # U054KRJP5: manic
    report = daily_channels_history(day).select do |msg|
      msg[:user] == user && 
        msg[:ts].to_i > day.to_time.to_i &&
        msg[:text] =~ /^【/
    end.reverse.map do |msg| 
      time = Time.at(msg[:ts].to_i).strftime('%H:%M')
      "[#{time}] #{format_text_for_report(msg[:text])}"
    end.join("\n")
    day_format = day.strftime
    msg = <<MSG
研發部 #{nickname(user)} #{day_format} 工作日誌
#{report}
MSG
  end

  def send_reports(day: Date.today.prev_day, channel: channel_id)
    dump_daily_history!(day)
    msg = members.map do |m|
      reports(m, day: day)
    end.join("-------------\n")
    #puts msg
    post(msg, channel: channel)
  end

  def format_text_for_report(text)
    mapped_members.each do |member_id, name|
      text.gsub!(/<@#{member_id}>/, name)
    end
    text
  end

  def post(message, channel: channel_id)
    options = { channel: channel, token: token }
    options.merge!({ username: '動態機器人', text: message })
    execute('chat.postMessage', :post, body: options)
  end

  def delete(ts)
    options = { channel: channel_id, token: token }
    options.merge!(ts: ts)
    execute('chat.delete', :post, body: options)
  end

  def nickname(user_id)
    users_list[:members].find { |m| m[:id] == user_id }[:name]
  end

  def mapped_members
    @mapped_members ||= begin
                          ret = {}
                          users_list[:members].each do |m|
                            ret[m[:id]] = m[:name]
                          end
                          ret
                        end
  end

  def cache_data!
    FileUtils.mkdir_p(DATA_DIR)
    File.write("#{DATA_DIR}/channels_info.json", fetch('channels.info'))
    File.write("#{DATA_DIR}/users_list.json", fetch('users.list'))
  end

  def dump_daily_history!(day = Date.today.prev_day)
    FileUtils.mkdir_p(DATA_DIR)
    oldest = day.to_time.to_i
    latest = oldest + 86400
    ret = fetch('channels.history', latest: latest, oldest: oldest, count: 1000)
    messages = JSON.parse(ret, symbolize_names: true)[:messages]
    File.write("#{DATA_DIR}/channels_history_#{day.strftime}.json", messages.to_json)
  end

  def channels_info
    res = File.read("#{DATA_DIR}/channels_info.json")
    JSON.parse(res, symbolize_names: true)
  end

  def users_list
    res = File.read("#{DATA_DIR}/users_list.json")
    JSON.parse(res, symbolize_names: true)
  end

  # 刪除過期的提醒訊息
  def clean_bot_notice(day = Date.today.prev_day)
    dump_daily_history!(day)
    res = File.read("#{DATA_DIR}/channels_history_#{day.strftime}.json")
    data = JSON.parse(res, symbolize_names: true)
    data.select { |d| d[:subtype] == 'bot_message' && (d[:text] =~ /沒發動態|尚未上線/ ) }.each { |d| delete(d[:ts]) }
  end

  private

  def url(action)
    "https://slack.com/api/#{action}"
  end

  def fetch(action, other_options = {})
    options = { channel: channel_id, token: token }.merge(other_options)
    execute(action, :get, query: options).body
  end

  def execute(action, method = :get, options = {})
    HTTParty.send(method, url(action), options)
  end
end