# app/services/ip_location_service.rb
class IpLocationService
  BASE_URL = "https://ipinfo.io"

  def self.lookup(ip)
    new(ip).call
  end

  def initialize(ip)
    @ip = ip
  end

def call
  return stub_location if local_ip?

  Rails.cache.fetch("ip_location:#{@ip}", expires_in: 7.days) do
    response = HTTParty.get("#{BASE_URL}/#{@ip}/json", query: {
      token: ENV["IPINFO_API_KEY"]
    })
    parse(response)
  end
rescue StandardError => e
  Rails.logger.error "IpLocationService error for #{@ip}: #{e.message}"
  empty_location
end

  private

  def parse(response)
    data = response.parsed_response
    return empty_location if data["bogon"] || data["error"]

    lat, lon = data["loc"]&.split(",")

    {
      city:      data["city"],
      region:    data["region"],
      country:   data["country"],
      latitude:  lat&.to_f,
      longitude: lon&.to_f,
      zip:       data["postal"],
      continent: nil
    }
  end

  def local_ip?
    [ "127.0.0.1", "::1", "localhost" ].include?(@ip)
  end

  def stub_location
    {
      city:      "Kuala Lumpur",
      region:    "Kuala Lumpur",
      country:   "MY",
      latitude:  3.1390,
      longitude: 101.6869,
      zip:       "50000",
      continent: nil
    }
  end

  def empty_location
    {
      city: nil, region: nil, country: nil,
      latitude: nil, longitude: nil,
      zip: nil, continent: nil
    }
  end
end
