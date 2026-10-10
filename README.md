# ApexLaundering

Laundromat money laundering for **Qbox**, **QBCore** and **ESX**. Load dirty money into a washing machine, wait out the cycle, and collect clean cash. Framework and inventory are detected automatically.

## Features
- **Every framework**: Qbox, QBCore and ESX, with ox_inventory or qb-inventory
- **Choose your amount**: wash a set amount, or leave it empty to wash everything
- **Wash time scales with the amount**: small loads are quick, big loads take longer
- **Dirty money sources**: `black_money` item (ox_inventory), `black_money` account (ESX), `markedbills` with a worth value (optional)
- **E key or target**: press E by default, or switch to ox_target / qb-target
- **Live timer box** while you're inside the laundromat, plus a **Check Time** option at your machine
- **Relog and restart safe**: loads belong to the character and are saved across server restarts
- **Notifications** when the cycle finishes, or on your next login if you were offline
- **Police risk**: each on-duty cop raises the return rate, capped so laundering never pays more than you put in
- **Server-side checks** on everything: distance, ownership, amount, one load per character
- **Optional machine sounds** with interact-sound

## Requirements
- One of: `qbx_core`, `qb-core`, `es_extended`
- Optional: `ox_lib` (notifications and amount dialog), `ox_inventory`, `ox_target` or `qb-target`, `interact-sound`
- Map: [gtaDPS Abandoned Laundromat](https://www.gta5-mods.com/maps/abandoned-laundromat-interior-singleplayer-fivem-gtadps) interior, or set your own machine coords in `config.lua`

## Install
1. Download and drop the `ApexLaundering` folder into your resources.
2. Add `ensure ApexLaundering` to `server.cfg` **after** your framework and inventory.
3. Optional sounds: put `washingmachine.ogg` and `washingmachinedone.ogg` in `interact-sound/client/html/sounds/` (included in the original qb-overlord-laundering release).

## Wash times (default)
`MinTime + MinutesPer1000 per $1,000`, capped at `MaxTime`: 5 min + 2 min per $1,000, max 60 min.

| Loaded | Time |
|---|---|
| $500 | 6 min |
| $5,000 | 15 min |
| $10,000 | 25 min |
| $20,000 | 45 min |
| $27,500+ | 60 min |

## Config
Everything is in `config.lua`: wash times, return rate per machine, police bonus and cap, police jobs, dirty money items/account, E or target, interact distance, timer area size and machine coords.

## Admin
`/launderfinish [machine]` instantly finishes a wash. With no number it picks the nearest washing machine. Works from the server console too (machine number required there).

```
add_ace group.admin apexlaundering.finish allow
```

## Credits
Based on qb-overlord-laundering by OverlordRP, rewritten for multi-framework support.
