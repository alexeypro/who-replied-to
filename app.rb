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
  @target = {}
  @target[:link] = params[:targetmessage]
  unless @target[:link] == nil || @target[:link].empty?
    # (not necessary /status/, but may be /statuses/, so .*?)
    all_match = (/twitter.com\/(.*?)\/.*?\/(.*)/).match(@target[:link].downcase)
    @target[:name] = all_match[1] unless all_match == nil
    @target[:sid] = all_match[2] unless all_match == nil    
    redirect '/problem' and return if all_match == nil

    # here we get all replies to author of target message (7 days is the limit)
    all_links = Array.new
    req = "http://search.twitter.com/search.atom?q=to:" + @target[:name] + "&rpp=1000&since_id=" + @target[:sid]
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
    req = @target[:link]
    begin
      open(req) do |f|
        data = f.read
        # get the body
        body_match = (/<span class="entry-content">(.*?)<\/span>/).match(data) unless data == nil
        @target[:body] = body_match[1].strip unless body_match == nil
        @target[:body] = "N/A" if body_match = nil
        # the body may contain @username, need to replace with good url
        @target[:body] = @target[:body].gsub(/@<a href=\"\//, "@<a href=\"http://twitter.com/")        
      end
    rescue
      # we can ignore here too, at least we'll show smth :-)
    end    
    
    @all_reply_links = Array.new
    all_links.each do |link|
      begin
        open(link) do |f|
          hash_data = {}
          hash_data[:link] = link
          data = f.read
          # get the body
          body_match = (/<span class="entry-content">(.*?)<\/span>/).match(data) unless data == nil
          hash_data[:body] = body_match[1].strip unless body_match == nil
          hash_data[:body] = "N/A" if body_match = nil
          # the body (as it is a reply) has @username, need to replace with good url
          hash_data[:body] = hash_data[:body].gsub(/@<a href=\"\//, "@<a href=\"http://twitter.com/")
          # get authors name (not necessary /status/, but may be /statuses/, so .*?)
          name_match = (/twitter.com\/(.*?)\/.*?\/(.*)/).match(link.downcase) 
          hash_data[:name] = name_match[1].strip unless name_match == nil
          hash_data[:name] = "unknown" if name_match == nil                    
          hash_data[:sid] = name_match[2].strip unless name_match == nil
          hash_data[:sid] = "0" if name_match == nil                              
          # now actually check if this is a reply
          search_string = "<a href=\"" + @target[:link] + "\">in reply to " + @target[:name] + "</a>"
          we_have_reply = data.downcase.index(search_string.downcase) unless data == nil
          @all_reply_links.push hash_data unless we_have_reply == nil
      	end
      rescue
        # ignore here
      end
    end  
  end  
  
  erb :who_replied_to
end
