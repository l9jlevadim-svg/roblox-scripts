-- 👕 АВТОПОКУПКА v7.6 - СИНХРОНИЗАЦИЯ + ИСПРАВЛЕННАЯ НАВИГАЦИЯ
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
print("👕 АВТОПОКУПКА v7.6 - СИНХРОНИЗАЦИЯ + НАВИГАЦИЯ")
print(string.rep("=", 60) .. "\n")

-- ============================================
-- НАСТROЙКИ
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
    MIN_PROMPT_DISTANCE = 3,
    MAX_PROMPT_DISTANCE = 8,
    ITEM_OFFSET = 3,         -- ✅ Отступ от предмета (не в стену!)
    SYNC_CART_ENABLED = true -- ✅ Синхронизация корзины
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
local cartGUI = nil          -- ✅ Ссылка на GUI корзины

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
-- 🛒 СИНХРОНИЗАЦИЯ КОРЗИНЫ С ИГРОЙ
-- ============================================

local function findCartGUI()
    if not player:FindFirstChild("PlayerGui") then return nil end
    
    -- Паттерны для поиска GUI корзины
    local cartPatterns = {"Cart", "Basket", "Корзина", "Inventory", "ShopCart"}
    
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        for _, pattern in ipairs(cartPatterns) do
            if gui.Name:lower():find(pattern:lower()) then
                log("🛒 Найден GUI корзины: " .. gui.Name)
                return gui
            end
        end
        
        -- Ищем вложенные элементы
        for _, child in ipairs(gui:GetDescendants()) do
            for _, pattern in ipairs(cartPatterns) do
                if child.Name:lower():find(pattern:lower()) then
                    log("🛒 Найден элемент корзины: " .. child:GetFullName())
                    return child
                end
            end
        end
    end
    
    return nil
end

local function getRealCartCount()
    -- Метод 1: Ищем Label с количеством в корзине
    if not player:FindFirstChild("PlayerGui") then return nil end
    
    for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local text = gui.Text or ""
            -- Ищем паттерны типа "В корзине: 5" или "Cart: 5"
            local count = text:match("(%d+)")
            if count and (text:lower():find("корзин") or 
                         text:lower():find("cart") or 
                         text:lower():find("basket") or
                         text:lower():find("товар")) then
                return tonumber(count)
            end
        end
    end
    
    -- Метод 2: Считаем фреймы в списке корзины
    local cartFrame = findCartGUI()
    if cartFrame then
        local itemsCount = 0
        for _, child in ipairs(cartFrame:GetDescendants()) do
            if child:IsA("Frame") and child.Name ~= cartFrame.Name then
                itemsCount = itemsCount + 1
            end
        end
        if itemsCount > 0 then
            return math.floor(itemsCount / 2) -- Делим на 2 так как каждый предмет может иметь 2 фрейма
        end
    end
    
    return nil
end

local function syncCart()
    if not SETTINGS.SYNC_CART_ENABLED then return end
    
    local realCount = getRealCartCount()
    if realCount and realCount ~= takenCount then
        log("🔄 Синхронизация корзины: " .. takenCount .. " → " .. realCount)
        takenCount = realCount
        updateStats()
        
        -- Если корзина полна - прерываем сбор
        if takenCount >= SETTINGS.MAX_TOTAL then
            log("🎯 Корзина полна после синхронизации!")
            return true -- Возвращаем true если нужно идти к оплате
        end
    end
    
    return false
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
-- СОРТИРОВКА ПО БЛИЗОСТИ
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
end

-- ============================================
-- ДВИЖЕНИЕ КАЖДЫЕ 2 СЕКУНДЫ
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
-- ✅ ИСПРАВЛЕННАЯ ХОДЬБА (С ОТСТУПОМ ОТ ПРЕДМЕТА)
-- ============================================

local function walkTo(targetPos, offsetDistance)
    if not targetPos or not humanoid or not rootPart then
        log("❌ walkTo: ошибка параметров")
        return false
    end
    
    -- ✅ ОТСТУП от цели (не идти прямо в предмет!)
    offsetDistance = offsetDistance or SETTINGS.ITEM_OFFSET
    
    local startPos = rootPart.Position
    local direction = (targetPos - startPos)
    if direction.Magnitude > 0 then
        direction = direction.Unit
    else
        direction = Vector3.new(1, 0, 0)
    end
    
    -- Цель с отступом (останавливаемся ДО предмета)
    local actualTarget = targetPos - (direction * offsetDistance)
    
    local totalDistance = getDistance(startPos, actualTarget)
    log("🚶 Иду: " .. math.floor(totalDistance) .. " студий (отступ " .. offsetDistance .. ")")
    
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
        path:ComputeAsync(startPos, actualTarget)
    end)
    
    if not success then
        log("⚠️  Ошибка пути")
        humanoid:MoveTo(actualTarget)
        local reached = humanoid.MoveToFinished:Wait(SETTINGS.MOVE_TIMEOUT)
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        return reached
    end
    
    if path.Status ~= Enum.PathStatus.Success then
        log("⚠️  Путь не найден")
        humanoid:MoveTo(actualTarget)
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
            
            if currentTime - lastCheckTime >= SETTINGS.STUCK_CHECK_INTERVAL then
                local moved = getDistance(currentPos, lastPosition)
                
                if moved < SETTINGS.STUCK_DISTANCE then
                    totalStuckTime = totalStuckTime + SETTINGS.STUCK_CHECK_INTERVAL
                    
                    if totalStuckTime >= SETTINGS.STUCK_TIME then
                        log("   🦘 Прыжок от застревания...")
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.5)
                        totalStuckTime = 0
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
    
    local finalDist = getDistance(rootPart.Position, actualTarget)
    log("📍 Финальное расстояние: " .. math.floor(finalDist))
    
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
    
    log("🔘 Активирую prompt")
    
    -- Проверяем расстояние
    local promptPos = findPosition(prompt)
    if promptPos then
        local dist = getDistance(rootPart.Position, promptPos)
        log("   Расстояние: " .. math.floor(dist))
        
        if dist > SETTINGS.MAX_PROMPT_DISTANCE then
            log("   ⚠️  Далеко! Подхожу...")
            walkTo(promptPos, SETTINGS.ITEM_OFFSET)
            task.wait(0.5)
        end
        
        dist = getDistance(rootPart.Position, promptPos)
        if dist > SETTINGS.MAX_PROMPT_DISTANCE then
            log("   ❌ Всё ещё далеко")
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
        log("   ❌ Ошибка")
        return false
    end
end

-- ============================================
-- ПОВТОРНЫЕ ПОПЫТКИ ВЗЯТИЯ
-- ============================================

local function tryTakeItem(item)
    log("🎯 Пробую взять: " .. item.name)
    
    if item.unavailable then
        log("   ⏭️  Недоступен, пропускаю")
        return false
    end
    
    if not item.obj or not item.obj.Parent then
        item.unavailable = true
        return false
    end
    
    for attempt = 1, SETTINGS.MAX_RETRIES do
        if not running then return false end
        
        if attempt > 1 then
            log("   🔄 Попытка #" .. attempt)
            task.wait(SETTINGS.RETRY_DELAY)
            
            if not item.obj or not item.obj.Parent then
                item.unavailable = true
                return false
            end
        end
        
        local activated = activatePrompt(item.obj)
        
        if activated then
            log("   ✅ Успех!")
            item.failedAttempts = 0
            
            -- 🛒 Синхронизируем корзину после взятия
            task.wait(0.5) -- Даём время GUI обновиться
            syncCart()
            
            return true
        end
    end
    
    log("   ❌ Все попытки неудачны")
    item.failedAttempts = item.failedAttempts + 1
    
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then
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
    
    log("   ❌ Не удалось")
    return false
end

-- ============================================
-- ФУНКЦИЯ ОПЛАТЫ
-- ============================================

local function goToPay()
    if takenCount == 0 then
        log("❌ Корзина пуста")
        addLog("❌ Пусто")
        return
    end
    
    -- 🛒 Финальная синхронизация перед оплатой
    syncCart()
    
    if takenCount == 0 then
        log("❌ После синхронизации корзина пуста")
        return
    end
    
    if not seller then
        log("❌ Продавец не найден!")
        return
    end
    
    log("\n💰 КОРЗИНА ПОЛНА (" .. takenCount .. ") → ОПЛАТА!")
    addLog("💰 Иду к продавцу...")
    statusLabel.Text = "💰 Иду к продавцу..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    if seller.position then
        walkTo(seller.position, SETTINGS.ITEM_OFFSET)
        task.wait(0.5)
    end
    
    log("💬 Разговор...")
    activatePrompt(seller.obj)
    task.wait(1)
    
    log("💳 Оплата...")
    local paid = pay()
    
    if paid then
        paidCount = paidCount + 1
        takenCount = 0 -- Обнуляем корзину после оплаты
        addLog("✅ Оплачено! (" .. paidCount .. ")")
        updateStats()
        task.wait(1)
    else
        addLog("⚠️  Ошибка оплаты")
    end
end

-- ============================================
-- GUI (сокращённая версия для экономии места)
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v7_6"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 650, 0, 750)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 55)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -45, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "👕 Автопокупка v7.6 | Синхронизация"
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

-- Перетаскивание
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

local function updateDrag(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput then updateDrag(input) end
end)

-- GUI элементы
local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, -20, 0, 40)
filterBox.Position = UDim2.new(0, 10, 0, 60)
filterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
filterBox.TextColor3 = Color3.new(1, 1, 1)
filterBox.PlaceholderText = "🔍 Фильтр..."
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
startBtn.Text = "▶️ ЗАПУСТИТЬ"
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
function addLog(msg)
    table.insert(logText, msg)
    if #logText > 6 then table.remove(logText, 1) end
    logLabel.Text = "📋 Лог:\n" .. table.concat(logText, "\n")
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -370)
scrollFrame.Position = UDim2.new(0, 10, 0, 360)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

function updateStats()
    takenLabel.Text = "🛒 Взято: " .. takenCount .. " / " .. SETTINGS.MAX_TOTAL
    paidLabel.Text = "💳 Оплачено: " .. paidCount
end

function updateList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local filter = filterBox.Text:lower()
    
    for i, item in ipairs(clothes) do
        local match = filter == "" or item.name:lower():find(filter) or item.shop:lower():find(filter)
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
            
            local limitText = (shopLimits[item.shop] or 0) >= SETTINGS.MAX_PER_SHOP and " [🔒]" or ""
            local unavailText = item.unavailable and " [❌]" or ""
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -10, 0, 24)
            nameLabel.Position = UDim2.new(0, 10, 0, 3)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = (item.taken and "✅ " or "📦 ") .. item.name .. unavailText
            nameLabel.TextColor3 = item.taken and Color3.fromRGB(100, 255, 100) or (item.unavailable and Color3.fromRGB(255, 100, 100) or Color3.new(1, 1, 1))
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

function resetAll()
    for _, item in ipairs(clothes) do
        item.taken = false
        item.unavailable = false
        item.failedAttempts = 0
    end
    shopLimits = {}
    takenCount = 0
    lastTakeTime = 0
    lastMoveTime = tick()
    addLog("🔄 Сброс")
    updateList()
    
    -- 🛒 Синхронизация после сброса
    syncCart()
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

local function mainLoop()
    log("\n🎬 ЗАПУСК ЦИКЛА!")
    
    while running do
        resetAll()
        sortByDistance()
        updateList()
        
        addLog("🔄 Новый цикл!")
        statusLabel.Text = "🔄 Начинаю..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        local shouldPay = false
        local itemsChecked = 0
        
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken or item.unavailable then continue end
            
            -- ✅ СИНХРОНИЗАЦИЯ: проверяем корзину ПЕРЕД каждой вещью
            if syncCart() then
                shouldPay = true
                break
            end
            
            if takenCount >= SETTINGS.MAX_TOTAL then
                log("\n🎯 ЛИМИТ ДОСТИГНУТ!")
                shouldPay = true
                break
            end
            
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then continue end
            
            itemsChecked = itemsChecked + 1
            
            -- Если проверили много предметов и не смогли взять - идём к кассе
            if itemsChecked > 10 and takenCount > 0 then
                log("🎯 Проверено много предметов, иду к кассе...")
                shouldPay = true
                break
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
            
            addLog("🚶 " .. item.name)
            statusLabel.Text = "🚶 " .. item.name
            
            if item.position then
                walkTo(item.position, SETTINGS.ITEM_OFFSET)
                task.wait(0.5)
            end
            
            addLog("🤖 Беру...")
            statusLabel.Text = "🤖 Беру " .. item.name
            
            local success = tryTakeItem(item)
            
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                
                addLog("✅ " .. item.name .. " (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                updateStats()
                updateList()
                
                -- ✅ ПРОВЕРКА: если лимит достигнут - идём к кассе
                if takenCount >= SETTINGS.MAX_TOTAL then
                    log("\n🎯 ЛИМИТ ДОСТИГНУТ! Иду к кассе...")
                    shouldPay = true
                    break
                end
            else
                addLog("❌ " .. item.name)
            end
            
            task.wait(0.5)
        end
        
        -- ✅ ВАЖНО: если взяли хотя бы что-то и не можем больше - идём к кассе
        if not shouldPay and takenCount > 0 then
            log("🎯 Ничего больше не могу взять, иду к кассе...")
            shouldPay = true
        end
        
        if shouldPay or takenCount > 0 then
            goToPay()
            sortByDistance()
            updateList()
        else
            addLog("❌ Пусто")
        end
        
        addLog("⏳ Жду 10 мин...")
        statusLabel.Text = "⏳ Ожидание..."
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        
        for i = 1, SETTINGS.REFRESH_TIME do
            if not running then break end
            if i % 2 == 0 then doQuickMove() end
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
        startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
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
sortByDistance()
updateStats()
updateList()

-- Ищем GUI корзины при запуске
cartGUI = findCartGUI()
if cartGUI then
    log("🛒 GUI корзины найден: " .. cartGUI.Name)
else
    log("⚠️  GUI корзины не найден, синхронизация может не работать")
end

print("\n" .. string.rep("=", 60))
print("✅ Скрипт v7.6 загружен!")
print("🛒 Синхронизация корзины: " .. (SETTINGS.SYNC_CART_ENABLED and "ВКЛ" or "ВЫКЛ"))
print("📊 Магазинов: " .. #shopZones .. " | Вещей: " .. #clothes)
print("🎯 Отступ от предмета: " .. SETTINGS.ITEM_OFFSET .. " студий")
print(string.rep("=", 60) .. "\n")
