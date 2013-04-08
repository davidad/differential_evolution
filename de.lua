local ffi = require("ffi")

PRINT_DOTS = false
PRINT_NEWBEST = false
PRINT_MOVEMENTS = false
PRINT_FINAL_ANSWER = true

local function unibox_guess(v, N)
    for i = 0, N-1 do
        v[i] = math.random()
    end
end

local function print_vec(v, N)
    io.write '[ '
    for i = 0, N-1 do
        io.write(string.format("%-10.5g ",v[i]))
    end
    io.write ']'
end

local doubles = ffi.typeof("double[?]")

local function differential_evolution(result, N, f, F, CR, NP, guess, iters)
    if (not (F and F >= 0 and F <= 2)) then
        F = 1.0
    end
    if (not (CR and CR >= 0 and CR <= 1)) then
        CR = 0.8
    end
    if (not (NP and NP >= 4)) then
        NP = 4
    end
    if (not guess) then
        guess = unibox_guess
    end
    
    local xs = ffi.new(doubles, N*NP)

    for x = 0, NP-1 do
        guess(xs+(x*N),N)
    end
    
    local y = ffi.new(doubles, N)

    local bestf = tonumber("infinity")
    local bestx = 0
    local fs = ffi.new(doubles, NP)
    for x = 0, NP-1 do
        fs[x] = f(xs+x*N)
    end
    repeat
        for x = 0, NP-1 do
            local xp = xs+x*N
            local a,b,c
            repeat a = math.random(0,NP-1) until (a ~= x)
            repeat b = math.random(0,NP-1) until (b ~= x and b ~= a)
            repeat c = math.random(0,NP-1) until (c ~= x and c ~= a and c ~= b)
            local R = math.random(0,N-1)
            for i = 0, N-1 do
                r = math.random()
                if (r < CR or i == R) then
                    y[i] = xs[a*N+i] + F*(xs[b*N+i] - xs[c*N+i])
                else
                    y[i] = xp[i]
                end
            end
            local fy = f(y)
            local fx = fs[x]
            if(fy < fx) then
                if(PRINT_MOVEMENTS) then
                    io.write(string.format("Moving #%d from ",x))
                    print_vec(xp,N)
                    io.write(string.format(" (f: %e) to ",fx))
                    print_vec(y, N)
                    io.write(string.format(" (f: %e)\n",fy))
                end
                ffi.copy(xp,y,ffi.sizeof(doubles,N))
                fs[x] = fy
                if(fy < bestf) then
                    bestf = fy
                    bestx = x
                    if(PRINT_NEWBEST) then
                        io.write(string.format("\nNew best f(x): %e ",bestf))
                        print_vec(xp, N)
                        io.write("\n")
                    end
                end
            end
        end
        iters = iters - 1
    until (iters == 0)
    ffi.copy(result,xs+bestx*N,ffi.sizeof(doubles,N))   
    return bestf
end

local tgt = {[0]=1.0, -2.0, 3.0, -4.0, 5.0, -6.0, 7.0, -8.0, 9.0, -10.0, 11.0, -12.0, 13.0, -14.0, 15.0, -16.0, 17.0, -18.0, 19.0, -20.0, 21.0, -22.0, 23.0, -24.0, 25.0, -26.0, 27.0, -28.0, 29.0, -30.0, 31.0, -32.0}
local N = #tgt

local total_f_evals = 0

local function test_f(v)
    total_f_evals = total_f_evals + 1
    if(PRINT_DOTS) then
        io.write(".")
    end
    local acc = 0.0
    for i = 0, N-1 do
        local diff = v[i] - tgt[i]
        acc = acc + diff*diff
    end
    return acc
end

local iters = 1100
local runs = 50
local F, CR, NP = 1.0, 0.0, 40
if arg[1] then
    iters = tonumber(arg[1])
    if arg[2] then
        runs = tonumber(arg[2])
        if arg[3] then
            NP = tonumber(arg[3])
            if arg[4] then
                CR = tonumber(arg[4])
                if arg[5] then
                    F = tonumber(arg[5])
                end end end end end

math.randomseed(os.time())
local result = ffi.new(doubles,N)
repeat
    local bestf = differential_evolution(result,N,test_f,F,CR,NP,nil,iters)
    if(PRINT_FINAL_ANSWER) then
        io.write(string.format("\nFINAL X  f(X): %e ",bestf))
        print_vec(result,N)
        io.write(string.format("\nwith %d total function evaluations\n", total_f_evals))
    end
    runs = runs - 1
until runs == 0
