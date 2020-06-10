class Follow::Notification
  def self.levels
    @levels ||= Enum.new(
      watching: 0,
      watching_first_post: 1
    )
  end
end