--[[ ===================================================== ]]--
--[[           MH NPC Services Script by MaDHouSe          ]]--
--[[ ===================================================== ]]--

local Translations = {
    target = {
        ['use_cell_phone'] = "Gebruik telefoon",
        ['get_in'] = "Stap in",
    },
    notify = {
        ['only_when_badly_injured'] = "Je kunt dit alleen gebruiken als je zwaargewond bent",
        ['to_much_ems_online'] = "Er zijn teveel %{job} spelers online.",
        ['cant_pay'] = "Je kunt het bedrag van €%{price} niet betalen, je hebt te weinig geld.",
        ['cooldown'] = "~r~%{job}~s~ cooldown actief ~g~%{cooldownTime}~s~ seconden",
        ['call_company'] = "De %{company} is gebeld",
        ['jail_free_time'] = 'Vrij IN: ~r~%{freetime}~s~ SECONDES',
        ['press_e_to_enter'] = "Druk ~g~[E]~s~ binnen %{waitTime} seconde anders vertrek de %{job}",
        ['you_are_calling'] = "Je bent de %{job} aan het bellen",
        ['not_the_owner'] = 'Je bent geen eigenaar van dit voertuig!',
        ['left_vehicle'] = "Je bent uitgestapt",
        ['can_not_use_services'] = "Je kunt deze services niet gebruiken als er een speler in de stad is met deze job",
    },
    menu = {
        ['title'] = "Bel Services",
        ['select_company'] = "Selecteer een Services",
        ['select_player'] = "Selecteer een speler",
        ['for_your_self'] = "Voor je zelf",
    },
    job = {
        ['police'] = {
            ['label'] = "NPC Politie",
        },
        ['ambulance'] = {
            ['label'] = "NPC Ziekenwagen",
        },
        ['mechanic'] = {
            ['label'] = "NPC Monteur",
        },
        ['taxi'] = {
            ['label'] = "NPC Taxi",
            ['missing_waypoint'] = "Je moet een waypoint zetten voor je een taxi kunt bellen",
        },
        ['limousine'] = {
            ['label'] = "NPC LIMO",
            ['missing_waypoint'] = "Je moet een waypoint zetten voor je een limousine kunt bellen",
        }
    },
}

Lang = Locale:new({
    phrases = Translations, 
    warnOnMissing = true
})