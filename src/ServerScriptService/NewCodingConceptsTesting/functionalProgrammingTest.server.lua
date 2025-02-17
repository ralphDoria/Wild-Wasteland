type Person = {
    FirstName : string,
    LastName : string,
    Age : number
}

local people : {Person} = {
    {FirstName = "Bob", LastName = "Smith", Age = 22},
    {FirstName = "John", LastName = "Doe", Age = 25},
    {FirstName = "Jane", LastName = "Doe", Age = 25},
    {FirstName = "Sam", LastName = "Roe", Age = 41}
}

--[[
A higher order function is a function that takes another function as a parameter or returns a function.
The Filter and Map functions below are considered higher order functions.
]]

local function Filter<T>(tbl : {T}, predicate : (value : T) -> boolean)
    local newTable = {}

    for _, v in tbl do
        if predicate(v) then
            table.insert(newTable, v)
        end
    end

    return newTable
end

local function Map(tbl, mapping)
    local newTable = {}

    for i, v in  tbl do
        newTable[i] = mapping(v)
    end

    return newTable
end

local function FilterAgeOver24(person) --predicate
    return person.Age > 24
end
local function GetFullName(person)
    return person.FirstName .. " " .. person.LastName
end

local fullNamesOver24 = Map(Filter(people, FilterAgeOver24), GetFullName)

local FullNamesUnderOrEqual22 = Map(
    Filter(people, function(person)
        return person.Age <= 22
    end),
    GetFullName
)
--[[
VS. :

local fullNamesUnder22 = {}
for _, person in people do
    if person.Age <= 22 then
        table.insert(fullNamesUnder22, GetFullName(person))
    end
end

Which is more readable? At first I thought the non-function programming approach, but now looking at it unbiased
and trying to avoid belief perserverence, I think the functional programming approach is more readable.
]]

local lastNamesOver40 = Map(
    Filter(people, function(person)
        return person.Age > 40
    end), 
    function(person)
        return person.LastName
    end
)

--[[
In pure functional programming languages, there aren't loops. Recusion is used in place of loops.
]]

local function iterate<T>(array : {T}, a : (T) -> any?, index : number)
    local value = array[index]
    a(value)
    if index < #array then
        return iterate(array, a, index + 1)
    end
end


iterate(people, function(person)
    print(person.FirstName)
end, 1)

--[[
print(fullNamesOver24)
print(FullNamesUnderOrEqual22)
print(lastNamesOver40)
]]