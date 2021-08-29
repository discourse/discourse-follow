class Follow::Notification
  def self.levels
    @levels ||= Enum.new(
      regular: 1,
      watching: 3,
      watching_first_post: 4
    )
  end
end
