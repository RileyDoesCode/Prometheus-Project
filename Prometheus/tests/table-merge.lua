-- Demonstrate deterministic table merging and traversal

--------------------------------------------------
-- Input tables
--------------------------------------------------

local breakfast = { eggs = 4, bacon = 3 }
local lunch = { bacon = 1, toast = 5 }

--------------------------------------------------
-- Merge function
--------------------------------------------------

local function mergeQuantities(a, b)
    local totals = {}

    for k, v in pairs(a) do
        totals[k] = v
    end

    for k, v in pairs(b) do
        totals[k] = (totals[k] or 0) + v
    end

    return totals
end

--------------------------------------------------
-- Execution
--------------------------------------------------

local merged = mergeQuantities(breakfast, lunch)

local order = { "eggs", "bacon", "toast" }

for _, item in ipairs(order) do
    print(string.format("%s:%d", item, merged[item] or 0))
end
