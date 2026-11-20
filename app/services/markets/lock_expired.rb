module Markets
  class LockExpired < ApplicationService
    def initialize(now: Time.current)
      @now = now
    end

    def perform
      Market.open.where(locks_at: ..@now).update_all([ "status = ?, locked_at = locks_at, updated_at = ?", "locked", @now ])
    end
  end
end
