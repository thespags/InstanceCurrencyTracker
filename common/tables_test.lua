ICT = {}
loadfile("tables.lua")(nil, ICT)
loadfile("asserts.lua")()
local actual

-- nspairsByValue tests
actual = ICT:nspairsByValue({3, 2, 1})
assertOrderedEquals({1, 2, 3}, actual)

actual = ICT:nspairsByValue({3, 2, 1}, function(v) return v ~= 2 end)
assertOrderedEquals({1, 3}, actual)

actual = ICT:nspairsByValue(nil)
assertOrderedEquals({}, actual)

-- spairsByValue tests
actual = ICT:spairsByValue({"a", "b", "c"}, ICT.reverseSort)
assertOrderedEquals({"c", "b", "a"}, actual)

actual = ICT:spairsByValue({"a", "b", "c"}, ICT.reverseSort, function(v) return v ~= "b" end)
assertOrderedEquals({"c", "a"}, actual)

actual = ICT:spairsByValue(nil)
assertOrderedEquals({}, actual)

actual = ICT:spairsByValue({"a", "b", "c"})
assertOrderedEquals({"a", "b", "c"}, actual)

-- spairs tests
actual = ICT:spairs({a=1, b=2, c=3}, ICT.reverseSort)
assertOrderedEquals({3, 2, 1}, actual)

actual = ICT:spairs({a=1, b=2, c=3}, ICT.reverseSort, function(v) return v ~= "b" end)
assertOrderedEquals({3, 1}, actual)

actual = ICT:spairs(nil)
assertOrderedEquals({}, actual)

-- nspirs tests
actual = ICT:nspairs({a=1, b=2, c=3})
assertOrderedEquals({1, 2, 3}, actual)

actual = ICT:nspairs({a=1, b=2, c=3}, function(k) return k ~= "b" end)
assertOrderedEquals({1, 3}, actual)

actual = ICT:nspairs({a=1, b=2, c=3}, function(_, v) return v ~= 2 end)
assertOrderedEquals({1, 3}, actual)

actual = ICT:nspairs(nil)
assertOrderedEquals({}, actual)

-- fpairs tests
actual = ICT:spairs(ICT:toTable(ICT:fpairs({a=1, b=2, c=3})))
assertUnorderedEquals({1, 2, 3}, actual)

actual = ICT:fpairs({a=1, b=2, c=3}, function(v) return v ~= "b" end)
assertUnorderedEquals({1, 3}, actual)

actual = ICT:fpairs(nil)
assertUnorderedEquals({}, actual)

-- fpairs tests
actual = ICT:fpairsByValue({a=1, b=2, c=3})
assertUnorderedEquals({1, 2, 3}, actual)

actual = ICT:fpairsByValue({a=1, b=2, c=3}, function(v) return v ~= 2 end)
assertUnorderedEquals({1, 3}, actual)

actual = ICT:fpairsByValue(nil)
assertUnorderedEquals({}, actual)

-- containsAllValues tests
actual = ICT:containsAllValues({})
assertEquals(true, actual)

actual = ICT:containsAllValues(nil)
assertEquals(true, actual)

actual = ICT:containsAllValues({true, false})
assertEquals(false, actual)

actual = ICT:containsAllValues({true, true})
assertEquals(true, actual)

actual = ICT:containsAllValues({1, 1}, function(v) return v > 0 end)
assertEquals(true, actual)

actual = ICT:containsAllValues({1, 0}, function(v) return v > 0 end)
assertEquals(false, actual)

-- containsAllValues tests
actual = ICT:containsAnyValue()
assertEquals(false, actual)

actual = ICT:containsAnyValue(nil)
assertEquals(false, actual)

actual = ICT:containsAnyValue({false, false})
assertEquals(false, actual)

actual = ICT:containsAnyValue({true, true})
assertEquals(true, actual)

actual = ICT:containsAnyValue({true, false})
assertEquals(true, actual)

actual = ICT:containsAnyValue({1, 1}, function(v) return v > 0 end)
assertEquals(true, actual)

actual = ICT:containsAnyValue({1, 0}, function(v) return v > 0 end)
assertEquals(true, actual)

actual = ICT:containsAnyValue({0, 0}, function(v) return v > 0 end)
assertEquals(false, actual)

-- sum tests
actual = ICT:sum({})
assertEquals(0, actual)

actual = ICT:sum(nil)
assertEquals(0, actual)

actual = ICT:sum({1, 2, 3})
assertEquals(6, actual)

actual = ICT:sum({1, 2, 3}, function(v) return v * 2 end)
assertEquals(12, actual)

actual = ICT:sum({1, 2, 3}, function(v) return v * 2 end, function(v) return v ~= 2 end)
assertEquals(8, actual)

actual = ICT:sum({1, 2, 3}, nil, function(v) return v ~= 2 end)
assertEquals(4, actual)

-- sum non nil tests
actual = ICT:sumNonNil({})
assertEquals(0, actual)

actual = ICT:sumNonNil(nil)
assertEquals(0, actual)

actual = ICT:sumNonNil({true, false})
assertEquals(1, actual)

actual = ICT:sumNonNil({"a", nil})
assertEquals(1, actual)

-- size tests
actual = ICT:size({})
assertEquals(0, actual)

actual = ICT:size(nil)
assertEquals(0, actual)

actual = ICT:size({a=1, z=2})
assertEquals(2, actual)

-- max tests
actual = ICT:max({})
assertEquals(nil, actual)

actual = ICT:max(nil)
assertEquals(nil, actual)

actual = ICT:max({5})
assertEquals(5, actual)

actual = ICT:max({-2, -5})
assertEquals(-2, actual)

actual = ICT:max({1, 2, 3}, function(v) return v * -1 end)
assertEquals(-1, actual)

actual = ICT:max({1, 2, 3}, nil, function(v) return v < 3 end)
assertEquals(2, actual)

actual = ICT:max({1, 2, 3}, function(v) return v * -1 end, function(v) return v > 1 end)
assertEquals(-2, actual)

-- putIfAbsent tests
local foo = {}
ICT:putIfAbsent(foo, "key", "bar")
assertEquals("bar", foo.key)

ICT:putIfAbsent(foo, "key", "notbar")
assertEquals("bar", foo.key)

actual = ICT:set("foo", "bar")
assertEquals(true, actual.foo)
assertEquals(true, actual.bar)

print("Tests Passed!")