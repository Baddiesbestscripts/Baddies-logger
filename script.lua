-- Simple Baddies Logger Test
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("✅ Baddies Simple Logger Loaded!")
print("Username:", localPlayer.Name)

local ls = localPlayer:FindFirstChild("leaderstats")
if ls then
    print("Dinero:", ls:FindFirstChild("Dinero") and ls.Dinero.Value or "N/A")
    print("Slays:", ls:FindFirstChild("Slays") and ls.Slays.Value or "N/A")
end

-- Inventory quick check
local tools = {}
for _, v in ipairs(localPlayer.Backpack:GetChildren()) do
    if v:IsA("Tool") then table.insert(tools, v.Name) end
end
for _, v in ipairs(localPlayer.Character:GetChildren()) do
    if v:IsA("Tool") then table.insert(tools, v.Name) end
end

print("You have " .. #tools .. " tools/weapons")
if #tools > 0 then
    print("Some tools:", table.concat(tools, ", "))
end
