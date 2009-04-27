xml.instruct!
xml.rss :version => "2.0" do
	xml.channel do
		xml.title "All replies to: " + @target[:link]
		xml.description @target[:body]
		xml.link "http://tweeplies.qwe3.com" + @my_rss
		xml.generator "http://tweeplies.qwe3.com"
		xml.lastBuildDate @last_time.httpdate()
		xml.pubDate Time.now.httpdate()
		
		@all_reply_links.each do |link_hash|
			xml.item do
				xml.title "Reply from @" + link_hash[:name]
				xml.description "&quot;" + link_hash[:body] + "&quot; [<a href=\"http://twitter.com/home?in_reply_to=" + link_hash[:name] + "&in_reply_to_status_id=" + link_hash[:sid] + "&status=%40" + link_hash[:name] + "\">reply</a>] [<a href=\"" + link_hash[:link] + "\">link</a>]"
				xml.link link_hash[:link]
				xml.guid link_hash[:link]
				xml.pubDate link_hash[:time].httpdate()
			end
		end
		
	end
end  
