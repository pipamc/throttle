# coding: utf-8

# system packages

# third-party packages

# own packages
from .rate_limiter import RateLimiter
from .user_rate_limit_policy import UserRateLimitPolicy

redis_config = {
    "host": "127.0.0.1",
    "port": 6379,
    "db": 0,
    "max_connection": 50
}

urlp = UserRateLimitPolicy(10, 1000, 10000)
args = dict()
args["redis"] = redis_config
args["rate_limit_policy"] = urlp
throttling = RateLimiter(**args)
throttling.access("gaoxun")
