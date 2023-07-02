---@diagnostic disable

local migration = {}

function migration.subfactory(subfactory, player)
    if util.globals.settings(player).belts_or_lanes == "lanes" then
        for _, product in pairs(subfactory.Product.datasets) do
            if product.required_amount.defined_by == "belts" then
                product.required_amount.defined_by = "lanes"
                product.required_amount.amount = product.required_amount.amount * 2
            end
        end
    end
end

return migration