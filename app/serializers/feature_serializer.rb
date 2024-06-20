class FeatureSerializer
  include JSONAPI::Serializer

  attributes :external_id, :magnitude, :place, :time, :tsunami, :mag_type, :title

  attribute :coordinates do |feature|
    {
      longitude: feature.longitude,
      latitude: feature.latitude
    }
  end

  link :external_url do |feature|
    feature.url
  end
end
