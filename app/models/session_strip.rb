class SessionStrip
  TILE_LIMIT = 40
  VISIBLE = 4

  attr_reader :user, :since

  def initialize(user:, since:)
    @user = user
    @since = since
  end

  def bets
    @bets ||= scope.includes(:market).order(created_at: :desc, id: :desc).limit(TILE_LIMIT).to_a
  end

  def net
    @net ||= scope.where.not(payout: nil).sum("payout - stake")
  end

  private
    def scope
      user.bets.where(created_at: since..)
    end
end
