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
  @target_message = params[:targetmessage]
  unless @target_message == nil || @target_message.empty?
    # (not necessary /status/, but may be /statuses/, so .*?)
    all_match = (/twitter.com\/(.*?)\/.*?\/(.*)/).match(@target_message.downcase)
    @target_name = all_match[1] unless all_match == nil
    @target_sid = all_match[2] unless all_match == nil    
    redirect '/problem' and return if all_match == nil

    # here we get all replies to author of target message (7 days is the limit)
    all_links = Array.new
    req = "http://search.twitter.com/search.atom?q=to:" + @target_name + "&rpp=1000&since_id=" + @target_sid
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
    
    # we want to get here the actual target message
    req = @target_message
    begin
      open(req) do |f|
        data = f.read
        # get the body
        body_match = (/<span class="entry-content">(.*?)<\/span>/).match(data) unless data == nil
        @target_body = body_match[1].strip unless body_match == nil
        @target_body = "N/A" if body_match = nil
        # the body may contain @username, need to replace with good url
        @target_body = @target_body.gsub(/@<a href=\"\//, "@<a href=\"http://twitter.com/")        
      end
    rescue
      # we can ignore here too, at least we'll show smth :-)
    end    
    
    @all_reply_links = Array.new
    @hash_with_body = {}
    @hash_with_name = {}    
    @hash_with_sid = {}
    all_links.each do |link|
      begin
        open(link) do |f|
          data = f.read
          # get the body
          body_match = (/<span class="entry-content">(.*?)<\/span>/).match(data) unless data == nil
          body_string = body_match[1].strip unless body_match == nil
          body_string = "N/A" if body_match = nil
          # the body (as it is a reply) has @username, need to replace with good url
          body_string = body_string.gsub(/@<a href=\"\//, "@<a href=\"http://twitter.com/")
          # get authors name (not necessary /status/, but may be /statuses/, so .*?)
          name_match = (/twitter.com\/(.*?)\/.*?\/(.*)/).match(link.downcase) 
          name_string = name_match[1].strip unless name_match == nil
          name_string = "unknown" if name_match == nil                    
          sid_value = name_match[2].strip unless name_match == nil
          sid_value = "0" if name_match == nil                              
          # now actually check if this is a reply
          search_string = "<a href=\"" + @target_message + "\">in reply to " + @target_name + "</a>"
          we_have_reply = data.downcase.index(search_string.downcase) unless data == nil
          @all_reply_links.push link unless we_have_reply == nil
          @hash_with_body[link] = body_string unless we_have_reply == nil
          @hash_with_name[link] = name_string unless we_have_reply == nil          
          @hash_with_sid[link] = sid_value unless we_have_reply == nil          
      	end
      rescue
        # ignore here
      end
    end  
  end  
  
  erb :who_replied_to
end
