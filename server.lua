local QBCore = exports['qb-core']:GetCoreObject()
local NXT = exports['nxt-log']

-- Gi items
RegisterServerEvent('nxt-chopshop:server:giveItem')
AddEventHandler('nxt-chopshop:server:giveItem', function(item, quantity)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    xPlayer.Functions.AddItem(item, quantity)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')

    DiscordLogItem(src, item, quantity)
end)

--logg funksjon
function sendToNXTLog(src, PlayerData, event, message, item, quantity)
    local citizenId = PlayerData.citizenid
    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)

    local logMessage = message
    if item and quantity then
        logMessage = logMessage .. "\nItem: " .. item .. ", Quantity: " .. quantity
    end

    NXT:log(citizenId, {playerCoords.x, playerCoords.y, playerCoords.z}, logMessage, "event", event, "info")
end

-- Funksjon for items
function lib.logger(source, event, message, item, quantity)
    local player = QBCore.Functions.GetPlayer(source)
    local playerName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    local citizenId = player.PlayerData.citizenid
    sendToNXTLog(source, player.PlayerData, event, "Player: " .. playerName .. " (Citizen ID: " .. citizenId .. ") - " .. message, item, quantity)
end
