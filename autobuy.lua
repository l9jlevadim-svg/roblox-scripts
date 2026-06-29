-- 👕 АВТОПОКУПКА v4.0 - ИДЕАЛЬНАЯ ХОДЬБА
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

print("\n" .. string.rep("=", 50))
print("👕 АВТОПОКУПКА v4.0 - ИДЕАЛЬНАЯ ХОДЬБА")
print(string.rep("=", 50) .. "\n")

-- ============================================
-- НАСТРОЙКИ
-- ============================================
local SETTINGS = {
    MAX_PER_SHOP = 15,
    DELAY_ITEMS = 2,
    REFRESH_TIME = 600,
    STOP_DISTANCE = 4,           -- Останавливаться в 4 студиях
    WALK_SPEED = 18,             -- Скорость ходьбы
    JUMP_POWER = 50,             -- Сила прыжка
    STUCK_CHECK_INTERVAL = 0.5,  -- Проверка застревания каждые 0.5 сек
    STUCK_DISTANCE = 1,          -- Если прошел меньше 1 студии - застрял
    STUCK_TIME = 4,              -- Если застрял на 4 секунды
    PATH_AGENT_RADIUS = 2,
    PATH_AGENT_HEIGHT = 5,
    MOVE_TIMEOUT = 25            -- Макс время на точку пути
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
                    taken = false
                })
            end
            
            if action:find("Поговорить") and not seller then
                seller = {obj = obj, position = findPosition(obj)}
                log("🏪 Продавец найден")
            end
        end
    end
    
    log("✅ Найдено одежды: " .. #clothes)
end

-- ============================================
-- 🌟 ИДЕАЛЬНАЯ ХОДЬБА (БЕЗ ТЕЛЕПОРТОВ)
-- ============================================

local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then
        log("❌ walkTo: ошибка параметров")
        return false
    end
    
    local startPos = rootPart.Position
    local totalDistance = getDistance(startPos, targetPos)
    
    log("🚶 Иду: " .. math.floor(totalDistance) .. " студий")
    log("   Старт: " .. tostring(startPos))
    log("   Цель: " .. tostring(targetPos))
    
    -- Сохраняем оригинальные статы
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    
    -- Устанавливаем скорость
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER
    
    -- Создаем путь
    local path = PathfindingService:CreatePath({
        AgentRadius = SETTINGS.PATH_AGENT_RADIUS,
        AgentHeight = SETTINGS.PATH_AGENT_HEIGHT,
        AgentCanJump = true,
        AgentCanClimb = true
    })
    
    -- Вычисляем путь
    local success = pcall(function()
        path:ComputeAsync(startPos, targetPos)
    end)
    
    if not success then
        log("⚠️  Ошибка создания пути, иду напрямик...")
        humanoid:MoveTo(targetPos)
        
        -- Ждем пока дойдет
        local reached = humanoid.MoveToFinished:Wait(SETTINGS.MOVE_TIMEOUT)
        
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        
        return reached
    end
    
    -- Проверяем статус пути
    if path.Status ~= Enum.PathStatus.Success then
        log("⚠️  Путь не найден (Status: " .. tostring(path.Status) .. ")")
        log("   Иду напрямик...")
        
        humanoid:MoveTo(targetPos)
        local reached = humanoid.MoveToFinished:Wait(SETTINGS.MOVE_TIMEOUT)
        
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        
        return reached
    end
    
    -- Получаем точки пути
    local waypoints = path:GetWaypoints()
    log("✅ Путь найден! Точек: " .. #waypoints)
    
    -- Идем по точкам
    for i, waypoint in ipairs(waypoints) do
        if not running then
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
            return false
        end
        
        log("   Точка " .. i .. "/" .. #waypoints .. ": " .. tostring(waypoint.Position))
        
        -- Двигаемся к точке
        humanoid:MoveTo(waypoint.Position)
        
        -- Прыгаем ТОЛЬКО если путь говорит что нужно
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            log("   ⬆️ Прыжок по пути!")
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        -- Ждем достижения точки с умной проверкой
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
            
            -- Расстояние до точки
            local distToWaypoint = getDistance(currentPos, waypoint.Position)
            
            -- Проверяем каждые STUCK_CHECK_INTERVAL секунд
            if currentTime - lastCheckTime >= SETTINGS.STUCK_CHECK_INTERVAL then
                local moved = getDistance(currentPos, lastPosition)
                
                log("   📊 Проверка: прошел " .. math.floor(moved) .. " студий, до точки " .. math.floor(distToWaypoint))
                
                -- Если почти не двигался
                if moved < SETTINGS.STUCK_DISTANCE then
                    totalStuckTime = totalStuckTime + SETTINGS.STUCK_CHECK_INTERVAL
                    log("   ⚠️  Застрял! Время: " .. math.floor(totalStuckTime) .. "с")
                    
                    -- Если застрял надолго - пробуем прыгнуть ОДИН РАЗ
                    if totalStuckTime >= SETTINGS.STUCK_TIME and totalStuckTime < SETTINGS.STUCK_TIME + 1 then
                        log("   🦘 Пробую прыжок...")
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.5)
                    end
                else
                    -- Двигался - сбрасываем счетчик
                    totalStuckTime = 0
                end
                
                lastPosition = currentPos
                lastCheckTime = currentTime
            end
            
            -- Если дошли до точки
            if distToWaypoint < 3 then
                log("   ✅ Точка достигнута!")
                break
            end
            
            -- Таймаут
            if currentTime - startTime > SETTINGS.MOVE_TIMEOUT then
                log("   ⏱️  Таймаут точки")
                break
            end
            
            task.wait(0.1)
        end
        
        -- Небольшая пауза между точками
        task.wait(0.15)
    end
    
    -- Финальная проверка расстояния до цели
    local finalDist = getDistance(rootPart.Position, targetPos)
    log("📍 Финальное расстояние: " .. math.floor(finalDist))
    
    -- Если далеко - подходим ближе (но не телепортируемся!)
    if finalDist > SETTINGS.STOP_DISTANCE then
        log("🚶 Подхожу ближе...")
        humanoid:MoveTo(targetPos)
        
        local reached = humanoid.MoveToFinished:Wait(10)
        
        if reached then
            finalDist = getDistance(rootPart.Position, targetPos)
            log("📍 После подхода: " .. math.floor(finalDist))
        end
    end
    
    -- Восстанавливаем скорость
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
    
    log("🔘 Активирую: " .. prompt:GetFullName())
    
    if prompt.Parent and prompt.Parent:IsA("BasePart") then
        local dist = getDistance(rootPart.Position, prompt.Parent.Position)
        log("   Расстояние: " .. math.floor(dist))
        
        if dist > 10 then
            log("   ⚠️  Далеко! Подхожу...")
            walkTo(prompt.Parent.Position)
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
    
    print(ok and "   ✅ InputHold" or "   ❌ Ошибка")
    return ok
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
    
    log("   ❌ Не удалось")
    return false
end

-- ============================================
-- GUI (сокращенная версия)
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v4"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 600, 0, 700)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.Parent = screenGui
Instance.new("UICorner").Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.Parent = frame
Instance.new("UICorner").Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "👕 Автопокупка v4.0 | ИДЕАЛЬНАЯ ХОДЬБА"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = titleBar
Instance.new("UICorner").Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() running = false screenGui:Destroy() end)

-- Перетаскивание
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, -20, 0, 35)
filterBox.Position = UDim2.new(0, 10, 0, 55)
filterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
filterBox.TextColor3 = Color3.new(1, 1, 1)
filterBox.PlaceholderText = "🔍 Фильтр..."
filterBox.Text = ""
filterBox.Parent = frame
Instance.new("UICorner").Parent = filterBox

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -20, 0, 50)
statsFrame.Position = UDim2.new(0, 10, 0, 95)
statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statsFrame.Parent = frame
Instance.new("UICorner").Parent = statsFrame

local takenLabel = Instance.new("TextLabel")
takenLabel.Size = UDim2.new(0.5, -5, 1, 0)
takenLabel.Position = UDim2.new(0, 5, 0, 0)
takenLabel.BackgroundTransparency = 1
takenLabel.Text = "🛒 Взято: 0"
takenLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
takenLabel.Font = Enum.Font.GothamBold
takenLabel.TextSize = 14
takenLabel.Parent = statsFrame

local paidLabel = Instance.new("TextLabel")
paidLabel.Size = UDim2.new(0.5, -5, 1, 0)
paidLabel.Position = UDim2.new(0.5, 5, 0, 0)
paidLabel.BackgroundTransparency = 1
paidLabel.Text = "💳 Оплачено: 0"
paidLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
paidLabel.Font = Enum.Font.GothamBold
paidLabel.TextSize = 14
paidLabel.Parent = statsFrame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 50)
startBtn.Position = UDim2.new(0, 10, 0, 150)
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
startBtn.Text = "▶️ ЗАПУСТИТЬ"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 15
startBtn.Parent = frame
Instance.new("UICorner").Parent = startBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 205)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🟢 Готов"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 13
statusLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 80)
logLabel.Position = UDim2.new(0, 10, 0, 235)
logLabel.BackgroundTransparency = 1
logLabel.Text = "📋 Лог:"
logLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 10
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.Parent = frame

local logText = {}
local function addLog(msg)
    table.insert(logText, msg)
    if #logText > 5 then table.remove(logText, 1) end
    logLabel.Text = "📋 Лог:\n" .. table.concat(logText, "\n")
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -320)
scrollFrame.Position = UDim2.new(0, 10, 0, 320)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = frame
Instance.new("UICorner").Parent = scrollFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = scrollFrame

local function updateStats()
    takenLabel.Text = "🛒 Взято: " .. takenCount
    paidLabel.Text = "💳 Оплачено: " .. paidCount
end

local function updateList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local filter = filterBox.Text:lower()
    local shown = 0
    
    for i, item in ipairs(clothes) do
        local match = filter == "" or item.name:lower():find(filter) or item.shop:lower():find(filter)
        if match then
            shown = shown + 1
            
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, 40)
            itemFrame.BackgroundColor3 = item.taken and Color3.fromRGB(40, 60, 40) or Color3.fromRGB(35, 35, 35)
            itemFrame.LayoutOrder = i
            itemFrame.Parent = scrollFrame
            Instance.new("UICorner").Parent = itemFrame
            
            local shopLimit = shopLimits[item.shop] or 0
            local limitText = shopLimit >= SETTINGS.MAX_PER_SHOP and " [ЛИМИТ]" or ""
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -10, 1, 0)
            nameLabel.Position = UDim2.new(0, 8, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = (item.taken and "✅ " or "📦 ") .. item.name .. " [" .. item.shop .. " " .. item.floor .. "]" .. limitText
            nameLabel.TextColor3 = item.taken and Color3.fromRGB(100, 255, 100) or Color3.new(1, 1, 1)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 10
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = itemFrame
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 5)
end

local function resetAll()
    for _, item in ipairs(clothes) do item.taken = false end
    shopLimits = {}
    takenCount = 0
    lastTakeTime = 0
    addLog("🔄 Сброс")
    updateList()
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

local function mainLoop()
    log("\n🎬 ЗАПУСК ЦИКЛА!")
    
    while running do
        resetAll()
        addLog("🔄 Новый цикл!")
        statusLabel.Text = "🔄 Начинаю..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken then continue end
            
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then continue end
            
            local waitTime = SETTINGS.DELAY_ITEMS - (tick() - lastTakeTime)
            if waitTime > 0 then
                log("⏳ Жду " .. math.ceil(waitTime) .. "с...")
                addLog("⏳ Жду " .. math.ceil(waitTime) .. "с...")
                for i = 1, math.ceil(waitTime) do
                    if not running then return end
                    task.wait(1)
                end
            end
            
            if not running then break end
            
            log(" " .. item.name .. " [" .. item.shop .. "]")
            addLog("🚶 " .. item.name)
            statusLabel.Text = "🚶 " .. item.name
            
            if item.position then
                walkTo(item.position)
                task.wait(0.5)
            end
            
            log("🤖 Беру...")
            addLog("🤖 Беру...")
            statusLabel.Text = "🤖 Беру..."
            
            local activated = activatePrompt(item.obj)
            
            if activated then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                log("✅ " .. item.name .. " [" .. shopLimits[item.shop] .. "/" .. SETTINGS.MAX_PER_SHOP .. "]")
                addLog("✅ " .. item.name)
                updateStats()
                updateList()
            else
                log("❌ " .. item.name)
                addLog("❌ " .. item.name)
            end
            
            task.wait(0.5)
        end
        
        if seller and takenCount > 0 then
            log("🚶 К продавцу...")
            if seller.position then
                walkTo(seller.position)
                task.wait(1)
            end
            
            log("💬 Разговор...")
            activatePrompt(seller.obj)
            task.wait(3)
            
            log("💳 Оплата...")
            if pay() then
                paidCount = paidCount + 1
                log("✅ Оплачено! Всего: " .. paidCount)
                addLog("✅ Оплачено!")
                updateStats()
            else
                log("⚠️  Не оплачено")
                addLog("⚠️  Ошибка оплаты")
            end
        end
        
        log("⏳ Жду 10 мин...")
        for i = 1, SETTINGS.REFRESH_TIME do
            if not running then break end
            task.wait(1)
        end
    end
    
    running = false
    startBtn.Text = "▶️ ЗАПУСТИТЬ"
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    addLog("⏹️ Остановлено")
end

startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "▶️ ЗАПУСТИТЬ"
        startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    else
        running = true
        startBtn.Text = "⏹️ СТОП"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
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

print("\n✅ Скрипт загружен!")
print("💡 Идеальная ходьба без телепортов")
print("💡 Умные прыжки только когда нужно")
print("💡 Нажми '▶️ ЗАПУСТИТЬ'")
