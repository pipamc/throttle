# coding: utf-8

# system packages
import os
import time
# third-party packages

# own packages
from .redis_single import connect


class LuaScriptNotFound(Exception):
    pass


class RateLimiter(object):
    def __init__(self, *args, **kwargs):
        self._redis_connection = connect(**kwargs["redis"]).get_session()
        self._rate_limit_policy = kwargs["rate_limit_policy"]
        lua_path = os.path.join(os.path.dirname(__file__), "throttling.lua")
        try:
            self._lua_sha = self._redis_connection.register_script(lua_path)
        except:
            raise LuaScriptNotFound("The path of lua script does not exist {}".format(lua_path))

    def access(self, key):
        bucket_key = self._rate_limit_policy.gen_bucket_key(key)
        result = self._redis_connection.evalsha(self._lua_sha, 1, bucket_key,
                                       self._rate_limit_policy._interval_per_permit,
                                       time.time() * 1000,
                                       self._rate_limit_policy._max_burst_tokens,
                                       self._rate_limit_policy._capacity,
                                       self._rate_limit_policy._interval)
        return int(result) == 1
