# coding: utf-8

# system packages

# third-party packages
from abc import abstractmethod

# own packages


class RateLimitPolicy(object):
    def __init__(self, capacity, interval, max_burst_time):
        self._capacity = capacity
        self._interval = interval
        self._interval_per_permit = interval / capacity
        self._max_burst_tokens = min(max_burst_time / self._interval_per_permit, capacity)

    @abstractmethod
    def gen_bucket_key(self, key):
        pass
