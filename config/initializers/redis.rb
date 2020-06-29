# Prevents error messages in sidekiq in dev boxes.
# should be removed once sidekiq uses #exists?
Redis.exists_returns_integer = false
