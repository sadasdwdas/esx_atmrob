ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('atmRobbery:reward')
AddEventHandler('atmRobbery:reward', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addMoney(amount)
    end
end)
