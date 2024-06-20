class FetchEarthquakeDataJob
  include Sidekiq::Job

  def perform(*args)
    require 'faraday'
    require 'json'

    url = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson'
    response = Faraday.get(url)
    data = JSON.parse(response.body)

    data['features'].each do |feature|
      properties = feature['properties']
      geometry = feature['geometry']

      next if properties['title'].nil? || properties['url'].nil? || properties['place'].nil? || properties['magType'].nil? || geometry['coordinates'].nil?

      magnitude = properties['mag']
      latitude = geometry['coordinates'][1]
      longitude = geometry['coordinates'][0]

      next if magnitude < -1.0 || magnitude > 10.0 || latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0

      Feature.find_or_create_by(external_id: feature['id']) do |f|
        f.magnitude = magnitude
        f.place = properties['place']
        f.time = Time.at(properties['time'] / 1000)
        f.tsunami = properties['tsunami'] == 1
        f.mag_type = properties['magType']
        f.title = properties['title']
        f.longitude = longitude
        f.latitude = latitude
        f.url = properties['url']
      end
    end
  end
end
