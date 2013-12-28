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
  def get_votes(name)
    id = legislator_id(name)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/votes?voter_ids." + id.to_s + "__exists=true", options)["results"]
    return data.to_json
  end

  # Get all amendments sponsored by a congressperson
  def get_amendments(name)
    id = legislator_id(name)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/amendments?sponsor_type=person&sponsor_id=" + id.to_s , options)["results"]
    return data.to_json
  end

  # Get all bills sponsored by a congressperson
  def get_bills(name)
    id = legislator_id(name)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/bills?sponsor_id=" + id.to_s , options)["results"]
    return data.to_json
  end

  # Get all floor updates that mention a congressperson
  def get_updates(name)
    id = legislator_id(name)
    options = {:query => {:apikey => @apikey} }
    data = HTTParty.get("http://congress.api.sunlightfoundation.com/floor_updates?legislator_ids=" + id.to_s , options)["results"]
    return data.to_json
  end

  # Get all committees a congressperson is on
  def get_committees(name)
    id = legislator_id(name)
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
  def get_events(name)
    # Get votes
    votes = JSON.parse(get_votes(name))
    votearray = Array.new
    votes.each do |v|
      savehash = Hash.new
      vhash = Hash[*v.flatten]

      savehash["start time"] = vhash["voted_at"].to_s
      savehash["end time"] = nil
      savehash["headline"] = "Vote(" + id + "): " + vhash["question"].to_s
      savehash["text"] = "roll_type: " + vhash["roll_type"].to_s + " result: " + vhash["result"].to_s + " vote_type: " + vhash["vote_type"].to_s + " url: " + vhash["url"].to_s

      votearray.push(savehash)
    end
    
    # Get amendments
    amendments = JSON.parse(get_amendments(name))
    amendmentarray = Array.new
    amendments.each do |a|
      savehash = Hash.new
      ahash = Hash[*a.flatten]
      
      savehash["start time"] = ahash["introduced_on"].to_s
      savehash["end time"] = ahash["last_action_at"].to_s
      savehash["headline"] = "Amendment(" + id + "): " + ahash["purpose"].to_s
      savehash["text"] = "description: " + ahash["description"].to_s + " amends_bill_id: " + ahash["amends_bill_id"].to_s

      amendmentarray.push(savehash)
    end

    # Get bills
    bills = JSON.parse(get_bills(name))
    billarray = Array.new
    bills.each do |b|
      savehash = Hash.new
      bhash = Hash[*b.flatten]

      savehash["start time"] = bhash["introduced_on"].to_s
      savehash["end time"] = bhash["last_vote_at"].to_s
      savehash["headline"] = "Bill(" + id + "): " + bhash["short_title"].to_s
      savehash["text"] = "official_title: " + bhash["official_title"].to_s + " bill_id: " + bhash["bill_id"].to_s

      billarray.push(savehash)
    end
    
    # Get updates
    updates = JSON.parse(get_updates(name))
    updatearray = Array.new
    updates.each do |u|
      savehash = Hash.new
      uhash = Hash[*u.flatten]

      savehash["start time"] = uhash["timestamp"].to_s
      savehash["end time"] = nil
      savehash["headline"] = "Update(" + id + ")"
      savehash["text"] = "update: " + uhash["update"].to_s

      updatearray.push(savehash)
    end
    
    # Get hearings
    hearings = JSON.parse(get_hearings_json(get_committees(name)))
    hearingarray = Array.new
    hearings.each do |h|
      savehash = Hash.new
      hhash = Hash[*h.flatten]
      
      savehash["start time"] = hhash["occurs_at"].to_s
      savehash["end time"] = nil
      savehash["headline"] = "Committee Hearing(" + id + "): " + hhash["description"].to_s
      savehash["text"] = "committee_id: " + hhash["committee_id"].to_s + " url: " + hhash["url"].to_s
        
      hearingarray.push(savehash)
    end

    combinedata = votearray + amendmentarray + billarray + updatearray + hearingarray
    combinedata.to_json
  end
end
