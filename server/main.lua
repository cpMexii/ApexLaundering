local loads = {} -- [machine] = { owner, worth, finishAt, done }

-- Sync to clients and save to KVP so loads survive restarts.
local function sync()
    local state, saved = {}, {}
    for k in ipairs(Config.Machines) do
        local l = loads[k]
        state[k] = l and (l.done and 2 or 1) or 0 -- 0 free, 1 washing, 2 done
        saved[tostring(k)] = l
    end
    GlobalState.ApexLaundering = state
    SetResourceKvp('loads', json.encode(saved))
end

local function finish(load)
    load.done = true
    load.finishAt = math.min(load.finishAt, os.time())
    sync()
    local src = Bridge.findSource(load.owner) -- offline owners get told on login instead
    if src then Bridge.notify(src, 'Washing machine cycle completed.', 'inform') end
end

local function schedule(k, load)
    SetTimeout(math.max(0, load.finishAt - os.time()) * 1000, function()
        if loads[k] == load and not load.done then finish(load) end
    end)
end

for key, l in pairs(json.decode(GetResourceKvpString('loads') or '{}') or {}) do
    local k = tonumber(key)
    if Config.Machines[k] and l.owner and l.finishAt then
        loads[k] = l
        if not l.done then schedule(k, l) end
    end
end
sync()

local function hasLoad(owner)
    for _, l in pairs(loads) do
        if l.owner == owner then return l end
    end
end

local function near(src, k)
    return #(GetEntityCoords(GetPlayerPed(src)) - Config.Machines[k].coords) < Config.InteractDistance + 2.0
end

RegisterNetEvent('ApexLaundering:load', function(k, amount)
    local src = source
    -- nil = wash everything, otherwise a whole number of dollars
    if amount ~= nil and (type(amount) ~= 'number' or amount < 1 or amount > 1e9 or amount % 1 ~= 0) then return end
    local m = Config.Machines[k]
    if not m or loads[k] or not near(src, k) then return end

    local p = Bridge.getPlayer(src)
    if not p then return end
    local owner = Bridge.identifier(p)

    if hasLoad(owner) then
        return Bridge.notify(src, 'You already have a load washing.', 'error')
    end

    local dirty = Bridge.takeDirty(src, p, amount)
    if dirty <= 0 then
        return Bridge.notify(src, amount and 'You don\'t have dirty money that fits that amount.' or 'You have no dirty money.', 'error')
    end

    local rate = math.min(m.rate + Config.PoliceBonus * Bridge.countPolice(), Config.MaxRate)
    local minutes = math.min(Config.MinTime + Config.MinutesPer1000 * dirty / 1000, Config.MaxTime)
    local load = { owner = owner, worth = math.floor(dirty * rate), finishAt = os.time() + math.floor(minutes * 60) }
    loads[k] = load
    sync()
    schedule(k, load)

    Bridge.notify(src, ('Loaded $%d of dirty money. Come back in about %d minutes.'):format(dirty, math.ceil(minutes)), 'success')
end)

-- Sends the caller seconds left on their own load (nil = no load), for the on-screen timer.
RegisterNetEvent('ApexLaundering:myLoad', function()
    local src = source
    local p = Bridge.getPlayer(src)
    if not p then return end
    local l = hasLoad(Bridge.identifier(p))
    TriggerClientEvent('ApexLaundering:myLoad', src, l and math.max(0, l.finishAt - os.time()) or nil)
end)

RegisterNetEvent('ApexLaundering:check', function(k)
    local src = source
    local load = loads[k]
    if not load or load.done or not near(src, k) then return end

    local p = Bridge.getPlayer(src)
    if not p then return end
    if Bridge.identifier(p) ~= load.owner then
        return Bridge.notify(src, 'Someone else\'s load is washing.', 'error')
    end

    local left = math.max(1, math.ceil((load.finishAt - os.time()) / 60))
    Bridge.notify(src, ('About %d minute%s left.'):format(left, left == 1 and '' or 's'), 'inform')
end)

RegisterNetEvent('ApexLaundering:collect', function(k)
    local src = source
    local load = loads[k]
    if not load or not load.done or not near(src, k) then return end

    local p = Bridge.getPlayer(src)
    if not p then return end
    if Bridge.identifier(p) ~= load.owner then
        return Bridge.notify(src, 'This is not your load.', 'error')
    end

    loads[k] = nil
    sync()
    Bridge.addCash(p, load.worth)
    Bridge.notify(src, ('You collected $%d clean cash.'):format(load.worth), 'success')
end)

-- Remind players on login if their laundry finished while they were away
Bridge.onPlayerLoaded(function(src, p)
    local l = hasLoad(Bridge.identifier(p))
    if not l then return end
    SetTimeout(5000, function() -- let the client finish loading so the notify shows
        Bridge.notify(src, l.done and 'Your laundry is ready to collect.'
            or ('Your laundry is still washing, about %d minutes left.'):format(math.max(1, math.ceil((l.finishAt - os.time()) / 60))), 'inform')
    end)
end)

-- /launderfinish [machine]: instantly finish a wash. No number = nearest washing machine.
-- Needs: add_ace group.admin apexlaundering.finish allow
RegisterCommand('launderfinish', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'apexlaundering.finish') then return end
    local function reply(msg, kind)
        if src == 0 then print('[ApexLaundering] ' .. msg) else Bridge.notify(src, msg, kind) end
    end

    local k = tonumber(args[1])
    if not k and src ~= 0 then
        local pos, best = GetEntityCoords(GetPlayerPed(src)), math.huge
        for i, m in ipairs(Config.Machines) do
            local d = #(m.coords - pos)
            if loads[i] and not loads[i].done and d < best then k, best = i, d end
        end
    end

    local load = k and loads[k]
    if not load or load.done then
        return reply(k and ('Machine %d is not washing.'):format(k) or 'Usage: /launderfinish [machine 1-' .. #Config.Machines .. ']', 'error')
    end
    finish(load)
    reply(('Finished machine %d.'):format(k), 'success')
end, false)
