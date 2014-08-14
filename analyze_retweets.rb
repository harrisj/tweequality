require "rubygems"
require "csv"
require 'oj'
require "multi_json"
require "active_support/core_ext"

# load the gender determinations
genders = {}

miscat = {}
Time.zone = "Eastern Time (US & Canada)"

counts = {
  "male" => 0,
  "female" => 0,
  "none" => 0
}

CSV.foreach("tweets/retweeted_users.csv", :headers => true) do |row|
  gender = row["gender_actual"].strip
  guess = row["gender_guess"].strip
  genders[row["username"]] = gender

  counts[gender] += 1

  if guess != gender
    miscat_key = "#{guess}->#{gender}"
    miscat[miscat_key] ||= 0
    miscat[miscat_key] += 1
  end
end

puts "TOTAL USERS RETWEETED: #{genders.count}"
puts "MALE #{counts["male"]} FEMALE  #{counts["female"]} NONE #{counts["none"]}"

miscat_count = miscat.values.inject(0) {|sum, m| sum + m}
puts "MISCATEGORIZED: #{miscat_count} (#{"%0.2f%%" % (miscat_count * 100.0 / genders.count)})"
miscat.keys.sort.each do |k|
  puts "  #{k}: #{miscat[k]}"
end

puts "Loading tweets"

tweets = []

files = Dir.glob("./tweets/data/js/tweets/*.js")
files.reverse.each do |file|
  hash = nil

  puts file
  open(file) do |f|
    str = f.read
    str.sub!(/^[^\n]+=/, '')
    hash = MultiJson.load(str)
  end

  hash.each do |tweet|
    if tweet["retweeted_status"]
      tweets << tweet
    else
      tweets << {"id" => tweet["id"], "created_at" => tweet["created_at"]}
    end
  end
end

print "EXPANDING WINDOW TEST"

CSV.open("expanding.csv", "w") do |csv|
  csv << %w(Num RT Male Female None Pct)

  retweet_count = {"male" => 0, "female" => 0, "none" => 0}

  tweets.each_with_index do |tweet, i|
    if tweet["retweeted_status"]
      username = tweet["retweeted_status"]["user"]["screen_name"]
      raise "No gender found for #{username}" if genders[username].nil?

      raise "Weird gender #{genders[username]} for #{username}" if retweet_count[genders[username]].nil?

      retweet_count[genders[username]] += 1
    end

    if ((i + 1) % 100 == 0)
      total = retweet_count["male"] + retweet_count["female"] + retweet_count["none"]
      csv << [i+1,total,retweet_count["male"],retweet_count["female"],retweet_count["none"],"%0.4f" % (retweet_count["male"].to_f / (retweet_count["male"] + retweet_count["female"]))]
    end
  end
end

puts "... DONE"

print "SLIDING WINDOW TEST"
current_date = nil

CSV.open("sliding.csv", "w") do |csv|

  csv << %w(Offset Date RT Male Female None Pct)
  offset = 0

  # that is, the most recent 20,000
  tweets.first(50_000).reverse.each_cons(100) do |slice|
    tweet = slice.first

    raise "NULL DATE #{tweet["id"]}" if tweet["created_at"].blank?

    tweet_date = Time.parse(tweet["created_at"]).to_date


    if tweet_date != current_date
      retweet_count = {"male" => 0, "female" => 0, "none" => 0}

      slice.each do |tweet|
        if tweet["retweeted_status"]
          username = tweet["retweeted_status"]["user"]["screen_name"]
          raise "No gender found for #{username}" if genders[username].nil?
          raise "Weird gender #{genders[username]} for #{username}" if retweet_count[genders[username]].nil?
  
          retweet_count[genders[username]] += 1
        end
      end

      total = retweet_count["male"] + retweet_count["female"] + retweet_count["none"]
      pct = retweet_count["male"] + retweet_count["female"] > 0 ? (retweet_count["male"].to_f / (retweet_count["male"] + retweet_count["female"])) : 0.0
      csv << [offset, tweet_date.strftime("%Y-%m-%d"), total, retweet_count["male"], retweet_count["female"] , retweet_count["none"], "%0.4f" % pct]
      current_date = tweet_date
    end

    offset += 1
  end
end

puts "...DONE"

print "RANDOM SAMPLING TEST"

CSV.open("sample.csv", "w") do |csv|
  csv << %w(Run RT Male Female None Pct)

  (0..1000).each do |i|
    picks = Set.new

    while picks.size < 100
      p = rand(tweets.length)

      picks << p unless picks.include?(p)
    end

    retweet_count = {"male" => 0, "female" => 0, "none" => 0}

    picks.each do |p|
      tweet = tweets[p]

      if tweet["retweeted_status"]
          username = tweet["retweeted_status"]["user"]["screen_name"]
          raise "No gender found for #{username}" if genders[username].nil?
          raise "Weird gender #{genders[username]} for #{username}" if retweet_count[genders[username]].nil?
  
          retweet_count[genders[username]] += 1
      end
    end

    total = retweet_count["male"] + retweet_count["female"] + retweet_count["none"]
    pct = retweet_count["male"] + retweet_count["female"] > 0 ? (retweet_count["male"].to_f / (retweet_count["male"] + retweet_count["female"])) : 0.0
    csv << [i, total, retweet_count["male"], retweet_count["female"] , retweet_count["none"], "%0.4f" % pct]
  end
end

puts "...DONE"
