 local GeneralGuiUtility = {}

 --[[
    Takes a string, "deletes" any character that's not a number, and then returns it.
 ]]
function GeneralGuiUtility.stripNonNumbers(text : string)
    return text:gsub("%D","")
end

function GeneralGuiUtility.commaValue(amount : number)
    local formatted = amount
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k==0 then
            break
        end
    end

    return formatted
end

return GeneralGuiUtility