ICT = {}
loadfile("functions.lua")("addon", ICT)
loadfile("asserts.lua")()
local f

f = ICT:returnX(1729)
assertEquals(1729, f())

f = ICT:add(function(v) return v * 2 end, function(v) return v * 3 end)
assertEquals(5, f(1))
assertEquals(10, f(2))

local input = function(a, b) return a * b end
f = ICT:fWith(input, 3)
assertEquals(3, f(1))
assertEquals(12, f(4))
assertEquals(15, f(5))

f = ICT:fNot(function(v) return v == 1729 end)
assertEquals(false, f(1729))
assertEquals(true, f(2000))

f = ICT:fAnd(function(v) return v < 2000 end, function(v) return 1000 < v end)
assertEquals(true, f(1729))
assertEquals(false, f(1000))
assertEquals(false, f(2000))

f = ICT:fOr(function(v) return v > 2000 end, function(v) return 1000 > v end)
assertEquals(false, f(1729))
assertEquals(true, f(500))
assertEquals(true, f(2500))

print("Tests Passed!")