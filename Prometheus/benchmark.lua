print("PROMETHEUS Benchmark")
print("Based On IronBrew Benchmark")

local ITERATIONS = 100000
print("Iterations: " .. tostring(ITERATIONS))

local totalStart = os.clock()

--------------------------------------------------
-- CLOSURE TEST
--------------------------------------------------
print("CLOSURE testing.")

local start = os.clock()

for i = 1, ITERATIONS do
    (function()
        if not true then
            print("Hey gamer.")
        end
    end)()
end

print("Time:", tostring(os.clock() - start) .. "s")

--------------------------------------------------
-- SETTABLE TEST
--------------------------------------------------
print("SETTABLE testing.")

start = os.clock()

local T = {}

for i = 1, ITERATIONS do
    T[tostring(i)] = "EPIC GAMER " .. tostring(i)
end

print("Time:", tostring(os.clock() - start) .. "s")

--------------------------------------------------
-- GETTABLE TEST
--------------------------------------------------
print("GETTABLE testing.")

start = os.clock()

for i = 1, ITERATIONS do
    T[1] = T[tostring(i)]
end

print("Time:", tostring(os.clock() - start) .. "s")

--------------------------------------------------
-- TOTAL TIME
--------------------------------------------------
print("Total Time:", tostring(os.clock() - totalStart) .. "s")
