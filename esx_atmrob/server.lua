ESX = exports['es_extended']:getSharedObject()

local function sendToWebhook(xPlayer, success, item, amount)
    local steamId = xPlayer.identifier
    local license = xPlayer.getIdentifier() or "N/A"
    local playerIp = GetPlayerEndpoint(xPlayer.source)
    
    local webhookUrl = "" --tähän webhook linkki
    
    local color = success and 3066993 or 15158332  -- Vihreä (onnistui), punainen (sähköisku)
    local description = success and 
        string.format("**Steam:** %s\n**License:** %s\n**IP:** %s\n**Palkinto:** %s x%d", steamId, license, playerIp, item, amount) or 
        string.format("**Steam:** %s\n**License:** %s\n**IP:** %s\n", steamId, license, playerIp)

    local embedMessage = {
        {
            ["color"] = color,
            ["title"] = success and "Ryöstö onnistui!" or "Ryöstö epäonnistui - Sähköisku!",
            ["description"] = description
        }
    }

    PerformHttpRequest(webhookUrl, function(err, text, headers) 
        if err == 200 then
            print("Webhook notification sent successfully")
        else
            print("Failed to send webhook notification: " .. err)
        end
    end, "POST", json.encode({embeds = embedMessage}), { ["Content-Type"] = "application/json" })
end

RegisterNetEvent('atmRobbery:reward')
AddEventHandler('atmRobbery:reward', function(item, amount, success)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        if success then
            if GetResourceState('ox_inventory') == 'started' then
                exports.ox_inventory:AddItem(xPlayer.source, item, amount)
            else
                xPlayer.addInventoryItem(item, amount)
            end
            TriggerClientEvent('atmRobbery:notifyReward', xPlayer.source, item, amount)
        end

        sendToWebhook(xPlayer, success, item, amount)
    end
end)

