require "rubygems"
require "csv"
require 'sexmachine'
require 'oj'
require "multi_json"

detector = SexMachine::Detector.new

files = Dir.glob("./tweets/data/js/tweets/*.js")
users = {}

files.reverse.each do |file|
  hash = nil

  puts file
  open(file) do |f|
    str = f.read
    str.sub!(/^[^\n]+=/, '')
    hash = MultiJson.load(str)
  end

  hash.each do |tweet|
    next unless tweet["retweeted_status"]
    screen_name = tweet["retweeted_status"]["user"]["screen_name"]
    if !users.key?(screen_name)
      users[screen_name] = tweet["retweeted_status"]["user"].dup
      gender = detector.get_gender(tweet["retweeted_status"]["user"]["name"].gsub(/\s.+$/, ''))

      users[screen_name]["gender"] = case gender
      when :male, :mostly_male
        "male"
      when :female, :mostly_female
        "female"
      when :andy
        "none"
      end
    end
  end
end

CSV.open("tweets/retweeted_users.csv", "w") do |csv|
  csv << %w(username name gender_guess gender_actual)

  users.values.each do |row|
    csv << [row["screen_name"], row["name"], row["gender"], row["gender"]]
  end
end
