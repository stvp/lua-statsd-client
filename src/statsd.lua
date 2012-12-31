-- Statsd client
--
-- For statsd protocol info: https://github.com/b/statsd_spec

local math = require "math"
local os = require "os"
local socket = require "socket"

math.randomseed( os.time() )

module( ..., package.seeall )

host = "127.0.0.1"
port = 8125
namespace = nil

function send_to_socket( string )
  local udp = socket.udp()
  udp:setpeername( host, port )
  udp:send( string )
  udp:close()
end

function send( stat, delta, kind, sample_rate )
  sample_rate = sample_rate or 1

  if sample_rate == 1 or math.random() <= sample_rate then
    -- Build prefix
    prefix = ""
    if namespace ~= nil then prefix = namespace.."." end
    -- Escape the stat name
    stat = stat:gsub( ":", "_" ):gsub( "|", "_" ):gsub( "@", "_" )
    -- Append the sample rate
    rate = ""
    if sample_rate ~= 1 then rate = "|@"..sample_rate end

    send_to_socket( prefix..stat..":"..delta.."|"..kind..rate )
  end
end

-- Record an instantaneous measurement. It's different from a counter in that
-- the value is calculated by the client rather than the server.
function gauge( stat, value, sample_rate )
  send( stat, value, "g", sample_rate )
end

-- A counter is a gauge whose value is calculated by the statsd server. The
-- client merely gives a delta value by which to change the gauge value.
function counter( stat, value, sample_rate )
  send( stat, value, "c", sample_rate )
end

-- Increment a counter by `value`.
function increment( stat, value, sample_rate )
  counter( stat, value, sample_rate )
end

-- Decrement a counter by `value`.
function decrement( stat, value, sample_rate )
  counter( stat, -value, sample_rate )
end

-- A timer is a measure of the number of milliseconds elapsed between a start
-- and end time, for example the time to complete rendering of a web page for
-- a user.
function timer( stat, ms )
  send( stat, ms, "ms" )
end

-- A histogram is a measure of the distribution of timer values over time,
-- calculated by the statsd server.
function histogram( stat, value )
  send( stat, value, "h" )
end

-- A meter measures the rate of events over time, calculated by the Statsd
-- server.
function meter( stat, value )
  send( stat, value, "m" )
end

