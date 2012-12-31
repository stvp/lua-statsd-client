Lua Statsd client
=================

`lua-statsd-client` is a [Statsd](https://github.com/etsy/statsd) client for Lua.

Installation
------------

```sh
% luarocks install statsd
```

Usage
-----

```lua
local statsd = require "statsd"

statsd.host = "stats.mysite.com" -- default: 127.0.0.1
statsd.port = 8888 -- default: 8125
statsd.namespace = "mysite.stats" -- default: none

statsd.gauge( "users", #my_users_table )
statsd.counter( "events", 5 )
statsd.increment( "events", 1 )
statsd.decrement( "events", 3 )
```

