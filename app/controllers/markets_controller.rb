class MarketsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show card ]
  before_action :settle_sealed_markets

  def index
    @feed = MarketFeed.new(viewer: Current.user, focus_id: Integer(params[:focus].to_s, exception: false))
  end

  def show
    @market = Market.includes(:creator, :outcomes, :winning_outcome).find(params[:id])
    @viewer_bet = Current.user&.bet_on(@market)
  end

  def card
    market = Market.includes(:creator, :outcomes, :winning_outcome).find(params[:id])
    context = params[:context] == "page" ? "page" : "feed"
    streams = [ turbo_stream.replace(market, partial: "markets/market", locals: { market:, viewer_bet: Current.user&.bet_on(market), context: }) ]
    streams << turbo_stream.replace("session-strip", partial: "markets/session_strip") if Current.user
    render turbo_stream: streams
  end

  private
    def settle_sealed_markets
      Markets::SettleSealed.call
    end
end
