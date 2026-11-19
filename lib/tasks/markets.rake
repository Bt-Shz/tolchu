namespace :markets do
  desc "Persist the locked status for open markets whose betting window has passed"
  task lock_expired: :environment do
    count = Markets::LockExpired.call.value
    puts "Locked #{count} expired #{count == 1 ? 'market' : 'markets'}."
    settled = Markets::SettleSealed.call.value
    puts "Settled #{settled} sealed #{settled == 1 ? 'market' : 'markets'}."
  end
end
