local QBCore = exports['qb-core']:GetCoreObject()
local IsPlayerAbleToVape = false
local VapeProp = nil
local IsVaping = false

local SmokeSettings = {
    Particle = "exp_grd_bzgas_smoke",
    ParticleAsset = "core",
    Bones = { 18905, 57005 },
    SmokeSize = 1.2,
    SmokeDuration = 6000,
}

local Animations = {
    VapeHold = { dict = "anim@heists@humane_labs@finale@keycards", anim = "ped_a_enter_loop" },
    VapeDrag = { dict = "mp_player_inteat@burger", anim = "mp_player_int_eat_burger" },
    VapeExit = { dict = "anim@heists@humane_labs@finale@keycards", anim = "exit" }
}

function LoadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(5)
    end
end

function StartVaping()
    local ped = PlayerPedId()
    IsPlayerAbleToVape = true

    LoadAnim(Animations.VapeHold.dict)
    TaskPlayAnim(ped, Animations.VapeHold.dict, Animations.VapeHold.anim, 8.0, -8.0, -1, (2+16+32), 0, false, false, false)

    local prop = "ba_prop_battle_vape_01"
    RequestModel(prop)
    while not HasModelLoaded(prop) do
        Citizen.Wait(10)
    end

    local pedPos = GetEntityCoords(ped)
    VapeProp = CreateObject(GetHashKey(prop), pedPos.x, pedPos.y, pedPos.z + 0.2, true, true, true)
    AttachEntityToEntity(VapeProp, ped, GetPedBoneIndex(ped, SmokeSettings.Bones[1]), 0.08, -0.01, 0.03, -150.0, 90.0, -10.0, true, true, false, true, 1, true)
end

function StopVaping()
    local ped = PlayerPedId()
    IsPlayerAbleToVape = false

    if DoesEntityExist(VapeProp) then
        DeleteObject(VapeProp)
        VapeProp = nil
    end

    LoadAnim(Animations.VapeExit.dict)
    TaskPlayAnim(ped, Animations.VapeExit.dict, Animations.VapeExit.anim, 8.0, -8.0, -1, (2+16+32), 0, false, false, false)
    ClearPedSecondaryTask(ped)
end

RegisterNetEvent("outlaw_vape:StartVaping")
AddEventHandler("outlaw_vape:StartVaping", function()
    local ped = PlayerPedId()

    if DoesEntityExist(ped) and not IsEntityDead(ped) then
        if not IsPedInAnyVehicle(ped, false) then
            if not IsPlayerAbleToVape then
                local currentWeapon = GetSelectedPedWeapon(ped)
                if currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                    QBCore.Functions.Notify("Relv käes, ei saa e-sigarit võtta!", "error")
                    return
                end
                StartVaping()
            else
                QBCore.Functions.Notify("Tõmbad juba kõssi!", "error")
            end
        else
            QBCore.Functions.Notify("Sõidukis on raske esigarit kimuda!", "error")
        end
    else
        QBCore.Functions.Notify("Pff sul tähtsamat teha kui e-sigarit tõmmata!", "error")
    end
end)

RegisterNetEvent("outlaw_vape:StopVaping")
AddEventHandler("outlaw_vape:StopVaping", function()
    if IsPlayerAbleToVape then
        StopVaping()
        QBCore.Functions.Notify("Panid e-sigari taskusse.", "success")
    end
end)

RegisterNetEvent("outlaw_vape:Drag")
AddEventHandler("outlaw_vape:Drag", function()
    if IsPlayerAbleToVape and not IsVaping then
        IsVaping = true
        local ped = PlayerPedId()
        local pedPos = GetEntityCoords(ped)

        LoadAnim(Animations.VapeDrag.dict)
        TaskPlayAnim(ped, Animations.VapeDrag.dict, Animations.VapeDrag.anim, 8.0, -8.0, -1, (2+16+32), 0, false, false, false)
        
        PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)

        Citizen.Wait(950)
        TriggerServerEvent("outlaw_vape:CreateSmoke", PedToNet(ped))

        Citizen.Wait(SmokeSettings.SmokeDuration - 1000)
        LoadAnim(Animations.VapeHold.dict)
        TaskPlayAnim(ped, Animations.VapeHold.dict, Animations.VapeHold.anim, 8.0, -8.0, -1, (2+16+32), 0, false, false, false)
        IsVaping = false
    end
end)

RegisterNetEvent("outlaw_vape:ShowSmoke")
AddEventHandler("outlaw_vape:ShowSmoke", function(netId)
    local ped = NetToPed(netId)
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
        RequestNamedPtfxAsset(SmokeSettings.ParticleAsset)
        while not HasNamedPtfxAssetLoaded(SmokeSettings.ParticleAsset) do
            Citizen.Wait(0)
        end

        for _, bone in pairs(SmokeSettings.Bones) do
            local boneIndex = GetPedBoneIndex(ped, bone)
            UseParticleFxAssetNextCall(SmokeSettings.ParticleAsset)
            local smoke = StartParticleFxLoopedOnEntityBone(
                SmokeSettings.Particle,
                ped,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                boneIndex,
                SmokeSettings.SmokeSize,
                false, false, false
            )
            UseParticleFxAssetNextCall(SmokeSettings.ParticleAsset)
            local smoke2 = StartParticleFxLoopedOnEntityBone(
                SmokeSettings.Particle,
                ped,
                0.05, 0.0, 0.0,
                0.0, 0.0, 0.0,
                boneIndex,
                SmokeSettings.SmokeSize * 0.8,
                false, false, false
            )
            Citizen.Wait(SmokeSettings.SmokeDuration)
            StopParticleFxLooped(smoke, 0)
            StopParticleFxLooped(smoke2, 0)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, true) and IsPlayerAbleToVape then
            StopVaping()
        end

        if IsPlayerAbleToVape and not IsVaping then
            if IsControlPressed(0, 38) then
                Citizen.Wait(300)
                if IsControlPressed(0, 38) then
                    TriggerEvent("outlaw_vape:Drag")
                end
                Citizen.Wait(2000)
            end
        end

        if IsPlayerAbleToVape then
            local currentWeapon = GetSelectedPedWeapon(ped)
            if currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
                QBCore.Functions.Notify("E-sigar käes, ei saa relva võtta!", "error")
            end
        end
    end
end)