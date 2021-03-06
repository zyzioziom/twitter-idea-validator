class HomeController < ApplicationController
  before_action :authenticate_user!, only: [:dashboard]

  @@logger = Logger.new(STDOUT)

  def index

  end

  def dashboard
    @monitored_keywords = Keyword.where(user_id: current_user)
    @keyword = Keyword.new
  end

  def validate
    user = User.find 12
    query = params["query"]
    twitter = Twitter.new(user)

    # find last search by this user
    last_search = TwitterSearch.where(user_id: user.id, query: query).order("created_at").first

    # search twitter for given keyword, for tweets newer than in last search
    if last_search
      results = twitter.search_with_id(query, last_search.last_tweet_id)
    else
      results = twitter.search(query)
    end

    data = JSON.parse(results)

    Sentimental.load_defaults
    sentiment = Sentimental.new

    @@logger.info "#{data['statuses'].count} statuses found"

    data['statuses'].each do |status|
      if sentiment.get_score(status['text']) >= 0 && status['favorited'] == false
        twitter.favorite(status['id'])
        @@logger.info "Favorited: #{status['id']}, #{status['text']}"
      end
    end

    if data['statuses'].count > 0
      TwitterSearch.create(user_id: user.id, query: query, last_tweet_id: data['statuses'].first['id'])
    end
  end
end
