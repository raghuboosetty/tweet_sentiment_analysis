module DataMine::Twitter
  extend self
  URL="https://www.twitter.com/"
  
  
  def follower_ratio(user)
    ratio = 0.0
    if user.friends_count > 0
      ratio = (user.followers_count.to_f/user.friends_count.to_f).round(2)
    end
    ratio
  end
  
  def topics(tweets='')
    stop_words = %w(a d i w an at be do if in is it me my on of rt so to and for its the was you does that this your there)
    tweets = tweets.gsub(/(@|#)\w+/i, '') # remove mentions & hashtags
    tweets = tweets.gsub(/[^a-zA-Z0-9' ]/,"") # remove special chars
    tweets = tweets.strip.downcase.split(/ /) # split to words
    tweets = tweets - stop_words # remove rubbish words
    tweets = tweets.group_by(&:to_s).map{|w| { w[0] => w[1].count }} # group and count
    tweets = tweets.reduce(Hash.new, :merge) # make a hash
    # tweets = tweets.sort_by { |k, v| v }.reverse # sort the hash
    # tweets = Hash[tweets] # array to hash
    tweets
  end  
  
  def users_profile_images(client, screen_names=[])
    users_profile_hash = {}
    client.users(screen_names).each do |user|
      users_profile_hash[user.screen_name] = user.profile_image_url
      Rails.logger.debug "\n#{user.screen_name}.upcase : #{user.id}"
    end
    users_profile_hash
  end
  
  def analysis(tweets)
    # 0 - hashtags
    # 1 - mentions
    # 2 - replies
    # 3 - retweets
    # 4 - sources
    # 5 - tweettime
    analysis_count = 6
    analysis_arr = [[]]
    analysis_count.times do |i|
      analysis_arr[i] = []
    end    
    retweets_count = 0
    replies_count  = 0
    tweet_hour = Hash.new(0)
    
    # tweet sentiment
    negative = 0
    neutral = 0
    positive = 0
    overall_sentiment = ''
    prob_sentiment = Hash.new(0.0) # probability of sad/happy
    
    tweets.each do |tweet|
      # Rails.logger.debug "\n\n TWEET INSPECT: #{tweet.inspect}\n\n"      
      # analysis_arr[1] += tweet.scan(/@(\w+)/i).flatten # direct scan
      # analysis_arr[0] += tweet.scan(/(?:^|\s)#(\w+)/i).flatten # direct scan
      analysis_arr[0] += tweet.hashtags.map{|m| m[:text]}      
      analysis_arr[1] += tweet.user_mentions.map{|m| m[:screen_name]}
      if !tweet.in_reply_to_user_id.nil?
        analysis_arr[2] += [tweet.in_reply_to_screen_name]
        replies_count += 1
      end
      if tweet.retweet?
        analysis_arr[3].push tweet.retweeted_status.user.screen_name
        retweets_count += 1
      end
      
      source = tweet.source
      source = (source.scan(/<a.+?href="(.+?)".+?/).flatten[0]) || source
      analysis_arr[4].push(source)
      
      tweet_hour[tweet.created_at.to_datetime.hour] += 1
        
      # SentimentData Attitude  
      sentiment = analyze_sentiment(tweet.text)
      if sentiment == 0
        negative += 1
      elsif sentiment == 1
        neutral += 1
      elsif sentiment == 2
        positive += 1
      end
      
      # SentimentData Probability(Happy/Sad)
      happy_prob, sad_prob = sentiment_probability(tweet.text)
      prob_sentiment[:happy] += happy_prob
      prob_sentiment[:sad] += sad_prob
    end
    
    if positive >= negative && (positive + negative) != 0
      overall_sentiment = " #{@name} has a #{((100.0 * positive) / (positive + negative)).round(0)}\% positive sentiment."
    elsif (positive + negative) != 0
      overall_sentiment = "#{@name} has a #{((100.0 * negative) / (positive + negative)).round(0)}\% negative sentiment."
    else
      overall_sentiment = "#{@name} has a neutral sentiment."
    end
        
    prob_sentiment[:happy] = prob_sentiment[:happy]/tweets.count
    prob_sentiment[:sad] = prob_sentiment[:sad]/tweets.count
        
    result_arr = []
    (analysis_count-1).times do |i|
      result_arr[i] = ordered_hash(analysis_arr[i])
    end
    result_arr.push(tweet_hour)
    result_arr.push(overall_sentiment)
    result_arr.push(prob_sentiment)
    result_arr
  end
  
  def ordered_hash(arr)
    ohash = Hash.new(0)
    arr = arr.reject(&:blank?)
    arr.each { |item| ohash[item] += 1 } # count items
    ohash = sort_hash(ohash, 'v')
    ohash
  end
  
  def sort_hash(ohash, kv='k')
    if kv == 'v'
      ohash = ohash.sort_by { |k, v| v }
      ohash = ohash.reverse
    else
      ohash = ohash.sort_by { |k, v| k }
    end
    Hash[ohash]
  end
  
  def sentiment_probability(text)
    happy_sentihash, sad_sentihash = SentimentData.twittersentihash
    # tokenize the text
    text = text.gsub(/[^a-zA-Z0-9' ]/,"") # remove special chars
    tokens = text.split

    happy_prob_total = 0.0
    sad_prob_total   = 0.0
    
    for token in tokens do
      happy_prob_value = happy_sentihash[token]
      happy_prob_total += happy_prob_value if happy_prob_value
      sad_prob_value = sad_sentihash[token]
      sad_prob_total += sad_prob_value if sad_prob_value
      # Rails.logger.debug "\n #{token} - #{sentiment_value}"
    end
    prob_happy = 1/(Math.exp(sad_prob_total - happy_prob_total) + 1)
    prob_sad = 1 - prob_happy
    
    [prob_happy, prob_sad]
    # [happy_prob_total, sad_prob_total]
  end
  
  
  def analyze_sentiment(text)
    sentihash = SentimentData.slanghash
    sentihash.merge!(SentimentData.wordhash)
  
    # tokenize the text
    tokens = text.split

    # Check the sentiment value of each token against the sentihash.
    # Since each word has a positive or negative numeric sentiment value
    # we can just sum the values of all the sentimental words. If it is
    # positive then we say the tweet is positive. If it is negative we 
    # say the tweet is negative.
    sentiment_total = 0.0
    
    for token in tokens do
      sentiment_value = sentihash[token]
      sentiment_total += sentiment_value if sentiment_value
      # Rails.logger.debug "\n #{token} - #{sentiment_value}"
    end
  
    # threshold for classification
    threshold = 0.0

    # if less then the negative threshold classify negative
    if sentiment_total < (-1 * threshold)
      return 0
    # if greater then the positive threshold classify positive
    elsif sentiment_total > threshold
      return 2
    # otherwise classify as neutral
    else
      return 1
    end
  end  
end  