TweetStream.configure do |config|
  config.consumer_key       = AppConfig.twitter.consumer_key
  config.consumer_secret    = AppConfig.twitter.consumer_secret
  config.oauth_token        = AppConfig.twitter.access_token
  config.oauth_token_secret = AppConfig.twitter.access_token_secret
  config.auth_method        = :oauth
end