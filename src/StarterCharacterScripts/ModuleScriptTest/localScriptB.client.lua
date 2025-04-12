local module = require("./module")

module.valueChanged:Connect(function(...: any)  
    print(module.getValue())
end)