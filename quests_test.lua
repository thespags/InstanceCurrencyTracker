local luaUnit = require('./luaunit')

function testAddPositive()
    luaUnit.assertEquals(2,2)
end

os.exit( luaUnit.LuaUnit.run() )