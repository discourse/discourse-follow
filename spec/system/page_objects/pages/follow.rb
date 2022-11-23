# frozen_string_literal: true

module PageObjects
  module Pages
    class Follow < PageObjects::Pages::Base
      CONTENT_CLASS = '.user-follows-tab'

      def initialize(user)
        super()
        @user = user
      end

      def visit
        page.visit("/u/#{@user.username}")
        click_on I18n.t('js.user.follow_nav')
        self
      end

      def click_on_followers
        click_on I18n.t("js.user.followers.label")
        self
      end

      def click_on_following
        click_on I18n.t("js.user.following.label")
        self
      end

      def has_follower?(user)
        within(CONTENT_CLASS) do
          page.has_content?(user.username)
        end
      end
      alias_method :has_following?, :has_follower?

      def has_following_topic?(topic)
        within(CONTENT_CLASS) do
          page.has_content?(topic.title)
        end
      end
    end
  end
end
