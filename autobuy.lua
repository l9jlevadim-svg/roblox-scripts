-- 👕 АВТОПОКУПКА v10.1 - НАДЁЖНАЯ ХОДЬБА БЕЗ PATHFINDING
-- GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/l9jlevadim-svg/roblox-scripts/main/autobuy.lua"))()
-- ✅ Надёжная ходьба | ✅ Все фильтры | ✅ Гарантированная оплата

-- ============================================
-- СЕРВИСЫ
-- ============================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

-- ============================================
-- ИГРОК
-- ============================================
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

print("\n" .. string.rep("=", 80))
print("👕 АВТОПОКУПКА v10.1 - НАДЁЖНАЯ ХОДЬБА")
print(string.rep("=", 80) .. "\n")

-- ============================================
-- НАСТРОЙКИ
-- ============================================
local SETTINGS = {
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
    DELAY_ITEMS = 2,
    REFRESH_TIME = 600,
    RETRY_DELAY = 1,
    CART_CHECK_DELAY = 0.5,
    MOVE_INTERVAL = 2,
    WALK_SPEED = 18,
    JUMP_POWER = 50,
    PROMPT_ACTIVATE_DISTANCE = 5,
    MAX_RETRIES = 3,
    MAX_FAILED_ATTEMPTS = 2,
    MIN_PRICE = 0,
    MAX_PRICE = 999999,
    RARITY_FILTER = {
        common = true,
        uncommon = true,
        rare = true,
        epic = true,
        legendary = true
    },
    NAME_FILTER = "",
    SHOP_FILTER = ""
}

-- ============================================
-- ЦВЕТА И НАЗВАНИЯ РЕДКОСТЕЙ
-- ============================================
local RARITY_COLORS = {
    common = Color3.fromRGB(150, 150, 150),
    uncommon = Color3.fromRGB(50, 200, 50),
    rare = Color3.fromRGB(50, 100, 255),
    epic = Color3.fromRGB(180, 50, 255),
    legendary = Color3.fromRGB(255, 200, 50)
}

local RARITY_NAMES = {
    common = "Обычная",
    uncommon = "Необычная",
    rare = "Редкая",
    epic = "Эпическая",
    legendary = "Легендарная"
}

local RARITY_KEYWORDS = {
    legendary = {"легенд", "legendary", "legend", "лег", "leg"},
    epic = {"эпич", "epic", "эп", "ep"},
    rare = {"редк", "rare", "ред", "r"},
    uncommon = {"необыч", "uncommon", "необы", "uc", "uncom"},
    common = {"обычн", "common", "обыч", "обы", "c", "com"}
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
local totalItemsBought = 0
local totalMoneySpent = 0
local cycleCount = 0

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
    print("[AutoBuy v10.1] " .. message)
end

local function formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- ============================================
-- ОПРЕДЕЛЕНИЕ РЕДКОСТИ
-- ============================================

local function detectRarity(item)
    if not item.parent then return "common" end
    
    if item.parent:GetAttribute("Rarity") then
        local attr = tostring(item.parent:GetAttribute("Rarity")):lower()
        for rarity, keywords in pairs(RARITY_KEYWORDS) do
            for _, kw in ipairs(keywords) do
                if attr:find(kw) then return rarity end
            end
        end
    end
    
    for _, child in ipairs(item.parent:GetDescendants()) do
        if child:IsA("StringValue") then
            local val = tostring(child.Value):lower()
            for rarity, keywords in pairs(RARITY_KEYWORDS) do
                for _, kw in ipairs(keywords) do
                    if val:find(kw) then return rarity end
                end
            end
        end
    end
    
    local searchObj = item.parent
    for i = 1, 5 do
        if searchObj then
            for _, child in ipairs(searchObj:GetChildren()) do
                if child:IsA("BillboardGui") then
                    for _, gui in ipairs(child:GetChildren()) do
                        if gui:IsA("TextLabel") then
                            local text = gui.Text:lower()
                            for rarity, keywords in pairs(RARITY_KEYWORDS) do
                                for _, kw in ipairs(keywords) do
                                    if text:find(kw) then return rarity end
                                end
                            end
                        end
                    end
                end
            end
            searchObj = searchObj.Parent
        end
    end
    
    local name = item.parent.Name:lower()
    for rarity, keywords in pairs(RARITY_KEYWORDS) do
        for _, kw in ipairs(keywords) do
            if name:find(kw) then return rarity end
        end
    end
    
    return "common"
end

-- ============================================
-- ОПРЕДЕЛЕНИЕ ЦЕНЫ
-- ============================================

local function detectPrice(item)
    if item.parent then
        local price = item.parent:GetAttribute("Price") or item.parent:GetAttribute("Cost")
        if price then return tonumber(price) or 0 end
    end
    
    if item.parent then
        for _, child in ipairs(item.parent:GetDescendants()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                local name = child.Name:lower()
                if name:find("price") or name:find("cost") then
                    return tonumber(child.Value) or 0
                end
            end
        end
    end
    
    if item.priceText then
        local numbers = {}
        for num in item.priceText:gmatch("(%d+)") do
            table.insert(numbers, tonumber(num))
        end
        if #numbers > 0 then
            local maxPrice = 0
            for _, num in ipairs(numbers) do
                if num > maxPrice then maxPrice = num end
            end
            return maxPrice
        end
    end
    
    return 0
end

-- ============================================
-- ФИЛЬТРАЦИЯ
-- ============================================

local function shouldBuyItem(item)
    if not item.rarity then item.rarity = detectRarity(item) end
    if not item.price then item.price = detectPrice(item) end
    
    if not SETTINGS.RARITY_FILTER[item.rarity] then return false end
    if item.price < SETTINGS.MIN_PRICE or item.price > SETTINGS.MAX_PRICE then return false end
    
    if SETTINGS.NAME_FILTER ~= "" then
        if not item.name:lower():find(SETTINGS.NAME_FILTER:lower()) then return false end
    end
    
    if SETTINGS.SHOP_FILTER ~= "" then
        if not item.shop:lower():find(SETTINGS.SHOP_FILTER:lower()) then return false end
    end
    
    return true
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
-- 🚶 НОВАЯ НАДЁЖНАЯ ХОДЬБА (БЕЗ PATHFINDING, С ОБХОДОМ ПРЕПЯТСТВИЙ)
-- ============================================
local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then
        log("❌ walkTo: ошибка параметров")
        return false
    end

    local startPos = rootPart.Position
    local totalDistance = getDistance(startPos, targetPos)
    log("🚶 Иду: " .. math.floor(totalDistance) .. " студий")

    -- Сохраняем оригинальные статы
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower

    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER

    -- Переменные для контроля застревания и обхода
    local lastPosition = rootPart.Position
    local stuckTime = 0
    local stuckCount = 0
    local maxWait = math.min(totalDistance * 0.5, 25)   -- адаптивный таймаут
    local startTime = tick()

    -- Параметры обхода препятствий (можешь подкрутить)
    local OBSTACLE_CHECK_DISTANCE = 4      -- дальность луча впереди
    local SIDE_STEP_ANGLE = 60             -- угол поворота при обходе (градусы)
    local MAX_DEVIATION_ANGLE = 45         -- максимальное отклонение от прямого направления к цели
    local DIRECTION_CHANGE_SPEED = 0.1     -- плавность поворота (0..1)

    -- Вспомогательная: проверка, свободен ли путь на distance студий вперёд от позиции pos с направлением lookVector
    local function isPathClear(pos, lookVector, distance)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {character}   -- игнорируем своего персонажа
        local rayResult = workspace:Raycast(pos, lookVector * distance, rayParams)
        return rayResult == nil
    end

    -- Начальное направление к цели
    local function getDirectionToTarget()
        return (targetPos - rootPart.Position).Unit
    end

    -- Основной цикл движения
    while tick() - startTime < maxWait do
        if not running then
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
            return false
        end

        local currentPos = rootPart.Position
        local distToTarget = getDistance(currentPos, targetPos)

        -- Если уже рядом (3 студии), завершаем
        if distToTarget <= 3 then
            log("   ✅ Дошел! Расстояние: " .. math.floor(distToTarget))
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
            return true
        end

        -- Проверка, движемся ли мы
        local moved = getDistance(currentPos, lastPosition)
        if moved < 0.3 then
            stuckTime = stuckTime + 0.1
            stuckCount = stuckCount + 1
        else
            stuckTime = 0
            stuckCount = 0
        end
        lastPosition = currentPos

        -- Обработка застревания
        if stuckTime >= 2 then
            if stuckTime < 2.5 then
                log("   ⚠️ Застрял! Прыгаю и смещаюсь...")
                -- Прыжок + движение в случайную сторону
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                local strafeDir = CFrame.Angles(0, math.rad(math.random(-90, 90)), 0) * rootPart.CFrame.LookVector
                humanoid:MoveTo(rootPart.Position + strafeDir * 3)
                task.wait(0.4)
            elseif stuckTime >= 4 then
                log("   🔄 Телепорт к цели...")
                rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
                task.wait(0.5)
                stuckTime = 0
                stuckCount = 0
            end
        end

        -- ===== ИНТЕЛЛЕКТУАЛЬНЫЙ ОБХОД ПРЕПЯТСТВИЙ =====
        local directionToTarget = getDirectionToTarget()
        local currentLook = rootPart.CFrame.LookVector
        local rayOrigin = rootPart.Position + Vector3.new(0, 1, 0)  -- чуть выше пола

        -- Проверяем луч вперёд по текущему направлению
        if not isPathClear(rayOrigin, currentLook, OBSTACLE_CHECK_DISTANCE) then
            -- Препятствие прямо перед нами! Нужно повернуть в сторону.
            -- Определим, поворачиваем влево или вправо (запоминаем предыдущий выбор, чтобы не метаться)
            local turnRight = (stuckCount % 2 == 0)  -- чередуем, чтобы обходить устойчивые препятствия
            local angle = turnRight and -SIDE_STEP_ANGLE or SIDE_STEP_ANGLE
            local newDirection = (CFrame.Angles(0, math.rad(angle), 0) * currentLook).Unit

            -- Но не отклоняемся слишком сильно от цели
            local deviation = math.acos(math.clamp(newDirection:Dot(directionToTarget), -1, 1))
            if math.deg(deviation) > MAX_DEVIATION_ANGLE then
                -- Если отклонение велико, идём напрямую к цели (риск застревания, но не теряем направление)
                newDirection = directionToTarget
            end

            -- Плавно поворачиваем персонажа в newDirection
            local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + newDirection)
            rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, DIRECTION_CHANGE_SPEED)
        else
            -- Путь свободен – движемся прямо к цели
            humanoid:MoveTo(targetPos)
        end

        task.wait(0.1)
    end

    -- Таймаут — последняя проверка
    local finalDist = getDistance(rootPart.Position, targetPos)
    log("   ⏰ Таймаут, расстояние: " .. math.floor(finalDist))
    if finalDist > 5 then
        log("   🔄 Финальный телепорт...")
        rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
        task.wait(0.5)
    end

    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    return true
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
-- ПОИСК МАГАЗИНОВ И ОДЕЖДЫ
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
                    failedAttempts = 0,
                    rarity = nil,
                    price = nil
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
    
    -- Определяем редкость и цену
    log("\n🎨 Определение редкости и цены...")
    for i, item in ipairs(clothes) do
        item.rarity = detectRarity(item)
        item.price = detectPrice(item)
        
        if i <= 10 then
            log("   " .. i .. ". " .. item.name .. " | " .. (RARITY_NAMES[item.rarity] or item.rarity) .. " | $" .. item.price)
        end
    end
end

-- ============================================
-- АКТИВАЦИЯ PROMPT
-- ============================================

local function activatePrompt(prompt)
    if not prompt then 
        log("   ❌ prompt = nil")
        return false 
    end
    
    log("   🔘 Активирую prompt...")
    
    -- Проверяем расстояние
    local promptPos = findPosition(prompt) or findPosition(prompt.Parent)
    if promptPos then
        local dist = getDistance(rootPart.Position, promptPos)
        log("   📍 Расстояние: " .. math.floor(dist) .. " студий")
        
        if dist > SETTINGS.PROMPT_ACTIVATE_DISTANCE then
            log("   🚶 Подхожу ближе...")
            walkTo(promptPos)
            task.wait(0.5)
        end
    end
    
    -- Метод 1: fireproximityprompt
    if fireproximityprompt then
        local ok = pcall(function() 
            fireproximityprompt(prompt) 
        end)
        if ok then 
            log("   ✅ fireproximityprompt")
            return true
        end
    end
    
    -- Метод 2: InputHold
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(1.5)
        prompt:InputHoldEnd()
    end)
    
    if ok then
        log("   ✅ InputHold")
        return true
    end
    
    log("   ❌ Не удалось")
    return false
end

-- ============================================
-- ПРОВЕРКА С ПОВТОРНЫМИ ПОПЫТКАМИ
-- ============================================

local function tryTakeItem(item)
    log("🎯 Беру: " .. item.name .. " [" .. (RARITY_NAMES[item.rarity] or item.rarity) .. "] $" .. item.price)
    
    if item.unavailable then return false end
    
    if not item.obj or not item.obj.Parent then
        log("   ❌ Prompt исчез")
        item.unavailable = true
        return false
    end
    
    for attempt = 1, SETTINGS.MAX_RETRIES do
        if not running then return false end
        
        if attempt > 1 then
            log("    Попытка #" .. attempt)
            task.wait(SETTINGS.RETRY_DELAY)
            
            if not item.obj or not item.obj.Parent then
                log("   ❌ Prompt исчез")
                item.unavailable = true
                return false
            end
        end
        
        local activated = activatePrompt(item.obj)
        
        if activated then
            log("   ✅ Взял!")
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
-- GUI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v10_1"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 750, 0, 850)
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
titleLabel.Text = " Автопокупка v10.1 | Надёжная ходьба"
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
filterFrame.Size = UDim2.new(1, -20, 0, 150)
filterFrame.Position = UDim2.new(0, 10, 0, 60)
filterFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
filterFrame.Parent = frame
Instance.new("UICorner", filterFrame).CornerRadius = UDim.new(0, 8)

local filterTitle = Instance.new("TextLabel")
filterTitle.Size = UDim2.new(1, -10, 0, 20)
filterTitle.Position = UDim2.new(0, 5, 0, 0)
filterTitle.BackgroundTransparency = 1
filterTitle.Text = " ФИЛЬТРЫ (зеленый = ВКЛ, серый = ВЫКЛ)"
filterTitle.TextColor3 = Color3.new(1, 1, 1)
filterTitle.Font = Enum.Font.GothamBold
filterTitle.TextSize = 12
filterTitle.TextXAlignment = Enum.TextXAlignment.Left
filterTitle.Parent = filterFrame

-- Кнопки редкостей
local rarityButtons = {}
local rarityOrder = {"common", "uncommon", "rare", "epic", "legendary"}

for idx, rarity in ipairs(rarityOrder) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.19, -5, 0, 30)
    btn.Position = UDim2.new((idx - 1) * 0.2, 5, 0, 25)
    btn.BackgroundColor3 = SETTINGS.RARITY_FILTER[rarity] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 80)
    btn.Text = (SETTINGS.RARITY_FILTER[rarity] and "✅ " or "❌ ") .. RARITY_NAMES[rarity]
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Parent = filterFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        SETTINGS.RARITY_FILTER[rarity] = not SETTINGS.RARITY_FILTER[rarity]
        btn.BackgroundColor3 = SETTINGS.RARITY_FILTER[rarity] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(80, 80, 80)
        btn.Text = (SETTINGS.RARITY_FILTER[rarity] and "✅ " or "❌ ") .. RARITY_NAMES[rarity]
        log(" Фильтр " .. RARITY_NAMES[rarity] .. ": " .. tostring(SETTINGS.RARITY_FILTER[rarity]))
        updateList()
    end)
    
    rarityButtons[rarity] = btn
end

-- Цена ОТ
local priceMinLabel = Instance.new("TextLabel")
priceMinLabel.Size = UDim2.new(0.15, 0, 0, 25)
priceMinLabel.Position = UDim2.new(0, 5, 0, 60)
priceMinLabel.BackgroundTransparency = 1
priceMinLabel.Text = "💰 От:"
priceMinLabel.TextColor3 = Color3.new(1, 1, 1)
priceMinLabel.Font = Enum.Font.GothamBold
priceMinLabel.TextSize = 11
priceMinLabel.TextXAlignment = Enum.TextXAlignment.Left
priceMinLabel.Parent = filterFrame

local priceMinInput = Instance.new("TextBox")
priceMinInput.Size = UDim2.new(0.15, 0, 0, 25)
priceMinInput.Position = UDim2.new(0.15, 5, 0, 60)
priceMinInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
priceMinInput.TextColor3 = Color3.new(1, 1, 1)
priceMinInput.Text = tostring(SETTINGS.MIN_PRICE)
priceMinInput.Font = Enum.Font.Gotham
priceMinInput.TextSize = 11
priceMinInput.Parent = filterFrame
Instance.new("UICorner", priceMinInput).CornerRadius = UDim.new(0, 4)

priceMinInput.FocusLost:Connect(function()
    local newPrice = tonumber(priceMinInput.Text)
    if newPrice and newPrice >= 0 then
        SETTINGS.MIN_PRICE = newPrice
        log("💰 Минимальная цена: $" .. newPrice)
        updateList()
    end
end)

-- Цена ДО
local priceMaxLabel = Instance.new("TextLabel")
priceMaxLabel.Size = UDim2.new(0.15, 0, 0, 25)
priceMaxLabel.Position = UDim2.new(0.35, 5, 0, 60)
priceMaxLabel.BackgroundTransparency = 1
priceMaxLabel.Text = "До:"
priceMaxLabel.TextColor3 = Color3.new(1, 1, 1)
priceMaxLabel.Font = Enum.Font.GothamBold
priceMaxLabel.TextSize = 11
priceMaxLabel.TextXAlignment = Enum.TextXAlignment.Left
priceMaxLabel.Parent = filterFrame

local priceMaxInput = Instance.new("TextBox")
priceMaxInput.Size = UDim2.new(0.15, 0, 0, 25)
priceMaxInput.Position = UDim2.new(0.5, 5, 0, 60)
priceMaxInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
priceMaxInput.TextColor3 = Color3.new(1, 1, 1)
priceMaxInput.Text = tostring(SETTINGS.MAX_PRICE)
priceMaxInput.Font = Enum.Font.Gotham
priceMaxInput.TextSize = 11
priceMaxInput.Parent = filterFrame
Instance.new("UICorner", priceMaxInput).CornerRadius = UDim.new(0, 4)

priceMaxInput.FocusLost:Connect(function()
    local newPrice = tonumber(priceMaxInput.Text)
    if newPrice and newPrice >= 0 then
        SETTINGS.MAX_PRICE = newPrice
        log("💰 Максимальная цена: $" .. newPrice)
        updateList()
    end
end)

-- Фильтр по названию
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.2, 0, 0, 25)
nameLabel.Position = UDim2.new(0, 5, 0, 90)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "🔍 Название:"
nameLabel.TextColor3 = Color3.new(1, 1, 1)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 11
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = filterFrame

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(0.3, 0, 0, 25)
nameInput.Position = UDim2.new(0.2, 5, 0, 90)
nameInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
nameInput.TextColor3 = Color3.new(1, 1, 1)
nameInput.Text = SETTINGS.NAME_FILTER
nameInput.PlaceholderText = "Пусто = все"
nameInput.Font = Enum.Font.Gotham
nameInput.TextSize = 11
nameInput.Parent = filterFrame
Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 4)

nameInput.FocusLost:Connect(function()
    SETTINGS.NAME_FILTER = nameInput.Text
    log(" Фильтр по названию: " .. (SETTINGS.NAME_FILTER ~= "" and SETTINGS.NAME_FILTER or "все"))
    updateList()
end)

-- Фильтр по магазину
local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(0.2, 0, 0, 25)
shopLabel.Position = UDim2.new(0.5, 5, 0, 90)
shopLabel.BackgroundTransparency = 1
shopLabel.Text = "🏪 Магазин:"
shopLabel.TextColor3 = Color3.new(1, 1, 1)
shopLabel.Font = Enum.Font.GothamBold
shopLabel.TextSize = 11
shopLabel.TextXAlignment = Enum.TextXAlignment.Left
shopLabel.Parent = filterFrame

local shopInput = Instance.new("TextBox")
shopInput.Size = UDim2.new(0.3, 0, 0, 25)
shopInput.Position = UDim2.new(0.7, 5, 0, 90)
shopInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
shopInput.TextColor3 = Color3.new(1, 1, 1)
shopInput.Text = SETTINGS.SHOP_FILTER
shopInput.PlaceholderText = "Пусто = все"
shopInput.Font = Enum.Font.Gotham
shopInput.TextSize = 11
shopInput.Parent = filterFrame
Instance.new("UICorner", shopInput).CornerRadius = UDim.new(0, 4)

shopInput.FocusLost:Connect(function()
    SETTINGS.SHOP_FILTER = shopInput.Text
    log("🏪 Фильтр по магазину: " .. (SETTINGS.SHOP_FILTER ~= "" and SETTINGS.SHOP_FILTER or "все"))
    updateList()
end)

-- Статистика фильтров
local filterStats = Instance.new("TextLabel")
filterStats.Size = UDim2.new(1, -10, 0, 20)
filterStats.Position = UDim2.new(0, 5, 0, 120)
filterStats.BackgroundTransparency = 1
filterStats.Text = "Всего: 0 | По фильтрам: 0"
filterStats.TextColor3 = Color3.fromRGB(200, 200, 200)
filterStats.Font = Enum.Font.Gotham
filterStats.TextSize = 10
filterStats.TextXAlignment = Enum.TextXAlignment.Left
filterStats.Parent = filterFrame

-- Статистика
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -20, 0, 80)
statsFrame.Position = UDim2.new(0, 10, 0, 215)
statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statsFrame.Parent = frame
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 8)

local takenLabel = Instance.new("TextLabel")
takenLabel.Size = UDim2.new(0.33, -5, 0.5, 0)
takenLabel.Position = UDim2.new(0, 5, 0, 0)
takenLabel.BackgroundTransparency = 1
takenLabel.Text = " Взято: 0/" .. SETTINGS.MAX_TOTAL
takenLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
takenLabel.Font = Enum.Font.GothamBold
takenLabel.TextSize = 12
takenLabel.TextXAlignment = Enum.TextXAlignment.Left
takenLabel.Parent = statsFrame

local paidLabel = Instance.new("TextLabel")
paidLabel.Size = UDim2.new(0.33, -5, 0.5, 0)
paidLabel.Position = UDim2.new(0.33, 5, 0, 0)
paidLabel.BackgroundTransparency = 1
paidLabel.Text = "💳 Оплачено: 0"
paidLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
paidLabel.Font = Enum.Font.GothamBold
paidLabel.TextSize = 12
paidLabel.TextXAlignment = Enum.TextXAlignment.Left
paidLabel.Parent = statsFrame

local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(0.33, -5, 0.5, 0)
totalLabel.Position = UDim2.new(0.66, 5, 0, 0)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = "📊 Циклов: 0"
totalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
totalLabel.Font = Enum.Font.GothamBold
totalLabel.TextSize = 12
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Parent = statsFrame

local itemsLabel = Instance.new("TextLabel")
itemsLabel.Size = UDim2.new(0.5, -5, 0.5, 0)
itemsLabel.Position = UDim2.new(0, 5, 0.5, 0)
itemsLabel.BackgroundTransparency = 1
itemsLabel.Text = "👕 Всего куплено: 0"
itemsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
itemsLabel.Font = Enum.Font.Gotham
itemsLabel.TextSize = 11
itemsLabel.TextXAlignment = Enum.TextXAlignment.Left
itemsLabel.Parent = statsFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.5, -5, 0.5, 0)
moneyLabel.Position = UDim2.new(0.5, 5, 0.5, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "💰 Потрачено: $0"
moneyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
moneyLabel.Font = Enum.Font.Gotham
moneyLabel.TextSize = 11
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = statsFrame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 55)
startBtn.Position = UDim2.new(0, 10, 0, 300)
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
startBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 360)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🟢 Готов"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 100)
logLabel.Position = UDim2.new(0, 10, 0, 395)
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
    if #logText > 7 then table.remove(logText, 1) end
    logLabel.Text = "📋 Лог:\n" .. table.concat(logText, "\n")
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -510)
scrollFrame.Position = UDim2.new(0, 10, 0, 500)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

local function updateStats()
    takenLabel.Text = "🛒 Взято: " .. takenCount .. "/" .. SETTINGS.MAX_TOTAL
    paidLabel.Text = "💳 Оплачено: " .. paidCount
    totalLabel.Text = "📊 Циклов: " .. cycleCount
    itemsLabel.Text = "👕 Всего куплено: " .. totalItemsBought
    moneyLabel.Text = "💰 Потрачено: $" .. formatNumber(totalMoneySpent)
end

local function getFilteredItems()
    local filtered = {}
    for _, item in ipairs(clothes) do
        if shouldBuyItem(item) and not item.taken and not item.unavailable then
            table.insert(filtered, item)
        end
    end
    return filtered
end

local function updateList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local filtered = getFilteredItems()
    
    filterStats.Text = "Всего: " .. #clothes .. " | По фильтрам: " .. #filtered
    
    for i, item in ipairs(filtered) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -10, 0, 65)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)
        
        local rarityBar = Instance.new("Frame")
        rarityBar.Size = UDim2.new(0, 4, 1, 0)
        rarityBar.BackgroundColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150)
        rarityBar.Parent = itemFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -15, 0, 20)
        nameLabel.Position = UDim2.new(0, 10, 0, 3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "📦 " .. item.name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
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
        rarityLabel.Text = RARITY_NAMES[item.rarity] or item.rarity
        rarityLabel.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150)
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.TextSize = 10
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
        rarityLabel.Parent = itemFrame
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
-- ОПЛАТА
-- ============================================

local function goToPay()
    log("\n💰 === НАЧИНАЮ ОПЛАТУ ===")
    addLog("💰 Иду к продавцу...")
    statusLabel.Text = "💰 Оплата..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    syncCart()
    
    if takenCount == 0 then
        log("❌ Корзина пуста!")
        addLog("❌ Пусто, не оплачиваю")
        return
    end
    
    if not seller then
        log("❌ Продавец не найден!")
        addLog("❌ Нет продавца")
        return
    end
    
    log("🛒 В корзине: " .. takenCount .. " товаров")
    
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
        totalItemsBought = totalItemsBought + takenCount
        cycleCount = cycleCount + 1
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
            totalItemsBought = totalItemsBought + takenCount
            cycleCount = cycleCount + 1
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
    log("\n ЗАПУСК ЦИКЛА!")
    
    while running do
        resetAll()
        
        log("\n🎯 Сортировка...")
        addLog("🎯 Сортировка...")
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
            
            if not shouldBuyItem(item) then
                continue
            end
            
            syncCart()
            
            if takenCount >= SETTINGS.MAX_TOTAL then
                log("\n КОРЗИНА ПОЛНА! (" .. takenCount .. ")")
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
            
            log("\n🎯 Цель: " .. item.name .. " [" .. (RARITY_NAMES[item.rarity] or item.rarity) .. "] $" .. item.price)
            addLog("🚶 " .. item.name)
            statusLabel.Text = "🚶 " .. item.name
            
            if item.position then
                walkTo(item.position)
                task.wait(0.5)
            end
            
            addLog(" Беру...")
            statusLabel.Text = "🤖 Беру " .. item.name
            
            local success = tryTakeItem(item)
            
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                totalMoneySpent = totalMoneySpent + item.price
                
                log("✅ Взял! [" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. "]")
                addLog("✅ " .. item.name .. " (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                
                updateStats()
                updateList()
                syncCart()
                
                if takenCount >= SETTINGS.MAX_TOTAL then
                    log("\n ЛИМИТ! → ОПЛАТА!")
                    addLog("🎯 Лимит! Иду платить...")
                    shouldPay = true
                    break
                end
            else
                addLog("❌ " .. item.name)
            end
            
            task.wait(0.5)
        end
        
        if shouldPay or takenCount > 0 then
            log("\n⚡ ПЕРЕХОД К ОПЛАТЕ! (взято: " .. takenCount .. ")")
            goToPay()
            
            if running then
                sortByDistance()
                updateList()
            end
        else
            addLog("❌ Пусто")
        end
        
        log("\n⏳ Ожидание (10 мин)...")
        addLog(" Жду 10 мин...")
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

print("\n" .. string.rep("=", 80))
print("✅ Скрипт v10.1 загружен!")
print("🚶 НАДЁЖНАЯ ХОДЬБА:")
print("   - Прямой MoveTo без Pathfinding")
print("   - Адаптивный таймаут")
print("   - Прыжок при застревании (2 сек)")
print("   - Телепорт при долгом застревании (4 сек)")
print("   - Остановка в 3 студиях от цели")
print("🎨 ФИЛЬТРЫ РЕДКОСТИ:")
for rarity, name in pairs(RARITY_NAMES) do
    print("   " .. (SETTINGS.RARITY_FILTER[rarity] and "✅" or "❌") .. " " .. name)
end
print("💰 ФИЛЬТР ЦЕНЫ: $" .. SETTINGS.MIN_PRICE .. " - $" .. SETTINGS.MAX_PRICE)
print("🔄 3 попытки взять предмет")
print("💰 Гарантированная оплата")
print("📊 Полная статистика")
print(string.rep("=", 80) .. "\n")
