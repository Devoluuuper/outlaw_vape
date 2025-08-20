local QBCore = exports['qb-core']:GetCoreObject()

local playersUsingVape = {}

QBCore.Functions.CreateUseableItem('vape', function(source)
    if not playersUsingVape[source] then
        TriggerClientEvent('QBCore:Notify', source, "Hoia E, et maffi tõmmata", "success", 5000)
        TriggerClientEvent("outlaw_vape:StartVaping", source)
        playersUsingVape[source] = true
    else
        TriggerClientEvent("outlaw_vape:StopVaping", source)
        playersUsingVape[source] = false
    end
end)

RegisterServerEvent("outlaw_vape:CreateSmoke")
AddEventHandler("outlaw_vape:CreateSmoke", function(netId)
    TriggerClientEvent("outlaw_vape:ShowSmoke", -1, netId)
end)
