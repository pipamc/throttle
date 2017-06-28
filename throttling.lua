--[[
A lua rate limiter runs in redis
why use lua?
Answer: cause multi threads will cause race condition,
so we need to run lua script in redis to provide thread safe
Args:
    intervalPerPermit: time interval in millis between two token permits;
    refillTime: timestamp when filling token for bucket
    limit: the max capacity of bucket
    interval: the time interval in millis of token bucket
    burstTokens: if the interval between two request large than interval, the burst number of bucket will be set burstTokens
]]--

local key = KEYS[1]
local intervalPerPermit = tonumber(ARGV[1])
local refillTime = tonumber(ARGV[2])
local burstTokens = tonumber(ARGV[3])
local limit = tonumber(ARGV[4])
local interval = tonumber(ARGV[5])

local bucket = redis.call('hgetall', key)
local currentTokens

if table.maxn(bucket) == 0 then
    -- check if bucket not exists, if yes, create a new one with full capacity, then grant access
    currentTokens = burstTokens
    redis.call('hset', key, 'lastRefillTime', refillTime)
elseif table.maxn(bucket) == 4 then
    local lastRifillTIme, tokensRemaining = tonumber(bucket[2]), tonumber(bucket[4])
    if refillTime > lastRifillTIme then
        -- if refillTime larger than lastRifillTime, should refill the token bucket
        local intervalSinceLast = refillTime - lastRifillTIme
        if intervalSinceLast > interval then
            -- if the interval between two requests is larger than interval, which means it's a long time that no requests come, we need refresh token
            currentTokens = burstTokens
            redis.call('hset', key, 'lastRefillTime', refillTime)
        else
            local grantedTokens = math.floor(intervalSinceLast / intervalPerPermit)
            if grantedTokens > 0 then
                local padMillis = math.fmod(intervalSinceLast, intervalPerPermit)
                redis.call('hset', key, 'lastRefillTime', refillTime - padMillis)
            end
            currentTokens = math.min(grantedTokens + tokensRemaining, limit)
        end
    else
        -- if not, it means no need to fill token into bucket
        currentTokens = tokensRemaining
    end
end

if currentTokens == 0 then
    -- no token can be consume
    redis.call('hset', key, 'tokenRemaining', currentTokens)
    return 0
else
    redis.call('hset', key, 'tokenRemainng', currentTokens - 1)
    return 1
end