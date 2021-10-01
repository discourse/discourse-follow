# frozen_string_literal: true

class FollowPostSerializer < ApplicationSerializer
  include PostItemExcerpt

  attributes *%i(
    category_id
    created_at
    id
    post_number
    post_type
    topic_id
    url
  )

  has_one :user, serializer: BasicUserSerializer, embed: :object
  has_one :topic, serializer: BasicTopicSerializer, embed: :object

  def category_id
    object.topic.category_id
  end
end
