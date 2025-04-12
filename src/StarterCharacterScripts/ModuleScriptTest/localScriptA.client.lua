local module = require("./module")

task.wait()

print(module.getValue())
module.incrementValue()