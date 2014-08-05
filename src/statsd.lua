-- Statsd client
--
-- For statsd protocol info: https://github.com/b/statsd_spec

local math = require "math"
local os = require "os"
local socket = require "socket"

math.randomseed(os.time())

local function send_to_socket(self, string)
  return self.udp:send(string)
end

local function make_statsd_message(self, stat, delta, kind, sample_rate)
  -- Build prefix
  local prefix = ""

  if self.namespace ~= nil then prefix = self.namespace.."." end

  -- Escape the stat name
  stat = stat:gsub("[:|@]", "_")

  -- Append the sample rate
  local rate = ""

  if sample_rate ~= 1 then rate = "|@"..sample_rate end

  return prefix..stat..":"..delta.."|"..kind..rate
end

local function send(self, stat, delta, kind, sample_rate, neg)
  local msg
  local stat_type = type(stat)
  if stat_type == 'table' then sample_rate = delta end
  sample_rate = sample_rate or 1
  if not (sample_rate == 1 or math.random() <= sample_rate) then
    return
  end

  if stat_type == 'table' then
    local t = {}
    for s, v in pairs(stat) do
      if kind == 'c' then
        if type(s) == 'number' then
          -- this is array or kyes ( increment{'register', 'register_accept'})
          s, v = v, 1
        end
        v = neg and -v or v
      end
      table.insert(t, (make_statsd_message(self, s, v, kind, sample_rate)))
    end
    msg = table.concat(t, "\n")
    -- @todo check max udp packet size
  else
    msg = make_statsd_message(self, stat, delta, kind, sample_rate)
  end
  return self:send_to_socket(msg)
end

-- Record an instantaneous measurement. It's different from a counter in that
-- the value is calculated by the client rather than the server.
local function gauge(self, stat, value, sample_rate)
  return self:send(stat, value, "g", sample_rate)
end

local function counter_(self, stat, value, sample_rate, ...)
  return self:send(stat, value, "c", sample_rate, ...)
end

-- A counter is a gauge whose value is calculated by the statsd server. The
-- client merely gives a delta value by which to change the gauge value.
local function counter(self, stat, value, sample_rate)
  return counter_(self, stat, value, sample_rate)
end

-- Increment a counter by `value`.
local function increment(self, stat, value, sample_rate)
  return counter_(self, stat, value or 1, sample_rate, false)
end

-- Decrement a counter by `value`.
local function decrement(self, stat, value, sample_rate)
  value = value or 1
  if type(stat) == 'string' then value = -value end
  return counter_(self, stat, value, sample_rate, true)
end

-- A timer is a measure of the number of milliseconds elapsed between a start
-- and end time, for example the time to complete rendering of a web page for
-- a user.
local function timer(self, stat, ms)
  return self:send(stat, ms, "ms")
end

-- A histogram is a measure of the distribution of timer values over time,
-- calculated by the statsd server. Not supported by all statsd implementations.
local function histogram(self, stat, value)
  return self:send(stat, value, "h")
end

-- A meter measures the rate of events over time, calculated by the Statsd
-- server. Not supported by all statsd implementations.
local function meter(self, stat, value)
  return self:send(stat, value, "m")
end

-- A set counts unique occurrences of events between flushes. Not supported by
-- all statsd implementations.
local function set(self, stat, value)
  return self:send(stat, value, "s")
end

return function(options)
  options = options or {}

  local host = options.host or "127.0.0.1"
  local port = options.port or 8125
  local namespace = options.namespace or nil

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

