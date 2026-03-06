-- Deterministic text statistics for repeated words

--------------------------------------------------
-- Input text
--------------------------------------------------

local passage = "lorem ipsum dolor sit amet ipsum lorem"

--------------------------------------------------
-- Word counting
--------------------------------------------------

local counts = {}

for word in passage:gmatch("%w+") do
    counts[word] = (counts[word] or 0) + 1
end

--------------------------------------------------
-- Deterministic output order
--------------------------------------------------

local order = { "lorem", "ipsum", "dolor", "sit", "amet" }

for _, word in ipairs(order) do
    print(string.format("%s:%d", word, counts[word] or 0))
end
