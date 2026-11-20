module Parimutuel
  RAKE_RATE = Rational(5, 100)
  MAX_CREATOR_SHARE = Rational(1, 2)

  module_function

  def contest_score(pools)
    total = pools.sum
    return Rational(0) if total.zero? || pools.size < 2

    max_share = Rational(pools.max, total)
    (1 - max_share) / (1 - Rational(1, pools.size))
  end

  def rake_for(total_pool:, losing_pool:)
    [ (total_pool * RAKE_RATE).floor, losing_pool ].min
  end

  def creator_reward_for(rake:, contest_score:)
    (rake * MAX_CREATOR_SHARE * contest_score).floor
  end

  def projected_multiplier(outcome_pool:, total_pool:, stake: 0)
    pool = outcome_pool + stake
    total = total_pool + stake
    return nil if pool.zero?

    losing = total - pool
    return Rational(1) if losing.zero?

    Rational(total - rake_for(total_pool: total, losing_pool: losing), pool)
  end
end
