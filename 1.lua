--[[
    PS-Style Camlock System
    Support: PC (C) & Console (L2)
    Targets: Players & NPCs
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local isLocked = false
local currentTarget = nil

-- Konfigurasi Utama
local CONFIG = {
    MaxDistance = 100,
    Smoothness = 0.15, -- Semakin kecil semakin mulus
    Keys = {Enum.KeyCode.C, Enum.KeyCode.ButtonL2},
    CrosshairId = "rbxassetid://6031068433"
}

-- UI Crosshair Setup
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "CamlockUI"

local crosshair = Instance.new("ImageLabel", screenGui)
crosshair.Size = UDim2.new(0, 55, 0, 55)
crosshair.BackgroundTransparency = 1
crosshair.Image = CONFIG.CrosshairId
crosshair.ImageColor3 = Color3.fromRGB(255, 50, 50)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Visible = false

-- Fungsi Mencari Target Terdekat (Player & NPC)
local function getNearestTarget()
    local nearestDist = CONFIG.MaxDistance
    local nearestChar = nil
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= myChar and obj.Health > 0 then
            local root = obj.Parent:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myChar.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestChar = obj.Parent
                end
            end
        end
    end
    return nearestChar
end

-- Input Listener (Keyboard & Controller)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if table.find(CONFIG.Keys, input.KeyCode) then
        if isLocked then
            isLocked = false
            currentTarget = nil
            crosshair.Visible = false
        else
            currentTarget = getNearestTarget()
            if currentTarget then
                isLocked = true
            end
        end
    end
end)

-- Main Loop (RenderStep agar smooth)
RunService:BindToRenderStep("PS_Camlock_Logic", Enum.RenderPriority.Camera.Value + 1, function()
    if isLocked and currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") and currentTarget:FindFirstChild("Humanoid").Health > 0 then
        local targetPart = currentTarget.HumanoidRootPart
        
        -- Pergerakan Kamera (Lerp)
        local goalCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
        camera.CFrame = camera.CFrame:Lerp(goalCFrame, CONFIG.Smoothness)
        
        -- Update Crosshair di Layar
        local screenPos, onScreen = camera:WorldToScreenPoint(targetPart.Position)
        if onScreen then
            crosshair.Visible = true
            crosshair.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
            crosshair.Rotation += 5 -- Animasi Putar
        else
            crosshair.Visible = false
        end
        
        -- Auto-unlock jika terlalu jauh
        local dist = (player.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude
        if dist > CONFIG.MaxDistance then
            isLocked = false
        end
    else
        isLocked = false
        crosshair.Visible = false
    end
end)
