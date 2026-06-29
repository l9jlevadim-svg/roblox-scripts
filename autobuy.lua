-- 👕 АВТОПОКУПКА v8.3 - ФИЛЬТРЫ ПО ЦЕНЕ И РЕДКОСТИ + ИСПРАВЛЕННАЯ ОПЛАТА
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
print("👕 АВТОПОКУПКА v8.3 - ФИЛЬТРЫ + ОПЛАТА")
print(string.rep("=", 60) .. "\n")

-- ============================================
-- НАСТРОЙКИ
-- ============================================
local SETTINGS = {
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
    DELAY_ITEMS = 2,
    REFRESH_TIME = 600,
    WALK_SPEED = 18,
    JUMP_POWER = 50,
    MOVE_INTERVAL = 2,
    MAX_RETRIES = 3,
    RETRY_DELAY = 1,
    MAX_FAILED_ATTEMPTS = 2,
    STOP_DISTANCE = 4,
    PROMPT_RANGE = 10,
    PATH_RADIUS = 2,
    PATH_HEIGHT = 5,
    CART_CHECK_DELAY = 0.5,
    -- Фильтры
    MAX_PRICE = 999999,  -- Максимальная цена (0 = без лимита)
    RARITY_FILTER = {    -- Фильтр по редкости (true = покупать)
        common = true,      -- Обычная (серая)
        uncommon = true,    -- Необычная (зеленая)
        rare = true,        -- Редкая (синяя)
        epic = true,        -- Эпическая (фиолетовая)
        legendary = true    -- Легендарная (желтая)
    }
}

-- Цвета редкостей
local RARITY_COLORS = {
    common = Color3.fromRGB(150, 150, 150),    -- Серый
    uncommon = Color3.fromRGB(50, 200, 50),    -- Зеленый
    rare = Color3.fromRGB(50, 100, 255),       -- Синий
    epic = Color3.fromRGB(180, 50, 255),       -- Фиолетовый
    legendary = Color3.fromRGB(255, 200, 50)   -- Желтый
}

local RARITY_NAMES = {
    common = "Обычная",
    uncommon = "Необычная",
    rare = "Редкая",
    epic = "Эпическая",
    legendary = "Легендарная"
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
--  ОПРЕДЕЛЕНИЕ РЕДКОСТИ
-- ============================================

local function detectRarity(item)
    -- Метод 1: Ищем текст с названием редкости в BillboardGui
    if item.parent then
        local searchObj = item.parent
        for i = 1, 5 do
            if searchObj then
                for _, child in ipairs(searchObj:GetChildren()) do
                    if child:IsA("BillboardGui") then
                        for _, gui in ipairs(child:GetChildren()) do
                            if gui:IsA("TextLabel") then
                                local text = gui.Text:lower()
                                local color = gui.TextColor3
                                
                                -- Проверяем по тексту
                                if text:find("обычн") or text:find("common") then
                                    return "common"
                                elseif text:find("необычн") or text:find("uncommon") then
                                    return "uncommon"
                                elseif text:find("редк") or text:find("rare") then
                                    return "rare"
                                elseif text:find("эпич") or text:find("epic") then
                                    return "epic"
                                elseif text:find("легенд") or text:find("legendary") then
                                    return "legendary"
                                end
                                
                                -- Проверяем по цвету текста
                                if color then
                                    for rarity, rarityColor in pairs(RARITY_COLORS) do
                                        if math.abs(color.R - rarityColor.R) < 0.1 and
                                           math.abs(color.G - rarityColor.G) < 0.1 and
                                           math.abs(color.B - rarityColor.B) < 0.1 then
                                            return rarity
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                searchObj = searchObj.Parent
            end
        end
    end
    
    -- Метод 2: Проверяем цвет самого предмета
    if item.parent and item.parent:IsA("BasePart") then
        local partColor = item.parent.Color or item.parent.BrickColor and item.parent.BrickColor.Color
        if partColor then
            for rarity, rarityColor in pairs(RARITY_COLORS) do
                if math.abs(partColor.R - rarityColor.R) < 0.15 and
                   math.abs(partColor.G - rarityColor.G) < 0.15 and
                   math.abs(partColor.B - rarityColor.B) < 0.15 then
                    return rarity
                end
            end
        end
    end
    
    -- По умолчанию - обычная
    return "common"
end

-- ============================================
-- 💰 ОПРЕДЕЛЕНИЕ ЦЕНЫ
-- ============================================

local function detectPrice(item)
    if item.priceText then
        -- Ищем число в тексте цены (например "$100", "100$", "100")
        local price = item.priceText:match("(%d+)")
        if price then
            return tonumber(price)
        end
    end
    return 0
end

-- ============================================
-- 🎯 ФИЛЬТРАЦИЯ ПРЕДМЕТОВ
-- ============================================

local function filterItems()
    local filtered = {}
    local skippedByRarity = 0
    local skippedByPrice = 0
    
    for _, item in ipairs(clothes) do
        -- Определяем редкость и цену
        item.rarity = detectRarity(item)
        item.price = detectPrice(item)
        
        -- Проверяем фильтр по редкости
        if not SETTINGS.RARITY_FILTER[item.rarity] then
            skippedByRarity = skippedByRarity + 1
            continue
        end
        
        -- Проверяем фильтр по цене
        if SETTINGS.MAX_PRICE > 0 and item.price > SETTINGS.MAX_PRICE then
            skippedByPrice = skippedByPrice + 1
            continue
        end
        
        table.insert(filtered, item)
    end
    
    log("🎯 Фильтрация:")
    log("   Всего предметов: " .. #clothes)
    log("   Пропущено по редкости: " .. skippedByRarity)
    log("   Пропущено по цене: " .. skippedByPrice)
    log("   Осталось: " .. #filtered)
    
    return filtered
end

-- ============================================
-- СИНХРОНИЗАЦИЯ КОРЗИНЫ
-- ============================================

local function getRealCartCount()
    if not player:FindFirstChild("PlayerGui") then return nil end
    
    local playerGui = player.PlayerGui
    
    for _, gui in ipairs(playerGui:GetChildren()) do
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local text = child.Text or ""
                local name = (child.Name or ""):lower()
                if name:find("cart") or name:find("item") or name:find("count") or name:find("total") then
                    local number = text:match("(%d+)")
                    if number then
                        local count = tonumber(number)
                        if count and count >= 0 and count <= 100 then
                            return count
                        end
                    end
                end
            end
        end
    end
    
    return nil
end

local function syncCart()
    local realCount = getRealCartCount()
    
    if realCount ~= nil then
        if realCount ~= takenCount then
            log("🔄 Синхронизация: скрипт=" .. takenCount .. " | реальная=" .. realCount)
            takenCount = realCount
        end
        return realCount
    end
    
    return takenCount
end

-- ============================================
-- ХОДЬБА
-- ============================================

local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then
        return false
    end
    
    local startPos = rootPart.Position
    local totalDistance = getDistance(startPos, targetPos)
    
    log("🚶 Иду: " .. math.floor(totalDistance) .. " студий")
    
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER
    
    local direction = (targetPos - startPos)
    if direction.Magnitude > 0 then
        direction = direction.Unit
    else
        direction = Vector3.new(0, 0, 1)
    end
    
    local walkTarget
    if totalDistance > SETTINGS.STOP_DISTANCE then
        walkTarget = targetPos - (direction * SETTINGS.STOP_DISTANCE)
    else
        walkTarget = targetPos
    end
    
    local path = PathfindingService:CreatePath({
        AgentRadius = SETTINGS.PATH_RADIUS,
        AgentHeight = SETTINGS.PATH_HEIGHT,
        AgentCanJump = true,
        AgentCanClimb = true
    })
    
    local success = pcall(function()
        path:ComputeAsync(startPos, walkTarget)
    end)
    
    if not success or path.Status ~= Enum.PathStatus.Success then
        log("   ⚠️ Путь не найден, иду напрямик...")
        humanoid:MoveTo(walkTarget)
        humanoid.MoveToFinished:Wait(15)
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        return true
    end
    
    local waypoints = path:GetWaypoints()
    log("   ✅ Путь: " .. #waypoints .. " точек")
    
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
        local lastPos = rootPart.Position
        local stuckTime = 0
        
        while tick() - startTime < 15 do
            if not running then
                humanoid.WalkSpeed = originalWalkSpeed
                humanoid.JumpPower = originalJumpPower
                return false
            end
            
            local currentPos = rootPart.Position
            local dist = getDistance(currentPos, waypoint.Position)
            local moved = getDistance(currentPos, lastPos)
            
            if moved < 0.5 then
                stuckTime = stuckTime + 0.1
                if stuckTime >= 3 then
                    log("   ⚠️ Застрял! Прыгаю...")
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.5)
                    stuckTime = 0
                end
            else
                stuckTime = 0
            end
            
            lastPos = currentPos
            
            if dist < 3 then break end
            
            task.wait(0.1)
        end
        
        task.wait(0.1)
    end
    
    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    
    return true
end

-- ============================================
-- СОРТИРОВКА
-- ============================================

local function sortByDistance()
    if not rootPart then return end
    
    local currentPos = rootPart.Position
    
    table.sort(clothes, function(a, b)
        local distA = a.position and getDistance(currentPos, a.position) or math.huge
        local distB = b.position and getDistance(currentPos, b.position) or math.huge
        return distA < distB
    end)
end

-- ============================================
-- ДВИЖЕНИЕ ТЕЛОМ
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
-- ПОИСК
-- ============================================

local function findShops()
    log("🔍 Поиск магазинов...")
    shopZones = {}
    
    local patterns = {"Shop_ShopZone", "ShopZone", "Shop_", "ClothingShop", "Store"}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            for _, pattern in ipairs(patterns) do
                if obj.Name:find(pattern) then
                    shopZones[obj.Name] = true
                    break
                end
            end
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
            
            local inShop = false
            for shopName, _ in pairs(shopZones) do
                if path:find(shopName) then
                    inShop = true
                    break
                end
            end
            
            if not inShop then
                if path:find("Shop") or path:find("Store") or path:find("Clothing") then
                    inShop = true
                end
            end
            
            if inShop and (action:find("Взять") or action:find("Take")) then
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
-- ✅ АКТИВАЦИЯ (УПРОЩЁННАЯ - ВСЕГДА СЧИТАЕТ УСПЕХОМ)
-- ============================================

local function activatePrompt(prompt)
    if not prompt then 
        log("   ❌ prompt = nil")
        return false 
    end
    
    log("   🔘 Активирую prompt...")
    
    -- Метод 1: fireproximityprompt
    if fireproximityprompt then
        local ok = pcall(function() 
            fireproximityprompt(prompt) 
        end)
        if ok then 
            log("   ✅ fireproximityprompt сработал")
            return true  -- ✅ ВСЕГДА считаем успехом
        end
        log("   ️ fireproximityprompt не сработал")
    end
    
    -- Метод 2: InputHold
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(1.5)
        prompt:InputHoldEnd()
    end)
    
    if ok then
        log("   ✅ InputHold сработал")
        return true  -- ✅ ВСЕГДА считаем успехом
    end
    
    log("   ❌ Оба метода не сработали")
    return false
end

-- ============================================
-- ПРОВЕРКА С ПОВТОРНЫМИ ПОПЫТКАМИ
-- ============================================

local function tryTakeItem(item)
    log("🎯 Пробую взять: " .. item.name .. " [" .. RARITY_NAMES[item.rarity] .. "] $" .. item.price)
    
    if item.unavailable then return false end
    
    if not item.obj or not item.obj.Parent then
        log("   ❌ Prompt исчез")
        item.unavailable = true
        return false
    end
    
    for attempt = 1, SETTINGS.MAX_RETRIES do
        if not running then return false end
        
        if attempt > 1 then
            log("   🔄 Попытка #" .. attempt .. " (жду " .. SETTINGS.RETRY_DELAY .. "с)...")
            task.wait(SETTINGS.RETRY_DELAY)
            
            if not item.obj or not item.obj.Parent then
                log("   ❌ Prompt исчез")
                item.unavailable = true
                return false
            end
        end
        
        local activated = activatePrompt(item.obj)
        
        if activated then
            log("   ✅ Взял с попытки #" .. attempt .. "!")
            item.failedAttempts = 0
            return true
        end
        
        log("   ❌ Попытка #" .. attempt .. " не удалась")
    end
    
    log("   ❌ Все попытки неудачны")
    item.failedAttempts = item.failedAttempts + 1
    
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then
        item.unavailable = true
    end
    
    return false
end

-- ============================================
-- 💰 ОПЛАТА (ВСЕГДА ПЫТАЕТСЯ ОПЛАТИТЬ)
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
        if ok then 
            log("   ✅ RemoteEvent")
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
                    log("   ✅ GUI")
                    return true 
                end
            end
        end
    end
    
    log("   ❌ Не удалось")
    return false
end

-- ============================================
-- GUI С ФИЛЬТРАМИ
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v8_3"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 700, 0, 800)
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
titleLabel.Text = "👕 Автопокупка v8.3 | Фильтры"
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
closeBtn.MouseButton1Click:Connect(function() running = false screenGui:Destroy() end)

-- ДВИГАЕМОЕ ОКНО
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput then
        updateDrag(input)
    end
end)

-- ФИЛЬТРЫ
local filterFrame = Instance.new("Frame")
filterFrame.Size = UDim2.new(1, -20, 0, 120)
filterFrame.Position = UDim2.new(0, 10, 0, 60)
filterFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
filterFrame.Parent = frame
Instance.new("UICorner", filterFrame).CornerRadius = UDim.new(0, 8)

local filterTitle = Instance.new("TextLabel")
filterTitle.Size = UDim2.new(1, -10, 0, 20)
filterTitle.Position = UDim2.new(0, 5, 0, 0)
filterTitle.BackgroundTransparency = 1
filterTitle.Text = "🎯 ФИЛЬТРЫ ПОКУПКИ"
filterTitle.TextColor3 = Color3.new(1, 1, 1)
filterTitle.Font = Enum.Font.GothamBold
filterTitle.TextSize = 12
filterTitle.TextXAlignment = Enum.TextXAlignment.Left
filterTitle.Parent = filterFrame

-- Чекбоксы редкостей
local rarityCheckboxes = {}
local rarityY = 25

for rarity, name in pairs(RARITY_NAMES) do
    local checkbox = Instance.new("TextButton")
    checkbox.Size = UDim2.new(0.2, -5, 0, 20)
    checkbox.Position = UDim2.new((rarityY - 25) / 95, 5, 0, rarityY)
    checkbox.BackgroundColor3 = SETTINGS.RARITY_FILTER[rarity] and RARITY_COLORS[rarity] or Color3.fromRGB(50, 50, 50)
    checkbox.Text = name
    checkbox.TextColor3 = Color3.new(1, 1, 1)
    checkbox.Font = Enum.Font.GothamBold
    checkbox.TextSize = 10
    checkbox.Parent = filterFrame
    Instance.new("UICorner", checkbox).CornerRadius = UDim.new(0, 4)
    
    checkbox.MouseButton1Click:Connect(function()
        SETTINGS.RARITY_FILTER[rarity] = not SETTINGS.RARITY_FILTER[rarity]
        checkbox.BackgroundColor3 = SETTINGS.RARITY_FILTER[rarity] and RARITY_COLORS[rarity] or Color3.fromRGB(50, 50, 50)
        log(" Фильтр редкости " .. name .. ": " .. tostring(SETTINGS.RARITY_FILTER[rarity]))
    end)
    
    rarityCheckboxes[rarity] = checkbox
    rarityY = rarityY + 22
end

-- Поле максимальной цены
local priceLabel = Instance.new("TextLabel")
priceLabel.Size = UDim2.new(0.3, 0, 0, 20)
priceLabel.Position = UDim2.new(0, 5, 0, 95)
priceLabel.BackgroundTransparency = 1
priceLabel.Text = "💰 Макс. цена:"
priceLabel.TextColor3 = Color3.new(1, 1, 1)
priceLabel.Font = Enum.Font.GothamBold
priceLabel.TextSize = 11
priceLabel.TextXAlignment = Enum.TextXAlignment.Left
priceLabel.Parent = filterFrame

local priceInput = Instance.new("TextBox")
priceInput.Size = UDim2.new(0.3, 0, 0, 20)
priceInput.Position = UDim2.new(0.3, 5, 0, 95)
priceInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
priceInput.TextColor3 = Color3.new(1, 1, 1)
priceInput.Text = tostring(SETTINGS.MAX_PRICE)
priceInput.Font = Enum.Font.Gotham
priceInput.TextSize = 11
priceInput.Parent = filterFrame
Instance.new("UICorner", priceInput).CornerRadius = UDim.new(0, 4)

priceInput.FocusLost:Connect(function()
    local newPrice = tonumber(priceInput.Text)
    if newPrice and newPrice >= 0 then
        SETTINGS.MAX_PRICE = newPrice
        log("💰 Максимальная цена: " .. newPrice)
    end
end)

-- Статистика
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -20, 0, 60)
statsFrame.Position = UDim2.new(0, 10, 0, 185)
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
startBtn.Position = UDim2.new(0, 10, 0, 250)
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 310)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🟢 Готов"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 90)
logLabel.Position = UDim2.new(0, 10, 0, 345)
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
    logLabel.Text = " Лог:\n" .. table.concat(logText, "\n")
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -450)
scrollFrame.Position = UDim2.new(0, 10, 0, 440)
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
    
    local filtered = filterItems()
    
    for i, item in ipairs(filtered) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -10, 0, 60)
        itemFrame.BackgroundColor3 = item.taken and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(35, 35, 35)
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)
        
        -- Цветная полоска редкости
        local rarityBar = Instance.new("Frame")
        rarityBar.Size = UDim2.new(0, 4, 1, 0)
        rarityBar.Position = UDim2.new(0, 0, 0, 0)
        rarityBar.BackgroundColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150)
        rarityBar.Parent = itemFrame
        Instance.new("UICorner", rarityBar).CornerRadius = UDim.new(0, 8)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -15, 0, 20)
        nameLabel.Position = UDim2.new(0, 10, 0, 3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = (item.taken and "✅ " or "📦 ") .. item.name
        nameLabel.TextColor3 = item.taken and Color3.fromRGB(100, 255, 100) or Color3.new(1, 1, 1)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -15, 0, 18)
        infoLabel.Position = UDim2.new(0, 10, 0, 23)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = item.shop .. " | " .. item.floor .. " | $" .. item.price
        infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 10
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = itemFrame
        
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, -15, 0, 18)
        rarityLabel.Position = UDim2.new(0, 10, 0, 41)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = RARITY_NAMES[item.rarity] or "Неизвестно"
        rarityLabel.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150)
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.TextSize = 10
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
        rarityLabel.Parent = itemFrame
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

local function resetAll()
    for _, item in ipairs(clothes) do item.taken = false; item.unavailable = false; item.failedAttempts = 0 end
    shopLimits = {}; takenCount = 0; lastTakeTime = 0; lastMoveTime = tick()
    addLog("🔄 Сброс счетчиков")
    updateList()
end

-- ============================================
-- 💰 ОПЛАТА (ВСЕГДА ПЫТАЕТСЯ)
-- ============================================

local function goToPay()
    log("\n💰 === НАЧИНАЮ ОПЛАТУ ===")
    addLog("💰 Иду к продавцу...")
    statusLabel.Text = "💰 Оплата..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    if not seller then
        log("❌ Продавец не найден!")
        addLog("❌ Нет продавца")
        return
    end
    
    log("🛒 Взято: " .. takenCount .. " товаров")
    
    if seller.position then
        log("🚶 Иду к продавцу...")
        walkTo(seller.position)
        task.wait(1)
    end
    
    log("💬 Разговор...")
    addLog("💬 Говорю...")
    statusLabel.Text = "💬 Разговор..."
    
    activatePrompt(seller.obj)
    task.wait(2)
    
    log("💳 Оплата...")
    addLog("💳 Оплачиваю...")
    statusLabel.Text = "💳 Оплата..."
    
    local paid = pay()
    
    if paid then
        paidCount = paidCount + 1
        takenCount = 0
        log("✅ ОПЛАТА УСПЕШНА! (" .. paidCount .. ")")
        addLog("✅ Оплачено! (" .. paidCount .. ")")
        updateStats()
        task.wait(2)
    else
        log("⚠️  Пробую ещё раз...")
        task.wait(1)
        paid = pay()
        if paid then
            paidCount = paidCount + 1
            takenCount = 0
            log("✅ ОПЛАТА УСПЕШНА со 2-й попытки!")
            addLog("✅ Оплачено! (" .. paidCount .. ")")
            updateStats()
        else
            log("❌ ОПЛАТА ПРОВАЛЕНА!")
            addLog("❌ Оплата провалена!")
        end
    end
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

local function mainLoop()
    log("\n🎬 ЗАПУСК ЦИКЛА!")
    
    while running do
        resetAll()
        
        log("\n🎯 Фильтрация и сортировка...")
        addLog("🎯 Фильтрация...")
        sortByDistance()
        updateList()
        
        addLog("🔄 Новый цикл!")
        statusLabel.Text = "🔄 Начинаю..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        local shouldPay = false
        
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken then continue end
            if item.unavailable then continue end
            
            -- Проверяем фильтры
            item.rarity = detectRarity(item)
            item.price = detectPrice(item)
            
            if not SETTINGS.RARITY_FILTER[item.rarity] then continue end
            if SETTINGS.MAX_PRICE > 0 and item.price > SETTINGS.MAX_PRICE then continue end
            
            syncCart()
            
            if takenCount >= SETTINGS.MAX_TOTAL then
                log("\n🎯 КОРЗИНА ПОЛНА! (" .. takenCount .. ")")
                shouldPay = true
                break
            end
            
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then continue end
            
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
            
            log("\n🎯 Цель: " .. item.name .. " [" .. RARITY_NAMES[item.rarity] .. "] $" .. item.price)
            addLog("🚶 " .. item.name)
            statusLabel.Text = "🚶 " .. item.name
            
            if item.position then
                walkTo(item.position)
                task.wait(0.5)
            end
            
            addLog("🤖 Беру...")
            statusLabel.Text = " Беру " .. item.name
            
            local success = tryTakeItem(item)
            
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                
                log("✅ Взял! [" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. "]")
                addLog("✅ " .. item.name .. " (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                
                updateStats()
                updateList()
                syncCart()
                
                if takenCount >= SETTINGS.MAX_TOTAL then
                    log("\n🎯 ЛИМИТ! → ОПЛАТА!")
                    addLog(" Лимит! Иду платить...")
                    shouldPay = true
                    break
                end
            else
                addLog("❌ " .. item.name)
            end
            
            task.wait(0.5)
        end
        
        if shouldPay or takenCount > 0 then
            log("\n ПЕРЕХОД К ОПЛАТЕ! (взято: " .. takenCount .. ")")
            goToPay()
            
            if running then
                sortByDistance()
                updateList()
            end
        else
            addLog("❌ Пусто")
        end
        
        log("\n⏳ Ожидание (10 мин)...")
        addLog("⏳ Жду 10 мин...")
        statusLabel.Text = "⏳ Ожидание..."
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        
        for i = 1, SETTINGS.REFRESH_TIME do
            if not running then break end
            if i % 30 == 0 then
                local mins = math.floor((SETTINGS.REFRESH_TIME - i) / 60)
                local secs = (SETTINGS.REFRESH_TIME - i) % 60
                log("   Осталось: " .. mins .. "м " .. secs .. "с")
            end
            if i % 2 == 0 then doQuickMove() end
            task.wait(1)
        end
        
        log("🔄 Магазин обновился!\n")
    end
    
    running = false
    startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    addLog("⏹️ Остановлено")
end

startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
        startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    else
        running = true
        startBtn.Text = "⏹️ ОСТАНОВИТЬ"
        startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        sortByDistance()
        updateList()
        task.spawn(mainLoop)
    end
end)

findShops()
findClothes()
sortByDistance()
updateStats()
updateList()

print("\n" .. string.rep("=", 60))
print("✅ Скрипт v8.3 загружен!")
print(" ФИЛЬТРЫ ПО РЕДКОСТИ:")
print("   ✅ Обычная (серая)")
print("   ✅ Необычная (зеленая)")
print("   ✅ Редкая (синяя)")
print("   ✅ Эпическая (фиолетовая)")
print("   ✅ Легендарная (желтая)")
print("💰 ФИЛЬТР ПО ЦЕНЕ: $" .. SETTINGS.MAX_PRICE)
print(" 3 попытки взять предмет")
print("💰 Всегда пытается оплатить")
print(string.rep("=", 60) .. "\n")
