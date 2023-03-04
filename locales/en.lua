--[[ ===================================================== ]]--
--[[           MH NPC Services Script by MaDHouSe          ]]--
--[[ ===================================================== ]]--

local Translations = {
    target = {
        ['use_cell_phone'] = "Use Phone",
        ['get_in'] = "Get In",
    },
    notify = {
        ['only_when_badly_injured'] = "You can only use this if you are badly injured",
        ['to_much_ems_online'] = "There are tomany EMS players online.",
        ['cant_pay'] = "You can't pay the amount of $%{price}, you don't have enough money.",
        ['cooldown'] = "~r~%{job}~s~ cooldown actief ~g~%{cooldownTime}~s~ seconde",
        ['call_company'] = "The %{company} has been called",
        ['jail_free_time'] = 'FREE IN: ~r~%{freetime}~s~ SECONDS',
        ['press_e_to_enter'] = "Press ~g~[E]~s~ in %{waitTime} seconde or the %{job} leaves",
        ['you_are_calling'] = "You are calling the %{job}",
        ['not_the_owner'] = 'You do not own this vehicle!',
        ['left_vehicle'] = "you left the vehicle",
        ['can_not_use_services'] = "You cannot use these services if there is a player in town with this job",
    },
    menu = {
        ['title'] = "Call Services",
        ['select_company'] = "Select a Services",
        ['select_player'] = "Select a Player",
        ['for_your_self'] = "For your self",
    },
    error = {
        ['none_nearby'] = "No one nearby!",
        ['not_the_owner'] = 'You do not own this vehicle!',
    },
    job = {
        ['police'] = {
            ['label'] = "NPC Police",
        },
        ['ambulance'] = {
            ['label'] = "NPC Ambulance",
        },
        ['mechanic'] = {
            ['label'] = "NPC Mechanic",
        },
        ['taxi'] = {
            ['label'] = "NPC Taxi",
            ['missing_waypoint'] = "You must set a waypoint before you can call a taxi",
        },
        ['limousine'] = {
            ['label'] = "NPC LIMO",
            ['missing_waypoint'] = "You must set a waypoint before you can call a limousine",
        }
    },
}

Lang = Locale:new({
    phrases = Translations, 
    warnOnMissing = true
})
