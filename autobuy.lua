-- 👕 АВТОПОКУПКА v8.0 - БЫСТРАЯ ВЕРСИЯ
-- GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/l9jlevadim-svg/roblox-scripts/main/autobuy.lua"))()
-- ✅ Быстрая ходьба | ✅ Движение каждые 2 сек | ✅ Быстрая оплата

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

print("\n" .. string.rep("=", 60))
print("👕 АВТОПОКУПКА v8.0 - БЫСТРАЯ ВЕРСИЯ")
print(" Быстрая ходьба | ⚡ Движение каждые 2 сек | ⚡ Быстрая оплата")
print(string.rep("=", 60) .. "\n")

-- ============================================
-- НАСТРОЙКИ (УСКОРЕННЫЕ)
-- ============================================
local SETTINGS = {
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
    DELAY_ITEMS = 1,              -- ⚡ Было 2, стало 1 сек
    REFRESH_TIME = 600,
    STOP_DISTANCE = 3,
    WALK_SPEED = 25,              -- ⚡ Было 18, стало 25 (быстрее!)
    JUMP_POWER = 50,
    STUCK_CHECK_INTERVAL = 0.3,   -- ⚡ Чаще проверяем застревание
    STUCK_DISTANCE = 1,
    STUCK_TIME = 2,               -- ⚡ Было 4, стало 2 сек
    PATH_AGENT_RADIUS = 2,
    PATH_AGENT_HEIGHT = 5,
    MOVE_TIMEOUT = 20,
    TAKE_TIMEOUT = 3,             -- ⚡ Было 5, стало 3 сек
    MAX_FAILED_ATTEMPTS = 2,
    MOVE_INTERVAL = 2             -- ⚡ Движение каждые 2 секунды
}

-- ============================================
-- ПЕРЕМЕННЫЕ
-- ============================================
local clothes = {}
local seller = nil
local running = false
local takenCount = 0
local paidCount = 0
local shopLimits = {}
local lastTakeTime = 0
local shopZones = {}
local lastMoveTime = 0

-- ============================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================

local function findPosition(obj)
    local checkObj = obj
    for i = 1, 6 do
        if checkObj then
            if checkObj:IsA("BasePart") then
                return checkObj.CFrame.Position
            end
            local part = checkObj:FindFirstChildWhichIsA("BasePart")
            if part then return part.CFrame.Position end
            checkObj = checkObj.Parent
        end
    end
    return nil
end

local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function log(message)
    print("[AutoBuy] " .. message)
end

-- ============================================
-- 🎯 ДВИЖЕНИЕ ТЕЛОМ КАЖДЫЕ 2 СЕКУНДЫ
-- ============================================

local function doQuickMove()
    local currentTime = tick()
    if currentTime - lastMoveTime >= SETTINGS.MOVE_INTERVAL then
        -- Небольшое движение/прыжок чтобы не стоял на месте
        if humanoid and humanoid.Health > 0 then
            -- Прыжок или небольшое движение
            if math.random(2) == 1 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            else
                -- Небольшое движение в случайном направлении
                local randomDir = Vector3.new(
                    math.random(-2, 2),
                    0,
                    math.random(-2, 2)
                )
                humanoid:MoveTo(rootPart.Position + randomDir)
            end
            lastMoveTime = currentTime
        end
    end
end

-- ============================================
-- ПОИСК
-- ============================================

local function findShops()
    log("🔍 Поиск магазинов...")
    shopZones = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Shop_ShopZone") then
            shopZones[obj.Name] = true
        end
    end
    
    log("📊 Всего магазинов: " .. #shopZones)
end

local function findClothes()
    log("\n🔍 Поиск одежды...")
    clothes = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local path = obj:GetFullName()
            local action = obj.ActionText or ""
            
            if path:find("Shop_ShopZone") and (action:find("Взять") or action:find("Take")) then
                local parent = obj.Parent
                local priceText = ""
                
                local searchObj = parent
                for i = 1, 5 do
                    if searchObj then
                        for _, child in ipairs(searchObj:GetChildren()) do
                            if child:IsA("BillboardGui") then
                                for _, gui in ipairs(child:GetChildren()) do
                                    if gui:IsA("TextLabel") then
                                        priceText = gui.Text
                                    end
                                end
                            end
                        end
                        searchObj = searchObj.Parent
                    end
                end
                
                local position = findPosition(obj) or findPosition(parent)
                
                local shopName = "Unknown"
                for name, _ in pairs(shopZones) do
                    if path:find(name) then
                        shopName = name
                        break
                    end
                end
                
                local floor = "1 этаж"
                if position and position.Y > 10 then
                    floor = "2 этаж"
                end
                
                table.insert(clothes, {
                    obj = obj,
                    parent = parent,
                    name = parent and parent.Name or "Item",
                    priceText = priceText,
                    position = position,
                    shop = shopName,
                    floor = floor,
                    taken = false,
                    unavailable = false,
                    failedAttempts = 0
                })
            end
            
            if action:find("Поговорить") or action:find("поговорить") then
                if not seller then
                    seller = {
                        obj = obj,
                        position = findPosition(obj)
                    }
                    log("🏪 Продавец найден")
                end
            end
        end
    end
    
    log("✅ Найдено одежды: " .. #clothes)
end

-- ============================================
-- ⚡ БЫСТРАЯ ХОДЬБА
-- ============================================

local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then
        log("❌ walkTo: ошибка параметров")
        return false
    end
    
    local startPos = rootPart.Position
    local totalDistance = getDistance(startPos, targetPos)
    
    log("⚡ Иду: " .. math.floor(totalDistance) .. " студий (скорость " .. SETTINGS.WALK_SPEED .. ")")
    
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    
    -- ⚡ Устанавливаем высокую скорость
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER
    
    local path = PathfindingService:CreatePath({
        AgentRadius = SETTINGS.PATH_AGENT_RADIUS,
        AgentHeight = SETTINGS.PATH_AGENT_HEIGHT,
        AgentCanJump = true,
        AgentCanClimb = true
    })
    
    local success = pcall(function()
        path:ComputeAsync(startPos, targetPos)
    end)
    
    if not success then
        log("⚠️  Ошибка пути, иду напрямик...")
        humanoid:MoveTo(targetPos)
        local reached = humanoid.MoveToFinished:Wait(SETTINGS.MOVE_TIMEOUT)
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        return reached
    end
    
    if path.Status ~= Enum.PathStatus.Success then
        log("⚠️  Путь не найден")
        humanoid:MoveTo(targetPos)
        local reached = humanoid.MoveToFinished:Wait(SETTINGS.MOVE_TIMEOUT)
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        return reached
    end
    
    local waypoints = path:GetWaypoints()
    log("✅ Путь: " .. #waypoints .. " точек")
    
    for i, waypoint in ipairs(waypoints) do
        if not running then
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
            return false
        end
        
        humanoid:MoveTo(waypoint.Position)
        
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        local startTime = tick()
        local lastPosition = rootPart.Position
        local lastCheckTime = tick()
        local totalStuckTime = 0
        
        while true do
            if not running then
                humanoid.WalkSpeed = originalWalkSpeed
                humanoid.JumpPower = originalJumpPower
                return false
            end
            
            local currentTime = tick()
            local currentPos = rootPart.Position
            local distToWaypoint = getDistance(currentPos, waypoint.Position)
            
            -- ⚡ Быстрая проверка застревания
            if currentTime - lastCheckTime >= SETTINGS.STUCK_CHECK_INTERVAL then
                local moved = getDistance(currentPos, lastPosition)
                
                if moved < SETTINGS.STUCK_DISTANCE then
                    totalStuckTime = totalStuckTime + SETTINGS.STUCK_CHECK_INTERVAL
                    
                    if totalStuckTime >= SETTINGS.STUCK_TIME and totalStuckTime < SETTINGS.STUCK_TIME + 0.5 then
                        log("   🦘 Прыжок от застревания...")
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.3)
                    end
                else
                    totalStuckTime = 0
                end
                
                lastPosition = currentPos
                lastCheckTime = currentTime
            end
            
            if distToWaypoint < 2 then break end
            if currentTime - startTime > SETTINGS.MOVE_TIMEOUT then break end
            
            task.wait(0.05)  -- ⚡ Меньше задержка
        end
        
        task.wait(0.1)  -- ⚡ Меньше пауза между точками
    end
    
    local finalDist = getDistance(rootPart.Position, targetPos)
    log("📍 Финальное расстояние: " .. math.floor(finalDist))
    
    if finalDist > SETTINGS.STOP_DISTANCE then
        log("🚶 Подхожу ближе...")
        humanoid:MoveTo(targetPos)
        humanoid.MoveToFinished:Wait(5)  -- ⚡ Было 10, стало 5
    end
    
    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    
    log("✅ Ходьба завершена!")
    return true
end

-- ============================================
-- АКТИВАЦИЯ PROMPT
-- ============================================

local function activatePrompt(prompt)
    if not prompt then return false end
    
    if prompt.Parent and prompt.Parent:IsA("BasePart") then
        local dist = getDistance(rootPart.Position, prompt.Parent.Position)
        
        if dist > 10 then
            walkTo(prompt.Parent.Position)
        end
    end
    
    if fireproximityprompt then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then return true end
    end
    
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(1)  -- ⚡ Было 1.5, стало 1
        prompt:InputHoldEnd()
    end)
    
    return ok
end

-- ============================================
-- ПРОВЕРКА ДОСТУПНОСТИ
-- ============================================

local function tryTakeItem(item)
    if item.unavailable then
        return false
    end
    
    if not item.obj or not item.obj.Parent then
        item.unavailable = true
        return false
    end
    
    local startTime = tick()
    local activated = false
    
    while tick() - startTime < SETTINGS.TAKE_TIMEOUT do
        if not running then return false end
        
        activated = activatePrompt(item.obj)
        
        if activated then
            return true
        end
        
        task.wait(0.5)  -- ⚡ Меньше задержка
    end
    
    item.failedAttempts = item.failedAttempts + 1
    
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then
        item.unavailable = true
    end
    
    return false
end

-- ============================================
--  БЫСТРАЯ ОПЛАТА
-- ============================================

local function pay()
    log("\n💳 БЫСТРАЯ ОПЛАТА...")
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local confirmPurchase = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirmPurchase then
        confirmPurchase = confirmPurchase:FindFirstChild("ConfirmPurchase")
    end
    
    if confirmPurchase then
        local ok = pcall(function() confirmPurchase:FireServer() end)
        if ok then 
            log("   ✅ RemoteEvent отправлен!")
            return true 
        end
    end
    
    if player:FindFirstChild("PlayerGui") then
        local shopGUI = player.PlayerGui:FindFirstChild("ShopGUI")
        if shopGUI then
            local buyButton = shopGUI:FindFirstChild("BuyButton", true)
            if buyButton and buyButton:IsA("TextButton") then
                local ok = pcall(function()
                    local pos = buyButton.AbsolutePosition
                    local size = buyButton.AbsoluteSize
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2))
                end)
                if ok then 
                    log("   ✅ GUI кнопка нажата!")
                    return true 
                end
            end
        end
    end
    
    log("   ❌ Не удалось")
    return false
end

-- ============================================
-- GUI С ДВИГАЕМЫМ ОКНОМ
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v8"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 650, 0, 750)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderSizePixel = 0
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -45, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ Автопокупка v8.0 | БЫСТРАЯ"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
    running = false
    screenGui:Destroy()
end)

-- ДВИГАЕМОЕ ОКНО
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput then
        updateDrag(input)
    end
end)

-- Элементы GUI
local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, -20, 0, 40)
filterBox.Position = UDim2.new(0, 10, 0, 60)
filterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
filterBox.TextColor3 = Color3.new(1, 1, 1)
filterBox.PlaceholderText = "🔍 Фильтр..."
filterBox.Text = ""
filterBox.Font = Enum.Font.Gotham
filterBox.TextSize = 14
filterBox.Parent = frame
Instance.new("UICorner", filterBox).CornerRadius = UDim.new(0, 8)

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -20, 0, 60)
statsFrame.Position = UDim2.new(0, 10, 0, 105)
statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statsFrame.Parent = frame
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 8)

local takenLabel = Instance.new("TextLabel")
takenLabel.Size = UDim2.new(0.5, -5, 1, 0)
takenLabel.Position = UDim2.new(0, 10, 0, 0)
takenLabel.BackgroundTransparency = 1
takenLabel.Text = "🛒 Взято: 0 / " .. SETTINGS.MAX_TOTAL
takenLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
takenLabel.Font = Enum.Font.GothamBold
takenLabel.TextSize = 14
takenLabel.TextXAlignment = Enum.TextXAlignment.Left
takenLabel.Parent = statsFrame

local paidLabel = Instance.new("TextLabel")
paidLabel.Size = UDim2.new(0.5, -5, 1, 0)
paidLabel.Position = UDim2.new(0.5, 5, 0, 0)
paidLabel.BackgroundTransparency = 1
paidLabel.Text = "💳 Оплачено: 0"
paidLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
paidLabel.Font = Enum.Font.GothamBold
paidLabel.TextSize = 14
paidLabel.TextXAlignment = Enum.TextXAlignment.Left
paidLabel.Parent = statsFrame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 55)
startBtn.Position = UDim2.new(0, 10, 0, 170)
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
startBtn.Text = "⚡ ЗАПУСТИТЬ БЫСТРО"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 230)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⚡ Готов | Быстрый режим"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 90)
logLabel.Position = UDim2.new(0, 10, 0, 265)
logLabel.BackgroundTransparency = 1
logLabel.Text = " Лог:"
logLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.Parent = frame

local logText = {}
local function addLog(msg)
    table.insert(logText, msg)
    if #logText > 6 then table.remove(logText, 1) end
    logLabel.Text = "📋 Лог:\n" .. table.concat(logText, "\n")
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -370)
scrollFrame.Position = UDim2.new(0, 10, 0, 360)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

local function updateStats()
    takenLabel.Text = "🛒 Взято: " .. takenCount .. " / " .. SETTINGS.MAX_TOTAL
    paidLabel.Text = "💳 Оплачено: " .. paidCount
end

local function updateList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local filter = filterBox.Text:lower()
    
    for i, item in ipairs(clothes) do
        local match = filter == "" or 
                      item.name:lower():find(filter) or 
                      item.shop:lower():find(filter)
        
        if match then
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, 50)
            
            if item.taken then
                itemFrame.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
            elseif item.unavailable then
                itemFrame.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
            else
                itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            end
            
            itemFrame.LayoutOrder = i
            itemFrame.Parent = scrollFrame
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)
            
            local shopLimit = shopLimits[item.shop] or 0
            local limitText = shopLimit >= SETTINGS.MAX_PER_SHOP and " [🔒 ЛИМИТ]" or ""
            local unavailableText = item.unavailable and " [❌ КУПЛЕНО]" or ""
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -10, 0, 24)
            nameLabel.Position = UDim2.new(0, 10, 0, 3)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = (item.taken and "✅ " or " ") .. item.name .. unavailableText
            nameLabel.TextColor3 = item.taken and 
                Color3.fromRGB(100, 255, 100) or 
                (item.unavailable and Color3.fromRGB(255, 100, 100) or Color3.new(1, 1, 1))
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = itemFrame
            
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, -10, 0, 20)
            infoLabel.Position = UDim2.new(0, 10, 0, 26)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = item.shop .. " | " .. item.floor .. " | " .. item.priceText .. limitText
            infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextSize = 10
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.Parent = itemFrame
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

local function resetAll()
    for _, item in ipairs(clothes) do
        item.taken = false
        item.unavailable = false
        item.failedAttempts = 0
    end
    shopLimits = {}
    takenCount = 0
    lastTakeTime = 0
    lastMoveTime = tick()
    addLog("🔄 Сброс счетчиков")
    updateList()
end

-- ============================================
-- ФУНКЦИЯ ОПЛАТЫ
-- ============================================

local function goToPay()
    if takenCount == 0 then
        return
    end
    
    if not seller then
        log("❌ Продавец не найден!")
        return
    end
    
    log("\n💰 КОРЗИНА ПОЛНА (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ") → БЫСТРАЯ ОПЛАТА!")
    addLog("💰 Иду оплачивать " .. takenCount .. " товаров!")
    statusLabel.Text = "💰 Быстрая оплата..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    if seller.position then
        walkTo(seller.position)
        task.wait(0.5)  -- ⚡ Было 1, стало 0.5
    end
    
    log("💬 Разговор с продавцом...")
    addLog("💬 Говорю...")
    statusLabel.Text = "💬 Разговор..."
    
    activatePrompt(seller.obj)
    task.wait(1)  -- ⚡ Было 3, стало 1!
    
    log("💳 Оплата...")
    addLog(" Оплачиваю...")
    statusLabel.Text = "💳 Оплата..."
    
    local paid = pay()
    
    if paid then
        paidCount = paidCount + 1
        log("✅ Оплачено! Всего оплат: " .. paidCount)
        addLog("✅ Оплачено! (" .. paidCount .. ")")
        updateStats()
        task.wait(1)  -- ⚡ Было 2, стало 1
    else
        log("⚠️  Не удалось оплатить")
        addLog("⚠️  Ошибка оплаты")
    end
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

local function mainLoop()
    log("\n ЗАПУСК БЫСТРОГО ЦИКЛА!")
    
    while running do
        resetAll()
        addLog("⚡ Быстрый цикл начался!")
        statusLabel.Text = "⚡ Начинаю..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        local shouldPay = false
        
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken then continue end
            
            if item.unavailable then
                continue
            end
            
            if takenCount >= SETTINGS.MAX_TOTAL then
                log("\n🎯 КОРЗИНА ПОЛНА! (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                shouldPay = true
                break
            end
            
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then
                continue
            end
            
            -- ⚡ Быстрая задержка с движением
            local waitTime = SETTINGS.DELAY_ITEMS - (tick() - lastTakeTime)
            if waitTime > 0 then
                local waitSec = math.ceil(waitTime)
                log("⏳ Задержка: " .. waitSec .. " сек...")
                
                -- ⚡ Во время ожидания двигаемся каждые 2 сек
                local waitStart = tick()
                while tick() - waitStart < waitTime do
                    if not running then return end
                    doQuickMove()  -- Движение каждые 2 сек
                    task.wait(0.5)
                end
            end
            
            if not running then break end
            
            log("\n🎯 Цель: " .. item.name .. " [" .. item.shop .. "]")
            addLog("🚶 " .. item.name)
            statusLabel.Text = " " .. item.name
            
            if item.position then
                walkTo(item.position)
                task.wait(0.3)  -- ⚡ Меньше пауза
            end
            
            log("🤖 Беру...")
            addLog("🤖 Беру...")
            statusLabel.Text = "🤖 Беру " .. item.name
            
            local success = tryTakeItem(item)
            
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                
                log("✅ Взял! " .. item.name .. " [" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. "]")
                addLog("✅ " .. item.name .. " (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                
                updateStats()
                updateList()
                
                if takenCount >= SETTINGS.MAX_TOTAL then
                    shouldPay = true
                    break
                end
            else
                addLog("❌ " .. item.name .. " (пропуск)")
            end
            
            task.wait(0.3)  -- ⚡ Меньше пауза
        end
        
        if shouldPay or takenCount > 0 then
            goToPay()
        else
            addLog("❌ Пусто")
        end
        
        log("\n⏳ Ожидание обновления (10 мин)...")
        addLog("⏳ Жду 10 мин...")
        statusLabel.Text = "⏳ Ожидание..."
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        
        for i = 1, SETTINGS.REFRESH_TIME do
            if not running then break end
            
            -- ⚡ Во время ожидания тоже двигаемся
            if i % 10 == 0 then
                doQuickMove()
            end
            
            task.wait(1)
        end
        
        log("🔄 Магазин обновился!\n")
    end
    
    running = false
    startBtn.Text = "⚡ ЗАПУСТИТЬ БЫСТРО"
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    addLog("️ Остановлено")
end

startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "⚡ ЗАПУСТИТЬ БЫСТРО"
        startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    else
        running = true
        startBtn.Text = "⏹️ СТОП"
        startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        task.spawn(mainLoop)
    end
end)

filterBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateList()
end)

-- ИНИЦИАЛИЗАЦИЯ
findShops()
findClothes()
updateStats()
updateList()

print("\n" .. string.rep("=", 60))
print("✅ БЫСТРЫЙ скрипт загружен!")
print("⚡ Скорость ходьбы: " .. SETTINGS.WALK_SPEED)
print("⚡ Задержка между предметами: " .. SETTINGS.DELAY_ITEMS .. " сек")
print("⚡ Движение каждые: " .. SETTINGS.MOVE_INTERVAL .. " сек")
print("⚡ Таймаут на предмет: " .. SETTINGS.TAKE_TIMEOUT .. " сек")
print("⚡ Быстрая оплата (1 сек вместо 3)")
print("🖱️  ОКНО МОЖНО ПЕРЕТАСКИВАТЬ!")
print(string.rep("=", 60) .. "\n")
