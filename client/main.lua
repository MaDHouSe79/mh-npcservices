--[[ ===================================================== ]]--
--[[           MH NPC Services Script by MaDHouSe          ]]--
--[[ ===================================================== ]]--

local QBCore = exports['qb-core']:GetCoreObject()
local stuckTimerCheck = Config.StuckTimerCheck
local stuckResetTimer = Config.StuckResetTimer
local company = {}
local count = 0
local phoneProp = 0
local waitTime = 60
local cooldownTime = Config.Cooldown
local jailTime = math.random(Config.MinJailTime, Config.MaxJailTime)
local isInJail = false
local followPedCamMode
local lastCoords = nil

local function DeletePhoneProp()
	if phoneProp ~= 0 then
		Citizen.InvokeNative(0xAE3CBE5BF394C9C9 , Citizen.PointerValueIntInitialized(phoneProp))
		phoneProp = 0
	end
end

local function CreatePhoneProp()
	DeletePhoneProp()
	RequestModel(Config.PhoneModel)
	while not HasModelLoaded(Config.PhoneModel) do Citizen.Wait(1) end
	phoneProp = CreateObject(Config.PhoneModel, 1.0, 1.0, 1.0, 1, 1, 0)
	local bone = GetPedBoneIndex(PlayerPedId(), 28422)
	AttachEntityToEntity(phoneProp, PlayerPedId(), bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end
end

local function CallAnimation(job)
    if not QBCore.Functions.GetPlayerData().metadata['isdead'] then
        local dictionary = Config.CallAnimation.call.dictionary
        local animation = Config.CallAnimation.call.animation
        if not QBCore.Functions.GetPlayerData().job.name == "taxi" or not QBCore.Functions.GetPlayerData().job.name == "limousine" then
            if QBCore.Functions.GetPlayerData().job.name == "police" or QBCore.Functions.GetPlayerData().job.name == "ambulance" or QBCore.Functions.GetPlayerData().job.name == "mechanic" then
                dictionary = Config.CallAnimation.jobcall.dictionary
                animation = Config.CallAnimation.jobcall.animation
            end
        end
        loadAnimDict(dictionary)
        CreatePhoneProp()
        QBCore.Functions.Notify(Lang:t('notify.you_are_calling', {job = job}), "success")
        TaskPlayAnim(PlayerPedId(), dictionary, animation, 1.5, 1.0, -1, 50, 2.0, 0, 0, 0)
        Wait(8100)
        ClearPedTasks(PlayerPedId())
        DeletePhoneProp()
    end
end

local function CalculateTaxiPrice(job, from, to)
    local route = CalculateTravelDistanceBetweenPoints(from.x, from.y, from.z, to.x, to.y, to.z)
    local price = ((route / 1000) * Config.Service[job].price)
    return price
end

local function TempDisableControl()
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 38, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 46, true)
end

local function GetDistance(pos1, pos2)
    return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
end

local function SetCompanyData(job)
    company = {
        name = Config.Service[job].name,
        job = Config.Service[job].job,
        ped = Config.JobPeds[job].models[math.random(1, #Config.JobPeds[job].models)],
        plate = Config.Service[job].plate,
        home = Config.Service[job].home,
        color = Config.Service[job].color,
        checkin = Config.Service[job].checkin,
        vehicleDrop = Config.Service[job].vehicleDrop,
        playerDrop  = Config.Service[job].playerDrop,
        driveStyle = Config.Service[job].driveStyle,
        walkStyle = Config.Service[job].walkStyle,
        speed = Config.Service[job].speed,
        price = Config.Service[job].price,
        truck_offset = Config.Service[job].truck_offset,
        spawnRadius = Config.Service[job].spawnRadius,
        spotRadius = Config.Service[job].spotRadius,
        passengerSeat =  Config.Service[job].passengerSeat,
        isCalled = false,
        isWaiting = false,
        isReadyToGo = false,
        driveToPlayer = false,
        driveToCompany = false,
        driveToLocation = false,
        driveToMechanic = false,
        driverIsInVehicle = false,
        playerIsInVehicle = false,
        driveAway = false,
        isHandcuffed = false,
        isDriving = false,
        isEscorted = false,
        damage_vehicle = nil,
        coords = nil,
        vehicle = nil,
        driver = nil,
        codriver = nil,
        blip = nil,
    }
    count = 0
end

local function DriveToLocation(from, to)
    if company.driver ~= nil and company.vehicle ~= nil then
        company.coords = to
        if GetDistance(from, to) < 500 then
            TaskVehicleDriveToCoord(company.driver, company.vehicle, to.x, to.y, to.z, company.speed, 0, GetEntityModel(company.vehicle), company.driveStyle, 2.0, true)
        else
            TaskVehicleDriveToCoordLongrange(company.driver, company.vehicle, to.x, to.y, to.z, company.speed, company.driveStyle, 2.0)
        end
        SetPedKeepTask(company.driver, true)
        company.isDriving = true
    end
end

local function DrawTxt(x, y, width, height, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

local function Reset()
    if company.vehicle ~= nil then DeleteEntity(company.vehicle) end
    if company.driver ~= nil then DeleteEntity(company.driver) end
    if company.codriver ~= nil then DeleteEntity(company.codriver) end
    company = {}
    company.isCalled = false
    company.isWaiting = false
    company.driveToPlayer = false
    company.driveToCompany = false
    company.driveToLocation = false
    company.driveToMechanic = false
    company.driverIsInVehicle = false
    company.playerIsInVehicle = false
    company.isHandcuffed = false
    company.isDriving = false
    company.isEscorted = false
    if QBCore.Functions.GetPlayerData().metadata['isdead'] or QBCore.Functions.GetPlayerData().metadata['inlaststand'] then
        company.sendNotify = true
    else
        company.sendNotify = false
    end
    lastCoords = nil
end

local function VehicleStuckCheck()
    if company.driver ~= nil and company.vehicle ~= nil and lastCoords ~= nil then
        if GetEntitySpeed(company.vehicle) < 0.9 then
            stuckTimerCheck = stuckTimerCheck - 1
            if stuckTimerCheck <= 0 then
                if GetDistance(GetEntityCoords(company.vehicle), lastCoords) <= 1.0 then
                    local coords = GetEntityCoords(company.vehicle)
                    local haeding = GetEntityHeading(company.vehicle)
                    local _, spawnPosition, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + 5.0, coords.y, coords.z, 0, 3, 0)
                    ClearAreaOfVehicles(spawnPosition, 15000, false, false, false, false, false)
                    SetEntityCoords(company.vehicle, spawnPosition, false, false, false, true)
                    SetEntityHeading(company.vehicle, haeding)
                    DriveToLocation(coords, company.coords)
                end
                stuckTimerCheck = stuckResetTimer
            end
        end
        lastCoords = nil
    end
end

local function CreateServicesBlips(entity, label)
    local blip = GetBlipFromEntity(entity)
    if not DoesBlipExist(blip) then
        blip = AddBlipForEntity(entity)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, company.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(label)
        EndTextCommandSetBlipName(blip)
    end
    if GetBlipFromEntity(PlayerPedId()) == blip then
        RemoveBlip(blip)
    end
    return blip
end

local function LeaveTarget()
    if company.driver ~= nil and company.vehicle ~= nil then
        ClearPedTasks(company.driver)
        SetPedKeepTask(company.driver, true)
        company.coords = vector3(127.2708, 642.6805, 207.4947)
        DriveToLocation(GetEntityCoords(company.vehicle), company.coords) -- From To
        company.driveAway = true
        SetTimeout(15000, function()
            Reset()
        end)
    end
end

local function CheckIfCompanyPedIsDeath()
    if company.vehile ~= nil or company.driver ~= nil or company.codriver ~= nil then 
        if DoesEntityExist(company.driver) then
            if IsEntityDead(company.driver) then
                if company.codriver ~= nil then DeleteEntity(company.codriver) end
                DeleteEntity(company.driver)
                DeleteEntity(company.vehile)
                Reset()
            end
        end
    end
end

local function GoToMechanicShop()
    QBCore.Functions.TriggerCallback("mh-npcservices:server:CanIPayTheBill", function(isPaid)
        if isPaid then
            SetVehicleDoorOpen(company.damage_vehicle, 4, false, false)
            TaskTurnPedToFaceCoord(company.driver, GetEntityCoords(company.damage_vehicle), -1)
            TaskStartScenarioInPlace(company.driver, "PROP_HUMAN_BUM_BIN", 0, false)
            QBCore.Functions.Progressbar("towtruck", company.job.." is helping...", 10000, false, false, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = false,
            }, {}, {}, {}, function() -- Done
                ClearPedTasks(company.driver)
                ClearPedTasks(PlayerPedId())
                AttachEntityToEntity(company.damage_vehicle, company.vehicle, 20, company.truck_offset.x, company.truck_offset.y, company.truck_offset.z, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                company.isWaiting = true
            end)
        else
            QBCore.Functions.Notify(Lang:t('notify.cant_pay',{price = company.price}), "error")
        end
    end, company.job, company.price)
end

local function HelpOnLocation()
    QBCore.Functions.TriggerCallback("mh-npcservices:server:CanIPayTheBill", function(isPaid)
        if isPaid then
            if company.job == "ambulance" then
                local dictionary = "mini@cpr@char_a@cpr_str"
                local animation = "cpr_pumpchest"
                loadAnimDict(dictionary)
                TaskTurnPedToFaceCoord(company.driver, GetEntityCoords(PlayerPedId()), -1)
                TaskPlayAnim(company.driver, dictionary, animation, 1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
            end
            if company.job == "mechanic" then
                local animation = "PROP_HUMAN_BUM_BIN"
                SetVehicleUndriveable(company.damage_vehicle, true)
                SetVehicleDoorOpen(company.damage_vehicle, 4, false, false)
                TaskTurnPedToFaceCoord(company.driver, GetEntityCoords(company.damage_vehicle), -1)
                TaskStartScenarioInPlace(company.driver, animation, 0, false)
            end
            QBCore.Functions.Progressbar("jobstuff", company.job.." is helping", 10000, false, false, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                ClearPedTasks(company.driver)
                if company.job == "ambulance" then
                    ClearPedTasks(company.codriver)
                    TaskWarpPedIntoVehicle(company.codriver, company.vehicle, 0)
                    TriggerEvent("hospital:client:Revive")
                    StopScreenEffect('DeathFailOut')
                end
                if company.job == "mechanic" then
                    SetVehicleDoorShut(company.damage_vehicle, 4, false, false)
                    Wait(1000)
                    SetVehicleFixed(company.damage_vehicle)
                    SetVehicleEngineHealth(company.damage_vehicle, 1000.0)
                    SetVehicleBodyHealth(company.damage_vehicle, 1000.0)
                    SetVehicleOnGroundProperly(company.damage_vehicle)
                    SetVehicleUndriveable(company.damage_vehicle, false)
                end
                company.coords = company.home
                TriggerServerEvent('mh-npcservices:server:pay', company.job, company.price)
                LeaveTarget()
            end)
        else
            QBCore.Functions.Notify(Lang:t('notify.cant_pay',{price = company.price}), "error")
        end
    end, company.job, company.price)
end

local function GoToLocation()
    if DoesBlipExist(GetFirstBlipInfoId(8)) and not company.driveToLocation and not company.isDriving then
        SetBlockingOfNonTemporaryEvents(company.driver, true)
        local x, y, z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, GetFirstBlipInfoId(8), Citizen.ResultAsVector()))
        PlayAmbientSpeech1(company.driver, "TAXID_BEGIN_JOURNEY", "SPEECH_PARAMS_FORCE_NORMAL")
        company.coords = vector3(x, y, z)
        DriveToLocation(GetEntityCoords(company.vehicle), company.coords)
        company.driveToLocation = true
    end
end

local function GoToCompany()
    QBCore.Functions.TriggerCallback("mh-npcservices:server:canPay", function(canPay)
        if canPay then
            company.coords = company.home
            if company.job == "police" or company.job == "ambulance" then
                SetVehicleSiren(company.vehicle, true)
                SetVehicleDoorsLocked(company.vehicle, 1)
                TaskWarpPedIntoVehicle(company.codriver, company.vehicle, 1)
                if company.job == "ambulance" then TaskWarpPedIntoVehicle(company.codriver, company.vehicle, 2) end
                if company.job == "police" then TaskWarpPedIntoVehicle(company.codriver, company.vehicle, 0) end
            end
            if company.job == 'mechanic' then
                PlayAmbientSpeech1(company.driver, "THANKS", "SPEECH_PARAMS_FORCE_NORMAL")
            end
            company.driveToCompany = true
            DriveToLocation(GetEntityCoords(company.vehicle), company.home)
        else
            PlayAmbientSpeech1(company.driver, "TAXID_NO_MONEY", "SPEECH_PARAMS_FORCE_NORMAL")
            QBCore.Functions.Notify(Lang:t('notify.cant_pay',{price = company.price}), "error")
        end
    end, company.job, company.price)
end

local function CreateServicesPed(coords, vehicle, seat)
    local model = GetHashKey(company.ped)
    loadModel(model)
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, 0, true, true)
    if company.job == 'police' then GiveWeaponToPed(ped, Config.Weapons[math.random(1, #Config.Weapons)], 999, false, true) end
    SetPedIntoVehicle(ped, vehicle, seat)
    SetEntityAsMissionEntity(ped, true, true)
    SetModelAsNoLongerNeeded(model)
    SetPedSweat(ped, 100.0)
    return ped
end

local function SelectVehicleModel()
    local model = Config.Vehicles[company.job].models[math.random(1, #Config.Vehicles[company.job].models)]
    loadModel(model)
    if company.job == "mechanic" and company.damage_vehicle ~= nil then
        if GetVehicleEngineHealth(company.damage_vehicle) < Config.MinDamageForFlatbed then
            model = Config.Vehicles[company.job].models[1]
        else
            model = Config.Vehicles[company.job].models[2]
        end
    end
    return model
end

local function CreateServicesVehicle(coords, heading)
    ClearAreaOfVehicles(coords, 10000, false, false, false, false, false)
    local model = SelectVehicleModel()
    loadModel(model)
    local vehicle = CreateVehicle(model, coords, heading, true, true)
    SetEntityInvincible(vehicle, true)
    NetworkSetEntityInvisibleToNetwork(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleDirtLevel(vehicle, 0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleDoorsLocked(vehicle, 1)
	DecorSetFloat(vehicle, "_FUEL_LEVEL", GetVehicleFuelLevel(vehicle))
    SetVehRadioStation(vehicle, 'OFF')
    SetEntityHeading(vehicle, heading)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleHasUnbreakableLights(vehicle, true)
    SetVehicleNumberPlateText(vehicle, company.plate)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleLights(vehicle, 2)
    SetModelAsNoLongerNeeded(model)
    return vehicle
end

local function CallServices()
    if isInJail then return end
    if company.job == "taxi" or company.job == "limousine" then
        local waypoint = GetFirstBlipInfoId(8)
        if not DoesBlipExist(GetFirstBlipInfoId(8)) then
            if company.job == 'taxi' then
                return QBCore.Functions.Notify(Lang:t('job.taxi.missing_waypoint'), "error")
            else
                return QBCore.Functions.Notify(Lang:t('job.limousine.missing_waypoint'), "error")
            end
        end
    end
    local coords = GetEntityCoords(PlayerPedId())
    if Config.ForceFirstperson then followPedCamMode = GetFollowPedCamViewMode() end
    local _, spawnPosition, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-company.spawnRadius, company.spawnRadius), coords.y + math.random(-company.spawnRadius, company.spawnRadius), coords.z, 0, 3, 0)
    company.vehicle = CreateServicesVehicle(spawnPosition, spawnHeading)
    company.driver = CreateServicesPed(spawnPosition, company.vehicle, -1)
    SetEntityAsMissionEntity(company.vehicle, true, true)
    SetEntityAsMissionEntity(company.driver, true, true)
    if company.job == "ambulance" then
        company.codriver = CreateServicesPed(spawnPosition, company.vehicle, 0)
    elseif company.job == "police" then
        company.codriver = CreateServicesPed(spawnPosition, company.vehicle, 0)
    end
    if company.driver ~= nil and company.vehicle ~= nil then
        if company.job == "police" or company.job == "ambulance" then SetVehicleSiren(vehicle, true) end
        company.blip = CreateServicesBlips(company.vehicle, company.name)
        DriveToLocation(spawnPosition, coords) -- From To
        company.driveToPlayer = true
        if company.job == "police" then SetFakeWantedLevel(6) end
    end
end

local function WalkToVehicle()
    if isInJail then return end
    if not company.isEscorted then
        company.isEscorted = true
        company.isHandcuffed = false
        if company.job == "police" then
            local heading = GetEntityHeading(PlayerPedId())
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "Cuff", 0.2)
            loadAnimDict("mp_arrest_paired")
            Wait(1000)
            TaskPlayAnim(PlayerPedId(), "mp_arrest_paired", "crook_p2_back_right", 3.0, 3.0, -1, 32, 0, 0, 0, 0 ,true, true, true)
            company.isHandcuffed = true
            Wait(2500)
        end
        TaskGoToCoordAnyMeans(company.driver, GetEntityCoords(company.vehicle), 2.0, 0, 0, company.walkStyle, 0xbf800000)
        AttachEntityToEntity(PlayerPedId(), company.driver, 11816, 0.0, -0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
        GoToCompany()
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        SetFakeWantedLevel(0)
        company = {}
        Reset()
        lastCoords = nil
    end
end)

RegisterNetEvent('mh-npcservices:client:sendService', function(callData)
    if isInJail then return end
    if #company == 0 and not company.isCalled then
        SetCompanyData(callData.job)
        company.isCalled = true
        company.price = callData.price
        if callData.job == "mechanic" then
            local vehicle, _ = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
            local props = QBCore.Functions.GetVehicleProperties(vehicle)
            QBCore.Functions.TriggerCallback('mh-npcservices:server:IsVehicleOwner', function(owned)
                if owned then
                    company.coords = GetEntityCoords(vehicle)
                    company.damage_vehicle = vehicle
                    QBCore.Functions.Notify(Lang:t('notify.call_company', {company = company.name}), "success", 8000)
                    Wait(8500)
                    CallServices()
                else
                    QBCore.Functions.Notify(Lang:t('error.not_the_owner'), "error")
                end
            end, props.plate)
        else
            QBCore.Functions.Notify(Lang:t('notify.call_company', {company = company.name}), "success", 8000)
            Wait(8500)
            CallServices()
        end
    end
end)

RegisterNetEvent('mh-npcservices:client:menu', function()
    if isInJail then return end
    local playerlist = {}
    QBCore.Functions.TriggerCallback('mh-npcservices:server:GetOnlinePlayers', function(online)
        playerlist[#playerlist + 1] = {value = GetPlayerServerId(PlayerId()), text = Lang:t('menu.for_your_self')}
        for key, v in pairs(online) do
            if v.source ~= GetPlayerServerId(PlayerId()) then playerlist[#playerlist + 1] = {value = v.source, text = "(ID:"..v.source..") "..v.fullname} end
        end
        QBCore.Functions.TriggerCallback("mh-npcservices:server:isEMSServices", function(isService)
            local menuData = {}
            if not IsPedInAnyVehicle(PlayerPedId()) then
                if DoesBlipExist(GetFirstBlipInfoId(8)) then menuData[#menuData + 1] = {value = "taxi", text = Lang:t('job.taxi.label') } end
                if DoesBlipExist(GetFirstBlipInfoId(8)) then menuData[#menuData + 1] = {value = "limousine", text = Lang:t('job.limousine.label') }  end
            end
            if IsPedInAnyVehicle(PlayerPedId()) then menuData[#menuData + 1] = {value = "mechanic", text = Lang:t('job.mechanic.label') } end
            menuData[#menuData + 1] = {value = "ambulance", text = Lang:t('job.ambulance.label') }
            if Config.UsePoliceAssist and QBCore.Functions.GetPlayerData().job.name == "police" and isService then menuData[#menuData + 1] = { value = "police", text = Lang:t('job.police.label')} end           
            local menu = exports["qb-input"]:ShowInput({
                header = Lang:t('menu.title'),
                submitText = "",
                inputs = {
                    {
                        text = Lang:t('menu.select_player'),
                        name = "id",
                        type = "select",
                        options = playerlist,
                        isRequired = true
                    },
                    {
                        text = Lang:t('menu.select_company'),
                        name = "company",
                        type = "select",
                        options = menuData,
                        isRequired = true
                    }
                }
            })
            if menu then
                if not menu.id or not menu.company then return end
                local call_data = {}
                call_data.job = tostring(menu.company)
                call_data.callerId = GetPlayerServerId(PlayerId())
                call_data.price = Config.Service[call_data.job].price
                if tonumber(menu.id) == GetPlayerServerId(PlayerId()) then
                    call_data.targetId = GetPlayerServerId(PlayerId())
                else
                    call_data.targetId = tonumber(menu.id)
                end
                if call_data.job == 'taxi' or call_data.job == 'limousine' then
                    if DoesBlipExist(GetFirstBlipInfoId(8)) then
                        local x, y, z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, GetFirstBlipInfoId(8), Citizen.ResultAsVector()))
                        local from = GetEntityCoords(PlayerPedId())
                        local to = vector3(x, y, z)
                        call_data.price = CalculateTaxiPrice(call_data.job, from, to)
                    end
                end
                if call_data.job == 'taxi' or call_data.job == 'limousine' then
                    if DoesBlipExist(GetFirstBlipInfoId(8)) then
                        local x, y, z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, GetFirstBlipInfoId(8), Citizen.ResultAsVector()))
                        local from = GetEntityCoords(PlayerPedId())
                        local to = vector3(x, y, z)
                        call_data.price = CalculateTaxiPrice(call_data.job, from, to)
                    end
                end
		TriggerServerEvent('mh-npcservices:server:sendService', call_data)
            end
        end)
    end)
end)

RegisterNetEvent('qb-radialmenu:client:onRadialmenuOpen', function()
    if MenuItemId ~= nil then
        exports['qb-radialmenu']:RemoveOption(MenuItemId)
        MenuItemId = nil
    end
    MenuItemId = exports['qb-radialmenu']:AddOption(
        {
            id = 'callemsservices',
            title = Lang:t('menu.title'),
            icon = Config.RadialMenuIcone,
            type = 'client',
            event = 'mh-npcservices:client:menu',
            shouldClose = true
        },
    MenuItemId)
end)

CreateThread(function()
    while true do
        Wait(1)
        if company.isEscorted then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
			EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 38, true)
            EnableControlAction(0, 322, true)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 46, true)
        end
        if company.isHandcuffed then
            DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			DisableControlAction(0, 45, true) -- Reload
			DisableControlAction(0, 22, true) -- Jump
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 23, true) -- Also 'enter'?
			DisableControlAction(0, 288, true) -- Disable phone
			DisableControlAction(0, 289, true) -- Inventory
			DisableControlAction(0, 170, true) -- Animations
			DisableControlAction(0, 167, true) -- Job
			DisableControlAction(0, 26, true) -- Disable looking behind
			DisableControlAction(0, 73, true) -- Disable clearing animation
			DisableControlAction(2, 199, true) -- Disable pause screen
			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle
			DisableControlAction(2, 36, true) -- Disable going stealth
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
            EnableControlAction(0, 249, true) -- Added for talking while cuffed
            EnableControlAction(0, 46, true)  -- Added for talking while cuffed
        end
        if not company.isHandcuffed and not company.isEscorted then
            Wait(2000)
        end
    end
end)

-- npc is driving (Taxi/Police/Ambulance/Mechanic/TowTruck)
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if company.driveToPlayer then
                local coords = nil
                if company.job == 'mechanic' then
                    coords = GetEntityCoords(company.damage_vehicle)
                else
                    coords = GetEntityCoords(PlayerPedId())
                end
                local vdistance = GetDistance(coords, GetEntityCoords(company.vehicle))
                local ddistance = GetDistance(coords, GetEntityCoords(company.driver))
                if company.job == 'mechanic' or company.job == 'taxi' or company.job == 'limousine' then
                    if QBCore.Functions.GetPlayerData().metadata['isdead'] or QBCore.Functions.GetPlayerData().metadata['inlaststand'] then
                        company.driveToPlayer = false
                        company.isDriving = false
                        ClearPedTasks(company.driver)
                        RemoveBlip(company.blip)
                        LeaveTarget()
                    end
                end
                if vdistance < company.spotRadius then
                    if company.job == "mechanic" then
                        local engine = GetWorldPositionOfEntityBone(company.damage_vehicle, GetEntityBoneIndexByName(company.damage_vehicle, "engine"))
                        TaskGoToCoordAnyMeans(company.driver, engine, 1.0, 0, 0, company.walkStyle, 0xbf800000)
                        ddistance = GetDistance(vector3(engine.x, engine.y, engine.z), GetEntityCoords(company.driver))
                    else
                        if company.job == "police" or company.job == "ambulance" then
                            if company.job == "police" then FreezeEntityPosition(PlayerPedId(), true) end
                            TaskGoToCoordAnyMeans(company.driver, coords, 2.0, 0, 0, company.walkStyle, 0xbf800000)
                        else
                            TaskGoToCoordAnyMeans(company.driver, coords, 1.0, 0, 0, company.walkStyle, 0xbf800000)
                        end
                    end
                    if company.job == 'police' or company.job == 'ambulance' then SetVehicleSiren(company.vehicle, false) end
                    if ddistance < 2.5 then
                        ClearPedTasks(company.driver)
                        RemoveBlip(company.blip)
                        company.driveToPlayer = false
                        company.isDriving = false
                        if company.job == 'police' then
                            SetFakeWantedLevel(0)
                            if not company.isEscorted then WalkToVehicle() end
                        elseif company.job == 'ambulance' then
                            if QBCore.Functions.GetPlayerData().metadata['isdead'] or QBCore.Functions.GetPlayerData().metadata['inlaststand'] then
                                if not company.isEscorted then WalkToVehicle() end
                            else
                                HelpOnLocation()
                            end
                        elseif company.job == 'mechanic' then
                            if GetVehicleEngineHealth(company.damage_vehicle) < Config.MinDamageForFlatbed then
                                GoToMechanicShop()
                            else
                                HelpOnLocation()
                            end
                        elseif company.job == 'taxi' then
                            company.isWaiting = true
                        elseif company.job == 'limousine' then
                            company.isWaiting = true
                        end
                    end
                end
            elseif company.isReadyToGo then
                if not IsPedInVehicle(PlayerPedId(), company.vehicle, false) then TempDisableControl() end
                SetVehicleDoorsLocked(company.vehicle, 0)
                if IsPedInVehicle(company.driver, company.vehicle, false) and IsPedInVehicle(PlayerPedId(), company.vehicle, false) then
                    company.isReadyToGo = false
                    if company.job == 'taxi' or company.job == 'limousine' then GoToLocation() end
                    if company.job == 'mechanic' then
                        DriveToLocation(GetEntityCoords(company.vehicle), company.home)
                        company.driveToMechanic = true
                    end
                end
            elseif company.isEscorted then
                local distance = GetDistance(GetEntityCoords(company.driver), GetEntityCoords(company.vehicle))
                if company.job == "police" then
                    loadAnimDict("mp_arresting")
                    TaskPlayAnim(PlayerPedId(), "mp_arresting", "idle", 8.0, -8, -1, 16, 0, 0, 0, 0)
                end
                if distance <= 5 then
                    company.isEscorted = false
                    company.coords = company.home
                    DoScreenFadeOut(500)
                    Wait(700)
                    DetachEntity(PlayerPedId(), true, false)
                    TaskWarpPedIntoVehicle(PlayerPedId(), company.vehicle, company.passengerSeat)
                    TaskWarpPedIntoVehicle(company.driver, company.vehicle, -1)
                    Wait(1000)
                    DoScreenFadeIn(500)
                    company.driveToCompany = true
                    DriveToLocation(GetEntityCoords(company.vehicle), company.home)
                end
            elseif company.driveToCompany then
                local distance = GetDistance(GetEntityCoords(company.vehicle), company.home)
                lastCoords = GetEntityCoords(company.vehicle)
                if Config.ForceFirstperson then SetFollowVehicleCamViewMode(4) end
                if distance <= 5 then
                    company.driveToCompany = false
                    company.isDriving = false
                    BringVehicleToHalt(company.vehicle, 5.0, 1000, true)
                    Wait(1100)
                    ClearPedTasks(company.driver)
                    SetVehicleSiren(company.vehicle, false)
                    DoScreenFadeOut(500)
                    Wait(600)
                    if Config.ForceFirstperson then SetFollowVehicleCamViewMode(followPedCamMode) end
                    SetEntityCoords(PlayerPedId(), vector3(company.checkin.x, company.checkin.y, company.checkin.z), false, false, false, true)
                    if company.job == "police" then
                        if Config.UseAutoJail then
                            isInJail = true
                            jailTime = math.random(Config.MinJailTime, Config.MaxJailTime)
                        end
                        FreezeEntityPosition(PlayerPedId(), false)
                        company.isHandcuffed = false
                    end

                    if company.job == "ambulance" then FreezeEntityPosition(PlayerPedId(), false) end
                    Wait(1000)
                    DoScreenFadeIn(500)
                    Wait(500)
                    LeaveTarget()                    
                end
            elseif company.driveToMechanic then
                local distance = GetDistance(GetEntityCoords(company.vehicle), company.home)
                lastCoords = GetEntityCoords(company.vehicle)
                if Config.ForceFirstperson then SetFollowVehicleCamViewMode(4) end
                if distance <= 5 then
                    company.driveToMechanic = false
                    company.isDriving = false
                    BringVehicleToHalt(company.vehicle, 5.0, 1000, true)
                    ClearPedTasks(company.driver)
                    TaskLeaveVehicle(PlayerPedId(), company.vehicle, 1)
                    TriggerServerEvent('mh-npcservices:server:pay', company.job, company.price)
                    if Config.ForceFirstperson then SetFollowVehicleCamViewMode(followPedCamMode) end
                    Wait(3000)
                    DetachEntity(company.damage_vehicle, false, false)
                    Wait(100)
                    SetEntityCoords(company.damage_vehicle, vector3(company.vehicleDrop.x, company.vehicleDrop.y, company.vehicleDrop.z), false, false, false, true)
                    Wait(2000)
                    LeaveTarget()
                end
            elseif company.driveToLocation then
                local distance = GetDistance(GetEntityCoords(company.vehicle), company.coords)
                if Config.ForceFirstperson then SetFollowVehicleCamViewMode(4) end
                lastCoords = GetEntityCoords(company.vehicle)
                if distance <= 5 or not DoesBlipExist(GetFirstBlipInfoId(8)) then
                    company.driveToLocation = false
                    company.isDriving = false
                    BringVehicleToHalt(company.vehicle, 5.0, 1000, true)
                    Wait(1100)
                    ClearPedTasks(company.driver)
                    TriggerServerEvent('mh-npcservices:server:pay', company.job, company.price)
                    PlayAmbientSpeech1(company.driver, "TAXID_CLOSE_AS_POSS", "SPEECH_PARAMS_FORCE_NORMAL")
                    Wait(100)
                    if Config.ForceFirstperson then SetFollowVehicleCamViewMode(followPedCamMode) end
                    TriggerServerEvent('mh-npcservices:server:leavevehicle', company.vehicle)
                    Wait(3100)
                    LeaveTarget()
                end
            elseif company.driveAway then
                lastCoords = GetEntityCoords(company.vehicle)
                local distance = GetDistance(GetEntityCoords(company.vehicle), GetEntityCoords(PlayerPedId()))
                if distance > 100 then
                    company.driveAway = false
                    Reset()
                end
            end
        end
        Wait(100)
    end
end)

CreateThread(function()
	while true do
        if LocalPlayer.state.isLoggedIn then
            if Config.AutoCallAmbulance and not company.sendNotify and not company.isCalled then
                if QBCore.Functions.GetPlayerData().metadata['inlaststand'] then
                    if not company.sendNotify then
                        local call_data = {}
                        call_data.job = 'ambulance'
                        call_data.callerId = GetPlayerServerId(PlayerId())
                        call_data.targetId = GetPlayerServerId(PlayerId())
                        call_data.price = Config.Service['ambulance'].price
                        Wait(Config.AutoCallTimer)
                        CallAnimation(call_data.job)
                        TriggerServerEvent('mh-npcservices:server:sendService', call_data)
                    end 
                end
            end
            CheckIfCompanyPedIsDeath()
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if company.job ~= nil then
                if company.driveToCompany or company.driveToLocation or company.driveToMechanic or company.driveToPlayer or company.driveAway then
                    if company.driverIsInVehicle then VehicleStuckCheck() end
                end
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
	while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn then
            if isInJail and Config.UseAutoJail then
                jailTime = jailTime - 1
                if jailTime <= 0 then
                    isInJail = false
                    SetEntityCoords(PlayerPedId(), vector3(Config.Service['police'].checkout.x, Config.Service['police'].checkout.y, Config.Service['police'].checkout.z), false, false, false, true)
                    SetEntityHeading(PlayerPedId(), Config.Service['police'].checkout.w)
                    Reset()
                end
            elseif company.isWaiting then
                waitTime = waitTime - 1
                if waitTime <= 0 then LeaveTarget() end

            elseif company.cooldown then
                cooldownTime = cooldownTime - 1
                if cooldownTime <= 0 then company.cooldown = false end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
	while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn then
            if isInJail and Config.UseAutoJail then
                sleep = 5
                if jailTime > 0 then
                    GetEntityHealth(PlayerPedId(), 200.0)
                    DrawTxt(0.93, 1.44, 1.0, 1.0, 0.6, Lang:t('notify.jail_free_time', {freetime = math.ceil(jailTime)}), 255, 255, 255, 255)
                end
            elseif company.isWaiting then
                sleep = 5
                if waitTime > 0 then
                    DrawTxt(0.83, 1.44, 1.0, 1.0, 0.6, Lang:t('notify.press_e_to_enter',{waitTime = math.ceil(waitTime), job = company.job}), 255, 255, 255, 255)
                    if IsControlJustPressed(0, 38) then -- press E to get in the taxi
                        if not IsPedInVehicle(PlayerPedId(), company.vehicle, false) then
                            company.isWaiting = false
                            company.isReadyToGo = true
                            SetVehicleDoorsLocked(company.vehicle, 0)
                            TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(company.vehicle), 0)
                            TriggerServerEvent('mh-npcservices:server:getin', company.job, company.vehicle)
                            TaskEnterVehicle(company.driver, company.vehicle, -1, -1, 1.0, 1, 0)
                        end
                    end
                elseif company.cooldown then
                    sleep = 5
                    if waitTime > 0 then
                        DrawTxt(0.93, 1.44, 1.0, 1.0, 0.6, Lang:t('notify.cooldown',{cooldownTime = math.ceil(cooldownTime), job = company.job}), 255, 255, 255, 255)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Debug Stuff
CreateThread(function()
    local count = 0
    while true do
        count = count + 1
        if LocalPlayer.state.isLoggedIn then
            if Config.Debug and company.job ~= nil then
                if company.driveToCompany or company.driveToLocation or company.driveToMechanic or company.driveToPlayer or company.driveAway or company.isEscorted or isInJail or not isInJail then
                    print("-----------"..count.."-----------")
                    print("Driver "..company.job.." Debugger")
                    print("Driver in Vehicle: "..tostring(company.driverIsInVehicle))
                    print("Driver Is Driving: "..tostring(company.isDriving))
                    print("Driver is Escorted: "..tostring(company.isEscorted))
                    print("Drive to Company: "..tostring(company.driveToCompany))
                    print("Drive to Location: "..tostring(company.driveToLocation))
                    print("Drive to Mechanic: "..tostring(company.driveToMechanic))
                    print("Drive to Player: "..tostring(company.driveToPlayer))
                    print("Drive Away: "..tostring(company.driveAway))
                    print("Player is in Jail: "..tostring(isInJail))
                else
                    count = 0
                end
            end
        end
        Wait(2000)
    end
end)

RegisterNetEvent('mh-npcservices:client:getinvehicle', function(vehicle)
    for i = 1, 7 do
        if IsVehicleSeatFree(vehicle, i) then
            TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), 0)
            SetVehicleDoorsLocked(vehicle, 0)
            TaskEnterVehicle(PlayerPedId(), vehicle, -1, i, 1.0, 1, 0)
        end
    end
end)

RegisterNetEvent('mh-npcservices:client:leavevehicle', function(passenger, vehicle)
    if IsPedInAnyVehicle(passenger, false) then
        SetVehicleDoorsLocked(vehicle, 0)
        TaskLeaveVehicle(passenger, vehicle, 1)
    end
end)

-- for taxi and limousine
if Config.UseTarget then
    RegisterNetEvent('mh-npcservices:client:taxi', function(vehicle)
        local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        TriggerServerEvent('mh-npcservices:server:getin', 'taxi', vehicle)
    end)
    RegisterNetEvent('mh-npcservices:client:limousine', function(vehicle)
        local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        TriggerServerEvent('mh-npcservices:server:getin', 'limousine', vehicle)
    end)
    for _, model in pairs(Config.Vehicles['taxi']) do
        exports['qb-target']:AddTargetModel(model, {
            options = {
                {
                    type = "client",
                    event = "mh-npcservices:client:taxi",
                    icon = "fas fa-car",
                    label = Lang:t('target.get_in'),
                },
            },
            distance = 2.5
        })
    end
    for _, model in pairs(Config.Vehicles['limousine']) do
        exports['qb-target']:AddTargetModel(model, {
            options = {
                {
                    type = "client",
                    event = "mh-npcservices:client:limousine",
                    icon = "fas fa-car",
                    label = Lang:t('target.get_in'),
                },
            },
            distance = 2.5
        })
    end
end
