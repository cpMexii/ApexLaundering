local state = GlobalState.ApexLaundering or {}
local inside = false -- player is inside the laundromat area
AddStateBagChangeHandler('ApexLaundering', 'global', function(_, _, value)
    state = value or {}
    if inside then TriggerServerEvent('ApexLaundering:myLoad') end
end)

local function DrawText3D(c, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(c.x, c.y, c.z, 0)
    DrawText(0.0, 0.0)
    DrawRect(0.0, 0.0125, 0.017 + #text / 370, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Returns amount (nil = all) and whether the player cancelled.
local function askAmount()
    if GetResourceState('ox_lib') == 'started' then
        local input = exports.ox_lib:inputDialog('Washing Machine', {
            { type = 'number', label = 'Dirty money to wash', description = 'Leave empty to wash all of it', placeholder = 'All', min = 1 },
        })
        if not input then return nil, true end
        return input[1], false
    end

    AddTextEntry('APEXLAUNDER', 'Dirty money to wash (empty = all)')
    DisplayOnscreenKeyboard(1, 'APEXLAUNDER', '', '', '', '', '', 10)
    while UpdateOnscreenKeyboard() == 0 do Wait(0) end
    if UpdateOnscreenKeyboard() ~= 1 then return nil, true end
    local text = GetOnscreenKeyboardResult()
    if not text or text == '' then return nil, false end
    local n = tonumber(text)
    if not n then return nil, true end
    return math.floor(n), false
end

local function load(k)
    CreateThread(function()
        local amount, cancelled = askAmount()
        if not cancelled then TriggerServerEvent('ApexLaundering:load', k, amount) end
    end)
end
local function collect(k) TriggerServerEvent('ApexLaundering:collect', k) end
local function check(k) TriggerServerEvent('ApexLaundering:check', k) end

if Config.UseTarget then
    local ox = GetResourceState('ox_target') == 'started'
    for k, m in ipairs(Config.Machines) do
        -- onSelect is ox_target, action is qb-target; each ignores the other
        local options = {
            {
                name = 'apexlaundering_load', icon = 'fas fa-soap', label = 'Load',
                distance = Config.InteractDistance + 0.5,
                canInteract = function() return (state[k] or 0) == 0 end,
                onSelect = function() load(k) end, action = function() load(k) end,
            },
            {
                name = 'apexlaundering_check', icon = 'fas fa-clock', label = 'Check Time',
                distance = Config.InteractDistance + 0.5,
                canInteract = function() return state[k] == 1 end,
                onSelect = function() check(k) end, action = function() check(k) end,
            },
            {
                name = 'apexlaundering_collect', icon = 'fas fa-money-bill', label = 'Collect',
                distance = Config.InteractDistance + 0.5,
                canInteract = function() return state[k] == 2 end,
                onSelect = function() collect(k) end, action = function() collect(k) end,
            },
        }
        if ox then
            exports.ox_target:addSphereZone({ coords = m.coords, radius = 0.6, options = options })
        else
            exports['qb-target']:AddCircleZone('ApexLaundering' .. k, m.coords, 0.6,
                { name = 'ApexLaundering' .. k, useZ = true },
                { options = options, distance = Config.InteractDistance + 0.5 })
        end
    end

    AddEventHandler('onResourceStop', function(res)
        if res ~= GetCurrentResourceName() or ox then return end -- ox_target cleans up its own zones
        for k in ipairs(Config.Machines) do exports['qb-target']:RemoveZone('ApexLaundering' .. k) end
    end)
end

CreateThread(function()
    while not Config.UseTarget do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())
        for k, m in ipairs(Config.Machines) do
            local dist = #(m.coords - pos)
            if dist < Config.InteractDistance then
                sleep = 0
                local s = state[k] or 0
                if s == 0 then
                    DrawText3D(m.coords, '~g~E~w~ - Load')
                    if IsControlJustPressed(0, 38) then load(k) end
                elseif s == 1 then
                    DrawText3D(m.coords, '~r~Washing... ~g~E~w~ - Check Time')
                    if IsControlJustPressed(0, 38) then check(k) end
                else
                    DrawText3D(m.coords, '~g~E~w~ - Collect')
                    if IsControlJustPressed(0, 38) then collect(k) end
                end
                break -- machines sit close together, show one prompt at a time
            elseif dist < 10.0 then
                sleep = math.min(sleep, 200)
            end
        end
        Wait(sleep)
    end
end)

-- Small on-screen timer box while inside the laundromat with a load
local center = vec3(0, 0, 0)
for _, m in ipairs(Config.Machines) do center = center + m.coords end
center = center / #Config.Machines

local myEnd -- GetGameTimer() when our load finishes, nil = no load
RegisterNetEvent('ApexLaundering:myLoad', function(secondsLeft)
    myEnd = secondsLeft and GetGameTimer() + secondsLeft * 1000 or nil
end)

local function drawBox(text)
    DrawRect(0.92, 0.5, 0.13, 0.04, 0, 0, 0, 160)
    SetTextFont(4)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.92, 0.486)
end

CreateThread(function()
    while true do
        local isIn = #(GetEntityCoords(PlayerPedId()) - center) < Config.AreaRadius
        if isIn and not inside then TriggerServerEvent('ApexLaundering:myLoad') end
        inside = isIn
        if inside and myEnd then
            local left = math.max(0, math.ceil((myEnd - GetGameTimer()) / 1000))
            drawBox(left > 0 and ('~r~Washing~w~ %d:%02d'):format(left // 60, left % 60) or '~g~Laundry ready')
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Machine sounds via interact-sound (optional, nothing happens without it)
CreateThread(function()
    local nextSound = {}
    while true do
        local pos = GetEntityCoords(PlayerPedId())
        local now = GetGameTimer()
        for k, m in ipairs(Config.Machines) do
            local s = state[k] or 0
            if s ~= 0 and #(m.coords - pos) < 8.0 and now >= (nextSound[k] or 0) then
                if s == 2 then
                    TriggerEvent('InteractSound_CL:PlayOnOne', 'washingmachinedone', 1.0)
                else
                    TriggerEvent('InteractSound_CL:PlayOnOne', 'washingmachine', 0.1)
                end
                nextSound[k] = now + math.random(15000, 25000)
            end
        end
        Wait(1000)
    end
end)
