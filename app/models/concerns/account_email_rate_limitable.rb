module AccountEmailRateLimitable
  extend ActiveSupport::Concern

  OUTBOUND_EMAIL_TTL = 25.hours.to_i

  def email_rate_limit
    return self[:limits]['emails'].to_i if self[:limits].present? && self[:limits]['emails'].present?

    config_name = 'ACCOUNT_EMAILS_LIMIT'
    global_limit = GlobalConfig.get(config_name)[config_name]
    return global_limit.to_i if global_limit.present?

    ChatwootApp.max_limit.to_i
  end

  def emails_sent_today
    key = format(Redis::Alfred::ACCOUNT_OUTBOUND_EMAIL_COUNT_KEY, account_id: id, date: Time.zone.today.to_s)
    Redis::Alfred.get(key).to_i
  end

  def within_email_rate_limit?
    emails_sent_today < email_rate_limit
  end

  def increment_email_sent_count
    key = format(Redis::Alfred::ACCOUNT_OUTBOUND_EMAIL_COUNT_KEY, account_id: id, date: Time.zone.today.to_s)
    count = Redis::Alfred.incr(key)
    Redis::Alfred.expire(key, OUTBOUND_EMAIL_TTL) if count == 1
    count
  end
end
