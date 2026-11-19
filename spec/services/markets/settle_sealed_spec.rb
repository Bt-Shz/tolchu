require "rails_helper"

RSpec.describe Markets::SettleSealed do
  def sealed_market(answer: "Lands it", **attributes)
    create(:market, sealed_answer_label: answer, **attributes)
  end

  it "settles a sealed market on its answer once betting has closed" do
    market = sealed_market
    winner = create(:user)
    place_bet(user: winner, market:, outcome: "Lands it", stake: 50)
    place_bet(user: create(:user), market:, outcome: "Bails", stake: 50)

    travel_to(market.locks_at + 1.second) { expect(described_class.call.value).to eq(1) }

    expect(market.reload).to have_attributes(status: "resolved", winning_outcome: outcome(market, "Lands it"))
    expect(winner.bets.sole).to have_attributes(status: "won", payout: 95)
  end

  it "leaves markets that are still open, unsealed, or already settled alone" do
    open_market = sealed_market(locks_at: 1.hour.from_now)
    unsealed = create(:market, :locked)
    settled = sealed_market
    travel_to(settled.locks_at + 1.second) { described_class.call }

    expect(described_class.call.value).to eq(0)
    expect(open_market.reload).to be_open
    expect(unsealed.reload).to be_locked
    expect(settled.reload.resolved_at).to be_present
  end

  it "can be limited to one market" do
    first = sealed_market
    second = sealed_market

    travel_to(first.locks_at + 1.second) do
      expect(described_class.call(scope: Market.where(id: first.id)).value).to eq(1)
    end
    expect(second.reload).not_to be_resolved
  end
end
