local Statsd = require "../src/statsd"
local statsd = nil

function assert_udp_received(string)
  assert.equal(statsd.sent_with, string)
end

before_each(function()
  statsd = nil
  statsd = Statsd()

  --stub send_to_socket
  statsd.send_to_socket = function(self, string)
    self.sent_with = string
  end
end)

describe("gauge", function()
  it("sets a simple gauge", function()
    statsd:gauge("foo", 10)
    assert_udp_received("foo:10|g")
  end)

  it("sets a gauge with a namespace", function()
    statsd = Statsd({
      namespace = "cool.dudes"
    })

    statsd.send_to_socket = function(self, string)
      self.sent_with = string
    end

    statsd:gauge("foo", 10)
    assert_udp_received("cool.dudes.foo:10|g")
  end)
  
  it("sets a gauge with a sample_rate", function()
    statsd:gauge("foo", 10, 2)
    assert_udp_received("foo:10|g|@2")
  end)

  it("escapes stat names", function()
    statsd:gauge("foo:dude|baz@99", 1)
    assert_udp_received("foo_dude_baz_99:1|g")
  end)
end)

describe("counter", function()
  it("counts", function()
    statsd:counter("neat", 10)
    assert_udp_received("neat:10|c")
  end)

  it("counts down", function()
    statsd:counter("neat", -5)
    assert_udp_received("neat:-5|c")
  end)
end)

describe("increment", function()
  it("increments", function()
    statsd:increment("neat", 5)
    assert_udp_received("neat:5|c")
  end)

  it("increments by one", function()
    statsd:increment("neat")
    assert_udp_received("neat:1|c")
  end)
end)

describe("decrement", function()
  it("decrements", function()
    statsd:decrement("neat", 5)
    assert_udp_received("neat:-5|c")
  end)
  it("decrements down by one", function()
    statsd:decrement("neat")
    assert_udp_received("neat:-1|c")
  end)
end)

describe("timer", function()
  it("records a timer", function()
    statsd:timer("cool", 125.3)
    assert_udp_received("cool:125.3|ms")
  end)
end)

describe("histogram", function()
  it("records a histogram", function()
    statsd:histogram("cool", 99)
    assert_udp_received("cool:99|h")
  end)
end)

describe("meter", function()
  it("records a meter", function()
    statsd:meter("cool", 99)
    assert_udp_received("cool:99|m")
  end)
end)

describe("escape characters", function()
  it("escape", function()
    statsd:meter("c:o@o|l", 99)
    assert_udp_received("c_o_o_l:99|m")
  end)
end)
