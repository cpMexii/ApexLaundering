Bridge = {}

local function started(res) return GetResourceState(res) == 'started' end

local ESX, QB
if started('qbx_core') then
    Bridge.name = 'qbx'
elseif started('qb-core') then
    Bridge.name = 'qb'
    QB = exports['qb-core']:GetCoreObject()
elseif started('es_extended') then
    Bridge.name = 'esx'
    ESX = exports.es_extended:getSharedObject()
else
    error('^1[ApexLaundering] No framework found. Start qbx_core, qb-core or es_extended before this resource.^0')
end

local ox = started('ox_inventory')
local oxlib = started('ox_lib')
local isESX = Bridge.name == 'esx'
print(('[ApexLaundering] framework: %s, inventory: %s'):format(Bridge.name, ox and 'ox_inventory' or 'framework'))

function Bridge.getPlayer(src)
    if isESX then return ESX.GetPlayerFromId(src) end
    if QB then return QB.Functions.GetPlayer(src) end
    return exports.qbx_core:GetPlayer(src)
end

function Bridge.identifier(p)
    return isESX and p.identifier or p.PlayerData.citizenid
end

-- Server id of the online player with this identifier, or nil.
function Bridge.findSource(identifier)
    for _, id in ipairs(GetPlayers()) do
        local p = Bridge.getPlayer(tonumber(id))
        if p and Bridge.identifier(p) == identifier then return tonumber(id) end
    end
end

-- Calls fn(src, player) when a character finishes loading in.
function Bridge.onPlayerLoaded(fn)
    if isESX then
        AddEventHandler('esx:playerLoaded', function(src, p) fn(src, p) end)
    else
        AddEventHandler('QBCore:Server:PlayerLoaded', function(p) fn(p.PlayerData.source, p) end)
    end
end

function Bridge.addCash(p, amount)
    if isESX then return p.addMoney(amount) end
    return p.Functions.AddMoney('cash', amount, 'laundering')
end

function Bridge.notify(src, msg, kind)
    if oxlib then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Laundromat', description = msg, type = kind })
    elseif isESX then
        TriggerClientEvent('esx:showNotification', src, msg)
    else
        TriggerClientEvent('QBCore:Notify', src, msg, kind)
    end
end

local function isCop(p)
    local job = isESX and p.job or p.PlayerData.job
    if not job then return false end
    local onDuty = isESX and job.onDuty ~= false or job.onduty
    return onDuty and (Config.PoliceJobs[job.name] or job.type == 'leo') or false
end

function Bridge.countPolice()
    local n = 0
    for _, id in ipairs(GetPlayers()) do
        local p = Bridge.getPlayer(tonumber(id))
        if p and isCop(p) then n = n + 1 end
    end
    return n
end

-- Removes up to `max` dirty money (nil = all of it) and returns the worth taken.
-- Marked bills can't be split, so only bags that fit under what's left are taken;
-- black money fills the rest exactly.
function Bridge.takeDirty(src, p, max)
    local worth = 0
    local function left() return max and max - worth or math.huge end
    local bills = Config.MarkedBillsItem

    if bills and ox then
        for _, s in pairs(exports.ox_inventory:Search(src, 'slots', bills) or {}) do
            local w = tonumber(s.metadata and s.metadata.worth)
            local n = w and w > 0 and math.min(s.count, left() // w) or 0
            if n > 0 and exports.ox_inventory:RemoveItem(src, bills, n, nil, s.slot) then
                worth = worth + w * n
            end
        end
    elseif bills and not isESX then
        for _, s in pairs(p.PlayerData.items) do
            local w = s.name == bills and type(s.info) == 'table' and tonumber(s.info.worth)
            local n = w and w > 0 and math.min(s.amount, left() // w) or 0
            if n > 0 and p.Functions.RemoveItem(bills, n, s.slot) then
                worth = worth + w * n
            end
        end
    end

    if isESX and Config.BlackMoneyAccount then
        local acc = p.getAccount(Config.BlackMoneyAccount)
        local n = acc and math.min(acc.money, left()) or 0
        if n > 0 then
            p.removeAccountMoney(acc.name, n)
            worth = worth + n
        end
    elseif ox and Config.BlackMoneyItem then
        local n = math.min(exports.ox_inventory:GetItemCount(src, Config.BlackMoneyItem) or 0, left())
        if n > 0 and exports.ox_inventory:RemoveItem(src, Config.BlackMoneyItem, n) then
            worth = worth + n
        end
    end

    return worth
end
