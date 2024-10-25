---@diagnostic disable

local parts = require("solver.parts")
local framework = require("solver.framework")
-- Doing the following is really bad, but writing a proper interface kinda is as well
--      Also, it doesn't work without dumb changes to the main mod, so this whole test
--      setup is non-functional and untested until the requires are cleaned up
require("__factoryplanner__.control")  -- pull in all the crap
local Factory = require("__factoryplanner__.backend.data.Factory")
local District= require("__factoryplanner__.backend.data.District")
local Product = require("__factoryplanner__.backend.data.Product")
local Line = require("__factoryplanner__.backend.data.Line")

-- Proof of concept builder object. Needs to be moved to a new file, documented, etc...
FactoryBuilder = {}

function FactoryBuilder:new (o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

function FactoryBuilder:set_goal(item, amount)
    local proto = prototyper.util.find("items", item, "item")
    -- See picker_dialog#close_picker_dialog
    local goal = Product.init(proto)
    goal.required_amount = amount
    self.factory:insert(goal)
end

function FactoryBuilder:add_recipe(recipe)
    local recipe_proto = prototyper.util.find("recipes", "iron-plate", nil)
    local line = Line.init(recipe_proto, "produce")
    line:change_machine_to_default(self.player)
    self.factory.top_floor:insert(line)
end

function builder(player, name)
    local f = Factory.init(name)
    -- A district is necessary for a location/pollutant_type
    f.parent = District.init("Test District")

    return FactoryBuilder:new {
        player = player,
        factory = f,
    }
end

local tests = {
    {
        name = "example_subfactory",
        builder = (function(player)
            local f = builder(player, "Test 1")
            f:set_goal("iron-plate", 10)
            f:add_recipe("iron-plate")
            return f.factory
        end),
        body = (function(subfactory)
            -- TODO: This is all very temporary proof-of-concept
            local EPSILON = 0.00001
            local expected = 10.0
            local ore_ingredient = subfactory.top_floor.ingredients.items[1]
            if not ore_ingredient then
                return "Did not find expected ingredient"
            end
            if ore_ingredient.proto.name == "iron-ore" and (math.abs(ore_ingredient.amount - expected) < EPSILON) then
                return "pass"
            else
                return "Expected " .. expected .. " got " .. ore_ingredient.amount
            end
            -- The framework needs to change but I don't know what too yet.
            --return framework.check_top_level_product(subfactory, "iron-plate", 10)
        end)
    }
}

local function runner(test)
    local player = game.get_player(1)
    local subfactory = test.builder(player)
    -- Handy to have in output for debugging
    print(util.porter.generate_export_string({subfactory}))
    if not subfactory.valid then error("Loaded subfactory setup is invalid") end
    solver.update(player, subfactory)  -- jank

    return test.body(subfactory)
end

for _, test in pairs(tests) do test.runner = runner end
return tests
