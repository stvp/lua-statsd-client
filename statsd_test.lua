local Statsd = require "statsd"
local statsd = nil

function assert_udp_received(string)
  assert.equal(statsd.sent_with, string)
end

function assert_udp_received_multipe(value1, value2)
  local flag = (statsd.sent_with == value1 .. '\n' .. value2) 
            or (statsd.sent_with == value2 .. '\n' .. value1)
  assert.is_true(flag)
end

before_each(function()
  statsd = nil
  statsd = Statsd()

  --stub send_to_socket
  statsd.send_to_socket = function(self, string)
    self.sent_with = string
    return #string
  end
end)

describe("gauge", function()
  it("sets a simple gauge", function()
    statsd:gauge("foo", 10)
    assert_udp_received("foo:10|g")
  end)

  it("sets a multiple gauge", function()
    statsd:gauge{
      foo = 10;
      boo = 20;
    }
    assert_udp_received_multipe("foo:10|g", "boo:20|g")
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

  it("counts multiple", function()
    statsd:counter{
      foo = 5;
      boo = -10;
    }
    assert_udp_received_multipe("foo:5|c", "boo:-10|c")
  end)

  it("counts array", function()
    statsd:counter{"foo","boo"}
    assert_udp_received_multipe("foo:1|c", "boo:1|c")
  end)

  it("counts array no value", function()
    statsd:counter({"foo","boo"}, 10)
    assert_udp_received_multipe("foo:1|c|@10", "boo:1|c|@10")
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

  it("increments multiple", function()
    statsd:increment{foo = 5;boo = 10;}
    assert_udp_received_multipe("foo:5|c", "boo:10|c")
  end)

  it("increments array", function()
    statsd:increment{"foo", "boo"}
    assert_udp_received_multipe("foo:1|c", "boo:1|c")
  end)

  it("increments array no value", function()
    statsd:increment({"foo", "boo"}, 10)
    assert_udp_received_multipe("foo:1|c|@10", "boo:1|c|@10")
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

  it("decrements multiple", function()
    statsd:decrement{foo = 5;boo = 10;}
    assert_udp_received_multipe("foo:-5|c", "boo:-10|c")
  end)

  it("decrements array", function()
    statsd:decrement{"foo", "boo"}
    assert_udp_received_multipe("foo:-1|c", "boo:-1|c")
  end)

  it("decrements array no value", function()
    statsd:decrement({"foo", "boo"}, 10)
    assert_udp_received_multipe("foo:-1|c|@10", "boo:-1|c|@10")
  end)

end)

describe("timer", function()
  it("records a timer", function()
    statsd:timer("cool", 125.3)
    assert_udp_received("cool:125.3|ms")
  end)

  it("records a multiple timers", function()
    statsd:timer{
      t1 = 125.3;
      t2 = 321.4;
    }
    assert_udp_received_multipe("t1:125.3|ms","t2:321.4|ms")
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
