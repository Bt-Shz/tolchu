FactoryBot.define do
  factory :market do
    association :creator, factory: :user
    sequence(:question) { |n| "Will the trick land? ##{n}" }
    video_url { "https://cdn.example.com/clips/trick.mp4" }
    freeze_at { 4.5 }
    locks_at { 15.minutes.from_now }

    transient do
      outcome_labels { [ "Lands it", "Bails" ] }
    end

    outcomes { outcome_labels.map { |label| association(:outcome, strategy: :build, label:, market: instance) } }

    trait :expired do
      after(:create) { |market| market.update_columns(locks_at: 1.minute.ago) }
    end

    trait :locked do
      after(:create) { |market| market.update_columns(status: "locked", locks_at: 1.minute.ago, locked_at: 1.minute.ago) }
    end
  end
end
