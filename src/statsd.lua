-- Statsd client
--
-- For statsd protocol info: https://github.com/b/statsd_spec

local math = require "math"
local os = require "os"
local socket = require "socket"

math.randomseed(os.time())

local function send_to_socket(self, string)
  self.udp:send(string)
end

local function send(self, stat, delta, kind, sample_rate)
  sample_rate = sample_rate or 1

  if sample_rate == 1 or math.random() <= sample_rate then
    -- Build prefix
    prefix = ""

    if self.namespace ~= nil then prefix = self.namespace.."." end

    -- Escape the stat name
    stat = stat:gsub(":", "_"):gsub("|", "_"):gsub("@", "_")

    -- Append the sample rate
    rate = ""

    if sample_rate ~= 1 then rate = "|@"..sample_rate end

    self:send_to_socket(prefix..stat..":"..delta.."|"..kind..rate)
  end
end

-- Record an instantaneous measurement. It's different from a counter in that
-- the value is calculated by the client rather than the server.
local function gauge(self, stat, value, sample_rate)
  self:send(stat, value, "g", sample_rate)
end

-- A counter is a gauge whose value is calculated by the statsd server. The
-- client merely gives a delta value by which to change the gauge value.
local function counter(self, stat, value, sample_rate)
  self:send(stat, value, "c", sample_rate)
end

-- Increment a counter by `value`.
local function increment(self, stat, value, sample_rate)
  self:counter(stat, value, sample_rate)
end

-- Decrement a counter by `value`.
local function decrement(self, stat, value, sample_rate)
  self:counter(stat, -value, sample_rate)
end

-- A timer is a measure of the number of milliseconds elapsed between a start
-- and end time, for example the time to complete rendering of a web page for
-- a user.
local function timer(self, stat, ms)
  self:send(stat, ms, "ms")
end

-- A histogram is a measure of the distribution of timer values over time,
-- calculated by the statsd server. Not supported by all statsd implementations.
local function histogram(self, stat, value)
  self:send(stat, value, "h")
end

-- A meter measures the rate of events over time, calculated by the Statsd
-- server. Not supported by all statsd implementations.
local function meter(self, stat, value)
  self:send(stat, value, "m")
end

-- A set counts unique occurrences of events between flushes. Not supported by
-- all statsd implementations.
local function set(self, stat, value)
  self:send(stat, value, "s")
end

return function(options)
  options = options or {}

  local host = options.host or "127.0.0.1"
  local port = options.port or 8125
  local namespace = options.namespace or nil

  print(host)
  print(port)
  print(namespace)

  local udp = socket.udp()
  udp:setpeername(host, port)

  return {
    namespace = namespace,
    udp = udp,
    gauge = gauge,
    counter = counter,
    increment = increment,
    decrement = decrement,
    timer = timer,
    histogram = histogram,
    meter = meter,
    send = send,
    send_to_socket = send_to_socket
  }
end

