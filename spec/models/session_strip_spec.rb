require "rails_helper"

RSpec.describe SessionStrip do
  let(:fan) { create(:user) }

  def settle(market, winner)
    Markets::Lock.call(market:)
    Markets::Resolve.call(market: market.reload, winning_outcome_id: outcome(market, winner).id)
  end

  it "lists only bets placed since the session started, newest first" do
    before_session = place_bet(user: fan, market: create(:market), outcome: "Lands it", stake: 10)
    started = 1.minute.from_now
    first, second = travel_to(2.minutes.from_now) do
      [ place_bet(user: fan, market: create(:market), outcome: "Lands it", stake: 10),
        place_bet(user: fan, market: create(:market), outcome: "Bails", stake: 10) ]
    end

    bets = described_class.new(user: fan, since: started).bets

    expect(bets).to eq([ second, first ])
    expect(bets).not_to include(before_session)
  end

  it "caps the number of tiles" do
    stub_const("SessionStrip::TILE_LIMIT", 1)
    2.times { place_bet(user: fan, market: create(:market), outcome: "Lands it", stake: 10) }

    expect(described_class.new(user: fan, since: 1.hour.ago).bets.size).to eq(1)
  end

  it "nets the settled bets and ignores pending ones" do
    won = create(:market)
    lost = create(:market)
    pending = create(:market)
    place_bet(user: fan, market: won, outcome: "Lands it", stake: 100)
    place_bet(user: create(:user), market: won, outcome: "Bails", stake: 100)
    place_bet(user: fan, market: lost, outcome: "Bails", stake: 30)
    place_bet(user: create(:user), market: lost, outcome: "Lands it", stake: 30)
    place_bet(user: fan, market: pending, outcome: "Lands it", stake: 40)
    settle(won, "Lands it")
    settle(lost, "Lands it")

    # Won: 200 pool − 10 rake = 190 back on 100 (+90). Lost: −30. Pending: 0.
    expect(described_class.new(user: fan, since: 1.hour.ago).net).to eq(60)
  end

  it "has no tiles and a zero net for a fresh session" do
    strip = described_class.new(user: fan, since: Time.current)

    expect(strip.bets).to be_empty
    expect(strip.net).to eq(0)
  end
end
