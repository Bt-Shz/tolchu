FactoryBot.define do
  factory :bet do
    user
    market
    outcome { market.outcomes.first }
    stake { 10 }
  end
end
