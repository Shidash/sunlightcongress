require "httparty"
require "json"

class SunlightCongress
  def initialize(apikey)
    @apikey = apikey
  end

  # Get legislator ID
  def legislator_id(name)
    options = {:query => {:apikey => @apikey} }
    namearray = name.split(" ")
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/legislators?query="+namearray.last, options)["results"]

    data.each do |l| 
      dhash = Hash[*l.flatten]
      if data.length > 1
        return dhash["bioguide_id"] if dhash["first_name"] == namearray.first
      else return dhash["bioguide_id"]
      end
    end
  end

  # Get all votes by particular congressperson
  def get_votes(id)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/votes?voter_ids." + id.to_s + "__exists=true", options)["results"]
    return data.to_json
  end

  # Get all amendments sponsored by a congressperson
  def get_amendments(id)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/amendments?sponsor_type=person&sponsor_id=" + id.to_s , options)["results"]
    return data.to_json
  end

  # Get all bills sponsored by a congressperson
  def get_bills(id)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/bills?sponsor_id=" + id.to_s , options)["results"]
    return data.to_json
  end

  # Get all floor updates that mention a congressperson
  def get_updates(id)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/floor_updates?legislator_ids=" + id.to_s , options)["results"]
    return data.to_json
  end

  # Get all committees a congressperson is on
  def get_committees(id)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/committees?member_ids=" + id.to_s , options)["results"]
    return data.to_json
  end

  # Get all hearings for a committee
  def get_hearings(cid)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/hearings?committee_id=" + cid.to_s , options)["results"]
    return data.to_json
  end

  # Get hearings for a particular committee (JSON input)
  def get_hearings_json(json_input)
    jinput = JSON.parse(json_input)
    savedata = Array.new

    jinput.each do |l|
      jhash = Hash[*l.flatten]
      cid = jhash["committee_id"]
      savedata = savedata + JSON.parse(get_hearings(cid))
    end
    return savedata.to_json
  end

  # Get all events (hearings, votes, bills, amendments, floor updates) for a congressperson and output JSON
  def get_events(id)
    votes = JSON.parse(get_votes(id))
    amendments = JSON.parse(get_amendments(id))
    bills = JSON.parse(get_bills(id))
    updates = JSON.parse(get_updates(id))
    hearings = JSON.parse(get_hearings_json(get_committees(id)))

    combinedata = votes + amendments + bills + updates + hearings
    combinedata.to_json
  end
end
