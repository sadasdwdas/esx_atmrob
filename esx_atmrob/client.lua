ESX = exports['es_extended']:getSharedObject()
local robbedATMs = {}

-- Function to check if an ATM can be robbed and return the remaining cooldown time
local function canRobATM(atm)
    if robbedATMs[atm] then
        local elapsedTime = (GetGameTimer() - robbedATMs[atm]) / 1000
        local remainingTime = Config.ATMCooldown - elapsedTime
        if remainingTime > 0 then
            return false, remainingTime
        else
            robbedATMs[atm] = nil
            return true, 0
        end
    end
    return true, 0
end

local function applyShockEffect()
    local playerPed = PlayerPedId()

    SetPedToRagdoll(playerPed, 30000, 30000, 0, true, true, false)

    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + 50000 -- 30 seconds shock + 20 seconds drunk

        -- Start drunk effect immediately
        SetPedIsDrunk(playerPed, true)
        ShakeGameplayCam('DRUNK_SHAKE', 1.0)
        SetTimecycleModifier('spectator5')

        while GetGameTimer() < endTime do
            Citizen.Wait(0)
            DisableAllControlActions(0)

            if GetGameTimer() >= endTime - 20000 then
                EnableAllControlActions(0)
            end
        end

        SetPedIsDrunk(playerPed, false)
        ShakeGameplayCam('DRUNK_SHAKE', 0.0)
        ClearTimecycleModifier()
    lib.notify({
        title = 'Automaatti',
        description = 'Palautit tajuntasi!',
        type = 'succes'
    })
    end)
end

local function robATM(atm)
    local canRob, remainingTime = canRobATM(atm)

    if not canRob then
        local hours = math.floor(remainingTime / 3600)
        local minutes = math.floor((remainingTime % 3600) / 60)
        local seconds = math.floor(remainingTime % 60)
        lib.notify({
            title = 'ATM Robbery',
            description = ('Tässä automaatissa on cooldown odota: %02d:%02d:%02d'):format(hours, minutes, seconds),
            type = 'error'
        })
        return
    end

    local success = lib.skillCheck({'easy', 'easy'})

    if success then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = {'police'}, 
            coords = data.coords,
            title = 'Automaattiryöstö',
            message = '' .. data.sex .. ' Ryöstää automaattia kohteessa: ' .. data.street, 
            flash = 0,
            unique_id = data.unique_id,
            sound = 1,
            blip = {
                sprite = 161, 
                scale = 0.8, 
                colour = 3,
                flashes = false, 
                text = 'Automaatti ryöstö',
                time = 5,
                radius = 0,
            }
        })

        lib.progressCircle({
            duration = 20000,
            label = 'Ryöstetään automaattia...',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true
            },
            anim = {
                dict = 'missheist_jewel',
                clip = 'smash_case'
            }
        })

        Citizen.Wait(500)

        if math.random(100) <= Config.ShockChance then
            lib.notify({
                title = 'Automaatti ryöstö',
                description = 'Menetit tajuntasi sähköiskusta.',
                type = 'error'
            })
            applyShockEffect()
        else
            local amount = math.random(Config.Reward.min, Config.Reward.max)
            TriggerServerEvent('atmRobbery:reward', amount)
            robbedATMs[atm] = GetGameTimer()
            lib.notify({
                title = 'Automaatti ryöstö',
                description = 'Ryöstit automaatin onnistuneesti!',
                type = 'success'
            })
        end
    else
        lib.notify({
            title = 'Automaatti ryöstö',
            description = 'Epäonnistuit!',
            type = 'error'
        })
    end
end

local function hasCrowbarInHand()
    local playerPed = PlayerPedId()
    local currentWeaponHash = GetSelectedPedWeapon(playerPed)
    return currentWeaponHash == GetHashKey('weapon_crowbar')
end

for _, prop in ipairs(Config.ATMProps) do
    exports.ox_target:addModel(prop, {
        {
            event = 'atmRobbery:start',
            icon = 'fa-solid fa-money-bill',
            label = 'Ryöstä automaatti',
            canInteract = function(entity, distance, data)
                return hasCrowbarInHand()
            end
        }
    })
end

RegisterNetEvent('atmRobbery:start')
AddEventHandler('atmRobbery:start', function(data)
    if hasCrowbarInHand() then
        robATM(data.entity)
    else
        lib.notify({
            title = 'Automaatti ryöstö',
            description = 'Tarvitset sorkkaraudan käteesi.',
            type = 'error'
        })
    end
end)
