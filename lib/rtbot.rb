require 'twitter'
require 'active_support'

class RTBot
  
  def initialize(yaml_file_path)
    @config = YAML.load(File.read(yaml_file_path))
    @config['last_id_path'] = "#{File.basename(yaml_file_path, File.extname(yaml_file_path))}.last_id" unless @config['last_id_path']
    @config['log_path'] = "#{File.basename(yaml_file_path, File.extname(yaml_file_path))}.log" unless @config['log_path']
    
    if File.exists?(@config['last_id_path'])
      @last_read_id = File.new(@config['last_id_path'], 'r').gets
    else
      @last_read_id = 1
    end
    
  end
  
  def test_run
    log = File.new(@config['log_path'], 'a')
    
    log.puts "Test run at #{Time.now}"
    
    search.each do | tweet |
      log.puts tweet_text = "RT @#{tweet.from_user}: #{tweet.text}".first(139)
    end  
    
    log.close
    
  end
  
  def run!
    @log = File.new(@config['log_path'], 'a')
    
    tweet authenticate, search
    
    @log.close
  end
  
  
  
  private
  
  def authenticate
    oauth = Twitter::OAuth.new(@config['consumer_key'], @config['consumer_secret'])
    oauth.authorize_from_access(@config['access_token'], @config['access_token_secret'])
    return oauth
  end
  
  def search
    Twitter::Search.new(@config['search_query']).since(@last_read_id).since_date(Date.today.strftime("%Y-%m-%d")).from(@config['bot_name'],true).to_a.reverse
  end
  
  def tweet(oauth,results)
    
    
    @log.puts Time.now
    
    results.each do | tweet |
      client = Twitter::Base.new(oauth)
      
      @log.puts tweet_text = "RT @#{tweet.from_user}: #{tweet.text}".first(139)
      client.update(tweet_text)
      @last_read_id = tweet.id
    end
    
    output = File.new(@config['last_id_path'], 'w')
    output.write @last_read_id
    output.close
    
  end
  
end