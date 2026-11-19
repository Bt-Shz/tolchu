module BettingHelpers
  def place_bet(user:, market:, outcome:, stake:)
    result = Betting::PlaceBet.call(user:, market:, outcome_id: market.outcomes.find_by!(label: outcome).id, stake:)
    raise "Bet failed: #{result.error}" if result.failure?

    result.value
  end

  def outcome(market, label)
    market.outcomes.find_by!(label:)
  end
end

RSpec.configure { |config| config.include BettingHelpers }
