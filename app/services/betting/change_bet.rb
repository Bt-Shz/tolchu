module Betting
  class ChangeBet < ApplicationService
    def initialize(bet:, outcome_id:, stake:)
      @bet = bet
      @market = bet.market
      @user = bet.user
      @outcome_id = outcome_id
      @stake = stake
    end

    def perform
      Market.transaction do
        @market.lock!
        @bet.reload
        fail!("Betting is closed for this market") unless @market.accepting_bets? && @bet.pending?
        outcome = @market.outcomes.find_by(id: @outcome_id) or fail!("Pick one of the outcomes before placing your bet")

        old_outcome_id, old_stake = @bet.outcome_id, @bet.stake
        @bet.assign_attributes(outcome:, stake: @stake)
        fail!(@bet.errors.full_messages.to_sentence) unless @bet.valid?
        next @bet unless @bet.changed?

        @bet.save!
        swap_stakes(old_stake)
        Outcome.update_counters(old_outcome_id, pool: -old_stake)
        Outcome.update_counters(outcome.id, pool: @bet.stake)
        Market.update_counters(@market.id, total_pool: @bet.stake - old_stake)
      end
      @market.reload
      @bet
    end

    private
      def swap_stakes(old_stake)
        @user.wallet.credit!(old_stake, kind: :refund, market: @market, bet: @bet)
        @user.wallet.debit!(@bet.stake, kind: :stake, market: @market, bet: @bet)
      rescue Wallet::InsufficientCredits
        fail!("You don't have enough credits for that stake (available: #{@user.reload.balance})")
      end
  end
end
