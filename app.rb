require "rubygems"
require "sinatra"
require "open-uri"

get '/' do
  erb :index
end

get '/results' do
  redirect '/'
end

get '/problem' do
  erb :problem
end

post '/results' do
  target_message = params[:targetmessage]
  unless target_message == nil || target_message.empty?
    all_match = (/twitter.com\/(.*?)\//).match(target_message.downcase)
    username = all_match[1] unless all_match == nil
    redirect '/problem' and return if all_match == nil

    all_links = Array.new
    req = "http://search.twitter.com/search.atom?q=to:" + username + "&rpp=1000"
    begin
      open(req) do |f|
    	  f.each_line do |line|
    		  status_mention_matches = (/<link type="text\/html" rel="alternate" href="(.*?)"/).match(line)
    		  status_mention_link = status_mention_matches[1] unless status_mention_matches == nil
    		  unless status_mention_link == nil || (/^http:\/\/search.twitter.com/).match(status_mention_link) != nil
    		    all_links.push status_mention_link 
    	    end
    	  end
      end
    rescue
      redirect '/problem'
      return
    end
    
    @all_reply_links = Array.new
    all_links.each do |link|
      begin
        open(link) do |f|
          data = f.read
          search_string = "<a href=\"" + target_message + "\">in reply to " + username + "</a>"
          we_have_reply = data.downcase.index(search_string) unless data == nil
          @all_reply_links.push link if we_have_reply != nil
      	end
      rescue
        # ignore here
      end
    end  
  end  
  
  erb :who_replied_to
end
