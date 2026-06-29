-- 👕 АВТОПОКУПКА v7.5 - ИСПРАВЛЕННЫЙ ПОИСК И ПОЗИЦИОНИРОВАНИЕ
-- GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/l9jlevadim-svg/roblox-scripts/main/autobuy.lua"))()

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
print("👕 АВТОПОКУПКА v7.5 - ИСПРАВЛЕННАЯ")
print(string.rep("=", 60) .. "\n")

-- ============================================
-- НАСТРОЙКИ
-- ============================================
local SETTINGS = {
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
    DELAY_ITEMS = 2,
    REFRESH_TIME = 600,
    STOP_DISTANCE = 4,
    WALK_SPEED = 18,
    JUMP_POWER = 50,
    STUCK_CHECK_INTERVAL = 0.5,
    STUCK_DISTANCE = 1,
    STUCK_TIME = 4,
    PATH_AGENT_RADIUS = 2,
    PATH_AGENT_HEIGHT = 5,
    MOVE_TIMEOUT = 25,
    MAX_FAILED_ATTEMPTS = 2,
    MOVE_INTERVAL = 2,
    MAX_RETRIES = 2,
    RETRY_DELAY = 1,
    MIN_PROMPT_DISTANCE = 3,  -- ✅ Минимальное расстояние для активации
    MAX_PROMPT_DISTANCE = 8   -- ✅ Максимальное расстояние для активации
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
--  УЛУЧШЕННЫЙ ПОИСК ПОЗИЦИИ ПРЕДМЕТА
-- ============================================

local function findItemPosition(prompt)
    -- Метод 1: Позиция самого ProximityPrompt
    if prompt:IsA("BasePart") then
        return prompt.CFrame.Position
    end
    
    -- Метод 2: Позиция родителя если это BasePart
    if prompt.Parent and prompt.Parent:IsA("BasePart") then
        return prompt.Parent.CFrame.Position
    end
    
    -- Метод 3: Ищем ближайший BasePart в родителе
    if prompt.Parent then
        for _, child in ipairs(prompt.Parent:GetChildren()) do
            if child:IsA("BasePart") then
                return child.CFrame.Position
            end
        end
    end
    
    -- Метод 4: Ищем BasePart выше в иерархии
    local checkObj = prompt.Parent
    for i = 1, 4 do
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

-- ============================================
-- 🎯 СОРТИРОВКА ПО БЛИЗОСТИ
-- ============================================

local function sortByDistance()
    if not rootPart then return end
    
    local currentPos = rootPart.Position
    
    table.sort(clothes, function(a, b)
        local distA = a.position and getDistance(currentPos, a.position) or math.huge
        local distB = b.position and getDistance(currentPos, b.position) or math.huge
        return distA < distB
    end)
    
    log("🎯 Отсортировано по близости!")
    
    for i, item in ipairs(clothes) do
        if item.position and i <= 10 then
            local dist = getDistance(currentPos, item.position)
            log("   " .. i .. ". " .. item.name .. " [" .. item.shop .. "] - " .. math.floor(dist) .. " студий")
        end
    end
end

-- ============================================
-- ДВИЖЕНИЕ ТЕЛОМ КАЖДЫЕ 2 СЕКУНДЫ
-- ============================================

local function doQuickMove()
    local currentTime = tick()
    if currentTime - lastMoveTime >= SETTINGS.MOVE_INTERVAL then
        if humanoid and humanoid.Health > 0 then
            local randomDir = Vector3.new(
                math.random(-2, 2),
                0,
                math.random(-2, 2)
            )
            humanoid:MoveTo(rootPart.Position + randomDir)
            lastMoveTime = currentTime
        end
    end
end

-- ============================================
-- 🔍 УЛУЧШЕННЫЙ ПОИСК МАГАЗИНОВ
-- ============================================

local function findShops()
    log("🔍 Поиск магазинов...")
    shopZones = {}
    
    -- Ищем по разным паттернам
    local patterns = {
        "Shop_ShopZone",
        "ShopZone",
        "Shop_",
        "ClothingShop",
        "Store"
    }
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            for _, pattern in ipairs(patterns) do
                if obj.Name:find(pattern) then
                    if not shopZones[obj.Name] then
                        shopZones[obj.Name] = true
                        log("  🏪 Найден: " .. obj.Name)
                    end
                    break
                end
            end
        end
    end
    
    log("📊 Всего магазинов: " .. #shopZones)
end

-- ============================================
--  УЛУЧШЕННЫЙ ПОИСК ОДЕЖДЫ
-- ============================================

local function findClothes()
    log("\n🔍 Поиск одежды...")
    clothes = {}
    
    local foundCount = 0
    local skippedCount = 0
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local path = obj:GetFullName()
            local action = obj.ActionText or ""
            
            -- Проверяем что это в магазине
            local inShop = false
            for shopName, _ in pairs(shopZones) do
                if path:find(shopName) then
                    inShop = true
                    break
                end
            end
            
            -- Также проверяем по ключевым словам
            if not inShop then
                if path:find("Shop") or path:find("Store") or path:find("Clothing") then
                    inShop = true
                end
            end
            
            if inShop and (action:find("Взять") or action:find("Take")) then
                local parent = obj.Parent
                local priceText = ""
                
                -- Ищем цену
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
                
                --  ВАЖНО: Ищем правильную позицию
                local position = findItemPosition(obj)
                
                if not position then
                    log("⚠️  Не удалось найти позицию для: " .. (parent and parent.Name or "Unknown"))
                    skippedCount = skippedCount + 1
                    continue
                end
                
                local shopName = "Unknown"
                for name, _ in pairs(shopZones) do
                    if path:find(name) then
                        shopName = name
                        break
                    end
                end
                
                local floor = "1 этаж"
                if position.Y > 10 then
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
                
                foundCount = foundCount + 1
                
                -- Логируем первые 10 найденных
                if foundCount <= 10 then
                    log("  ✅ " .. parent.Name .. " | " .. shopName .. " | " .. floor .. " | " .. priceText)
                    log("     Позиция: " .. tostring(position))
                end
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
    
    log("✅ Найдено одежды: " .. foundCount)
    if skippedCount > 0 then
        log("️  Пропущено (нет позиции): " .. skippedCount)
    end
end

-- ============================================
-- ХОДЬБА
-- ============================================

local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then
        log("❌ walkTo: ошибка параметров")
        return false
    end
    
    local startPos = rootPart.Position
    local totalDistance = getDistance(startPos, targetPos)
    
    log("🚶 Иду: " .. math.floor(totalDistance) .. " студий")
    
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    
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
        log("️  Путь не найден")
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
        
        log("   Точка " .. i .. "/" .. #waypoints)
        
        humanoid:MoveTo(waypoint.Position)
        
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            log("   ⬆️ Прыжок!")
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
            
            if currentTime - lastCheckTime >= SETTINGS.STUCK_CHECK_INTERVAL then
                local moved = getDistance(currentPos, lastPosition)
                
                if moved < SETTINGS.STUCK_DISTANCE then
                    totalStuckTime = totalStuckTime + SETTINGS.STUCK_CHECK_INTERVAL
                    
                    if totalStuckTime >= SETTINGS.STUCK_TIME and totalStuckTime < SETTINGS.STUCK_TIME + 1 then
                        log("    Прыжок от застревания...")
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.5)
                    end
                else
                    totalStuckTime = 0
                end
                
                lastPosition = currentPos
                lastCheckTime = currentTime
            end
            
            if distToWaypoint < 3 then break end
            if currentTime - startTime > SETTINGS.MOVE_TIMEOUT then break end
            
            task.wait(0.1)
        end
        
        task.wait(0.15)
    end
    
    local finalDist = getDistance(rootPart.Position, targetPos)
    log("📍 Финальное расстояние: " .. math.floor(finalDist))
    
    if finalDist > SETTINGS.STOP_DISTANCE then
        log("🚶 Подхожу ближе...")
        humanoid:MoveTo(targetPos)
        humanoid.MoveToFinished:Wait(10)
    end
    
    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    
    log("✅ Ходьба завершена!")
    return true
end

-- ============================================
-- ✅ ПРОВЕРКА РАССТОЯНИЯ ПЕРЕД АКТИВАЦИЕЙ
-- ============================================

local function activatePrompt(prompt)
    if not prompt then return false end
    
    log("🔘 Активирую prompt")
    
    -- 🎯 ВАЖНО: Проверяем расстояние ДО активации
    local promptPos = findItemPosition(prompt)
    if promptPos then
        local dist = getDistance(rootPart.Position, promptPos)
        log("   Расстояние до предмета: " .. math.floor(dist) .. " студий")
        
        -- Если слишком далеко - подходим
        if dist > SETTINGS.MAX_PROMPT_DISTANCE then
            log("   ⚠️  Далеко! Подхожу...")
            walkTo(promptPos)
            task.wait(0.5)
            
            -- Проверяем ещё раз после подхода
            dist = getDistance(rootPart.Position, promptPos)
            log("   Расстояние после подхода: " .. math.floor(dist) .. " студий")
        end
        
        -- Если всё ещё далеко - не активируем
        if dist > SETTINGS.MAX_PROMPT_DISTANCE then
            log("   ❌ Всё ещё далеко, пропускаю")
            return false
        end
    end
    
    if fireproximityprompt then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then log("   ✅ fireproximityprompt"); return true end
    end
    
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(1.5)
        prompt:InputHoldEnd()
    end)
    
    if ok then
        log("   ✅ InputHold")
        return true
    else
        log("   ❌ Ошибка активации")
        return false
    end
end

-- ============================================
-- 🔄 ПРОВЕРКА С ПОВТОРНЫМИ ПОПЫТКАМИ
-- ============================================

local function tryTakeItem(item)
    log(" Пробую взять: " .. item.name)
    
    if item.unavailable then
        log("   ️  Предмет помечен как недоступный, пропускаю")
        return false
    end
    
    if not item.obj or not item.obj.Parent then
        log("   ❌ Prompt исчез, помечаю как недоступный")
        item.unavailable = true
        return false
    end
    
    -- 🔄 ПОВТОРНЫЕ ПОПЫТКИ
    for attempt = 1, SETTINGS.MAX_RETRIES do
        if not running then return false end
        
        if attempt > 1 then
            log("    Попытка #" .. attempt .. " (жду " .. SETTINGS.RETRY_DELAY .. "с)...")
            task.wait(SETTINGS.RETRY_DELAY)
            
            if not item.obj or not item.obj.Parent then
                log("   ❌ Prompt исчез во время ожидания")
                item.unavailable = true
                return false
            end
        end
        
        log("   Попытка " .. attempt .. "/" .. SETTINGS.MAX_RETRIES)
        
        local activated = activatePrompt(item.obj)
        
        if activated then
            log("   ✅ Успешно взял с попытки #" .. attempt .. "!")
            item.failedAttempts = 0
            return true
        end
        
        log("   ❌ Попытка #" .. attempt .. " не удалась")
    end
    
    log("   ❌ Все " .. SETTINGS.MAX_RETRIES .. " попытки неудачны, пропускаю")
    item.failedAttempts = item.failedAttempts + 1
    
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then
        log("   ❌ Слишком много неудачных циклов (" .. item.failedAttempts .. "), помечаю как недоступный")
        item.unavailable = true
    end
    
    return false
end

-- ============================================
-- ОПЛАТА
-- ============================================

local function pay()
    log("\n💳 ОПЛАТА...")
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local confirmPurchase = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirmPurchase then
        confirmPurchase = confirmPurchase:FindFirstChild("ConfirmPurchase")
    end
    
    if confirmPurchase then
        local ok = pcall(function() confirmPurchase:FireServer() end)
        if ok then log("   ✅ RemoteEvent"); return true end
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
                if ok then log("   ✅ GUI"); return true end
            end
        end
    end
    
    log("    Не удалось")
    return false
end

-- ============================================
-- GUI С ДВИГАЕМЫМ ОКНОМ
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v7_5"
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
titleLabel.Text = "👕 Автопокупка v7.5 | Исправленная"
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
startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 230)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🟢 Готов"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 90)
logLabel.Position = UDim2.new(0, 10, 0, 265)
logLabel.BackgroundTransparency = 1
logLabel.Text = "📋 Лог:"
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
            nameLabel.Text = (item.taken and "✅ " or "📦 ") .. item.name .. unavailableText
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
-- БЫСТРАЯ ФУНКЦИЯ ОПЛАТЫ
-- ============================================

local function goToPay()
    if takenCount == 0 then
        log("❌ Корзина пуста, оплата не нужна")
        addLog("❌ Пусто")
        return
    end
    
    if not seller then
        log("❌ Продавец не найден!")
        addLog("❌ Нет продавца")
        return
    end
    
    log("\n💰 КОРЗИНА ПОЛНА (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ") → БЫСТРАЯ ОПЛАТА!")
    addLog("💰 Иду оплачивать " .. takenCount .. " товаров!")
    statusLabel.Text = "💰 Иду к продавцу..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    if seller.position then
        walkTo(seller.position)
        task.wait(0.5)
    end
    
    log("💬 Разговор с продавцом...")
    addLog("💬 Говорю...")
    statusLabel.Text = "💬 Разговор..."
    
    activatePrompt(seller.obj)
    task.wait(1)
    
    log("💳 Оплата...")
    addLog("💳 Оплачиваю...")
    statusLabel.Text = " Оплата..."
    
    local paid = pay()
    
    if paid then
        paidCount = paidCount + 1
        log("✅ Оплачено! Всего оплат: " .. paidCount)
        addLog("✅ Оплачено! (" .. paidCount .. ")")
        updateStats()
        task.wait(1)
    else
        log("⚠️  Не удалось оплатить")
        addLog("️  Ошибка оплаты")
    end
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

local function mainLoop()
    log("\n🎬 ЗАПУСК ОСНОВНОГО ЦИКЛА!")
    
    while running do
        resetAll()
        
        log("\n🎯 Сортировка магазинов по близости...")
        addLog("🎯 Сортировка...")
        sortByDistance()
        updateList()
        
        addLog("🔄 Новый цикл начался!")
        statusLabel.Text = "🔄 Начинаю с ближайшего магазина..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        local shouldPay = false
        
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken then continue end
            
            if item.unavailable then
                log("⏭️  Пропускаю " .. item.name .. " (куплено другим)")
                continue
            end
            
            if takenCount >= SETTINGS.MAX_TOTAL then
                log("\n🎯 КОРЗИНА ПОЛНА! (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                shouldPay = true
                break
            end
            
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then
                log("⏭️  " .. item.shop .. " - лимит магазина")
                continue
            end
            
            local waitTime = SETTINGS.DELAY_ITEMS - (tick() - lastTakeTime)
            if waitTime > 0 then
                local waitStart = tick()
                while tick() - waitStart < waitTime do
                    if not running then return end
                    doQuickMove()
                    task.wait(0.5)
                end
            end
            
            if not running then break end
            
            log("\n🎯 Цель: " .. item.name .. " [" .. item.shop .. " " .. item.floor .. "]")
            addLog("🚶 " .. item.name)
            statusLabel.Text = "🚶 " .. item.name .. " (" .. item.shop .. ")"
            
            if item.position then
                walkTo(item.position)
                task.wait(0.5)
            end
            
            log("🤖 Пробую взять...")
            addLog("🤖 Беру...")
            statusLabel.Text = "🤖 Беру " .. item.name .. "..."
            
            local success = tryTakeItem(item)
            
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                
                local currentShopCount = shopLimits[item.shop]
                log("✅ Взял! " .. item.name .. " [" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. "]")
                addLog("✅ " .. item.name .. " (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                
                updateStats()
                updateList()
                
                if takenCount >= SETTINGS.MAX_TOTAL then
                    log("\n🎯 ДОСТИГНУТ ЛИМИТ КОРЗИНЫ!")
                    shouldPay = true
                    break
                end
            else
                log("❌ Не удалось взять: " .. item.name)
                addLog("❌ " .. item.name .. " (пропуск)")
            end
            
            task.wait(0.5)
        end
        
        if shouldPay or takenCount > 0 then
            goToPay()
            
            if running then
                log("\n🎯 Пересортировка после оплаты...")
                addLog("🎯 Ищу ближайший магазин...")
                sortByDistance()
                updateList()
            end
        else
            log("❌ Ничего не взял в этом цикле")
            addLog(" Пусто")
        end
        
        log("\n⏳ Ожидание обновления магазина (10 минут)...")
        addLog("⏳ Жду 10 мин...")
        statusLabel.Text = "⏳ Ожидание обновления..."
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        
        for i = 1, SETTINGS.REFRESH_TIME do
            if not running then break end
            
            local mins = math.floor((SETTINGS.REFRESH_TIME - i) / 60)
            local secs = (SETTINGS.REFRESH_TIME - i) % 60
            
            if i % 30 == 0 then
                log("   Осталось: " .. mins .. "м " .. secs .. "с")
            end
            
            if i % 2 == 0 then
                doQuickMove()
            end
            
            task.wait(1)
        end
        
        log("🔄 Магазин обновился! Новый цикл...\n")
    end
    
    running = false
    startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    addLog("⏹️ Остановлено")
    statusLabel.Text = "⏹️ Остановлено"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    
    log("\n👋 Скрипт остановлен")
end

-- ============================================
-- КНОПКА СТАРТ/СТОП
-- ============================================

startBtn.MouseButton1Click:Connect(function()
    if running then
        log("\n⏹️ Остановка скрипта...")
        running = false
        startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
        startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    else
        log("\n▶️ Запуск скрипта...")
        running = true
        startBtn.Text = "⏹️ ОСТАНОВИТЬ"
        startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        
        log("\n🎯 Сортировка магазинов по близости...")
        addLog("🎯 Ищу ближайший магазин...")
        sortByDistance()
        updateList()
        
        task.spawn(mainLoop)
    end
end)

filterBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateList()
end)

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

findShops()
findClothes()

log("\n🎯 Начальная сортировка по близости...")
sortByDistance()

updateStats()
updateList()

print("\n" .. string.rep("=", 60))
print("✅ Скрипт v7.5 успешно загружен!")
print("📊 Найдено магазинов: " .. #shopZones)
print(" Найдено одежды: " .. #clothes)
print("🎯 Отсортировано по близости!")
print("🔄 Повторные попытки: " .. SETTINGS.MAX_RETRIES .. " раза с задержкой " .. SETTINGS.RETRY_DELAY .. "с")
print("❌ Макс неудачных циклов: " .. SETTINGS.MAX_FAILED_ATTEMPTS)
print("🎯 После " .. SETTINGS.MAX_TOTAL .. " товаров → оплата!")
print("🏃 Движение каждые " .. SETTINGS.MOVE_INTERVAL .. " сек")
print("⚡ Быстрая оплата")
print("🖱️  ОКНО МОЖНО ПЕРЕТАСКИВАТЬ за заголовок!")
print(string.rep("=", 60) .. "\n")
