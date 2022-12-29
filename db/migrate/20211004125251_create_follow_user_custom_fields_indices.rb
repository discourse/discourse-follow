# frozen_string_literal: true

class CreateFollowUserCustomFieldsIndices < ActiveRecord::Migration[6.1]
  def up
    %w[
      notify_me_when_followed
      notify_followed_user_when_followed
      notify_me_when_followed_replies
      notify_me_when_followed_creates_topic
      allow_people_to_follow_me
    ].each do |field|
      DB.exec(<<~SQL, field: field)
        DELETE FROM user_custom_fields ucf1
        USING user_custom_fields ucf2
        WHERE ucf1.id != ucf2.id
        AND ucf1.name = :field
        AND ucf2.name = :field
        AND ucf1.user_id = ucf2.user_id
        AND ucf1.updated_at < ucf2.updated_at
      SQL
      add_index(
        :user_custom_fields,
        %i[name user_id],
        name: index_name_for(field),
        unique: true,
        where: "name = '#{field}'",
      )
    end
  end

  def down
    %w[
      notify_me_when_followed
      notify_followed_user_when_followed
      notify_me_when_followed_replies
      notify_me_when_followed_creates_topic
      allow_people_to_follow_me
    ].each do |field|
      remove_index(:user_custom_fields, name: index_name_for(field), if_exists: true)
    end
  end

  private

  def index_name_for(name)
    :"idx_user_custom_fields_#{name}"
  end
end
