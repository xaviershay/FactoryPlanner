local Object = require("backend.data.Object")
local DistrictItem = require("backend.data.DistrictItem")

---@alias DistrictItemCategory "product" | "ingredient"

---@class DistrictItemSet: Object, ObjectMethods
---@field class "DistrictItemSet"
---@field category DistrictItemCategory
---@field first DistrictItem?
---@field map { [FPItemPrototype]: DistrictItem }
local DistrictItemSet = Object.methods()
DistrictItemSet.__index = DistrictItemSet
script.register_metatable("DistrictItemSet", DistrictItemSet)

---@param category DistrictItemCategory
---@return DistrictItemSet
local function init(category)
    local object = Object.init({
        category = category,
        first = nil,
        map = {}
    }, "DistrictItemSet", DistrictItemSet)  --[[@as DistrictItemSet]]
    return object
end


function DistrictItemSet:index()
    OBJECT_INDEX[self.id] = self
    for district_item in self:iterator() do district_item:index() end
end


---@param proto FPItemPrototype
---@param amount number
function DistrictItemSet:add_item(proto, amount)
    local existing_item = self.map[proto]
    if existing_item then
        existing_item.amount = existing_item.amount + amount
    else
        local district_item = DistrictItem.init(proto, amount)
        district_item.parent = self
        self:_insert(district_item)
        self.map[district_item.proto] = district_item
    end
end


---@param filter ObjectFilter?
---@param pivot DistrictItem?
---@param direction NeighbourDirection?
---@return fun(): DistrictItem?
function DistrictItemSet:iterator(filter, pivot, direction)
    return self:_iterator(filter, pivot, direction)
end


-- Sorts (awkwardly) based on type first ("item" before "fluid") and then amount
local function item_compare(a, b)
    local a_type, b_type = a.proto.type, b.proto.type
    if a_type < b_type then return true
    elseif a_type > b_type then return false
    elseif a.amount < b.amount then return true
    elseif a.amount > b.amount then return false end
    return false
end

function DistrictItemSet:sort()
    local next_object = self.first
    self.first = nil  -- clear to re-insert into below

    while next_object ~= nil do
        local current_object = next_object
        next_object = next_object.next

        local inserted = false
        for object in self:iterator() do
            if item_compare(object, current_object) then
                self:_insert(current_object, object, "previous")
                inserted = true
                break
            end
        end
        if not inserted then  -- first or last element
            self:_insert(current_object)
        end
    end
end


function DistrictItemSet:clear()
    self.first = nil
    self.map = {}
end

return {init = init}
