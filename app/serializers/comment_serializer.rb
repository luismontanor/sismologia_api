class CommentSerializer
  include JSONAPI::Serializer

  attributes :id, :body, :created_at, :updated_at
end
