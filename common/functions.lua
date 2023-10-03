local addOn, ICT = ...

-- Returns a function that simply returns the provided value.
function ICT:returnX(x)
    return function(...) return x end
end

--- Creates a function adding the result of two functions.
---@generic T : any
---@param left fun(self: T): number
---@param right fun(self: T): number
---@return fun(self: T): number
function ICT:add(left, right)
    return function(v) return left(v) + right(v) end
end

--- Creates a function that takes function and supplies parameters to the call.
---@generic T : any
---@generic U : any
---@param f fun(self: T, U): boolean
---@param v1 U 
---@return fun(self: T): boolean
function ICT:fWith(f, v1)
    return function(v) return f(v, v1) end
end

--- Creates a function that negates the provided function.
---@generic T : any
---@param f fun(self: T): boolean
---@return fun(self: T): boolean
function ICT:fNot(f)
    return function(v) return not f(v) end
end

--- Creates a function that and's two functions together with the same input.
---@generic T : any
---@param f fun(self: T): boolean
---@param g fun(self: T): boolean
---@return fun(self: T): boolean
function ICT:fAnd(f, g)
    return function(v) return f(v) and g(v) end
end

--- Creates a function that or's two functions together with the same input.
---@generic T : any
---@param f fun(self: T): boolean
---@param g fun(self: T): boolean
---@return fun(self: T): boolean
function ICT:fOr(f, g)
    return function(v) return f(v) or g(v) end
end