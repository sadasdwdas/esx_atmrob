ESX = exports['es_extended']:getSharedObject()
local ryostetytAutomaatit = {}
local isShowingTextUI = false

local function voikoRyostaaAutomaatin(automaatti)
    if ryostetytAutomaatit[automaatti] then
        local kulunutAika = (GetGameTimer() - ryostetytAutomaatit[automaatti]) / 1000
        local jaljellaOlevaAika = Config.AutomaattiCooldown - kulunutAika
        if jaljellaOlevaAika > 0 then
            return false, jaljellaOlevaAika
        else
            ryostetytAutomaatit[automaatti] = nil
            return true, 0
        end
    end
    return true, 0
end

local function kaytaIskuEfektia()
    local pelaaja = PlayerPedId()

    SetPedToRagdoll(pelaaja, 30000, 30000, 0, true, true, false)

    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + 50000 

        SetPedIsDrunk(pelaaja, true)
        ShakeGameplayCam('DRUNK_SHAKE', 1.0)
        SetTimecycleModifier('spectator5')

        while GetGameTimer() < endTime do
            Citizen.Wait(0)
            DisableAllControlActions(0)

            if GetGameTimer() >= endTime - 20000 then
                EnableAllControlActions(0)
            end
        end

        SetPedIsDrunk(pelaaja, false)
        ShakeGameplayCam('DRUNK_SHAKE', 0.0)
        ClearTimecycleModifier()
        lib.notify({
            title = 'Automaatti',
            description = 'Palautit tajuntasi!',
            type = 'success'
        })
    end)
end

local function luoPoliisinBlip(sijainti)
    local blip = AddBlipForCoord(sijainti.x, sijainti.y, sijainti.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Automaatti ryöstö")
    EndTextCommandSetBlipName(blip)

    Citizen.CreateThread(function()
        Citizen.Wait(Config.PoliisinBlipKesto * 1000)
        RemoveBlip(blip)
    end)
end

local function ilmoitaPoliisille(data)
    if Config.PoliisinIlmoitus == 'cd' then
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = {'police'}, 
            coords = data.coords,
            title = 'Automaattiryosto',
            message = '' .. data.sex .. ' Ryostaa automaattia kohteessa: ' .. data.street, 
            flash = 0,
            unique_id = data.unique_id,
            sound = 1,
            blip = {
                sprite = 161, 
                scale = 0.8, 
                colour = 3,
                flashes = false, 
                text = 'Automaatti ryosto',
                time = 5,
                radius = 0,
            }
        })
    elseif Config.PoliisinIlmoitus == 'normi' then
        ESX.ShowAdvancedNotification('Automaatit', 'Automaattia ryöstetään!', "", "CHAR_CALL911", 1)
        luoPoliisinBlip(data.coords)
    end
end

local function ryostaAutomaatti(automaatti)
    local canRob, remainingTime = voikoRyostaaAutomaatin(automaatti)

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
        ilmoitaPoliisille(data)

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

        if math.random(100) <= Config.IskuMahdollisuus then
            lib.notify({
                title = 'Automaatti ryöstö',
                description = 'Menetit tajuntasi sähköiskusta.',
                type = 'error'
            })
            TriggerServerEvent('atmRobbery:reward', nil, 0, false) 
            kaytaIskuEfektia()
        else
            local chosenReward = nil
            for _, palkkio in ipairs(Config.Palkkiot) do
                if math.random(100) <= palkkio.chance then
                    chosenReward = palkkio
                    break
                end
            end

            if chosenReward then
                local amount = math.random(chosenReward.minMaara, chosenReward.maxMaara)
                TriggerServerEvent('atmRobbery:reward', chosenReward.item, amount)
                lib.notify({
                    title = 'Automaatti ryöstö',
                    description = ('Ryöstit automaatista %s %d!'):format(chosenReward.itemlabel, amount),
                    type = 'success'
                })
                ryostetytAutomaatit[automaatti] = GetGameTimer()
            else
                lib.notify({
                    title = 'Automaatti ryöstö',
                    description = 'Et saanut mitään.',
                    type = 'error'
                })
            end
        end
    else
        lib.notify({
            title = 'Automaatti ryöstö',
            description = 'Epäonnistuit!',
            type = 'error'
        })
    end
end


local function onSorkkarautaKadessa()
    local pelaaja = PlayerPedId()
    local currentWeaponHash = GetSelectedPedWeapon(pelaaja)
    return currentWeaponHash == GetHashKey('weapon_crowbar')
end

local function naytaTextUI(automaatti)
    if isShowingTextUI then return end
    if onSorkkarautaKadessa() then
        lib.showTextUI('[E] Ryöstä automaatti')
        isShowingTextUI = true

        Citizen.CreateThread(function()
            while isShowingTextUI do
                Citizen.Wait(0)
                local pelaaja = PlayerPedId()
                local pelaajanSijainti = GetEntityCoords(pelaaja)
                local automaatinSijainti = GetEntityCoords(automaatti)
                local etaisyys = #(pelaajanSijainti - automaatinSijainti)

                if etaisyys > 2.0 or not onSorkkarautaKadessa() then
                    lib.hideTextUI()
                    isShowingTextUI = false
                end

                if IsControlJustPressed(0, 38) and etaisyys <= 2.0 and onSorkkarautaKadessa() then
                    ryostaAutomaatti(automaatti)
                    lib.hideTextUI()
                    isShowingTextUI = false
                end
            end
        end)
    end
end


if Config.RyostaTapa == 'target' then
    for _, prop in ipairs(Config.AutomaattiPropit) do
        exports.ox_target:addModel(prop, {
            {
                event = 'atmRobbery:start',
                icon = 'fa-solid fa-money-bill',
                label = 'Ryöstä automaatti',
                canInteract = function(entity, distance, data)
                    return onSorkkarautaKadessa()
                end
            }
        })
    end

    RegisterNetEvent('atmRobbery:start')
    AddEventHandler('atmRobbery:start', function(data)
        if onSorkkarautaKadessa() then
            ryostaAutomaatti(data.entity)
        else
            lib.notify({
                title = 'Automaatti ryosto',
                description = 'Tarvitset sorkkaraudan kateesi.',
                type = 'error'
            })
        end
    end)

elseif Config.RyostaTapa == 'textui' then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local pelaaja = PlayerPedId()
            local pelaajanSijainti = GetEntityCoords(pelaaja)

            for _, prop in ipairs(Config.AutomaattiPropit) do
                local automaatit = GetClosestObjectOfType(pelaajanSijainti.x, pelaajanSijainti.y, pelaajanSijainti.z, 2.0, GetHashKey(prop), false, false, false)
                
                if automaatit ~= 0 then
                    naytaTextUI(automaatit)
                end
            end
        end
    end)
end


