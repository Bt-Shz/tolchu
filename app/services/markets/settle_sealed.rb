module Markets
  class SettleSealed < ApplicationService
    def initialize(now: Time.current, scope: Market.all)
      @now = now
      @scope = scope
    end

    def perform
      @scope.due_for_sealed_settlement(@now).includes(:sealed_winner).to_a.count do |market|
        Resolve.call(market:, winning_outcome_id: market.sealed_winner.id).success?
      end
    end
  end
end
