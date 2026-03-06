-- Print all prime numbers up to n

local function primes(n)
    local function isPrime(num)
        for i = 2, math.floor(math.sqrt(num)) do
            if num % i == 0 then
                return false
            end
        end
        return true
    end

    for i = 2, n do
        if isPrime(i) then
            print(i)
        end
    end
end

primes(20)
