require 'open-uri'

namespace :fifa do
  desc "scrape events from FIFA site"
  task get_all_events: :environment do
    FIFA_SITE = "http://www.fifa.com/"
    MATCH_URL = FIFA_SITE + "worldcup/matches/index.html"
    matches = Nokogiri::HTML(open(MATCH_URL))
    matches.css(".col-xs-12 .mu").each do |match|
      fifa_id = match.first[1] #get unique fifa_id

      #get game events
      url = match.children[0]['href']
      next if url == nil
      match_info_page = Nokogiri::HTML(open(FIFA_SITE+url))
      home_events =  []
      away_events = []
      match_info_page.css("td.home").css(".event").each do |event|
        event_type = event.attributes["class"].value.gsub("event ","")
        player = event.parent.parent.parent.css('.p-n').text.titlecase
        event_hash = event.attributes["data-guid"].value
        home_events << [event_hash, player, event_type]
      end
      match_info_page.css("td.away").css(".event").each do |event|
        event_type = event.attributes["class"].value.gsub("event ","")
        player = event.parent.parent.parent.css('.p-n').text.titlecase
        event_hash = event.attributes["data-guid"].value
        away_events << [event_hash, player, event_type]
      end
      match = Match.find_or_create_by_fifa_id(fifa_id)
      home_events.each do |event_array|
        event = Event.find_or_create_by_fifa_id(event_array[0])
        event.player = event_array[1]
        event.type_of_event = event_array[2]
        event.home_team = true
        event.match_id = match.id
        event.save
      end

      away_events.each do |event_array|
        event = Event.find_or_create_by_fifa_id(event_array[0])
        event.player = event_array[1]
        event.type_of_event = event_array[2]
        event.home_team = false
        event.match_id = match.id
        event.save
      end

    end
  end
end