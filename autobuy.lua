-- 👕 АВТОПОКУПКА v3.0 - УЛУЧШЕННАЯ ХОДЬБА
-- GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/l9jlevadim-svg/roblox-scripts/main/autobuy.lua"))()

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

print("\n" .. string.rep("=", 50))
print("👕 АВТОПОКУПКА v3.0 - ЗАПУСК")
print(string.rep("=", 50) .. "\n")

-- ============================================
-- НАСТРОЙКИ
-- ============================================
local SETTINGS = {
    MAX_PER_SHOP = 15,
    DELAY_ITEMS = 2,
    REFRESH_TIME = 600,
    STOP_DISTANCE = 3,
    STUCK_TIMEOUT = 2.5,
    STUCK_DISTANCE = 0.3,
    TELEPORT_OFFSET = Vector3.new(0, 3, 0),
    WALK_SPEED = 16,
    JUMP_POWER = 50,
    PATH_AGENT_RADIUS = 2,
    PATH_AGENT_HEIGHT = 5,
    MAX_PATH_RETRIES = 3,
    MOVE_TO_TIMEOUT = 20
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
local currentShop = nil

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
            if part then
                return part.CFrame.Position
            end
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
-- ПОИСК МАГАЗИНОВ И ОДЕЖДЫ
-- ============================================

local function findShops()
    log("🔍 Поиск магазинов...")
    shopZones = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Shop_ShopZone") then
            shopZones[obj.Name] = true
            log("  🏪 Найден: " .. obj.Name)
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
                    floor = "2 этаж (Y=" .. math.floor(position.Y) .. ")"
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
                    attempts = 0
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
    
    local shopsCount = {}
    for _, item in ipairs(clothes) do
        shopsCount[item.shop] = (shopsCount[item.shop] or 0) + 1
    end
    
    log("\n📊 По магазинам:")
    for shop, count in pairs(shopsCount) do
        log("  " .. shop .. ": " .. count .. " вещей")
    end
end

-- ============================================
-- УЛУЧШЕННАЯ СИСТЕМА ХОДЬБЫ
-- ============================================

local function smoothMoveTo(targetPosition)
    if not targetPosition or not humanoid or not rootPart then
        log("❌ smoothMoveTo: нет цели или персонажа")
        return false
    end
    
    local startPos = rootPart.Position
    local distance = getDistance(startPos, targetPosition)
    log("🚶 Ходьба: " .. math.floor(distance) .. " студий")
    
    -- Устанавливаем скорость
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER
    
    -- Создаем путь
    local path = PathfindingService:CreatePath({
        AgentRadius = SETTINGS.PATH_AGENT_RADIUS,
        AgentHeight = SETTINGS.PATH_AGENT_HEIGHT,
        AgentCanJump = true,
        AgentCanClimb = true,
        Costs = {
            Water = 100,
            Door = 50,
            Normal = 1
        }
    })
    
    local success, err = pcall(function()
        path:ComputeAsync(startPos, targetPosition)
    end)
    
    if not success then
        log("❌ Ошибка создания пути: " .. tostring(err))
        humanoid:MoveTo(targetPosition)
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        task.wait(2)
        return true
    end
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        log("   ✅ Путь: " .. #waypoints .. " точек")
        
        local stuckCount = 0
        local lastPosition = rootPart.Position
        local totalPoints = #waypoints
        
        for i, waypoint in ipairs(waypoints) do
            if not running then
                humanoid.WalkSpeed = originalWalkSpeed
                humanoid.JumpPower = originalJumpPower
                return false
            end
            
            log("   Точка " .. i .. "/" .. totalPoints)
            
            -- Двигаемся к точке
            humanoid:MoveTo(waypoint.Position)
            
            -- Прыжок если нужно
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                log("   ⬆️ Прыжок!")
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            -- Ждем достижения с умной проверкой
            local timeout = 0
            local maxWait = SETTINGS.MOVE_TO_TIMEOUT
            
            while timeout < maxWait do
                if not running then
                    humanoid.WalkSpeed = originalWalkSpeed
                    humanoid.JumpPower = originalJumpPower
                    return false
                end
                
                local currentPos = rootPart.Position
                local distToWaypoint = getDistance(currentPos, waypoint.Position)
                local moved = getDistance(currentPos, lastPosition)
                
                -- Проверяем застревание
                if moved < SETTINGS.STUCK_DISTANCE then
                    stuckCount = stuckCount + 1
                    
                    if stuckCount > SETTINGS.STUCK_TIMEOUT * 10 then
                        log("⚠️  Застрял! Пробую обойти...")
                        
                        -- Пробуем прыгнуть
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.5)
                        
                        -- Если не помогло - телепорт
                        if getDistance(rootPart.Position, waypoint.Position) > 5 then
                            local offset = Vector3.new(
                                math.random(-3, 3),
                                3,
                                math.random(-3, 3)
                            )
                            log("   🔄 Телепорт с оффсетом...")
                            rootPart.CFrame = CFrame.new(waypoint.Position + offset)
                            task.wait(0.5)
                        end
                        
                        stuckCount = 0
                    end
                else
                    stuckCount = 0
                end
                
                lastPosition = currentPos
                
                -- Если дошли
                if distToWaypoint < 2 then
                    break
                end
                
                timeout = timeout + 0.1
                task.wait(0.1)
            end
            
            task.wait(0.1)
        end
        
        -- Финальная проверка
        local finalDist = getDistance(rootPart.Position, targetPosition)
        log("   📍 Финальное расстояние: " .. math.floor(finalDist))
        
        if finalDist > SETTINGS.STOP_DISTANCE then
            log("   🔄 Подхожу ближе...")
            humanoid:MoveTo(targetPosition)
            
            local timeout = 0
            while timeout < 5 do
                if getDistance(rootPart.Position, targetPosition) < 3 then
                    break
                end
                timeout = timeout + 0.1
                task.wait(0.1)
            end
            
            -- Если всё ещё далеко - телепорт
            if getDistance(rootPart.Position, targetPosition) > 4 then
                log("   🔄 Финальный телепорт...")
                rootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 1, 0))
                task.wait(0.3)
            end
        end
        
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        log("   ✅ Дошел!")
        return true
        
    else
        log("⚠️  Путь не найден (Status: " .. tostring(path.Status) .. ")")
        
        -- Пробуем прямой путь
        log("   🔄 Иду напрямик...")
        humanoid:MoveTo(targetPosition)
        
        local timeout = 0
        while timeout < 10 do
            if getDistance(rootPart.Position, targetPosition) < 5 then
                break
            end
            timeout = timeout + 0.5
            task.wait(0.5)
        end
        
        -- Телепорт если не дошел
        if getDistance(rootPart.Position, targetPosition) > 5 then
            log("   🔄 Телепорт к цели...")
            rootPart.CFrame = CFrame.new(targetPosition + SETTINGS.TELEPORT_OFFSET)
            task.wait(0.5)
        end
        
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        return true
    end
end

-- ============================================
-- АКТИВАЦИЯ PROMPT
-- ============================================

local function activatePrompt(prompt)
    if not prompt then
        log("❌ activatePrompt: prompt = nil")
        return false
    end
    
    log("🔘 Активирую: " .. prompt:GetFullName())
    
    -- Проверяем расстояние
    if prompt.Parent and prompt.Parent:IsA("BasePart") then
        local dist = getDistance(rootPart.Position, prompt.Parent.Position)
        log("   Расстояние: " .. math.floor(dist))
        
        if dist > 8 then
            log("   ⚠️  Далеко! Подхожу...")
            smoothMoveTo(prompt.Parent.Position)
        end
    end
    
    -- Метод 1: fireproximityprompt
    if fireproximityprompt then
        log("   🎯 fireproximityprompt...")
        local ok = pcall(function()
            fireproximityprompt(prompt)
        end)
        if ok then
            log("   ✅ Успех!")
            return true
        end
    end
    
    -- Метод 2: InputHold
    log("   🎯 InputHold...")
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration or 0.5, 1.5))
        prompt:InputHoldEnd()
    end)
    
    if ok then
        log("   ✅ Успех!")
        return true
    else
        log("   ❌ Ошибка")
        return false
    end
end

-- ============================================
-- ОПЛАТА
-- ============================================

local function pay()
    log("\n💳 ОПЛАТА...")
    
    -- RemoteEvent
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local confirmPurchase = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirmPurchase then
        confirmPurchase = confirmPurchase:FindFirstChild("ConfirmPurchase")
    end
    
    if confirmPurchase then
        log("   🎯 RemoteEvent...")
        local ok = pcall(function()
            confirmPurchase:FireServer()
        end)
        if ok then
            log("   ✅ RemoteEvent отправлен!")
            return true
        end
    end
    
    -- GUI кнопка
    log("   🎯 GUI кнопка...")
    if player:FindFirstChild("PlayerGui") then
        local shopGUI = player.PlayerGui:FindFirstChild("ShopGUI")
        if shopGUI then
            local buyButton = shopGUI:FindFirstChild("BuyButton", true)
            if buyButton and buyButton:IsA("TextButton") then
                log("   BuyButton найден")
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
    
    log("   ❌ Не удалось оплатить")
    return false
end

-- ============================================
-- GUI ИНТЕРФЕЙС
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v3"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 650, 0, 750)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BorderSizePixel = 0
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -45, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "👕 Автопокупка v3.0 | 18 Магазинов"
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

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
    running = false
    screenGui:Destroy()
end)

-- Перетаскивание
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                     input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Фильтр
local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, -20, 0, 40)
filterBox.Position = UDim2.new(0, 10, 0, 60)
filterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
filterBox.TextColor3 = Color3.new(1, 1, 1)
filterBox.PlaceholderText = "🔍 Фильтр (название или магазин)..."
filterBox.Text = ""
filterBox.Font = Enum.Font.Gotham
filterBox.TextSize = 14
filterBox.Parent = frame

Instance.new("UICorner", filterBox).CornerRadius = UDim.new(0, 6)

-- Статистика
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -20, 0, 55)
statsFrame.Position = UDim2.new(0, 10, 0, 105)
statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statsFrame.Parent = frame

Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 6)

local takenLabel = Instance.new("TextLabel")
takenLabel.Size = UDim2.new(0.5, -5, 1, 0)
takenLabel.Position = UDim2.new(0, 10, 0, 0)
takenLabel.BackgroundTransparency = 1
takenLabel.Text = "🛒 Взято: 0 / " .. SETTINGS.MAX_PER_SHOP .. " (на магазин)"
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

-- Кнопка
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 50)
startBtn.Position = UDim2.new(0, 10, 0, 165)
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame

Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

-- Статус
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 220)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🟢 Готов к запуску | Улучшенная навигация"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- Лог
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 90)
logLabel.Position = UDim2.new(0, 10, 0, 255)
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

-- Список
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -360)
scrollFrame.Position = UDim2.new(0, 10, 0, 350)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame

Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

local function updateStats()
    takenLabel.Text = "🛒 Взято: " .. takenCount .. " / " .. SETTINGS.MAX_PER_SHOP .. " (на магазин)"
    paidLabel.Text = "💳 Оплачено: " .. paidCount
end

local function updateList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local filter = filterBox.Text:lower()
    local shown = 0
    
    for i, item in ipairs(clothes) do
        local match = filter == "" or 
                      item.name:lower():find(filter) or 
                      item.shop:lower():find(filter)
        
        if match then
            shown = shown + 1
            
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, 45)
            itemFrame.BackgroundColor3 = item.taken and 
                Color3.fromRGB(40, 80, 40) or 
                Color3.fromRGB(35, 35, 35)
            itemFrame.LayoutOrder = i
            itemFrame.Parent = scrollFrame
            
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 6)
            
            local shopLimit = shopLimits[item.shop] or 0
            local limitText = shopLimit >= SETTINGS.MAX_PER_SHOP and " [🔒 ЛИМИТ]" or ""
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -10, 0, 22)
            nameLabel.Position = UDim2.new(0, 10, 0, 3)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = (item.taken and "✅ " or "📦 ") .. item.name
            nameLabel.TextColor3 = item.taken and 
                Color3.fromRGB(100, 255, 100) or 
                Color3.new(1, 1, 1)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = itemFrame
            
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, -10, 0, 18)
            infoLabel.Position = UDim2.new(0, 10, 0, 24)
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
        item.attempts = 0
    end
    shopLimits = {}
    takenCount = 0
    lastTakeTime = 0
    addLog("🔄 Сброс счетчиков")
    updateList()
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

local function mainLoop()
    log("\n🎬 ЗАПУСК ОСНОВНОГО ЦИКЛА!")
    
    while running do
        resetAll()
        addLog("🔄 Новый цикл начался!")
        statusLabel.Text = "🔄 Начинаю обход магазинов..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken then continue end
            
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then
                log("⏭️  " .. item.shop .. " - лимит достигнут (" .. shopCount .. "/" .. SETTINGS.MAX_PER_SHOP .. ")")
                continue
            end
            
            -- Задержка между предметами
            local waitTime = SETTINGS.DELAY_ITEMS - (tick() - lastTakeTime)
            if waitTime > 0 then
                local waitSec = math.ceil(waitTime)
                log("⏳ Задержка: " .. waitSec .. " сек...")
                addLog("⏳ Жду " .. waitSec .. "с...")
                statusLabel.Text = "⏳ Задержка " .. waitSec .. "с..."
                
                for i = 1, waitSec do
                    if not running then return end
                    task.wait(1)
                end
            end
            
            if not running then break end
            
            log("\n🎯 Цель: " .. item.name .. " [" .. item.shop .. " " .. item.floor .. "]")
            addLog("🚶 " .. item.name)
            statusLabel.Text = "🚶 " .. item.name .. " (" .. item.shop .. ")"
            
            if item.position then
                local success = smoothMoveTo(item.position)
                
                if not success then
                    log("⚠️  Не удалось дойти, пробую еще раз...")
                    item.attempts = item.attempts + 1
                    
                    if item.attempts <= SETTINGS.MAX_PATH_RETRIES then
                        task.wait(1)
                        smoothMoveTo(item.position)
                    end
                end
                
                task.wait(0.5)
            else
                log("❌ Нет позиции для " .. item.name)
            end
            
            -- Берем предмет
            log("🤖 Активация prompt...")
            addLog("🤖 Беру...")
            statusLabel.Text = "🤖 Беру " .. item.name .. "..."
            
            local activated = activatePrompt(item.obj)
            
            if activated then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                
                local currentShopCount = shopLimits[item.shop]
                log("✅ Взял! " .. item.name .. " [" .. currentShopCount .. "/" .. SETTINGS.MAX_PER_SHOP .. " в " .. item.shop .. "]")
                addLog("✅ " .. item.name .. " (" .. currentShopCount .. "/" .. SETTINGS.MAX_PER_SHOP .. ")")
                
                updateStats()
                updateList()
            else
                log("❌ Не удалось взять: " .. item.name)
                addLog("❌ " .. item.name)
                item.attempts = item.attempts + 1
            end
            
            task.wait(0.5)
        end
        
        -- Оплата
        if seller and takenCount > 0 then
            log("\n💰 ВРЕМЯ ОПЛАТЫ!")
            addLog("🚶 Иду к продавцу...")
            statusLabel.Text = "🚶 К продавцу..."
            
            if seller.position then
                smoothMoveTo(seller.position)
                task.wait(1)
            end
            
            log("💬 Разговор с продавцом...")
            addLog("💬 Говорю...")
            statusLabel.Text = "💬 Разговор..."
            
            activatePrompt(seller.obj)
            task.wait(3)
            
            log("💳 Оплата...")
            addLog("💳 Оплачиваю...")
            statusLabel.Text = "💳 Оплата..."
            
            local paid = pay()
            
            if paid then
                paidCount = paidCount + 1
                log("✅ Оплачено! Всего оплат: " .. paidCount)
                addLog("✅ Оплачено! (" .. paidCount .. ")")
                updateStats()
                task.wait(2)
            else
                log("⚠️  Не удалось оплатить")
                addLog("⚠️  Ошибка оплаты")
            end
        elseif takenCount == 0 then
            log("❌ Ничего не взял, пропускаю оплату")
            addLog("❌ Пусто")
        end
        
        -- Ожидание обновления
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
        task.spawn(mainLoop)
    end
end)

-- Обновление при изменении фильтра
filterBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateList()
end)

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

findShops()
findClothes()
updateStats()
updateList()

print("\n" .. string.rep("=", 50))
print("✅ Скрипт успешно загружен!")
print("📊 Найдено магазинов: " .. #shopZones)
print("📊 Найдено одежды: " .. #clothes)
print("💡 Нажми '▶️ ЗАПУСТИТЬ АВТОПОКУПКУ' для старта")
print("💡 GitHub: loadstring(game:HttpGet('URL'))()")
print(string.rep("=", 50) .. "\n")
