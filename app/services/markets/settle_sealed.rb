module Markets
  # Settles every sealed market whose betting window has closed. It runs inside
  # page loads (the feed, a clip page, a card refresh), so it must be cheap when
  # nothing is due and must never raise: one market that cannot settle is
  # logged and skipped, and the rest still settle.
  class SettleSealed < ApplicationService
    def initialize(now: Time.current, scope: Market.all)
      @now = now
      @scope = scope
    end

    def perform
      due = @scope.due_for_sealed_settlement(@now)
      return 0 unless due.exists?

      due.includes(:sealed_winner).to_a.count { |market| settle(market) }
    end

    private
      def settle(market)
        Resolve.call(market:, winning_outcome_id: market.sealed_winner.id).success?
      rescue StandardError => e
        Rails.logger.error("[Markets::SettleSealed] market #{market.id} could not be settled: #{e.class}: #{e.message}")
        Rails.error.report(e, handled: true, context: { market_id: market.id })
        false
      end
  end
end
