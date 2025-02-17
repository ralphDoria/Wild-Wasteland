--!strict

--[[
What is above is called the type inferencing mode, and it can be changed between strict, nocheck, nonstrict (default mode)
 - Defined how the type checker for lua should infer the types of variables

Dynamically vs statically typed languages
 - Dynamically: Variables can change values during run time (e.g. from a number to a string)
    (e.g. Luau)
 - Statically: Variable types have to have their values declared and can't change during run time
    (e.g Java)
]]

local function map<T, K>(tbl : {T}, mapping : (T) -> (K)) : {K}
    local newTbl = {}

    for i, v in tbl do
        newTbl[i] = mapping(v)
    end

    return newTbl
end

print(map(
    {1, 2, 3}, 
    function(num)
        return tostring(num)
    end
))

print(map(
    {1, 2, 3}, 
    function(num)
        return num * 10
    end
))


type ExampleType = {
    CFrame
}

local array : ExampleType

local foo : () -> ()