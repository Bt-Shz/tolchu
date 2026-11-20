require "rails_helper"

RSpec.describe Betting::ChangeBet do
  let(:market) { create(:market, outcome_labels: [ "Lands it", "Bails" ]) }
  let(:user) { create(:user, balance: 500) }
  let(:lands_it) { outcome(market, "Lands it") }
  let(:bails) { outcome(market, "Bails") }
  let!(:bet) { place_bet(user:, market:, outcome: "Lands it", stake: 40) }

  def call(outcome_id: bails.id, stake: 60)
    described_class.call(bet:, outcome_id:, stake:)
  end

  it "moves the bet to the new outcome and stake" do
    result = call

    expect(result).to be_success
    expect(result.value.reload).to have_attributes(outcome: bails, stake: 60, status: "pending")
    expect(market.reload.bets_count).to eq(1)
  end

  it "moves the money between the pools" do
    call

    expect(lands_it.reload.pool).to eq(0)
    expect(bails.reload.pool).to eq(60)
    expect(market.reload.total_pool).to eq(60)
  end

  it "refunds the old stake and debits the new one in the ledger" do
    call

    expect(user.reload.balance).to eq(440)
    expect(user.ledger_entries.order(:id).last(2).map { |entry| [ entry.kind, entry.amount ] }).to eq([ [ "refund", 40 ], [ "stake", -60 ] ])
  end

  it "changes nothing when the pick and stake are the same" do
    expect { call(outcome_id: lands_it.id, stake: 40) }.not_to change(LedgerEntry, :count)
  end

  it "lets the new stake use the credits freed by the old one" do
    user.update_columns(balance: 0)

    expect(call(stake: 40)).to be_success
    expect(user.reload.balance).to eq(0)
  end

  shared_examples "a rejected change" do |message|
    it "fails with a helpful message and changes nothing" do
      expect { @result = perform }.not_to change { [ user.reload.balance, bet.reload.attributes, market.reload.total_pool ] }
      expect(@result.error).to eq(message)
    end
  end

  context "when betting has closed" do
    let(:perform) { travel_to(market.locks_at + 1.second) { call } }

    it_behaves_like "a rejected change", "Betting is closed for this market"
  end

  context "when the outcome isn't in this market" do
    let(:perform) { call(outcome_id: create(:market).outcomes.first.id) }

    it_behaves_like "a rejected change", "Pick one of the outcomes before placing your bet"
  end

  context "when the stake is over the cap" do
    let(:perform) { call(stake: Bet::MAX_STAKE + 1) }

    it_behaves_like "a rejected change", "Stake must be less than or equal to #{Bet::MAX_STAKE}"
  end

  context "when the new stake is more than the user can cover" do
    before { user.update_columns(balance: 10) }

    let(:perform) { call(stake: 60) }

    it_behaves_like "a rejected change", "You don't have enough credits for that stake (available: 50)"
  end
end
