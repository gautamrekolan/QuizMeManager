class Post < ActiveRecord::Base
	belongs_to :question
	belongs_to :account
	has_many :mentions

	def repost_tweet
		account = Account.find(self.account_id)
		Post.tweet(account, self.text, self.question.url, "repost", self.question_id)
	end

	def self.shorten_url(url, source, lt, campaign)
		authorize = UrlShortener::Authorize.new 'o_29ddlvmooi', 'R_4ec3c67bda1c95912185bc701667d197'
    shortener = UrlShortener::Client.new authorize
    url = shortener.shorten("#{url}?s=#{source}&lt=#{lt}&c=#{campaign}").urls
    url
	end

	def self.tweet(current_acct, tweet, url, lt, question_id)
		short_url = Post.shorten_url(url, 'twi', lt, current_acct.twi_screen_name)
    res = current_acct.twitter.update("#{tweet} #{short_url}")
    Post.create(:account_id => current_acct.id,
                :question_id => question_id,
                :provider => 'twitter',
                :text => tweet,
                :url => short_url,
                :link_type => lt,
                :post_type => 'status',
                :provider_post_id => res.id.to_s)
  end

  def self.dm(current_acct, tweet, url, lt, question_id, user_id)
  	short_url = Post.shorten_url(url, 'twi', lt, current_acct.twi_screen_name) if url
    res = current_acct.twitter.direct_message_create(user_id, "#{tweet} #{short_url if short_url}")
    Post.create(:account_id => current_acct.id,
                :question_id => question_id,
                :to_twi_user_id => user_id,
                :provider => 'twitter',
                :text => tweet,
                :url => url.nil? ? nil : short_url,
                :link_type => lt,
                :post_type => 'dm',
                :provider_post_id => res.id.to_s)
  end

  def self.dm_new_followers(current_acct)
    new_followers = current_acct.twitter.follower_ids.ids.first(10).to_set
    messaged = current_acct.posts.where(:provider => 'twitter',
                            :post_type => 'dm').collect(&:to_twi_user_id).to_set
    to_message = new_followers - messaged

    to_message.each do |id|
			Post.dm(current_acct,
							"Here's your first question: How many base pairs make a codon? ", 
							"http://www.studyegg.com/review/112/10187", 
							"dm",
							21,
							id)
			sleep(1)
    end
  end
	# def self.get_old_tweets(current_acct)
	# 	client = current_acct.twitter
	# 	posts = client.user_timeline(current_acct.twi_screen_name, {:count => 100, :exclude_replies => true})
	# 	posts.each do |p|
	# 		q = nil
	# 		msg = p.text
	# 		hashtag = msg =~ /#/
	# 		if hashtag
	# 			sp = msg.index(/ /,hashtag)
	# 			sp = -1 if sp.nil?
	# 			question_id = msg.slice(hashtag+1..sp).to_i
	# 			question_id = nil if question_id==0
	# 			q = Question.find_by_q_id(question_id) unless question_id.nil?
	# 		end

	# 		if q
	# 			post = Post.find_or_create_by_provider_post_id(p.id.to_s)
	# 			puts p.id
	# 			post.update_attributes(:account_id => current_acct.id,
	# 													 :provider => 'twitter',
	# 													 :text => p.text,
	# 													 :post_type => 'status',
	# 													 :question_id => q.id)
	# 		end
	# 	end
	# end
end
