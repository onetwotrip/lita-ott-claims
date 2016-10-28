class OttClaim
  REDIS_NAMESPACE = 'handlers:ottclaims'.freeze

  class << self
    def create(env_name, claimer)
      claim_data = {}
      claim_data[:claimer] = claimer
      claim_data[:timestamp] = Time.now.to_s

      return false if exists?(env_name.to_s)
      redis.set(env_name.to_s, claim_data.to_json)
    end

    def read(env_name)
      claim_data = redis.get(env_name.to_s)
      return nil unless claim_data
      JSON.parse(claim_data)
    end

    def destroy(env_name)
      redis.del(env_name.to_s)
    end

    def exists?(env_name)
      redis.exists(env_name.to_s)
    end

    def redis
      @redis ||= Redis::Namespace.new(REDIS_NAMESPACE, redis: Lita.redis)
    end
  end
end
