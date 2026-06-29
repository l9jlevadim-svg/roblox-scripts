-- AUTOBUY v15.0
-- Pathfinding + price filter + 2 retries
-- ============================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

print("\n" .. string.rep("=", 80))
print("AUTOBUY v15.0 - Pathfinding + price filter")
print(string.rep("=", 80) .. "\n")

-- ============================================
-- SETTINGS
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
    MAX_RETRIES = 2,
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
    SHOP_FILTER = "",
    RARITY_BY_PRICE = {
        { min = 10000, rarity = "legendary" },
        { min = 5000,  rarity = "epic" },
        { min = 2000,  rarity = "rare" },
        { min = 500,   rarity = "uncommon" },
        { min = 0,     rarity = "common" }
    }
}

-- ============================================
-- RARITY COLORS & NAMES
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

-- ============================================
-- VARIABLES
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
-- CONFIG LOADING
-- ============================================
local function safeRequire(inst)
    if not inst then return nil end
    local ok, mod = pcall(require, inst)
    return ok and mod or nil
end

local Configs = ReplicatedStorage:FindFirstChild("Configs")
local ClothingConfig = safeRequire(ReplicatedStorage:FindFirstChild("ClothingConfig"))
local AccessoryCfg = safeRequire(Configs and Configs:FindFirstChild("AccessoryConfig"))

local NAME_INDEX = {}
if ClothingConfig or AccessoryCfg then
    local function addToIndex(name, fair, profile)
        if name and fair then
            NAME_INDEX[tostring(name):lower()] = { fair = fair, profile = profile or "normal" }
        end
    end
    if ClothingConfig and ClothingConfig.SHOP_ITEMS then
        local function scan(node, depth)
            if type(node) ~= "table" or depth > 6 then return end
            if node.name and (node.fairPrice or node.value) then
                addToIndex(node.name, node.fairPrice or node.value, node.economyProfile)
                return
            end
            for _, c in pairs(node) do scan(c, depth + 1) end
        end
        scan(ClothingConfig.SHOP_ITEMS, 0)
    end
    if AccessoryCfg then
        local function scanAcc(node, depth)
            if type(node) ~= "table" or depth > 6 then return end
            if node.name and (node.fairPrice or node.value) then
                addToIndex(node.name, node.fairPrice or node.value, node.economyProfile)
                return
            end
            for _, c in pairs(node) do scanAcc(c, depth + 1) end
        end
        scanAcc(AccessoryCfg, 0)
    end
    log("📚 Loaded price index: " .. table.maxn(NAME_INDEX) .. " items")
else
    log("⚠️ No configs found, will use SlotPriceReveal as fallback")
end

local function getFairPrice(name)
    local rec = NAME_INDEX[tostring(name or ""):lower()]
    return rec and rec.fair
end

local function rarityByPrice(price)
    for _, tier in ipairs(SETTINGS.RARITY_BY_PRICE) do
        if price >= tier.min then return tier.rarity end
    end
    return "common"
end

-- ============================================
-- UTILS
-- ============================================
local function findPosition(obj)
    local checkObj = obj
    for i = 1, 6 do
        if checkObj then
            if checkObj:IsA("BasePart") then return checkObj.CFrame.Position end
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

local function formatNumber(num)
    if num >= 1000000 then return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then return string.format("%.1fK", num / 1000)
    else return tostring(num) end
end

-- ============================================
-- FILTER (PRICE ONLY)
-- ============================================
local function shouldBuyItem(item)
    if not item.price then return false end

    if item.price < SETTINGS.MIN_PRICE or item.price > SETTINGS.MAX_PRICE then
        log("⛔ " .. item.name .. " excluded: price $" .. item.price .. " out of range " .. SETTINGS.MIN_PRICE .. "-" .. SETTINGS.MAX_PRICE)
        return false
    end

    if SETTINGS.NAME_FILTER ~= "" and not item.name:lower():find(SETTINGS.NAME_FILTER:lower()) then
        log("⛔ " .. item.name .. " excluded by name")
        return false
    end

    if SETTINGS.SHOP_FILTER ~= "" and not item.shop:lower():find(SETTINGS.SHOP_FILTER:lower()) then
        log("⛔ " .. item.name .. " excluded by shop")
        return false
    end

    return true
end

-- ============================================
-- CART SYNC
-- ============================================
local function getRealCartCount()
    if not player:FindFirstChild("PlayerGui") then return nil end
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local text = child.Text or ""
                local name = (child.Name or ""):lower()
                if name:find("cart") or name:find("item") or name:find("count") or name:find("total") then
                    local number = text:match("(%d+)")
                    if number then
                        local count = tonumber(number)
                        if count and count >= 0 and count <= 100 then return count end
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
            log("🔄 Sync: script=" .. takenCount .. " | real=" .. realCount)
            takenCount = realCount
        end
        return realCount
    end
    return takenCount
end

-- ============================================
-- PATHFINDING WALK
-- ============================================
local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then
        log("❌ walkTo: invalid params")
        return false
    end

    local startPos = rootPart.Position
    local totalDistance = getDistance(startPos, targetPos)
    log("🚀 Walking to target (" .. math.floor(totalDistance) .. " studs)")

    if totalDistance <= 3 then
        log("   ✅ Already close")
        return true
    end

    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER

    local pathParams = {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentMaxSlope = 45,
        Costs = { Water = 20 }
    }
    local path = PathfindingService:CreatePath(pathParams)

    local success, err = pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)
    if not success or path.Status ~= Enum.PathStatus.Success then
        log("   ⚠️ Path not built, trying direct walk")
    end

    local waypoints = path:GetWaypoints()
    if #waypoints == 0 then
        log("   ❌ No waypoints, teleporting...")
        rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
        task.wait(0.5)
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        return getDistance(rootPart.Position, targetPos) <= 3
    end

    local lastPosition = rootPart.Position
    local stuckTime = 0
    local currentWaypoint = 1
    local startTime = tick()
    local maxTime = math.min(totalDistance * 0.7, 45)

    while tick() - startTime < maxTime do
        if not running then
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
            return false
        end

        local currentPos = rootPart.Position
        local distToTarget = getDistance(currentPos, targetPos)
        if distToTarget <= 3 then break end

        if currentWaypoint <= #waypoints then
            local wp = waypoints[currentWaypoint]
            local wpDist = getDistance(currentPos, wp.Position)
            if wpDist <= 3 then
                currentWaypoint = currentWaypoint + 1
            else
                if wp.Action == Enum.PathWaypointAction.Jump then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                humanoid:MoveTo(wp.Position)
            end
        else
            humanoid:MoveTo(targetPos)
        end

        local moved = getDistance(currentPos, lastPosition)
        if moved < 0.5 then
            stuckTime = stuckTime + 0.2
        else
            stuckTime = 0
        end
        lastPosition = currentPos

        if stuckTime >= 4 then
            log("   ⚠️ Stuck! Teleporting to next waypoint...")
            local teleportPos = (currentWaypoint <= #waypoints and waypoints[currentWaypoint].Position) or targetPos
            rootPart.CFrame = CFrame.new(teleportPos + Vector3.new(0, 2, 0))
            stuckTime = 0
            task.wait(0.3)
            pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)
            waypoints = path:GetWaypoints()
            currentWaypoint = 1
        end

        task.wait(0.15)
    end

    if getDistance(rootPart.Position, targetPos) > 3 then
        log("   🔄 Final teleport to target")
        rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
        task.wait(0.5)
    end

    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    log("   ✅ Arrived!")
    return true
end

-- ============================================
-- SORT BY DISTANCE
-- ============================================
local function sortByDistance()
    if not rootPart then return end
    local currentPos = rootPart.Position
    table.sort(clothes, function(a, b)
        local distA = a.position and getDistance(currentPos, a.position) or math.huge
        local distB = b.position and getDistance(currentPos, b.position) or math.huge
        return distA < distB
    end)
    log("🎯 Sorted by distance")
end

-- ============================================
-- QUICK MOVE
-- ============================================
local function doQuickMove()
    local currentTime = tick()
    if currentTime - lastMoveTime >= SETTINGS.MOVE_INTERVAL then
        if humanoid and humanoid.Health > 0 then
            local randomDir = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
            humanoid:MoveTo(rootPart.Position + randomDir)
            lastMoveTime = currentTime
        end
    end
end

-- ============================================
-- FIND SHOPS & CLOTHES
-- ============================================
local function findShops()
    log("🔍 Searching shops...")
    shopZones = {}
    local patterns = {"Shop_ShopZone", "Shop_", "ClothingShop", "Store"}
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
    local count = 0
    for _ in pairs(shopZones) do count = count + 1 end
    log("📊 Total shops: " .. count)
end

local function findClothes()
    log("\n🔍 Searching clothes...")
    clothes = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local path = obj:GetFullName()
            local action = obj.ActionText or ""
            local inShop = path:find("Shop_") or path:find("Shop") or path:find("Store") or path:find("Clothing")
            if inShop and (action:find("Взять") or action:find("Take")) then
                local parent = obj.Parent
                local rawName = parent and parent.Name or "Item"
                local position = findPosition(obj) or findPosition(parent)
                local shopName = "Unknown"
                for name in path:gmatch("Shop_ShopZone_%d+") do shopName = name; break end
                if shopName == "Unknown" then
                    for name in path:gmatch("Shop_[%w_]+") do shopName = name; break end
                end
                local floor = "1st floor"
                if position and position.Y > 10 then floor = "2nd floor" end

                local fair = getFairPrice(rawName)
                local rarity = fair and rarityByPrice(fair) or nil
                local price = fair

                table.insert(clothes, {
                    obj = obj,
                    parent = parent,
                    name = rawName,
                    position = position,
                    shop = shopName,
                    floor = floor,
                    taken = false,
                    unavailable = false,
                    failedAttempts = 0,
                    rarity = rarity,
                    price = price,
                    slotRef = parent
                })

                if fair then
                    log("   📦 " .. rawName .. " | " .. (RARITY_NAMES[rarity] or "?") .. " | $" .. fair)
                end
            end
            if action:find("Поговорить") or action:find("поговорить") then
                if not seller then
                    seller = { obj = obj, position = findPosition(obj) }
                    log("🏪 Seller found")
                end
            end
        end
    end
    log("✅ Clothes found: " .. #clothes)
    log("   With config price: " .. (table.maxn(NAME_INDEX) > 0 and "yes" or "no"))
end

-- ============================================
-- PROMPT ACTIVATION
-- ============================================
local function activatePrompt(prompt)
    if not prompt then log("   ❌ prompt = nil"); return false end
    log("   🔘 Activating prompt...")
    local promptPos = findPosition(prompt) or findPosition(prompt.Parent)
    if promptPos then
        local dist = getDistance(rootPart.Position, promptPos)
        log("   📍 Distance: " .. math.floor(dist) .. " studs")
        if dist > SETTINGS.PROMPT_ACTIVATE_DISTANCE then
            log("   🚶 Moving closer...")
            walkTo(promptPos)
            task.wait(0.5)
        end
    end
    if fireproximityprompt then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then log("   ✅ fireproximityprompt"); return true end
    end
    local ok = pcall(function() prompt:InputHoldBegin(); task.wait(1.5); prompt:InputHoldEnd() end)
    if ok then log("   ✅ InputHold"); return true end
    log("   ❌ Failed"); return false
end

-- ============================================
-- TRY TAKE ITEM (2 RETRIES)
-- ============================================
local function tryTakeItem(item)
    log("🎯 Taking: " .. item.name .. " [" .. (RARITY_NAMES[item.rarity] or item.rarity) .. "] $" .. item.price)
    if item.unavailable then return false end
    if not item.obj or not item.obj.Parent then
        log("   ❌ Prompt disappeared"); item.unavailable = true; return false
    end
    for attempt = 1, SETTINGS.MAX_RETRIES do
        if not running then return false end
        if attempt > 1 then
            log("    Attempt #" .. attempt)
            task.wait(SETTINGS.RETRY_DELAY)
            if not item.obj or not item.obj.Parent then
                log("   ❌ Prompt disappeared"); item.unavailable = true; return false
            end
        end
        local activated = activatePrompt(item.obj)
        if activated then
            log("   ✅ Taken!"); item.failedAttempts = 0; return true
        end
        log("   ❌ Attempt #" .. attempt .. " failed")
    end
    log("   ❌ All attempts failed")
    item.failedAttempts = item.failedAttempts + 1
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then item.unavailable = true end
    return false
end

-- ============================================
-- PAYMENT
-- ============================================
local function pay()
    log("\n💳 PAYMENT...")
    local confirmPurchase = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirmPurchase then confirmPurchase = confirmPurchase:FindFirstChild("ConfirmPurchase") end
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
    log("   ❌ Failed"); return false
end

-- ============================================
-- GUI (FULL)
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v15"
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
titleLabel.Text = " AutoBuy v15.0 | Pathfinding"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
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

-- Draggable
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

-- Filters
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
filterTitle.Text = " FILTERS (green = ON, gray = OFF)"
filterTitle.TextColor3 = Color3.new(1, 1, 1)
filterTitle.Font = Enum.Font.GothamBold
filterTitle.TextSize = 12
filterTitle.TextXAlignment = Enum.TextXAlignment.Left
filterTitle.Parent = filterFrame

-- Rarity buttons (cosmetic only now)
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
        log("Rarity " .. RARITY_NAMES[rarity] .. ": " .. tostring(SETTINGS.RARITY_FILTER[rarity]))
        updateList()
    end)
    rarityButtons[rarity] = btn
end

-- Price min
local priceMinLabel = Instance.new("TextLabel")
priceMinLabel.Size = UDim2.new(0.15, 0, 0, 25)
priceMinLabel.Position = UDim2.new(0, 5, 0, 60)
priceMinLabel.BackgroundTransparency = 1
priceMinLabel.Text = "💰 Min:"
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
        log("💰 Min price: $" .. newPrice)
        updateList()
    end
end)

-- Price max
local priceMaxLabel = Instance.new("TextLabel")
priceMaxLabel.Size = UDim2.new(0.15, 0, 0, 25)
priceMaxLabel.Position = UDim2.new(0.35, 5, 0, 60)
priceMaxLabel.BackgroundTransparency = 1
priceMaxLabel.Text = "Max:"
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
        log("💰 Max price: $" .. newPrice)
        updateList()
    end
end)

-- Name filter
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.2, 0, 0, 25)
nameLabel.Position = UDim2.new(0, 5, 0, 90)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "🔍 Name:"
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
nameInput.PlaceholderText = "all"
nameInput.Font = Enum.Font.Gotham
nameInput.TextSize = 11
nameInput.Parent = filterFrame
Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 4)
nameInput.FocusLost:Connect(function()
    SETTINGS.NAME_FILTER = nameInput.Text
    log("🔍 Name filter: " .. (SETTINGS.NAME_FILTER ~= "" and SETTINGS.NAME_FILTER or "all"))
    updateList()
end)

-- Shop filter
local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(0.2, 0, 0, 25)
shopLabel.Position = UDim2.new(0.5, 5, 0, 90)
shopLabel.BackgroundTransparency = 1
shopLabel.Text = "🏪 Shop:"
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
shopInput.PlaceholderText = "all"
shopInput.Font = Enum.Font.Gotham
shopInput.TextSize = 11
shopInput.Parent = filterFrame
Instance.new("UICorner", shopInput).CornerRadius = UDim.new(0, 4)
shopInput.FocusLost:Connect(function()
    SETTINGS.SHOP_FILTER = shopInput.Text
    log("🏪 Shop filter: " .. (SETTINGS.SHOP_FILTER ~= "" and SETTINGS.SHOP_FILTER or "all"))
    updateList()
end)

-- Filter stats
local filterStats = Instance.new("TextLabel")
filterStats.Size = UDim2.new(1, -10, 0, 20)
filterStats.Position = UDim2.new(0, 5, 0, 120)
filterStats.BackgroundTransparency = 1
filterStats.Text = "Total: 0 | Filtered: 0"
filterStats.TextColor3 = Color3.fromRGB(200, 200, 200)
filterStats.Font = Enum.Font.Gotham
filterStats.TextSize = 10
filterStats.TextXAlignment = Enum.TextXAlignment.Left
filterStats.Parent = filterFrame

-- Stats
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
takenLabel.Text = " Taken: 0/" .. SETTINGS.MAX_TOTAL
takenLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
takenLabel.Font = Enum.Font.GothamBold
takenLabel.TextSize = 12
takenLabel.TextXAlignment = Enum.TextXAlignment.Left
takenLabel.Parent = statsFrame

local paidLabel = Instance.new("TextLabel")
paidLabel.Size = UDim2.new(0.33, -5, 0.5, 0)
paidLabel.Position = UDim2.new(0.33, 5, 0, 0)
paidLabel.BackgroundTransparency = 1
paidLabel.Text = "💳 Paid: 0"
paidLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
paidLabel.Font = Enum.Font.GothamBold
paidLabel.TextSize = 12
paidLabel.TextXAlignment = Enum.TextXAlignment.Left
paidLabel.Parent = statsFrame

local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(0.33, -5, 0.5, 0)
totalLabel.Position = UDim2.new(0.66, 5, 0, 0)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = "📊 Cycles: 0"
totalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
totalLabel.Font = Enum.Font.GothamBold
totalLabel.TextSize = 12
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Parent = statsFrame

local itemsLabel = Instance.new("TextLabel")
itemsLabel.Size = UDim2.new(0.5, -5, 0.5, 0)
itemsLabel.Position = UDim2.new(0, 5, 0.5, 0)
itemsLabel.BackgroundTransparency = 1
itemsLabel.Text = "👕 Bought: 0"
itemsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
itemsLabel.Font = Enum.Font.Gotham
itemsLabel.TextSize = 11
itemsLabel.TextXAlignment = Enum.TextXAlignment.Left
itemsLabel.Parent = statsFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.5, -5, 0.5, 0)
moneyLabel.Position = UDim2.new(0.5, 5, 0.5, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "💰 Spent: $0"
moneyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
moneyLabel.Font = Enum.Font.Gotham
moneyLabel.TextSize = 11
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = statsFrame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 55)
startBtn.Position = UDim2.new(0, 10, 0, 300)
startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
startBtn.Text = "▶️ START"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 360)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🟢 Ready"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 100)
logLabel.Position = UDim2.new(0, 10, 0, 395)
logLabel.BackgroundTransparency = 1
logLabel.Text = " Log:"
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
    logLabel.Text = "📋 Log:\n" .. table.concat(logText, "\n")
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
    takenLabel.Text = "🛒 Taken: " .. takenCount .. "/" .. SETTINGS.MAX_TOTAL
    paidLabel.Text = "💳 Paid: " .. paidCount
    totalLabel.Text = "📊 Cycles: " .. cycleCount
    itemsLabel.Text = "👕 Bought: " .. totalItemsBought
    moneyLabel.Text = "💰 Spent: $" .. formatNumber(totalMoneySpent)
end

local function getFilteredItems()
    local filtered = {}
    for _, item in ipairs(clothes) do
        if not item.taken and not item.unavailable then
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
    filterStats.Text = "Total: " .. #clothes .. " | Filtered: " .. #filtered
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
        nameLabel.Text = "📦 " .. (item.name or "??")
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -15, 0, 18)
        infoLabel.Position = UDim2.new(0, 10, 0, 23)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = item.shop .. " | " .. item.floor .. " | $" .. (item.price or "?")
        infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 10
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = itemFrame

        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, -15, 0, 18)
        rarityLabel.Position = UDim2.new(0, 10, 0, 41)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = RARITY_NAMES[item.rarity] or "?"
        rarityLabel.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150)
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.TextSize = 10
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
        rarityLabel.Parent = itemFrame
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- ============================================
-- GO TO PAY
-- ============================================
local function goToPay()
    log("\n💰 === PAYMENT PROCESS ===")
    addLog("💰 Going to seller...")
    statusLabel.Text = "💰 Payment..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

    syncCart()
    if takenCount == 0 then
        log("❌ Cart empty!")
        addLog("❌ Empty, skipping payment")
        return
    end
    if not seller then
        log("❌ Seller not found!")
        addLog("❌ No seller")
        return
    end
    log("🛒 Cart: " .. takenCount .. " items")
    if seller.position then
        log("🚶 Moving to seller...")
        walkTo(seller.position)
        task.wait(1)
    end
    log("💬 Talking...")
    addLog("💬 Talking...")
    statusLabel.Text = "💬 Talking..."
    activatePrompt(seller.obj)
    task.wait(2)
    log("💳 Paying...")
    addLog("💳 Paying...")
    statusLabel.Text = "💳 Paying..."
    local paid = pay()
    if paid then
        paidCount = paidCount + 1
        totalItemsBought = totalItemsBought + takenCount
        cycleCount = cycleCount + 1
        takenCount = 0
        log("✅ PAYMENT SUCCESSFUL! (" .. paidCount .. ")")
        addLog("✅ Paid! (" .. paidCount .. ")")
        updateStats()
        task.wait(2)
    else
        log("⚠️  Retrying...")
        task.wait(1)
        paid = pay()
        if paid then
            paidCount = paidCount + 1
            totalItemsBought = totalItemsBought + takenCount
            cycleCount = cycleCount + 1
            takenCount = 0
            log("✅ PAYMENT SUCCESSFUL on 2nd attempt!")
            addLog("✅ Paid! (" .. paidCount .. ")")
            updateStats()
        else
            log("❌ PAYMENT FAILED!")
            addLog("❌ Payment failed!")
        end
    end
end

-- ============================================
-- MAIN LOOP
-- ============================================
local function mainLoop()
    log("\n🚀 STARTING MAIN LOOP!")
    while running do
        -- Reset
        for _, item in ipairs(clothes) do
            item.taken = false
            item.unavailable = false
            item.failedAttempts = 0
        end
        shopLimits = {}
        takenCount = 0
        lastTakeTime = 0
        lastMoveTime = tick()

        log("\n🎯 Sorting by distance...")
        addLog("🎯 Sorting...")
        sortByDistance()
        updateList()
        addLog("🔄 New cycle!")
        statusLabel.Text = "🔄 Starting..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

        local shouldPay = false
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken or item.unavailable then continue end

            syncCart()
            if takenCount >= SETTINGS.MAX_TOTAL then
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

            -- Apply filter if price known
            if item.price and not shouldBuyItem(item) then
                addLog("⛔ " .. item.name .. " filtered out")
                updateList()
                continue
            end

            -- Walk to item
            if item.position then
                walkTo(item.position)
                task.wait(0.3)
            end

            addLog("🤖 Taking...")
            statusLabel.Text = "🤖 Taking " .. item.name
            local success = tryTakeItem(item)
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                totalMoneySpent = totalMoneySpent + (item.price or 0)
                log("✅ Taken! [" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. "]")
                addLog("✅ " .. item.name .. " (" .. takenCount .. "/" .. SETTINGS.MAX_TOTAL .. ")")
                updateStats()
                updateList()
                syncCart()
                if takenCount >= SETTINGS.MAX_TOTAL then
                    shouldPay = true
                    break
                end
            else
                addLog("❌ " .. item.name)
            end
            task.wait(0.3)
        end

        if shouldPay or takenCount > 0 then
            log("\n⚡ PROCEED TO PAYMENT (taken: " .. takenCount .. ")")
            goToPay()
            if running then
                sortByDistance()
                updateList()
            end
        else
            addLog("❌ Nothing to take")
        end

        log("\n⏳ Waiting " .. SETTINGS.REFRESH_TIME .. " sec...")
        addLog("⏳ Waiting " .. SETTINGS.REFRESH_TIME .. "s...")
        statusLabel.Text = "⏳ Waiting..."
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        for i = 1, SETTINGS.REFRESH_TIME do
            if not running then break end
            if i % 30 == 0 then
                local mins = math.floor((SETTINGS.REFRESH_TIME - i) / 60)
                local secs = (SETTINGS.REFRESH_TIME - i) % 60
                log("   Remaining: " .. mins .. "m " .. secs .. "s")
            end
            if i % 2 == 0 then doQuickMove() end
            task.wait(1)
        end
        log("🔄 Shop refreshed!\n")
    end
    running = false
    startBtn.Text = "▶️ START"
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    addLog("⏹️ Stopped")
end

startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "▶️ START"
        startBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    else
        running = true
        startBtn.Text = "⏹️ STOP"
        startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        sortByDistance()
        updateList()
        task.spawn(mainLoop)
    end
end)

-- Init
findShops()
findClothes()
sortByDistance()
updateStats()
updateList()

print("\n" .. string.rep("=", 80))
print("✅ Script v15.0 loaded!")
print("🧭 Pathfinding active")
print("💰 Filter: price only")
print("🔄 Retries: 2")
print(string.rep("=", 80) .. "\n")
