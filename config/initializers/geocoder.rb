# config/initializers/geocoder.rb
Geocoder.configure(
  timeout:  5,
  cache:    Rails.cache,          # cache lookups to avoid rate limits
  units:    :km,
  # use a paid provider in production for better accuracy:
  # lookup: :maxmind_local,
  # lookup: :ipinfo_io, api_key: ENV['IPINFO_KEY'],
) 
if Rails.env.development?
  Geocoder.configure(lookup: :test)
  Geocoder::Lookup::Test.add_stub("127.0.0.1", [{ country: "Malaysia", city: "Kuala Lumpur" }])
end