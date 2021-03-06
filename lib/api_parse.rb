require 'rest-client'
require 'json'
require 'net/http'
require 'active_support'
require 'active_support/core_ext'
require 'pry'


def parse_api(link)
  data ={}
  raw_data = RestClient.get(link)
  data = JSON.parse(raw_data)
  # binding.pry
end

#{geo['lat']}#{geo['lng']}
def nyartbeat_parse(geo , free=1)
  link = "http://www.nyartbeat.com/list/event_searchNear?latitude=#{geo['lat']}&longitude=#{geo['lng']}&SearchRange=3000m&MaxResults=10&SortOrder=distance&free=#{free}"
  s = Net::HTTP.get_response(URI.parse(link)).body
  # binding.pry
  data = JSON.parse(Hash.from_xml(s).to_json)
end

def ticketmaster_parse(geo)
  link = "https://app.ticketmaster.com/discovery/v2/events.json?classificationName=music&latlong=#{geo['lat']},#{geo['lng']}&apikey=9uklioBkyS6ApmJyfrI10SXV5CLNZP32"
  s = Net::HTTP.get_response(URI.parse(link)).body
  data = JSON.parse(s)
  #data["_embedded"]["events"][0]
end

def eventbrite(geo, sort="distance", category="food", range="10mi")


  api_key = 'TVBPW6RABWSC73XMYW5Y'

  url = "https://www.eventbriteapi.com/v3/events/search/?sort_by=#{sort}&expand=organizer,venue&location.latitude=#{geo['lat']}&location.longitude=#{geo['lng']}&start_date.keyword=this_week&location.within=#{range}&subcategories=10003&token=#{api_key}"
  # binding.pry
  data = parse_api(url)

end



def address_to_geo(address)
  geo= {}
  geo['lat'] = 40.7319579
  geo['lng'] = -73.9768964
  # byebug
  link = 'https://maps.googleapis.com/maps/api/geocode/json?address='
  key= '&key=AIzaSyB8y9s45xVG7OAhCdYa14p80sQBEiKEgV8'
  address = "nyc "+address.gsub(' ', '+')
  link = link + address + key
  data = parse_api(link)
  # binding.pry
  if data['results'].count > 0
    data['results'][0]['geometry']['location']
  else
    geo
  end
end


def address_to_geo_v2(address)
  link = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address="
  address = address.gsub(' ', '+')
  link = link + address
  data = parse_api(link)
  # binding.pry
  if data['results'].count > 0
    data['results'][0]['geometry']['location']
  else
    geo
  end
end

def geo_to_address(geo)
  link = 'https://maps.googleapis.com/maps/api/geocode/json?latlng='
  key= '&key=AIzaSyB8y9s45xVG7OAhCdYa14p80sQBEiKEgV8'
  link = link + geo['lat'].to_s + ","+ geo['lng'].to_s + key
  data = parse_api(link)
  data["results"][0]["formatted_address"]
end

def geo_to_neighborhood(geo)
  link = 'https://maps.googleapis.com/maps/api/geocode/json?latlng='
  key= '&key=AIzaSyB8y9s45xVG7OAhCdYa14p80sQBEiKEgV8'
  link = link + geo['lat'].to_s + ","+ geo['lng'].to_s + key
  data = parse_api(link)
  n=data["results"][0]["address_components"].select{|c| c.values.flatten.include?("neighborhood")}
  n=data["results"][0]["address_components"].select{|c| c.values.flatten.include?("locality")} if n.empty?
  n=data["results"][0]["address_components"].select{|c| c.values.flatten.include?("political")} if n.empty?

  # binding.pry
  n[0]["long_name"]
end



# geo= {}
# geo['lat'] = 40.7319579
# geo['lng'] = -73.9768964
# eventbrite(geo)

# geo= {}
# geo['lat'] = 40.7319579
# geo['lng'] = -73.9768964

# puts geo_to_address(geo)
# puts geo_to_neighborhood(geo)
#
y = address_to_geo_v2(" NYC Washington St & Front St, Brooklyn, NY 11201")
puts y
# puts nyartbeat_parse(y, 0)
