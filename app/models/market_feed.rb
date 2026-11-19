class MarketFeed
  RECENT_RESULTS_LIMIT = 12

  attr_reader :viewer, :now, :focus_id

  def initialize(viewer: nil, now: Time.current, focus_id: nil)
    @viewer = viewer
    @now = now
    @focus_id = focus_id
  end

  def markets
    @markets ||= begin
      feed = [
        base.accepting_bets(now).order(:locks_at, :id),
        base.awaiting_result(now).order(locks_at: :desc, id: :desc),
        base.resolved.order(resolved_at: :desc, id: :desc).limit(RECENT_RESULTS_LIMIT)
      ].flat_map(&:to_a)
      focused = focus_id && (feed.find { |market| market.id == focus_id } || base.find_by(id: focus_id))
      focused ? [ focused, *feed.excluding(focused) ] : feed
    end
  end

  def bet_for(market)
    viewer_bets[market.id]
  end

  private
    def base
      Market.includes(:creator, :outcomes, :winning_outcome)
    end

    def viewer_bets
      @viewer_bets ||= viewer ? viewer.bets.where(market_id: markets.map(&:id)).includes(:outcome).index_by(&:market_id) : {}
    end
end
