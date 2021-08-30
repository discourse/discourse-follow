## PostAlerter
  ## A number of overridden methods need to refer to the core method (i.e. super class)

  module PostAlerterFollowExtension
    def after_save_post(post, new_record = false)
      super(post, new_record)

      if SiteSetting.discourse_follow_enabled && SiteSetting.follow_notifications_enabled && new_record && !post.topic.private_message?
        notified = [*notified_users[post.id]]
        followers =  post.is_first_post? ? author_posted_followers(post) : author_replied_followers(post)
        type = post.is_first_post? ? :following_posted : :following_replied
        notify_users((followers || []) - notified, type, post)
      end
    end

    def author_posted_followers(post)
      User.find(post.user_id).followers.map do |user_id|
        unless (user = User.find_by(id: user_id)) && user.notify_me_when_followed_posts
          user = nil
        end
        user
      end.reject(&:nil?)
    end

    def author_replied_followers(post)
      User.find(post.user_id).followers.reduce([]) do |users, user_id|
        unless (user = User.find_by(id: user_id)) && user.notify_me_when_followed_replies
          user = nil
        end
        following = user ? user.following.find { |data| data[0] == post.user_id.to_s } : nil
        if following && following.last == Follow::Notification.levels[:watching]
          users.push(user)
        else
          users
        end
      end
    end

    def notify_users(users, type, post, opts = {})
      users = super(users, type, post, opts = {})
      add_notified_users(users, post.id)
      users
    end

    def add_notified_users(users, post_id)
      new_users = [*users]
      current_users = notified_users[post_id] || []
      notified_users[post_id] = (new_users + current_users).uniq
    end

    def notified_users
      @notified_users ||= []
    end

    def create_notification(user, type, post, opts = {})
      @current_notification_type = type
      super(user, type, post, opts)
      @current_notification_type = nil
    end

    def unread_posts(user, topic)
      if @current_notification_type == Notification.types[:following_replied]
        posts = Post.secured(Guardian.new(user))
          .where('post_number > COALESCE((
                   SELECT last_read_post_number FROM topic_users tu
                   WHERE tu.user_id = ? AND tu.topic_id = ? ),0)',
                    user.id, topic.id)

        posts = posts
          .where("exists(
                SELECT 1 from user_custom_fields ucf
                WHERE ucf.user_id = ? AND
                  ucf.name = 'following' AND
                  split_part(ucf.value,',', 1)::integer = posts.user_id AND
                  split_part(ucf.value, ',', 2)::integer = ?
                )", user.id, Follow::Notification.levels[:watching])
          .where(topic_id: topic.id)
      else
        posts = super(user, topic)
      end

      posts
    end

    def first_unread_post(user, topic)
      unread_posts(user, topic).order('post_number').first
    end

    def unread_count(user, topic)
      unread_posts(user, topic).count
    end
  end

  require_dependency 'post_alerter'
  class ::PostAlerter
    prepend PostAlerterFollowExtension
  end
  