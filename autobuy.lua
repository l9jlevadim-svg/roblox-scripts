-- 👕 АВТОПОКУПКА v2.0 - ЧАСТЬ 1/5
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

print("\n👕 АВТОПОКУПКА v2.0 - ЗАПУСК\n")

-- НАСТРОЙКИ
local MAX_PER_SHOP = 15
local DELAY_ITEMS = 2
local REFRESH_TIME = 600
local STOP_DISTANCE = 2

-- ПЕРЕМЕННЫЕ
local clothes = {}
local seller = nil
local running = false
local takenCount = 0
local paidCount = 0
local shopLimits = {}
local lastTakeTime = 0
local shopZones = {}

-- ФУНКЦИЯ: Поиск позиции
local function findPosition(obj)
    local checkObj = obj
    for i = 1, 5 do
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

-- ФУНКЦИЯ: Поиск магазинов
local function findShops()
    print("🔍 Поиск магазинов...")
    shopZones = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Shop_ShopZone") then
            shopZones[obj.Name] = true
            print("  🏪 " .. obj.Name)
        end
    end
    print("📊 Всего: " .. #shopZones)
end

-- ФУНКЦИЯ: Поиск одежды
local function findClothes()
    print("\n🔍 Поиск одежды...")
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
                    if path:find(name) then shopName = name break end
                end
                
                local floor = position and position.Y > 10 and "2 этаж" or "1 этаж"
                
                table.insert(clothes, {
                    obj = obj, parent = parent, name = parent and parent.Name or "Item",
                    priceText = priceText, position = position, shop = shopName,
                    floor = floor, taken = false
                })
            end
            
            if action:find("Поговорить") and not seller then
                seller = {obj = obj, position = findPosition(obj)}
                print("🏪 Продавец найден")
            end
        end
    end
    print("✅ Найдено: " .. #clothes)
end
-- 👕 АВТОПОКУПКА v2.0 - ЧАСТЬ 2/5
-- ============================================
-- НАВИГАЦИЯ
-- ============================================

local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then return false end
    
    print("🚶 Иду к: " .. tostring(targetPos))
    
    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5,
        AgentCanJump = true, AgentCanClimb = true
    })
    
    local success = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPos)
    end)
    
    if not success then
        print("❌ Ошибка пути, телепорт...")
        rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        task.wait(0.5)
        return true
    end
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        print("   ✅ Путь: " .. #waypoints .. " точек")
        
        for i, waypoint in ipairs(waypoints) do
            if not running then return false end
            
            humanoid:MoveTo(waypoint.Position)
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            local timeout = 0
            local lastPos = rootPart.Position
            local stuckTime = 0
            
            while timeout < 15 do
                if not running then return false end
                
                local currentPos = rootPart.Position
                local dist = (currentPos - waypoint.Position).Magnitude
                local moved = (currentPos - lastPos).Magnitude
                
                if moved < 0.2 then
                    stuckTime = stuckTime + 0.1
                    if stuckTime > 3 then
                        print("⚠️  Застрял! Телепорт...")
                        local nextPos = waypoint.Position + Vector3.new(0, 3, 0)
                        if i < #waypoints then
                            nextPos = waypoints[i+1].Position + Vector3.new(0, 3, 0)
                        end
                        rootPart.CFrame = CFrame.new(nextPos)
                        task.wait(0.5)
                        stuckTime = 0
                    end
                else
                    stuckTime = 0
                end
                
                lastPos = currentPos
                if dist < 2 then break end
                timeout = timeout + 0.1
                task.wait(0.1)
            end
            task.wait(0.2)
        end
        
        local finalDist = (rootPart.Position - targetPos).Magnitude
        if finalDist > 4 then
            rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 1, 0))
            task.wait(0.5)
        end
        
        return true
    else
        print("⚠️  Пути нет, иду напрямик...")
        humanoid:MoveTo(targetPos)
        task.wait(2)
        return false
    end
end

-- ============================================
-- АКТИВАЦИЯ PROMPT
-- ============================================

local function activatePrompt(prompt)
    if not prompt then return false end
    
    print("🔘 Активирую: " .. prompt:GetFullName())
    
    if fireproximityprompt then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then print("   ✅ fireproximityprompt"); return true end
    end
    
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(1.5)
        prompt:InputHoldEnd()
    end)
    
    print(ok and "   ✅ InputHold" or "   ❌ Ошибка")
    return ok
end
-- 👕 АВТОПОКУПКА v2.0 - ЧАСТЬ 3/5
-- ============================================
-- ОПЛАТА
-- ============================================

local function pay()
    print("\n💳 ОПЛАТА...")
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local confirmPurchase = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirmPurchase then
        confirmPurchase = confirmPurchase:FindFirstChild("ConfirmPurchase")
    end
    
    if confirmPurchase then
        print("   🎯 RemoteEvent...")
        local ok = pcall(function() confirmPurchase:FireServer() end)
        if ok then print("   ✅ RemoteEvent"); return true end
    end
    
    print("   🎯 GUI кнопка...")
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
                if ok then print("   ✅ GUI"); return true end
            end
        end
    end
    
    print("   ❌ Не удалось")
    return false
end

-- ============================================
-- GUI ИНТЕРФЕЙС
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy"
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
titleLabel.Text = "👕 Автопокупка v2.0"
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
-- 👕 АВТОПОКУПКА v2.0 - ЧАСТЬ 4/5
-- Фильтр
local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, -20, 0, 35)
filterBox.Position = UDim2.new(0, 10, 0, 55)
filterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
filterBox.TextColor3 = Color3.new(1, 1, 1)
filterBox.PlaceholderText = "🔍 Фильтр..."
filterBox.Text = ""
filterBox.Parent = frame
Instance.new("UICorner").Parent = filterBox

-- Статистика
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

-- Кнопка
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 50)
startBtn.Position = UDim2.new(0, 10, 0, 150)
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
startBtn.Text = "▶️ АВТОПОКУПКА"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14
startBtn.Parent = frame
Instance.new("UICorner").Parent = startBtn

-- Статус
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 205)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🟢 Готов"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 13
statusLabel.Parent = frame

-- Лог
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
local function log(msg)
    table.insert(logText, msg)
    if #logText > 5 then table.remove(logText, 1) end
    logLabel.Text = "📋 Лог:\n" .. table.concat(logText, "\n")
end

-- Список
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
            local limitText = shopLimit >= MAX_PER_SHOP and " [ЛИМИТ]" or ""
            
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
    log("🔄 Сброс")
    updateList()
end
-- 👕 АВТОПОКУПКА v2.0 - ЧАСТЬ 5/5
-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

local function mainLoop()
    print("\n🎬 ЗАПУСК ЦИКЛА!")
    
    while running do
        resetAll()
        log("🔄 Новый цикл!")
        statusLabel.Text = "🔄 Начинаю..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken then continue end
            
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= MAX_PER_SHOP then
                print("⏭️  " .. item.shop .. " лимит достигнут")
                continue
            end
            
            -- Задержка
            local waitTime = DELAY_ITEMS - (tick() - lastTakeTime)
            if waitTime > 0 then
                log("⏳ Жду " .. math.ceil(waitTime) .. "с...")
                statusLabel.Text = "⏳ Жду..."
                for i = 1, math.ceil(waitTime) do
                    if not running then return end
                    task.wait(1)
                end
            end
            
            if not running then break end
            
            log("🚶 " .. item.name .. " [" .. item.shop .. "]")
            statusLabel.Text = "🚶 " .. item.name
            
            if item.position then
                walkTo(item.position)
                task.wait(0.5)
            end
            
            log("🤖 Беру...")
            statusLabel.Text = "🤖 Беру..."
            
            local activated = activatePrompt(item.obj)
            
            if activated then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                log("✅ " .. item.name .. " [" .. shopLimits[item.shop] .. "/" .. MAX_PER_SHOP .. "]")
                updateStats()
                updateList()
            else
                log("❌ " .. item.name)
            end
            
            task.wait(0.5)
        end
        
        -- Оплата
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
                updateStats()
            else
                log("⚠️  Не оплачено")
            end
        end
        
        -- Ждем обновления
        log("⏳ Жду 10 мин...")
        for i = 1, REFRESH_TIME do
            if not running then break end
            task.wait(1)
        end
    end
    
    running = false
    startBtn.Text = "▶️ АВТОПОКУПКА"
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    log("⏹️ Остановлено")
end

-- КНОПКА СТАРТ
startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "▶️ АВТОПОКУПКА"
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
print("💡 Нажми '▶️ АВТОПОКУПКА' для старта")
print("💡 GitHub: loadstring(game:HttpGet('URL'))()")
