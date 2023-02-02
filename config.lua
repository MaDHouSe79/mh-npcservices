--[[ ===================================================== ]]--
--[[           MH NPC Services Script by MaDHouSe          ]]--
--[[ ===================================================== ]]--

Config = {}
Config.UseTarget              = true             -- Defalt false, if you want to use target for cellphones
Config.Debug                  = false            -- Defalt false, debug in console (client/server)
Config.InteractDiustance      = 2.5              -- Default 2.5, the distance when you can interact with the npc ped driver
Config.MinOnlineEMS           = 1                -- Defalt 1, How many ems people have to be online, to iqnore the npc services.
Config.Cooldown               = 350000           -- Defalt 25000, A cooldown, (5mins) this is so players can't spam it.
Config.AutoCallAmbulance      = true             -- Defalt true, if true, it calls the ambulance automatically for you.
Config.AutoCallTimer          = 25000            -- Defalt 20000, A timer to call ambulance automatically after 20secs.
Config.ForceFirstperson       = false            -- Default false, it force firstperon when inside a job vehicle.
Config.MinDamageForFlatbed    = 750              -- Defalt 750, a flatbed is comming if the vehicle damage is below this value.
Config.RadialMenuIcone        = "star-of-life"   -- Defalt "star-of-life", icon form the radial menu.
Config.PhoneModel             = "prop_amb_phone" -- Default prop_amb_phone, hand phone, if you have a other phone model, you can use it here
Config.StuckTimerCheck        = 15               -- Default 15, a stuck timer check.
Config.StuckResetTimer        = 15               -- Default 15, reset stuck time.
Config.UseUnlimitHealth       = true             -- if true, all service peds and vehicles will have inlimit health.
Config.UseCallForOtherPlayers = false            -- if false, players can't call the service for other players
Config.UseServicesForJobs     = true             -- if true, your are able to call a police service for your self (normal you can't do this)
Config.UsePoliceAssist        = false            -- if true, a plice player can let a police ped drive the player to the HQ
Config.UseAutoJail            = false            -- Default false, if you dont have police you can set this true
Config.MinJailTime            = 120              -- 2 min min jail time (Default: 120)
Config.MaxJailTime            = 250              -- 5 min max jail time (Default: 350)


Config.JobPeds = {
    ['police']        = {models = {"mp_m_fibsec_01"}},
    ['ambulance']     = {models = {"s_m_m_doctor_01"}},
    ['mechanic']      = {models = {"S_M_M_TRUCKER_01"}},
    ['taxi']          = {models = {"a_m_y_stlat_01"}},
    ['limousine']     = {models = {"cs_solomon"}},
}

Config.Vehicles = {   -- Job Vehicles
    ['police']        = {models = {"riot"}},
    ['ambulance']     = {models = {"ambulance"}},
    ['mechanic']      = {models = {"flatbed", "towtruck"}},-- dont change the order, you can change the model but keep it as it is.(flatbed/towtruck)
    ['taxi']          = {models = {"taxi"}},
    ['limousine']     = {models = {"stretch", "patriot2"}},
}

Config.CallAnimation = { -- Call Aminations
    call    = {dictionary = "cellphone@", animation = "cellphone_call_listen_base"},
    jobcall = {dictionary = "random@arrests", animation = "generic_radio_enter"}
}

-- Cop Weapons
Config.Weapons = {"WEAPON_PISTOL", "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_STUNGUN"}

 -- Job Service data.
Config.Service = {                           
    ['ambulance'] = {
        name        = "Ambulance",                           -- name of the company
        job         = "ambulance",                           -- the job name.
        plate       = "NPC-AMBU",                            -- vehicle plate.
        color       = 3,                                     -- blip color
        speed       = 29.0,                                  -- drive speed.
        price       = 500,                                   -- cost..
        spawnRadius = 250,                                   -- spawn Radius around the player
        spotRadius  = 50,                                    -- the radius a ped spots a player
        driveStyle  = 831,                                   -- if you want to chang this go to: https://www.vespura.com/fivem/drivingstyle/ or try 524863 - 537133628 - 262447 - 262204 
        walkStyle   = 786603,                                -- walk style (running)
        passengerSeat = 1,                                   -- -1 is the driver
        home        = vector3(351.8928, -541.3893, 28.7438), -- home location for the company (you may need to need to adjust this)
        checkin     = vector3(306.8108, -595.3231, 43.2918), -- checkin for hospital (you may need to need to adjust this)
    },
    ['police'] = {
        name        = "Police",
        job         = "police",
        plate       = "NPC-POLI",
        color       = 38,
        speed       = 29.0,
        price       = 0,
        spawnRadius = 250,
        spotRadius  = 50,
        driveStyle  = 447,            
        walkStyle   = 786603,
        passengerSeat = 2, -- -1 is the driver
        home        = vector3(437.3315, -1022.2286, 28.6478),         -- home location for the company (you may need to need to adjust this)
        checkin     = vector3(459.7083, -994.9054, 24.9149),          -- checkin police hq jail (you may need to need to adjust this)
        checkout    = vector4(437.3625, -978.5160, 30.6896, 181.8552), -- checkout after jail
    },

    ['mechanic'] = {
        name        = "Mechanic",
        job         = "mechanic",
        plate       = "NPC-MECH",
        color       = 81,
        speed       = 29.0,
        price       = 1000,
        spawnRadius = 250,
        spotRadius  = 10,
        driveStyle  = 447, --525119, --524863,            
        walkStyle   = 786603,
        passengerSeat = 0, -- -1 is the driver
        home        = vector3(127.6150, -1133.2461, 28.5707),           -- home location for the company (you may need to need to adjust this)
        vehicleDrop = vector4(115.2420, -1138.1442, 28.6723, 336.7379), -- drop location for the player vehicle. (you may need to need to adjust this)
        truck_offset = { -- for the vehicle position on the flatbed
            x = -0.5,    -- left/right
            y = -5.0,    -- front/back
            z = 1.0,     -- up/down
        },
    },

    ['taxi'] = {
        name        = "Taxi",
        job         = "taxi",
        plate       = "NPC-TAXI",
        color       = 46,
        speed       = 29.0,
        price       = 10,
        spawnRadius = 250,
        spotRadius  = 15,
        driveStyle  = 447,
        walkStyle   = 786603,
        passengerSeat = 2, -- -1 is the driver
        home        = vector3(915.7531, -163.6132, 74.6438), -- (you may need to need to adjust this)
    },

    ['limousine'] = {
        name        = "limousine",
        job         = "limousine",
        plate       = "NPC-LIMO",
        color       = 25,
        speed       = 29.0,
        price       = 100,
        spawnRadius = 250,
        spotRadius  = 15,
        driveStyle  = 447,
        walkStyle   = 786603,
        passengerSeat = 1, -- -1 is the driver
        home        = vector3(915.7531, -163.6132, 74.6438), -- (you may need to need to adjust this)
    }
}
