--[[ ===================================================== ]]--
--[[         MH Vehicle Key Item Script by MaDHouSe        ]]--
--[[ ===================================================== ]]--

local user = "MaDHouSe79"
local script = "mh-npcservices"

local resourceName = mil

local function checkVersion(err, responseText, headers)
    curVersion = LoadResourceFile(GetCurrentResourceName(), "version")
    if responseText == nil then
        print("^1"..resourceName.." check for updates failed ^7")
        return
    end
    if curVersion ~= responseText and tonumber(curVersion) < tonumber(responseText) then
        updateavail = true
        print("\n^1----------------------------------------------------------------------------------^7")
        print(resourceName.." is outdated, latest version is: ^2"..responseText.."^7, installed version: ^1"..curVersion.."^7!\nupdate from https://github.com"..updatePath.."")
        print("^1----------------------------------------------------------------------------------^7")
    elseif tonumber(curVersion) > tonumber(responseText) then
        print("\n^3----------------------------------------------------------------------------------^7")
        print(resourceName.." git version is: ^2"..responseText.."^7, installed version: ^1"..curVersion.."^7!")
		print("READ THE UPDATES.md to see if you have to make any changes!!")
        print("^3----------------------------------------------------------------------------------^7")
    else
        print("\n"..resourceName.." is up to date. (^2"..curVersion.."^7)")
    end
end

if Config.CheckForUpdates then
    Citizen.CreateThread( function()
        resourceName = ""..GetCurrentResourceName()..""
        PerformHttpRequest("https://raw.githubusercontent.com".."/"..user.."/"..script.."/master/version", checkVersion, "GET")
    end)
end
