require "./lib/api_parse"

class EventsController < ApplicationController

  before_action :get_event, only: [:show]
  def index
    if logged_in?
      @events = Event.all.uniq{|e| e.title}
    else
      redirect_to home_path
    end
  end

  def show

    @events =[]
    @events << @event
    @hash = Gmaps4rails.build_markers(@events) do |event, marker|
      marker.lat event.location.latitude
      marker.lng event.location.longitude
      marker.infowindow event.title + event.address
    end
    @events = @@search_results



  end

  def search
    empty_search

  end

  def info
    # byebug
    @event = @@search_results[params[:id].to_i]
    geo={}
    geo['lat'] = @event.location.latitude
    geo['lng'] = @event.location.longitude
    @event.location.neighborhood = geo_to_neighborhood(geo)
    @events =[]
    @events << @event
    @hash = Gmaps4rails.build_markers(@events) do |event, marker|
      marker.lat event.location.latitude
      marker.lng event.location.longitude
      marker.infowindow event.title + event.address
    end
  end

  def results
#if event.category == music // event.category == art
    @user = current_user
    geo = address_to_geo(params[:search])

    # binding.pry

    case params["search_type"]
    when "Art"
      data = nyartbeat_parse(geo, 0)
      @events_from_search = data["Events"]["Event"]
    when "Food"
      data = eventbrite(geo)
      @events_from_search = data["events"]
    when "Music"
      data = ticketmaster_parse(geo)
      @events_from_search = data["_embedded"]["events"]
    end


    # data = nyartbeat_parse(y, 0)
    # @events_from_search = data["Events"]["Event"]


    if @events_from_search == nil
      flash[:errors] = "Nothing found, please search again."
      redirect_to search_path
    else

      loc = Location.find_or_create_by(latitude:geo['lat'],longitude:geo['lng'])

      case params["search_type"]
      when "Art"
        art = Category.find_or_create_by(name: "Art")

        @events_from_search.each{|e| new_art_event(e,art,loc)} if @@search_results.empty?

      when "Food"
        food = Category.find_or_create_by(name: "Food")

        @events_from_search.each{|e| new_food_event(e, food, loc)} if @@search_results.empty?

      when "Music"
        music = Category.find_or_create_by(name:"Music")
        location = Location.find_or_create_by(latitude:geo['lat'],longitude:geo['lng'])

        @events_from_search.each{|e| new_music_event(e, music, location)} if @@search_results.empty?

      end


    # @events_from_search.each{|e| new_art_event(e)} if @@search_results.empty?

    @events = @@search_results
    redirect_to display_path
    end
  end

  def display
    @user = current_user
    @events = @@search_results
  end

  private


  def new_art_event(event, art, loc)

    hash = {}
    # byebug
    #Change category depending on event category.
    hash["title"]=event["Name"]
    hash["venue"]=event["Venue"]["Name"]
    hash["address"]=event["Venue"]["Address"]
    hash["description"]=event["Description"]
    hash["price"]=event["Venue"]["Price"]
    hash["date"]=Date.strptime(event["DateStart"]).strftime('%a, %B %d, %Y') + " to " +  Date.strptime(event["DateEnd"]).strftime('%a, %B %d, %Y')
    hash["hours"]=Time.strptime(event["Venue"]["OpeningHour"],'%H:%M').strftime('%l:%M %p')+" - "+Time.strptime(event["Venue"]["ClosingHour"],'%H:%M').strftime('%l:%M %p')
    hash["location"] = loc
    hash["category"] = art
    # byebug
    new_event= Event.new(hash)
    @@search_results << new_event
  end


  def new_food_event(event, food, loc)
    # binding.pry
    hash = {}
    hash["title"]=event["name"]["text"]
    # hash["venue"]=event["Venue"]["Name"]
    hash["address"]=event["venue"]["address"]["localized_address_display"]
    hash["description"]=event["description"]["text"]
    start_time = event["start"]["local"].split("T")
    end_time = event["end"]["local"].split("T")

    hash["date"]=Date.strptime(start_time[0]).strftime('%a, %B %d, %Y') + " to " +  Date.strptime(end_time[0]).strftime('%a, %B %d, %Y')
    hash["hours"]=Time.strptime(start_time[1],'%H:%M').strftime('%l:%M %p')+" - "+Time.strptime(end_time[1],'%H:%M').strftime('%l:%M %p')
    hash["price"]=" "
    loc.latitude = event["venue"]["address"]["latitude"].to_f
    loc.longitude = event["venue"]["address"]["longitude"].to_f

    hash["category"] = food
    hash["location"] = loc

    new_event= Event.new(hash)
    @@search_results << new_event
  end

  def new_music_event(event, music, location)
    hash = {}
    
    hash["title"]=event["name"]
    hash["venue"]=event["_embedded"]["venues"][0]["name"]
    hash["address"]=event["_embedded"]["venues"][0]["address"]["line1"]
    hash["description"]=event["url"]
    hash["price"]="$" + event["priceRanges"][0]["min"].to_s + "0" + " to " + "$" + event["priceRanges"][0]["max"].to_s + "0"
    hash["date"]=Date.strptime(event["dates"]["start"]["localDate"]).strftime('%a, %B %d, %Y') + " to " +  Date.strptime(event["dates"]["start"]["localDate"]).strftime('%a, %B %d, %Y')
    hash["hours"]=Time.strptime(event["dates"]["start"]["localTime"],'%H:%M').strftime('%l:%M %p')
    hash["category"] = music
    location.longitude = event["_embedded"]["venues"][0]["location"]["longitude"]
    location.latitude = event["_embedded"]["venues"][0]["location"]["latitude"]
    hash["location"] = location


    new_event= Event.new(hash)
    @@search_results << new_event

  end

  def get_event
    @event = Event.find(params[:id])
  end
end
