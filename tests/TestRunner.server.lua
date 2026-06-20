--!nocheck
--[[
	TestEZ entry point. Synced into ServerScriptService only by `test.project.json`
	(never by default.project.json), so production builds never include it.

	Run it by serving the test project and pressing Play:
		rojo serve test.project.json
	then in Studio: Play (the runner executes on server start and prints a TextReporter
	summary to Output, erroring if any spec fails).

	It discovers every ModuleScript named `*.spec` under ReplicatedStorage.Tests.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

local results = TestEZ.TestBootstrap:run({ ReplicatedStorage.Tests }, TestEZ.Reporters.TextReporter)

if results.failureCount > 0 then
	error(string.format("TestEZ: %d test(s) failed", results.failureCount), 0)
end
