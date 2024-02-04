function assertEquals(expected, actual)
    if expected ~= actual then
        print(string.format("Expected %s but was %s", expected, actual))
        assert(false)
    end
end

function concat(pairs)
    local s = ""
    for _, v in pairs do
        if s:len() == 0 then
            s = tostring(v)
        else
            s = s .. "" .. v
        end
    end
    return s
end

function assertOrderedEquals(expected, actual)
    expected = table.concat(expected)
    actual = concat(actual)
    assertEquals(expected, actual)
end

function assertUnorderedEquals(expected, actual)
    assertOrderedEquals(expected, ICT:nspairs(ICT:toTable(actual)))
end