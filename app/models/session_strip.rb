# The status row above the feed: one tile per bet placed since the viewer
# signed in (newest first), and the net result of the ones that have settled.
class SessionStrip
  TILE_LIMIT = 40

  attr_reader :user, :since

  def initialize(user:, since:)
    @user = user
    @since = since
  end

  def bets
    @bets ||= scope.includes(:market).order(created_at: :desc, id: :desc).limit(TILE_LIMIT).to_a
  end

  # Payout minus stake across every settled bet this session, not just the visible tiles.
  # Pending bets count as zero until they settle.
  def net
    @net ||= scope.where.not(payout: nil).sum("payout - stake")
  end

  private
    def scope
      user.bets.where(created_at: since..)
    end
end
