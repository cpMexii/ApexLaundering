Config = {}

-- Wash time scales with the amount loaded: MinTime + MinutesPer1000 per $1000, capped at MaxTime.
-- Defaults: $500 = 6 min, $5,000 = 15 min, $20,000 = 45 min, $27,500+ = 60 min
Config.MinTime = 5               -- minutes even the smallest load takes
Config.MinutesPer1000 = 2        -- extra minutes per $1000 of dirty money loaded
Config.MaxTime = 60              -- longest a wash can take, in minutes

Config.PoliceBonus = 0.05        -- added to a machine's rate per on-duty cop (risk = reward)
Config.MaxRate = 0.85            -- rate cap, so lots of cops never makes laundering profitable
Config.PoliceJobs = { police = true, sheriff = true, bcso = true, sasp = true } -- qb/qbox jobs with type 'leo' also count

-- Dirty money sources. All of them are taken when a machine is loaded. Set any to false to disable.
Config.MarkedBillsItem = false             -- e.g. 'markedbills': item with info/metadata.worth (qb-inventory, ox_inventory)
Config.BlackMoneyItem = 'black_money'      -- ox_inventory item counted $1 each (QBCore/Qbox only)
Config.BlackMoneyAccount = 'black_money'   -- ESX account

Config.UseTarget = false     -- false = press E at the machine, true = ox_target / qb-target
Config.InteractDistance = 1.0
Config.AreaRadius = 15.0     -- timer box shows within this distance of the machines

-- Default coords are for gtaDPS's Abandoned Laundromat MLO.
-- rate = share of dirty money returned clean
Config.Machines = {
    { coords = vec3(1136.28, -992.11, 46.11), rate = 0.6 },
    { coords = vec3(1136.09, -990.77, 46.11), rate = 0.6 },
    { coords = vec3(1135.98, -989.56, 46.11), rate = 0.6 },
    { coords = vec3(1135.74, -988.05, 46.11), rate = 0.6 },
}
