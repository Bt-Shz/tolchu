module ApplicationHelper
  PHASE_LABELS = { open: "Live", locked: "Locked", resolved: "Settled", cancelled: "Cancelled" }.freeze
  PAD_DIRECTIONS = { 2 => %w[l r], 3 => %w[u l r], 4 => %w[ul ur dl dr] }.freeze

  def credits(amount)
    "#{amount.to_i.to_fs(:delimited)} #{amount.to_i.abs == 1 ? 'credit' : 'credits'}"
  end

  def signed_credits(amount)
    return "0" if amount.to_i.zero?

    sign = amount.positive? ? "+" : "−"
    "#{sign}#{amount.abs.to_fs(:delimited)}"
  end

  def multiplier(value)
    value ? "×#{format('%.2f', value.to_f)}" : "—"
  end

  def percent(fraction)
    "#{(fraction.to_f * 100).round}%"
  end

  def phase_label(market)
    PHASE_LABELS.fetch(market.phase)
  end

  def phase_badge(market)
    tag.span(phase_label(market), class: [ "badge", "badge--#{market.phase}" ])
  end

  def lock_status_text(market, now: Time.current)
    case market.phase(now)
    when :open then "Locks in #{distance_of_time_in_words(now, market.locks_at)}"
    when :locked then "Betting closed. Waiting for the result"
    when :resolved then "Result is in"
    when :cancelled then "Cancelled. Stakes refunded"
    end
  end

  def bet_status_label(bet)
    case bet.status.to_sym
    when :pending then "Pending"
    when :won then "Won #{signed_credits(bet.net)}"
    when :lost then "Lost #{signed_credits(bet.net)}"
    when :refunded then "Refunded"
    end
  end

  def pad_directions(count)
    PAD_DIRECTIONS.fetch(count)
  end

  def projected_payout(market, outcome, stake)
    (market.projected_multiplier(outcome, stake:) * stake).floor
  end

  def lock_clock(market, now: Time.current)
    remaining = (market.locks_at - now).ceil
    return if remaining <= 0

    hours, rest = remaining.divmod(3600)
    minutes, seconds = rest.divmod(60)
    hours.positive? ? format("%d:%02d:%02d", hours, minutes, seconds) : format("%d:%02d", minutes, seconds)
  end

  def bet_multiplier(bet)
    case bet.status.to_sym
    when :won then Rational(bet.payout, bet.stake)
    when :refunded then 1
    else bet.market.projected_multiplier(bet.outcome)
    end
  end

  def lock_progress(market, now: Time.current)
    total = market.locks_at - market.created_at
    return 0.0 unless total.positive?

    ((market.locks_at - now) / total).clamp(0.0, 1.0)
  end
end
