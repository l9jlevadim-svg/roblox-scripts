-- ============================================================================
-- 👕 АВТОПОКУПКА v10.0 ULTIMATE
-- GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/l9jlevadim-svg/roblox-scripts/main/autobuy.lua"))()
-- ✅ Умная навигация с обходом стен | ✅ Фильтры цена/редкость | ✅ Синхронизация корзины
-- ✅ Отказоустойчивая оплата | ✅ Профессиональный GUI | ✅ Анти-застревание
-- ============================================================================

-- ============================================
-- 1. КОНФИГУРАЦИЯ И КОНСТАНТЫ
-- ============================================
local CONFIG = {
    -- Лимиты
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
    REFRESH_TIME = 600,
    
    -- Навигация
    WALK_SPEED = 18,
    RUN_SPEED = 24,
    JUMP_POWER = 50,
    STOP_DISTANCE = 5,           -- Остановка в 5 студиях от цели
    PROMPT_RANGE = 6,            -- Дальность активации prompt
    PATH_RADIUS = 2.5,           -- Радиус агента (обход стен)
    PATH_HEIGHT = 5,
    STUCK_THRESHOLD = 0.4,       -- Минимальное движение для считания "застрял"
    STUCK_TIME = 2.5,            -- Время до реакции на застревание
    MAX_PATH_RETRIES = 3,        -- Пересчет пути при ошибке
    
    -- Взаимодействие
    DELAY_ITEMS = 1.5,
    MAX_RETRIES = 3,
    RETRY_DELAY = 1,
    MAX_FAILED_ATTEMPTS = 2,
    CART_CHECK_DELAY = 0.4,
    
    -- Фильтры
    MIN_PRICE = 0,
    MAX_PRICE = 999999,
    RARITY_FILTER = {
        common = true,
        uncommon = true,
        rare = true,
        epic = true,
        legendary = true
    },
    
    -- GUI
    THEME = {
        bg = Color3.fromRGB(12, 12, 12),
        panel = Color3.fromRGB(22, 22, 22),
        accent = Color3.fromRGB(80, 200, 80),
        danger = Color3.fromRGB(220, 50, 50),
        text = Color3.new(1, 1, 1),
        subtext = Color3.fromRGB(180, 180, 180)
    }
}

-- Цвета редкостей для GUI и логики
local RARITY_DATA = {
    common = {name = "Обычная", color = Color3.fromRGB(150, 150, 150), keywords = {"обычн", "common", "обыч", "обы", "c", "com"}},
    uncommon = {name = "Необычная", color = Color3.fromRGB(50, 200, 50), keywords = {"необыч", "uncommon", "необы", "uc", "uncom"}},
    rare = {name = "Редкая", color = Color3.fromRGB(50, 100, 255), keywords = {"редк", "rare", "ред", "r"}},
    epic = {name = "Эпическая", color = Color3.fromRGB(180, 50, 255), keywords = {"эпич", "epic", "эп", "ep"}},
    legendary = {name = "Легендарная", color = Color3.fromRGB(255, 200, 50), keywords = {"легенд", "legendary", "legend", "лег", "leg"}}
}

-- ============================================
-- 2. СЕРВИСЫ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ============================================
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

-- Состояние скрипта
local State = {
    running = false,
    clothes = {},
    seller = nil,
    shopZones = {},
    takenCount = 0,
    paidCount = 0,
    shopLimits = {},
    lastTakeTime = 0,
    lastMoveTime = 0,
    initialCartCount = 0,
    cycleActive = false
}

-- ============================================
-- 3. УТИЛИТЫ И ЛОГИРОВАНИЕ
-- ============================================

local function log(msg, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[%s][%s] %s", timestamp, level, msg))
end

local function getDistance(p1, p2)
    return (p1 - p2).Magnitude
end

local function findPosition(obj)
    local check = obj
    for _ = 1, 6 do
        if check then
            if check:IsA("BasePart") then return check.CFrame.Position end
            local part = check:FindFirstChildWhichIsA("BasePart")
            if part then return part.CFrame.Position end
            check = check.Parent
        end
    end
    return nil
end

local function waitSeconds(sec)
    local start = tick()
    while tick() - start < sec do
        if not State.running then return false end
        task.wait(0.1)
    end
    return true
end

-- ============================================
-- 4. ДВИЖОК НАВИГАЦИИ (УМНЫЙ МАРШРУТИЗАТОР)
-- ============================================

local Navigation = {}

function Navigation:calculatePath(startPos, endPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = CONFIG.PATH_RADIUS,
        AgentHeight = CONFIG.PATH_HEIGHT,
        AgentCanJump = true,
        AgentCanClimb = true,
        Costs = {Water = 100, Door = 50}
    })
    
    local success = pcall(function() path:ComputeAsync(startPos, endPos) end)
    return success and path.Status == Enum.PathStatus.Success, path
end

function Navigation:moveToTarget(targetPos, callback)
    if not targetPos or not humanoid or not rootPart then return false end
    
    local startPos = rootPart.Position
    local totalDist = getDistance(startPos, targetPos)
    log("🚶 Маршрут: " .. math.floor(totalDist) .. " студий")
    
    -- Сохраняем статы
    local origSpeed = humanoid.WalkSpeed
    local origJump = humanoid.JumpPower
    humanoid.WalkSpeed = totalDist > 30 and CONFIG.RUN_SPEED or CONFIG.WALK_SPEED
    humanoid.JumpPower = CONFIG.JUMP_POWER
    
    -- Вычисляем точку остановки (не вплотную к стенам)
    local dir = (targetPos - startPos)
    dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(0,0,1)
    local stopPos = totalDist > CONFIG.STOP_DISTANCE and targetPos - (dir * CONFIG.STOP_DISTANCE) or targetPos
    
    -- Строим путь
    local success, path = self:calculatePath(startPos, stopPos)
    if not success then
        log("⚠️ Путь не построен, использую прямой MoveTo", "WARN")
        humanoid:MoveTo(stopPos)
        local reached = humanoid.MoveToFinished:Wait(15)
        humanoid.WalkSpeed = origSpeed
        humanoid.JumpPower = origJump
        return reached
    end
    
    local waypoints = path:GetWaypoints()
    log("✅ Построено " .. #waypoints .. " точек маршрута")
    
    -- Проходим по точкам
    for i, wp in ipairs(waypoints) do
        if not State.running then
            humanoid.WalkSpeed = origSpeed
            humanoid.JumpPower = origJump
            return false
        end
        
        humanoid:MoveTo(wp.Position)
        if wp.Action == Enum.PathWaypointAction.Jump then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        -- Анти-застревание
        local startTime = tick()
        local lastPos = rootPart.Position
        local stuckTimer = 0
        local stuckCount = 0
        
        while tick() - startTime < 15 do
            if not State.running then
                humanoid.WalkSpeed = origSpeed
                humanoid.JumpPower = origJump
                return false
            end
            
            local curPos = rootPart.Position
            local distToWP = getDistance(curPos, wp.Position)
            local moved = getDistance(curPos, lastPos)
            
            if moved < CONFIG.STUCK_THRESHOLD then
                stuckTimer = stuckTimer + 0.1
                if stuckTimer >= CONFIG.STUCK_TIME then
                    stuckCount = stuckCount + 1
                    log("⚠️ Застревание на точке " .. i .. "! Восстановление...", "WARN")
                    
                    if stuckCount == 1 then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait(0.3)
                    elseif stuckCount == 2 then
                        -- Откат и пересчет
                        local backPos = curPos - (dir * 3)
                        humanoid:MoveTo(backPos)
                        task.wait(0.5)
                        -- Пересчет пути
                        local resuccess, rpath = self:calculatePath(rootPart.Position, stopPos)
                        if resuccess then
                            waypoints = rpath:GetWaypoints()
                            i = 0 -- Перезапуск цикла точек
                            log("✅ Путь пересчитан", "INFO")
                        end
                    else
                        -- Фолбэк на прямой MoveTo
                        humanoid:MoveTo(stopPos)
                        task.wait(2)
                        break
                    end
                    stuckTimer = 0
                end
            else
                stuckTimer = 0
            end
            
            lastPos = curPos
            if distToWP < 2.5 then break end
            task.wait(0.1)
        end
        
        task.wait(0.05)
    end
    
    -- Финальная проверка расстояния
    local finalDist = getDistance(rootPart.Position, targetPos)
    log("📍 Финиш: " .. math.floor(finalDist) .. " студий от цели")
    
    humanoid.WalkSpeed = origSpeed
    humanoid.JumpPower = origJump
    
    if callback then callback(finalDist) end
    return finalDist <= CONFIG.STOP_DISTANCE + 2
end

-- ============================================
-- 5. СИСТЕМА ФИЛЬТРОВ И СКАНИРОВАНИЯ
-- ============================================

local FilterEngine = {}

function FilterEngine:detectRarity(item)
    if not item.parent then return "common" end
    
    -- 1. Атрибуты
    local attr = item.parent:GetAttribute("Rarity")
    if attr then
        attr = tostring(attr):lower()
        for r, data in pairs(RARITY_DATA) do
            for _, kw in ipairs(data.keywords) do
                if attr:find(kw) then return r end
            end
        end
    end
    
    -- 2. Value объекты
    for _, child in ipairs(item.parent:GetDescendants()) do
        if child:IsA("StringValue") then
            local val = tostring(child.Value):lower()
            for r, data in pairs(RARITY_DATA) do
                for _, kw in ipairs(data.keywords) do
                    if val:find(kw) then return r end
                end
            end
        end
    end
    
    -- 3. Текст в BillboardGui
    local search = item.parent
    for _ = 1, 5 do
        if search then
            for _, child in ipairs(search:GetChildren()) do
                if child:IsA("BillboardGui") then
                    for _, gui in ipairs(child:GetChildren()) do
                        if gui:IsA("TextLabel") then
                            local txt = gui.Text:lower()
                            for r, data in pairs(RARITY_DATA) do
                                for _, kw in ipairs(data.keywords) do
                                    if txt:find(kw) then return r end
                                end
                            end
                        end
                    end
                end
            end
            search = search.Parent
        end
    end
    
    -- 4. Имя предмета
    local name = item.parent.Name:lower()
    for r, data in pairs(RARITY_DATA) do
        for _, kw in ipairs(data.keywords) do
            if name:find(kw) then return r end
        end
    end
    
    return "common"
end

function FilterEngine:detectPrice(item)
    -- 1. Атрибуты
    if item.parent then
        local p = item.parent:GetAttribute("Price") or item.parent:GetAttribute("Cost")
        if p then return tonumber(p) or 0 end
    end
    
    -- 2. Value
    if item.parent then
        for _, child in ipairs(item.parent:GetDescendants()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                if child.Name:lower():match("price|cost") then
                    return tonumber(child.Value) or 0
                end
            end
        end
    end
    
    -- 3. Текст
    if item.priceText then
        local max = 0
        for num in item.priceText:gmatch("(%d+)") do
            local n = tonumber(num)
            if n and n > max then max = n end
        end
        return max
    end
    
    return 0
end

function FilterEngine:matchesFilters(item)
    if not item.rarity then item.rarity = self:detectRarity(item) end
    if not item.price then item.price = self:detectPrice(item) end
    
    if not CONFIG.RARITY_FILTER[item.rarity] then return false end
    if item.price < CONFIG.MIN_PRICE or item.price > CONFIG.MAX_PRICE then return false end
    
    return true
end

function FilterEngine:sortAndFilter()
    if not rootPart then return {} end
    local pos = rootPart.Position
    
    local valid = {}
    for _, item in ipairs(State.clothes) do
        if not item.taken and not item.unavailable and self:matchesFilters(item) then
            item.dist = getDistance(pos, item.position)
            table.insert(valid, item)
        end
    end
    
    table.sort(valid, function(a, b) return a.dist < b.dist end)
    return valid
end

-- ============================================
-- 6. КОРЗИНА И ВЗАИМОДЕЙСТВИЕ
-- ============================================

local CartManager = {}

function CartManager:getRealCount()
    if not player.PlayerGui then return nil end
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local txt = child.Text or ""
                local nm = (child.Name or ""):lower()
                if nm:match("cart|item|count|total") then
                    local num = txt:match("(%d+)")
                    if num then
                        local c = tonumber(num)
                        if c and c >= 0 and c <= 100 then return c end
                    end
                end
            end
        end
    end
    return nil
end

function CartManager:sync()
    local real = self:getRealCount()
    if real then
        if real ~= State.takenCount then
            log("🔄 Синхронизация корзины: скрипт=" .. State.takenCount .. " | игра=" .. real)
            State.takenCount = real
        end
        return real
    end
    return State.takenCount
end

function CartManager:activatePrompt(prompt)
    if not prompt then return false end
    
    local pos = findPosition(prompt) or findPosition(prompt.Parent)
    if pos then
        local dist = getDistance(rootPart.Position, pos)
        if dist > CONFIG.PROMPT_RANGE then
            log("📍 Далеко (" .. math.floor(dist) .. "), подхожу...")
            Navigation:moveToTarget(pos)
            task.wait(0.3)
        end
    end
    
    -- fireproximityprompt
    if fireproximityprompt then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then return true end
    end
    
    -- InputHold
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(1.5)
        prompt:InputHoldEnd()
    end)
    
    return ok
end

function CartManager:tryTake(item)
    log("🎯 Беру: " .. item.name .. " [" .. (RARITY_DATA[item.rarity].name) .. "] $" .. item.price)
    
    if item.unavailable or not item.obj or not item.obj.Parent then
        if item.obj and not item.obj.Parent then item.unavailable = true end
        return false
    end
    
    for att = 1, CONFIG.MAX_RETRIES do
        if not State.running then return false end
        if att > 1 then
            log("🔄 Попытка #" .. att)
            task.wait(CONFIG.RETRY_DELAY)
            if not item.obj or not item.obj.Parent then
                item.unavailable = true
                return false
            end
        end
        
        if self:activatePrompt(item.obj) then
            log("✅ Успешно взято (попытка " .. att .. ")")
            item.failedAttempts = 0
            return true
        end
        log("❌ Попытка #" .. att .. " провалена")
    end
    
    log("❌ Все попытки исчерпаны")
    item.failedAttempts = (item.failedAttempts or 0) + 1
    if item.failedAttempts >= CONFIG.MAX_FAILED_ATTEMPTS then
        item.unavailable = true
    end
    return false
end

-- ============================================
-- 7. СИСТЕМА ОПЛАТЫ
-- ============================================

local PaymentSystem = {}

function PaymentSystem:execute()
    log(" Инициализация оплаты...")
    CartManager:sync()
    
    if State.takenCount == 0 then
        log("⚠️ Корзина пуста, оплата пропущена", "WARN")
        return false
    end
    
    if not State.seller then
        log("❌ Продавец не найден!", "ERROR")
        return false
    end
    
    -- Путь к продавцу
    if State.seller.position then
        log("🚶 Маршрут к кассе...")
        Navigation:moveToTarget(State.seller.position)
        task.wait(0.5)
    end
    
    -- Разговор
    log("💬 Взаимодействие с продавцом...")
    CartManager:activatePrompt(State.seller.obj)
    task.wait(1.5)
    
    -- Методы оплаты
    local paid = false
    
    -- 1. RemoteEvent
    local rs = game:GetService("ReplicatedStorage")
    local rem = rs:FindFirstChild("ShopRemotes", true)
    if rem then rem = rem:FindFirstChild("ConfirmPurchase") end
    if rem then
        paid = pcall(function() rem:FireServer() end)
        if paid then log("✅ Оплата через RemoteEvent") end
    end
    
    -- 2. GUI Click
    if not paid and player.PlayerGui then
        local gui = player.PlayerGui:FindFirstChild("ShopGUI")
        if gui then
            local btn = gui:FindFirstChild("BuyButton", true)
            if btn and btn:IsA("TextButton") then
                paid = pcall(function()
                    VirtualUser:CaptureController()
                    local p = btn.AbsolutePosition
                    local s = btn.AbsoluteSize
                    VirtualUser:ClickButton1(Vector2.new(p.X + s.X/2, p.Y + s.Y/2))
                end)
                if paid then log("✅ Оплата через GUI") end
            end
        end
    end
    
    -- 3. Промпт оплаты
    if not paid then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and (obj.ActionText:find("Оплатить") or obj.ActionText:find("Pay")) then
                paid = CartManager:activatePrompt(obj)
                if paid then log("✅ Оплата через Prompt") end
                break
            end
        end
    end
    
    if paid then
        State.paidCount = State.paidCount + 1
        State.takenCount = 0
        log("✅ ОПЛАТА УСПЕШНА! Всего: " .. State.paidCount)
        task.wait(1.5)
        return true
    else
        log("⚠️ Попытка повторной оплаты...", "WARN")
        task.wait(1)
        -- Повтор
        if player.PlayerGui then
            local gui = player.PlayerGui:FindFirstChild("ShopGUI")
            if gui then
                local btn = gui:FindFirstChild("BuyButton", true)
                if btn and btn:IsA("TextButton") then
                    local ok = pcall(function()
                        VirtualUser:CaptureController()
                        local p = btn.AbsolutePosition
                        local s = btn.AbsoluteSize
                        VirtualUser:ClickButton1(Vector2.new(p.X + s.X/2, p.Y + s.Y/2))
                    end)
                    if ok then
                        State.paidCount = State.paidCount + 1
                        State.takenCount = 0
                        log("✅ Оплата успешна со 2-й попытки")
                        return true
                    end
                end
            end
        end
        log("❌ ОПЛАТА ПРОВАЛЕНА", "ERROR")
        return false
    end
end

-- ============================================
-- 8. ПРОФЕССИОНАЛЬНЫЙ GUI
-- ============================================

local GUI = {}
local Elements = {}

function GUI:init()
    local screen = Instance.new("ScreenGui")
    screen.Name = "AutoBuy_v10"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = player:WaitForChild("PlayerGui")
    Elements.Screen = screen
    
    -- Main Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 720, 0, 820)
    frame.Position = UDim2.new(0, 100, 0, 100)
    frame.BackgroundColor3 = CONFIG.THEME.bg
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", frame).Color = Color3.fromRGB(40,40,40)
    Elements.Frame = frame
    
    -- Draggable Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CONFIG.THEME.panel
    header.BorderSizePixel = 0
    header.Parent = frame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "👕 Автопокупка v10.0 ULTIMATE"
    title.TextColor3 = CONFIG.THEME.text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -42, 0, 7)
    closeBtn.BackgroundColor3 = CONFIG.THEME.danger
    closeBtn.Text = ""
    closeBtn.TextColor3 = CONFIG.THEME.text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.MouseButton1Click:Connect(function() State.running = false screen:Destroy() end)
    
    -- Drag Logic
    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = inp.Position; startPos = frame.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    header.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = inp.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    
    -- Filter Panel
    local filterPanel = Instance.new("Frame")
    filterPanel.Size = UDim2.new(1, -20, 0, 130)
    filterPanel.Position = UDim2.new(0, 10, 0, 55)
    filterPanel.BackgroundColor3 = CONFIG.THEME.panel
    filterPanel.Parent = frame
    Instance.new("UICorner", filterPanel).CornerRadius = UDim.new(0, 8)
    
    local fTitle = Instance.new("TextLabel")
    fTitle.Size = UDim2.new(1, -10, 0, 18)
    fTitle.Position = UDim2.new(0, 5, 0, 2)
    fTitle.BackgroundTransparency = 1
    fTitle.Text = "🎯 ФИЛЬТРЫ (✅ ВКЛ | ❌ ВЫКЛ)"
    fTitle.TextColor3 = CONFIG.THEME.text
    fTitle.Font = Enum.Font.GothamBold
    fTitle.TextSize = 11
    fTitle.TextXAlignment = Enum.TextXAlignment.Left
    fTitle.Parent = filterPanel
    
    -- Rarity Toggles
    local order = {"common", "uncommon", "rare", "epic", "legendary"}
    for i, r in ipairs(order) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.19, -4, 0, 26)
        btn.Position = UDim2.new((i-1)*0.2, 5, 0, 22)
        btn.BackgroundColor3 = CONFIG.RARITY_FILTER[r] and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(70,70,70)
        btn.Text = (CONFIG.RARITY_FILTER[r] and "✅ " or "❌ ") .. RARITY_DATA[r].name
        btn.TextColor3 = CONFIG.THEME.text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.Parent = filterPanel
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            CONFIG.RARITY_FILTER[r] = not CONFIG.RARITY_FILTER[r]
            btn.BackgroundColor3 = CONFIG.RARITY_FILTER[r] and Color3.fromRGB(40, 180, 40) or Color3.fromRGB(70,70,70)
            btn.Text = (CONFIG.RARITY_FILTER[r] and "✅ " or "❌ ") .. RARITY_DATA[r].name
            GUI:updateList()
        end)
    end
    
    -- Price Range
    local lblMin = Instance.new("TextLabel")
    lblMin.Size = UDim2.new(0.12, 0, 0, 22)
    lblMin.Position = UDim2.new(0, 5, 0, 55)
    lblMin.BackgroundTransparency = 1
    lblMin.Text = "От $:"
    lblMin.TextColor3 = CONFIG.THEME.text
    lblMin.Font = Enum.Font.GothamBold
    lblMin.TextSize = 10
    lblMin.TextXAlignment = Enum.TextXAlignment.Left
    lblMin.Parent = filterPanel
    
    local inpMin = Instance.new("TextBox")
    inpMin.Size = UDim2.new(0.15, 0, 0, 22)
    inpMin.Position = UDim2.new(0.12, 5, 0, 55)
    inpMin.BackgroundColor3 = Color3.fromRGB(35,35,35)
    inpMin.TextColor3 = CONFIG.THEME.text
    inpMin.Text = tostring(CONFIG.MIN_PRICE)
    inpMin.Font = Enum.Font.Gotham
    inpMin.TextSize = 10
    inpMin.Parent = filterPanel
    Instance.new("UICorner", inpMin).CornerRadius = UDim.new(0, 4)
    inpMin.FocusLost:Connect(function()
        local v = tonumber(inpMin.Text)
        if v and v >= 0 then CONFIG.MIN_PRICE = v; GUI:updateList() end
    end)
    
    local lblMax = Instance.new("TextLabel")
    lblMax.Size = UDim2.new(0.12, 0, 0, 22)
    lblMax.Position = UDim2.new(0.32, 5, 0, 55)
    lblMax.BackgroundTransparency = 1
    lblMax.Text = "До $:"
    lblMax.TextColor3 = CONFIG.THEME.text
    lblMax.Font = Enum.Font.GothamBold
    lblMax.TextSize = 10
    lblMax.TextXAlignment = Enum.TextXAlignment.Left
    lblMax.Parent = filterPanel
    
    local inpMax = Instance.new("TextBox")
    inpMax.Size = UDim2.new(0.15, 0, 0, 22)
    inpMax.Position = UDim2.new(0.44, 5, 0, 55)
    inpMax.BackgroundColor3 = Color3.fromRGB(35,35,35)
    inpMax.TextColor3 = CONFIG.THEME.text
    inpMax.Text = tostring(CONFIG.MAX_PRICE)
    inpMax.Font = Enum.Font.Gotham
    inpMax.TextSize = 10
    inpMax.Parent = filterPanel
    Instance.new("UICorner", inpMax).CornerRadius = UDim.new(0, 4)
    inpMax.FocusLost:Connect(function()
        local v = tonumber(inpMax.Text)
        if v and v >= 0 then CONFIG.MAX_PRICE = v; GUI:updateList() end
    end)
    
    Elements.FilterStats = Instance.new("TextLabel")
    Elements.FilterStats.Size = UDim2.new(1, -10, 0, 18)
    Elements.FilterStats.Position = UDim2.new(0, 5, 0, 82)
    Elements.FilterStats.BackgroundTransparency = 1
    Elements.FilterStats.Text = "Всего: 0 | Доступно: 0"
    Elements.FilterStats.TextColor3 = CONFIG.THEME.subtext
    Elements.FilterStats.Font = Enum.Font.Gotham
    Elements.FilterStats.TextSize = 10
    Elements.FilterStats.TextXAlignment = Enum.TextXAlignment.Left
    Elements.FilterStats.Parent = filterPanel
    
    -- Stats Bar
    local stats = Instance.new("Frame")
    stats.Size = UDim2.new(1, -20, 0, 50)
    stats.Position = UDim2.new(0, 10, 0, 190)
    stats.BackgroundColor3 = CONFIG.THEME.panel
    stats.Parent = frame
    Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 8)
    
    Elements.TakenLabel = Instance.new("TextLabel")
    Elements.TakenLabel.Size = UDim2.new(0.5, -5, 1, 0)
    Elements.TakenLabel.Position = UDim2.new(0, 8, 0, 0)
    Elements.TakenLabel.BackgroundTransparency = 1
    Elements.TakenLabel.Text = "🛒 Взято: 0 / " .. CONFIG.MAX_TOTAL
    Elements.TakenLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    Elements.TakenLabel.Font = Enum.Font.GothamBold
    Elements.TakenLabel.TextSize = 13
    Elements.TakenLabel.TextXAlignment = Enum.TextXAlignment.Left
    Elements.TakenLabel.Parent = stats
    
    Elements.PaidLabel = Instance.new("TextLabel")
    Elements.PaidLabel.Size = UDim2.new(0.5, -5, 1, 0)
    Elements.PaidLabel.Position = UDim2.new(0.5, 5, 0, 0)
    Elements.PaidLabel.BackgroundTransparency = 1
    Elements.PaidLabel.Text = "💳 Оплачено: 0"
    Elements.PaidLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    Elements.PaidLabel.Font = Enum.Font.GothamBold
    Elements.PaidLabel.TextSize = 13
    Elements.PaidLabel.TextXAlignment = Enum.TextXAlignment.Left
    Elements.PaidLabel.Parent = stats
    
    -- Start Button
    Elements.StartBtn = Instance.new("TextButton")
    Elements.StartBtn.Size = UDim2.new(1, -20, 0, 45)
    Elements.StartBtn.Position = UDim2.new(0, 10, 0, 245)
    Elements.StartBtn.BackgroundColor3 = CONFIG.THEME.accent
    Elements.StartBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
    Elements.StartBtn.TextColor3 = Color3.new(0,0,0)
    Elements.StartBtn.Font = Enum.Font.GothamBold
    Elements.StartBtn.TextSize = 15
    Elements.StartBtn.Parent = frame
    Instance.new("UICorner", Elements.StartBtn).CornerRadius = UDim.new(0, 8)
    
    -- Status & Log
    Elements.Status = Instance.new("TextLabel")
    Elements.Status.Size = UDim2.new(1, -20, 0, 24)
    Elements.Status.Position = UDim2.new(0, 10, 0, 295)
    Elements.Status.BackgroundTransparency = 1
    Elements.Status.Text = "🟢 Готов к работе"
    Elements.Status.TextColor3 = Color3.fromRGB(100, 255, 100)
    Elements.Status.Font = Enum.Font.GothamBold
    Elements.Status.TextSize = 12
    Elements.Status.TextXAlignment = Enum.TextXAlignment.Left
    Elements.Status.Parent = frame
    
    Elements.LogBox = Instance.new("TextLabel")
    Elements.LogBox.Size = UDim2.new(1, -20, 0, 80)
    Elements.LogBox.Position = UDim2.new(0, 10, 0, 325)
    Elements.LogBox.BackgroundTransparency = 1
    Elements.LogBox.Text = " Лог системы:"
    Elements.LogBox.TextColor3 = CONFIG.THEME.subtext
    Elements.LogBox.Font = Enum.Font.Code
    Elements.LogBox.TextSize = 10
    Elements.LogBox.TextXAlignment = Enum.TextXAlignment.Left
    Elements.LogBox.TextYAlignment = Enum.TextYAlignment.Top
    Elements.LogBox.Parent = frame
    
    -- Item List
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -420)
    scroll.Position = UDim2.new(0, 10, 0, 410)
    scroll.BackgroundColor3 = CONFIG.THEME.panel
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.Parent = frame
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 8)
    Elements.Scroll = scroll
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = scroll
    Elements.Layout = layout
end

function GUI:updateStats()
    Elements.TakenLabel.Text = " Взято: " .. State.takenCount .. " / " .. CONFIG.MAX_TOTAL
    Elements.PaidLabel.Text = "💳 Оплачено: " .. State.paidCount
end

function GUI:addLog(msg)
    local lines = {}
    local raw = Elements.LogBox.Text:gsub("📋 Лог системы:\n", "")
    for line in raw:gmatch("[^\r\n]+") do table.insert(lines, line) end
    table.insert(lines, msg)
    if #lines > 8 then table.remove(lines, 1) end
    Elements.LogBox.Text = "📋 Лог системы:\n" .. table.concat(lines, "\n")
end

function GUI:updateList()
    for _, ch in ipairs(Elements.Scroll:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    
    local valid = FilterEngine:sortAndFilter()
    Elements.FilterStats.Text = "Всего: " .. #State.clothes .. " | Доступно по фильтрам: " .. #valid
    
    for i, item in ipairs(valid) do
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -10, 0, 55)
        f.BackgroundColor3 = Color3.fromRGB(28,28,28)
        f.LayoutOrder = i
        f.Parent = Elements.Scroll
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 4, 1, 0)
        bar.BackgroundColor3 = RARITY_DATA[item.rarity].color
        bar.Parent = f
        
        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, -15, 0, 18)
        nm.Position = UDim2.new(0, 10, 0, 2)
        nm.BackgroundTransparency = 1
        nm.Text = "📦 " .. item.name
        nm.TextColor3 = CONFIG.THEME.text
        nm.Font = Enum.Font.GothamBold
        nm.TextSize = 11
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.Parent = f
        
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -15, 0, 16)
        info.Position = UDim2.new(0, 10, 0, 20)
        info.BackgroundTransparency = 1
        info.Text = item.shop .. " | " .. item.floor .. " | $" .. item.price
        info.TextColor3 = CONFIG.THEME.subtext
        info.Font = Enum.Font.Gotham
        info.TextSize = 9
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Parent = f
        
        local rLabel = Instance.new("TextLabel")
        rLabel.Size = UDim2.new(1, -15, 0, 16)
        rLabel.Position = UDim2.new(0, 10, 0, 36)
        rLabel.BackgroundTransparency = 1
        rLabel.Text = RARITY_DATA[item.rarity].name
        rLabel.TextColor3 = RARITY_DATA[item.rarity].color
        rLabel.Font = Enum.Font.GothamBold
        rLabel.TextSize = 9
        rLabel.TextXAlignment = Enum.TextXAlignment.Left
        rLabel.Parent = f
    end
    
    Elements.Scroll.CanvasSize = UDim2.new(0, 0, 0, Elements.Layout.AbsoluteContentSize.Y + 10)
end

function GUI:setStatus(text, color)
    Elements.Status.Text = text
    Elements.Status.TextColor3 = color or Color3.fromRGB(100, 255, 100)
end

Elements.StartBtn.MouseButton1Click:Connect(function()
    if State.running then
        State.running = false
        Elements.StartBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
        Elements.StartBtn.BackgroundColor3 = CONFIG.THEME.accent
        GUI:addLog("⏹️ Скрипт остановлен")
    else
        State.running = true
        Elements.StartBtn.Text = "️ ОСТАНОВИТЬ"
        Elements.StartBtn.BackgroundColor3 = CONFIG.THEME.danger
        task.spawn(MainLoop)
    end
end)

-- ============================================
-- 9. СКАНЕР МАГАЗИНОВ И ПРЕДМЕТОВ
-- ============================================

local Scanner = {}

function Scanner:findShops()
    log("🔍 Сканирование магазинов...")
    State.shopZones = {}
    
    local patterns = {"Shop_ShopZone", "ShopZone", "Shop_", "ClothingShop", "Store"}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            for _, p in ipairs(patterns) do
                if obj.Name:find(p) then
                    State.shopZones[obj.Name] = true
                    break
                end
            end
        end
    end
    log("📊 Найдено магазинов: " .. #State.shopZones)
end

function Scanner:findClothes()
    log("\n🔍 Сканирование одежды...")
    State.clothes = {}
    State.seller = nil
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local path = obj:GetFullName()
            local action = obj.ActionText or ""
            
            local inShop = false
            for name in pairs(State.shopZones) do
                if path:find(name) then inShop = true; break end
            end
            if not inShop and (path:find("Shop") or path:find("Store")) then inShop = true end
            
            if inShop and (action:find("Взять") or action:find("Take")) then
                local parent = obj.Parent
                local priceTxt = ""
                local search = parent
                for _ = 1, 5 do
                    if search then
                        for _, ch in ipairs(search:GetChildren()) do
                            if ch:IsA("BillboardGui") then
                                for _, g in ipairs(ch:GetChildren()) do
                                    if g:IsA("TextLabel") then priceTxt = g.Text end
                                end
                            end
                        end
                        search = search.Parent
                    end
                end
                
                local pos = findPosition(obj) or findPosition(parent)
                local shopName = "Unknown"
                for name in pairs(State.shopZones) do
                    if path:find(name) then shopName = name; break end
                end
                
                table.insert(State.clothes, {
                    obj = obj, parent = parent, name = parent and parent.Name or "Item",
                    priceText = priceTxt, position = pos, shop = shopName,
                    floor = (pos and pos.Y > 10) and "2 этаж" or "1 этаж",
                    taken = false, unavailable = false, failedAttempts = 0,
                    rarity = nil, price = nil
                })
            end
            
            if (action:find("Поговорить") or action:find("поговорить")) and not State.seller then
                State.seller = {obj = obj, position = findPosition(obj)}
                log("🏪 Продавец обнаружен")
            end
        end
    end
    
    log("✅ Найдено предметов: " .. #State.clothes)
    
    -- Предварительное определение фильтров
    for _, item in ipairs(State.clothes) do
        item.rarity = FilterEngine:detectRarity(item)
        item.price = FilterEngine:detectPrice(item)
    end
end

-- ============================================
-- 10. ГЛАВНЫЙ ЦИКЛ (ОРКЕСТРАТОР)
-- ============================================

function MainLoop()
    log("🎬 ЗАПУСК СИСТЕМЫ v10.0")
    GUI:addLog("🚀 Система инициализирована")
    
    while State.running do
        -- Сброс цикла
        for _, item in ipairs(State.clothes) do
            item.taken = false
            item.unavailable = false
            item.failedAttempts = 0
        end
        State.shopLimits = {}
        State.takenCount = 0
        State.lastTakeTime = 0
        State.lastMoveTime = tick()
        CartManager:sync()
        GUI:updateStats()
        GUI:updateList()
        
        GUI:addLog("🔄 Начало цикла сбора")
        GUI:setStatus(" Сбор предметов...", Color3.fromRGB(255, 200, 100))
        
        local shouldPay = false
        local filteredItems = FilterEngine:sortAndFilter()
        
        for _, item in ipairs(filteredItems) do
            if not State.running then break end
            if item.taken or item.unavailable then continue end
            
            CartManager:sync()
            
            if State.takenCount >= CONFIG.MAX_TOTAL then
                log("🎯 ЛИМИТ КОРЗИНЫ ДОСТИГНУТ (" .. State.takenCount .. ")")
                shouldPay = true
                break
            end
            
            local shopC = State.shopLimits[item.shop] or 0
            if shopC >= CONFIG.MAX_PER_SHOP then continue end
            
            -- Задержка с движением
            local waitT = CONFIG.DELAY_ITEMS - (tick() - State.lastTakeTime)
            if waitT > 0 then
                GUI:setStatus(" Задержка " .. math.ceil(waitT) .. "с...", Color3.fromRGB(200, 200, 200))
                local startW = tick()
                while tick() - startW < waitT do
                    if not State.running then return end
                    if tick() - State.lastMoveTime >= CONFIG.MOVE_INTERVAL then
                        local rd = Vector3.new(math.random(-2,2), 0, math.random(-2,2))
                        humanoid:MoveTo(rootPart.Position + rd)
                        State.lastMoveTime = tick()
                    end
                    task.wait(0.2)
                end
            end
            
            if not State.running then break end
            
            log("\n🎯 Цель: " .. item.name .. " [" .. RARITY_DATA[item.rarity].name .. "] $" .. item.price)
            GUI:addLog("🚶 " .. item.name)
            GUI:setStatus("🚶 " .. item.name, Color3.fromRGB(100, 200, 255))
            
            if item.position then
                Navigation:moveToTarget(item.position)
                task.wait(0.3)
            end
            
            GUI:addLog("🤖 Взаимодействие...")
            GUI:setStatus("🤖 Беру " .. item.name, Color3.fromRGB(255, 150, 50))
            
            if CartManager:tryTake(item) then
                item.taken = true
                State.takenCount = State.takenCount + 1
                State.shopLimits[item.shop] = (State.shopLimits[item.shop] or 0) + 1
                State.lastTakeTime = tick()
                
                log("✅ Успех! [" .. State.takenCount .. "/" .. CONFIG.MAX_TOTAL .. "]")
                GUI:addLog("✅ " .. item.name .. " (" .. State.takenCount .. "/" .. CONFIG.MAX_TOTAL .. ")")
                GUI:updateStats()
                GUI:updateList()
                CartManager:sync()
                
                if State.takenCount >= CONFIG.MAX_TOTAL then
                    shouldPay = true
                    break
                end
            else
                GUI:addLog("❌ " .. item.name)
            end
            
            task.wait(0.3)
        end
        
        -- Оплата
        if shouldPay or State.takenCount > 0 then
            log("\n💰 Переход к оплате...")
            GUI:addLog("💰 Иду на кассу...")
            GUI:setStatus("💰 Оплата...", Color3.fromRGB(255, 200, 100))
            
            PaymentSystem:execute()
            
            if State.running then
                filteredItems = FilterEngine:sortAndFilter()
                GUI:updateList()
            end
        else
            GUI:addLog("⚠️ Нет доступных предметов")
        end
        
        -- Ожидание обновления
        log("\n⏳ Ожидание обновления магазина (10 мин)...")
        GUI:addLog("⏳ Ожидание обновления...")
        GUI:setStatus("⏳ Ожидание...", Color3.fromRGB(150, 150, 255))
        
        for i = 1, CONFIG.REFRESH_TIME do
            if not State.running then break end
            if i % 30 == 0 then
                local m = math.floor((CONFIG.REFRESH_TIME - i)/60)
                local s = (CONFIG.REFRESH_TIME - i) % 60
                log("   Осталось: " .. m .. "м " .. s .. "с")
            end
            if i % 2 == 0 and tick() - State.lastMoveTime >= CONFIG.MOVE_INTERVAL then
                local rd = Vector3.new(math.random(-2,2), 0, math.random(-2,2))
                humanoid:MoveTo(rootPart.Position + rd)
                State.lastMoveTime = tick()
            end
            task.wait(1)
        end
        
        log("🔄 Магазин обновлен. Следующий цикл...\n")
    end
    
    State.running = false
    Elements.StartBtn.Text = "▶️ ЗАПУСТИТЬ АВТОПОКУПКУ"
    Elements.StartBtn.BackgroundColor3 = CONFIG.THEME.accent
    GUI:setStatus("⏹️ Остановлено", Color3.fromRGB(200,200,200))
    GUI:addLog("⏹️ Система остановлена")
    log("👋 Скрипт завершен")
end

-- ============================================
-- 11. ИНИЦИАЛИЗАЦИЯ
-- ============================================

log("⚙️ Инициализация системы...")
Scanner:findShops()
Scanner:findClothes()
GUI:init()
GUI:updateStats()
GUI:updateList()

log("✅ Система v10.0 готова!")
log("📊 Магазинов: " .. #State.shopZones)
log("📊 Предметов: " .. #State.clothes)
log("💰 Фильтр цены: $" .. CONFIG.MIN_PRICE .. " - $" .. CONFIG.MAX_PRICE)
log("🎨 Активные редкости:")
for r, v in pairs(CONFIG.RARITY_FILTER) do if v then log("   ✅ " .. RARITY_DATA[r].name) end end
log("🖱️ Перетаскивайте окно за заголовок")
log("▶️ Нажмите кнопку в GUI для старта")

print("\n" .. string.rep("=", 60))
print(" АВТОПОКУПКА v10.0 ULTIMATE ЗАГРУЖЕНА")
print("✅ Умная навигация | ✅ Фильтры | ✅ Оплата | ✅ GUI")
print(string.rep("=", 60) .. "\n")
