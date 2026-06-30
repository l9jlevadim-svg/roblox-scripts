-- clean v15.8 avoid head-level obstacles
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
print("AUTOBUY v15.8")
print(string.rep("=", 80) .. "\n")
local SETTINGS = {
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
    REFRESH_TIME = 600,
    RETRY_DELAY = 1,
    SUCCESS_DELAY = 4,
    FAIL_DELAY = 1,
    MOVE_INTERVAL = 2,
    WALK_SPEED = 18,
    JUMP_POWER = 50,
    PROMPT_ACTIVATE_DISTANCE = 5,
    MAX_RETRIES = 2,
    MAX_FAILED_ATTEMPTS = 2,
    MIN_PRICE = 0,
    MAX_PRICE = 999999,
    NAME_FILTER = "",
    SHOP_FILTER = "",
    OBSTACLE_CHECK_DIST = 3,    -- уменьшили, чтобы раньше реагировать на вешалки
    SIDE_STEP_DIST = 5,
    STUCK_TIMEOUT = 3,
    RARITY_BY_PRICE = {
        { min = 10000, rarity = "legendary" },
        { min = 5000,  rarity = "epic" },
        { min = 2000,  rarity = "rare" },
        { min = 500,   rarity = "uncommon" },
        { min = 0,     rarity = "common" }
    }
}
local RARITY_COLORS = {
    common = Color3.fromRGB(150,150,150),
    uncommon = Color3.fromRGB(50,200,50),
    rare = Color3.fromRGB(50,100,255),
    epic = Color3.fromRGB(180,50,255),
    legendary = Color3.fromRGB(255,200,50)
}
local RARITY_NAMES = {
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary"
}
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
local function log(msg)
    print("[AutoBuy] " .. msg)
end
local function formatNumber(num)
    if num >= 1000000 then return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then return string.format("%.1fK", num / 1000)
    else return tostring(num) end
end
local function shouldBuyItem(item)
    if not item.price then return false end
    if item.price < SETTINGS.MIN_PRICE or item.price > SETTINGS.MAX_PRICE then
        return false
    end
    if SETTINGS.NAME_FILTER ~= "" and not item.name:lower():find(SETTINGS.NAME_FILTER:lower()) then
        return false
    end
    if SETTINGS.SHOP_FILTER ~= "" and not item.shop:lower():find(SETTINGS.SHOP_FILTER:lower()) then
        return false
    end
    return true
end
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
            takenCount = realCount
        end
        return realCount
    end
    return takenCount
end

-- ============================================
-- УМНЫЙ ОБХОД ПРЕПЯТСТВИЙ (с учётом вешалок на уровне головы)
-- ============================================
local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then return false end
    local startPos = rootPart.Position
    local totalDistance = getDistance(startPos, targetPos)
    if totalDistance <= 3 then return true end

    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentMaxSlope = 45,
        Costs = { Water = 20 }
    })
    local pathSuccess = pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end) and path.Status == Enum.PathStatus.Success
    local waypoints = pathSuccess and path:GetWaypoints() or {}
    local usePath = pathSuccess and #waypoints > 0

    local lastPosition = rootPart.Position
    local stuckTime = 0
    local currentWaypoint = 1
    local startTime = tick()
    local maxTime = math.min(totalDistance * 0.8, 60)

    local avoidDirection = nil
    local avoidTimer = 0

    while tick() - startTime < maxTime do
        if not running then
            humanoid.WalkSpeed = originalWalkSpeed
            humanoid.JumpPower = originalJumpPower
            return false
        end

        local currentPos = rootPart.Position
        local distToTarget = getDistance(currentPos, targetPos)
        if distToTarget <= 3 then break end

        local moved = getDistance(currentPos, lastPosition)
        if moved < 0.3 then
            stuckTime = stuckTime + 0.15
        else
            stuckTime = 0
            avoidDirection = nil
            avoidTimer = 0
        end
        lastPosition = currentPos

        local dirToTarget = (targetPos - currentPos).Unit
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {character}

        -- Лучи на двух уровнях: грудь и голова
        local lowRayOrigin = currentPos + Vector3.new(0, 1.5, 0)
        local highRayOrigin = currentPos + Vector3.new(0, 2.5, 0)
        local frontLowRay = workspace:Raycast(lowRayOrigin, dirToTarget * SETTINGS.OBSTACLE_CHECK_DIST, rayParams)
        local frontHighRay = workspace:Raycast(highRayOrigin, dirToTarget * SETTINGS.OBSTACLE_CHECK_DIST, rayParams)
        local blockedLow = frontLowRay ~= nil
        local blockedHigh = frontHighRay ~= nil

        if usePath and stuckTime < 1 and not avoidDirection then
            if currentWaypoint <= #waypoints then
                local wp = waypoints[currentWaypoint]
                if getDistance(currentPos, wp.Position) <= 4 then
                    currentWaypoint = currentWaypoint + 1
                else
                    humanoid:MoveTo(wp.Position)
                end
            else
                humanoid:MoveTo(targetPos)
            end
        elseif blockedLow or blockedHigh or stuckTime >= 1 then
            if stuckTime >= 1 then
                log("Stuck, finding alternative route")
            end

            if not avoidDirection then
                local right = dirToTarget:Cross(Vector3.new(0,1,0)).Unit
                local left = -right

                -- Проверяем свободное пространство на обоих уровнях
                local function isSideClear(sideDir)
                    local lowSideRay = workspace:Raycast(lowRayOrigin, sideDir * SETTINGS.SIDE_STEP_DIST, rayParams)
                    local highSideRay = workspace:Raycast(highRayOrigin, sideDir * SETTINGS.SIDE_STEP_DIST, rayParams)
                    return lowSideRay == nil and highSideRay == nil
                end
                local rightFree = isSideClear(right)
                local leftFree = isSideClear(left)

                if rightFree and leftFree then
                    local angleRight = math.acos(math.clamp(right:Dot(dirToTarget), -1, 1))
                    local angleLeft = math.acos(math.clamp(left:Dot(dirToTarget), -1, 1))
                    avoidDirection = angleRight < angleLeft and right or left
                elseif rightFree then
                    avoidDirection = right
                elseif leftFree then
                    avoidDirection = left
                else
                    local backDir = -dirToTarget
                    humanoid:MoveTo(currentPos + backDir * 3)
                    task.wait(0.5)
                    avoidDirection = right
                end
                avoidTimer = tick()
            end

            local moveDir = (avoidDirection + dirToTarget * 0.3).Unit
            humanoid:MoveTo(currentPos + moveDir * SETTINGS.SIDE_STEP_DIST)

            if tick() - avoidTimer > 1.5 then
                avoidDirection = nil
                avoidTimer = 0
            end
        else
            humanoid:MoveTo(targetPos)
        end

        if stuckTime >= 2 and moved < 0.1 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        if usePath and currentWaypoint <= #waypoints then
            local wp = waypoints[currentWaypoint]
            if wp and getDistance(currentPos, wp.Position) > 15 then
                local newPath = PathfindingService:CreatePath({
                    AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentMaxSlope = 45, Costs = { Water = 20 }
                })
                local ok = pcall(function() newPath:ComputeAsync(currentPos, targetPos) end)
                if ok and newPath.Status == Enum.PathStatus.Success then
                    path = newPath
                    waypoints = newPath:GetWaypoints()
                    currentWaypoint = 1
                else
                    usePath = false
                end
            end
        end

        task.wait(0.1)
    end

    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    if getDistance(rootPart.Position, targetPos) > 3 then
        humanoid:MoveTo(targetPos)
        task.wait(0.5)
    end
    return getDistance(rootPart.Position, targetPos) <= 3
end

local function sortByDistance()
    if not rootPart then return end
    local currentPos = rootPart.Position
    table.sort(clothes, function(a, b)
        local distA = a.position and getDistance(currentPos, a.position) or math.huge
        local distB = b.position and getDistance(currentPos, b.position) or math.huge
        return distA < distB
    end)
end
local function doQuickMove()
    local currentTime = tick()
    if currentTime - lastMoveTime >= SETTINGS.MOVE_INTERVAL then
        if humanoid and humanoid.Health > 0 then
            humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-2,2),0,math.random(-2,2)))
            lastMoveTime = currentTime
        end
    end
end
local function findShops()
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
end
local function findClothes()
    clothes = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local path = obj:GetFullName()
            local action = obj.ActionText or ""
            if (path:find("Shop_") or path:find("Shop") or path:find("Store") or path:find("Clothing")) and (action:find("Take") or action:find("Взять")) then
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
                    obj = obj, parent = parent, name = rawName,
                    position = position, shop = shopName, floor = floor,
                    taken = false, unavailable = false, failedAttempts = 0,
                    rarity = rarity, price = price, slotRef = parent
                })
            end
            if action:find("Поговорить") or action:find("Talk") then
                if not seller then
                    seller = { obj = obj, position = findPosition(obj) }
                end
            end
        end
    end
end
local function activatePrompt(prompt)
    if not prompt then return false end
    local promptPos = findPosition(prompt) or findPosition(prompt.Parent)
    if promptPos then
        if getDistance(rootPart.Position, promptPos) > SETTINGS.PROMPT_ACTIVATE_DISTANCE then
            walkTo(promptPos)
            task.wait(0.5)
        end
    end
    if fireproximityprompt then
        if pcall(function() fireproximityprompt(prompt) end) then return true end
    end
    return pcall(function() prompt:InputHoldBegin(); task.wait(1.5); prompt:InputHoldEnd() end)
end
local function tryTakeItem(item)
    if item.unavailable then return false end
    if not item.obj or not item.obj.Parent then item.unavailable = true; return false end
    for attempt = 1, SETTINGS.MAX_RETRIES do
        if not running then return false end
        if attempt > 1 then
            log("Retrying in " .. SETTINGS.RETRY_DELAY .. "s...")
            task.wait(SETTINGS.RETRY_DELAY)
            if not item.obj or not item.obj.Parent then item.unavailable = true; return false end
        end
        if activatePrompt(item.obj) then item.failedAttempts = 0; return true end
        log("Attempt " .. attempt .. " failed")
    end
    item.failedAttempts = item.failedAttempts + 1
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then item.unavailable = true end
    return false
end
local function pay()
    local confirmPurchase = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirmPurchase then confirmPurchase = confirmPurchase:FindFirstChild("ConfirmPurchase") end
    if confirmPurchase and pcall(function() confirmPurchase:FireServer() end) then return true end
    if player:FindFirstChild("PlayerGui") then
        local shopGUI = player.PlayerGui:FindFirstChild("ShopGUI")
        if shopGUI then
            local buyButton = shopGUI:FindFirstChild("BuyButton", true)
            if buyButton and buyButton:IsA("TextButton") then
                local pos = buyButton.AbsolutePosition
                local size = buyButton.AbsoluteSize
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2))
                return true
            end
        end
    end
    return false
end
-- GUI (тот же, что в v15.7, без кнопок редкости, только цена)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v15"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 750, 0, 850)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(10,10,10)
frame.BorderSizePixel = 0
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,55)
titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,-45,1,0)
titleLabel.Position = UDim2.new(0,10,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = " AutoBuy v15.8 | Price filter"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-45,0,7)
closeBtn.BackgroundColor3 = Color3.fromRGB(220,50,50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
closeBtn.MouseButton1Click:Connect(function() running = false screenGui:Destroy() end)
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil
local function updateDrag(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput then updateDrag(input) end
end)

local filterFrame = Instance.new("Frame")
filterFrame.Size = UDim2.new(1,-20,0,90)
filterFrame.Position = UDim2.new(0,10,0,60)
filterFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
filterFrame.Parent = frame
Instance.new("UICorner", filterFrame).CornerRadius = UDim.new(0,8)

local filterTitle = Instance.new("TextLabel")
filterTitle.Size = UDim2.new(1,-10,0,20)
filterTitle.Position = UDim2.new(0,5,0,0)
filterTitle.BackgroundTransparency = 1
filterTitle.Text = " Price filter (Min / Max)"
filterTitle.TextColor3 = Color3.new(1,1,1)
filterTitle.Font = Enum.Font.GothamBold
filterTitle.TextSize = 11
filterTitle.TextXAlignment = Enum.TextXAlignment.Left
filterTitle.Parent = filterFrame

local priceMinLabel = Instance.new("TextLabel")
priceMinLabel.Size = UDim2.new(0.15,0,0,25)
priceMinLabel.Position = UDim2.new(0,5,0,25)
priceMinLabel.BackgroundTransparency = 1
priceMinLabel.Text = "Min $"
priceMinLabel.TextColor3 = Color3.new(1,1,1)
priceMinLabel.Font = Enum.Font.GothamBold
priceMinLabel.TextSize = 11
priceMinLabel.TextXAlignment = Enum.TextXAlignment.Left
priceMinLabel.Parent = filterFrame
local priceMinInput = Instance.new("TextBox")
priceMinInput.Size = UDim2.new(0.15,0,0,25)
priceMinInput.Position = UDim2.new(0.15,5,0,25)
priceMinInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
priceMinInput.TextColor3 = Color3.new(1,1,1)
priceMinInput.Text = tostring(SETTINGS.MIN_PRICE)
priceMinInput.Font = Enum.Font.Gotham
priceMinInput.TextSize = 11
priceMinInput.Parent = filterFrame
Instance.new("UICorner", priceMinInput).CornerRadius = UDim.new(0,4)
priceMinInput.FocusLost:Connect(function()
    local newPrice = tonumber(priceMinInput.Text)
    if newPrice then SETTINGS.MIN_PRICE = newPrice updateList() end
end)

local priceMaxLabel = Instance.new("TextLabel")
priceMaxLabel.Size = UDim2.new(0.15,0,0,25)
priceMaxLabel.Position = UDim2.new(0.35,5,0,25)
priceMaxLabel.BackgroundTransparency = 1
priceMaxLabel.Text = "Max $"
priceMaxLabel.TextColor3 = Color3.new(1,1,1)
priceMaxLabel.Font = Enum.Font.GothamBold
priceMaxLabel.TextSize = 11
priceMaxLabel.TextXAlignment = Enum.TextXAlignment.Left
priceMaxLabel.Parent = filterFrame
local priceMaxInput = Instance.new("TextBox")
priceMaxInput.Size = UDim2.new(0.15,0,0,25)
priceMaxInput.Position = UDim2.new(0.5,5,0,25)
priceMaxInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
priceMaxInput.TextColor3 = Color3.new(1,1,1)
priceMaxInput.Text = tostring(SETTINGS.MAX_PRICE)
priceMaxInput.Font = Enum.Font.Gotham
priceMaxInput.TextSize = 11
priceMaxInput.Parent = filterFrame
Instance.new("UICorner", priceMaxInput).CornerRadius = UDim.new(0,4)
priceMaxInput.FocusLost:Connect(function()
    local newPrice = tonumber(priceMaxInput.Text)
    if newPrice then SETTINGS.MAX_PRICE = newPrice updateList() end
end)

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.2,0,0,25)
nameLabel.Position = UDim2.new(0,5,0,55)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Name:"
nameLabel.TextColor3 = Color3.new(1,1,1)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 11
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = filterFrame
local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(0.3,0,0,25)
nameInput.Position = UDim2.new(0.2,5,0,55)
nameInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
nameInput.TextColor3 = Color3.new(1,1,1)
nameInput.Text = SETTINGS.NAME_FILTER
nameInput.PlaceholderText = "all"
nameInput.Font = Enum.Font.Gotham
nameInput.TextSize = 11
nameInput.Parent = filterFrame
Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0,4)
nameInput.FocusLost:Connect(function()
    SETTINGS.NAME_FILTER = nameInput.Text updateList()
end)

local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(0.2,0,0,25)
shopLabel.Position = UDim2.new(0.5,5,0,55)
shopLabel.BackgroundTransparency = 1
shopLabel.Text = "Shop:"
shopLabel.TextColor3 = Color3.new(1,1,1)
shopLabel.Font = Enum.Font.GothamBold
shopLabel.TextSize = 11
shopLabel.TextXAlignment = Enum.TextXAlignment.Left
shopLabel.Parent = filterFrame
local shopInput = Instance.new("TextBox")
shopInput.Size = UDim2.new(0.3,0,0,25)
shopInput.Position = UDim2.new(0.7,5,0,55)
shopInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
shopInput.TextColor3 = Color3.new(1,1,1)
shopInput.Text = SETTINGS.SHOP_FILTER
shopInput.PlaceholderText = "all"
shopInput.Font = Enum.Font.Gotham
shopInput.TextSize = 11
shopInput.Parent = filterFrame
Instance.new("UICorner", shopInput).CornerRadius = UDim.new(0,4)
shopInput.FocusLost:Connect(function()
    SETTINGS.SHOP_FILTER = shopInput.Text updateList()
end)

local filterStats = Instance.new("TextLabel")
filterStats.Size = UDim2.new(1,-10,0,20)
filterStats.Position = UDim2.new(0,5,0,120)
filterStats.BackgroundTransparency = 1
filterStats.Text = "Total: 0 | Filtered: 0"
filterStats.TextColor3 = Color3.fromRGB(200,200,200)
filterStats.Font = Enum.Font.Gotham
filterStats.TextSize = 10
filterStats.TextXAlignment = Enum.TextXAlignment.Left
filterStats.Parent = frame
filterStats.Position = UDim2.new(0,10,0,155)

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1,-20,0,80)
statsFrame.Position = UDim2.new(0,10,0,180)
statsFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
statsFrame.Parent = frame
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0,8)
local takenLabel = Instance.new("TextLabel")
takenLabel.Size = UDim2.new(0.33,-5,0.5,0)
takenLabel.Position = UDim2.new(0,5,0,0)
takenLabel.BackgroundTransparency = 1
takenLabel.Text = " Taken: 0/" .. SETTINGS.MAX_TOTAL
takenLabel.TextColor3 = Color3.fromRGB(255,200,100)
takenLabel.Font = Enum.Font.GothamBold
takenLabel.TextSize = 12
takenLabel.TextXAlignment = Enum.TextXAlignment.Left
takenLabel.Parent = statsFrame
local paidLabel = Instance.new("TextLabel")
paidLabel.Size = UDim2.new(0.33,-5,0.5,0)
paidLabel.Position = UDim2.new(0.33,5,0,0)
paidLabel.BackgroundTransparency = 1
paidLabel.Text = " Paid: 0"
paidLabel.TextColor3 = Color3.fromRGB(100,200,255)
paidLabel.Font = Enum.Font.GothamBold
paidLabel.TextSize = 12
paidLabel.TextXAlignment = Enum.TextXAlignment.Left
paidLabel.Parent = statsFrame
local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(0.33,-5,0.5,0)
totalLabel.Position = UDim2.new(0.66,5,0,0)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = " Cycles: 0"
totalLabel.TextColor3 = Color3.fromRGB(200,200,200)
totalLabel.Font = Enum.Font.GothamBold
totalLabel.TextSize = 12
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Parent = statsFrame
local itemsLabel = Instance.new("TextLabel")
itemsLabel.Size = UDim2.new(0.5,-5,0.5,0)
itemsLabel.Position = UDim2.new(0,5,0.5,0)
itemsLabel.BackgroundTransparency = 1
itemsLabel.Text = " Bought: 0"
itemsLabel.TextColor3 = Color3.fromRGB(180,180,180)
itemsLabel.Font = Enum.Font.Gotham
itemsLabel.TextSize = 11
itemsLabel.TextXAlignment = Enum.TextXAlignment.Left
itemsLabel.Parent = statsFrame
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.5,-5,0.5,0)
moneyLabel.Position = UDim2.new(0.5,5,0.5,0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = " Spent: $0"
moneyLabel.TextColor3 = Color3.fromRGB(180,180,180)
moneyLabel.Font = Enum.Font.Gotham
moneyLabel.TextSize = 11
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = statsFrame
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1,-20,0,55)
startBtn.Position = UDim2.new(0,10,0,270)
startBtn.BackgroundColor3 = Color3.fromRGB(80,200,80)
startBtn.Text = "START"
startBtn.TextColor3 = Color3.new(0,0,0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,10)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-20,0,30)
statusLabel.Position = UDim2.new(0,10,0,330)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = Color3.fromRGB(100,255,100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1,-20,0,100)
logLabel.Position = UDim2.new(0,10,0,365)
logLabel.BackgroundTransparency = 1
logLabel.Text = " Log:"
logLabel.TextColor3 = Color3.fromRGB(180,180,180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.Parent = frame
local logText = {}
local function addLog(msg)
    table.insert(logText, msg)
    if #logText > 7 then table.remove(logText, 1) end
    logLabel.Text = "Log:\n" .. table.concat(logText, "\n")
end
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,-20,1,-475)
scrollFrame.Position = UDim2.new(0,10,0,470)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0,8)
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0,4)
listLayout.Parent = scrollFrame
local function updateStats()
    takenLabel.Text = "Taken: " .. takenCount .. "/" .. SETTINGS.MAX_TOTAL
    paidLabel.Text = "Paid: " .. paidCount
    totalLabel.Text = "Cycles: " .. cycleCount
    itemsLabel.Text = "Bought: " .. totalItemsBought
    moneyLabel.Text = "Spent: $" .. formatNumber(totalMoneySpent)
end
local function getFilteredItems()
    local filtered = {}
    for _, item in ipairs(clothes) do
        if not item.taken and not item.unavailable then
            if shouldBuyItem(item) then
                table.insert(filtered, item)
            end
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
        itemFrame.Size = UDim2.new(1,-10,0,65)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0,8)
        local rarityBar = Instance.new("Frame")
        rarityBar.Size = UDim2.new(0,4,1,0)
        rarityBar.BackgroundColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150,150,150)
        rarityBar.Parent = itemFrame
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1,-15,0,20)
        nameLabel.Position = UDim2.new(0,10,0,3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name or "??"
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1,-15,0,18)
        infoLabel.Position = UDim2.new(0,10,0,23)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = item.shop .. " | " .. item.floor .. " | $" .. (item.price or "?")
        infoLabel.TextColor3 = Color3.fromRGB(180,180,180)
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 10
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = itemFrame
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1,-15,0,18)
        rarityLabel.Position = UDim2.new(0,10,0,41)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = RARITY_NAMES[item.rarity] or "?"
        rarityLabel.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150,150,150)
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.TextSize = 10
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
        rarityLabel.Parent = itemFrame
    end
    scrollFrame.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 10)
end
local function goToPay()
    if takenCount == 0 then return end
    if not seller then return end
    if seller.position then walkTo(seller.position) task.wait(1) end
    activatePrompt(seller.obj)
    task.wait(2)
    local paid = pay()
    if paid then
        paidCount = paidCount + 1
        totalItemsBought = totalItemsBought + takenCount
        cycleCount = cycleCount + 1
        takenCount = 0
        updateStats()
    else
        task.wait(1)
        paid = pay()
        if paid then
            paidCount = paidCount + 1
            totalItemsBought = totalItemsBought + takenCount
            cycleCount = cycleCount + 1
            takenCount = 0
            updateStats()
        end
    end
end
local function mainLoop()
    while running do
        for _, item in ipairs(clothes) do item.taken = false item.unavailable = false item.failedAttempts = 0 end
        shopLimits = {}
        takenCount = 0
        lastTakeTime = 0
        lastMoveTime = tick()
        sortByDistance()
        updateList()
        local shouldPay = false
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken or item.unavailable then continue end
            syncCart()
            if takenCount >= SETTINGS.MAX_TOTAL then shouldPay = true break end
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then continue end

            if item.price and not shouldBuyItem(item) then
                updateList()
                continue
            end

            if item.position then walkTo(item.position) task.wait(0.3) end

            local success = tryTakeItem(item)
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                lastTakeTime = tick()
                totalMoneySpent = totalMoneySpent + (item.price or 0)
                updateStats()
                updateList()
                syncCart()
                if takenCount >= SETTINGS.MAX_TOTAL then shouldPay = true break end

                addLog("Success! Waiting 4s...")
                local waitStart = tick()
                while tick() - waitStart < SETTINGS.SUCCESS_DELAY do
                    if not running then break end
                    doQuickMove()
                    task.wait(0.5)
                end
            else
                addLog("Failed. Waiting 1s...")
                local waitStart = tick()
                while tick() - waitStart < SETTINGS.FAIL_DELAY do
                    if not running then break end
                    doQuickMove()
                    task.wait(0.5)
                end
                updateList()
            end
        end
        if shouldPay or takenCount > 0 then
            goToPay()
            if running then sortByDistance() updateList() end
        end
        for i = 1, SETTINGS.REFRESH_TIME do
            if not running then break end
            if i % 2 == 0 then doQuickMove() end
            task.wait(1)
        end
    end
end
startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "START"
        startBtn.BackgroundColor3 = Color3.fromRGB(80,200,80)
    else
        running = true
        startBtn.Text = "STOP"
        startBtn.BackgroundColor3 = Color3.fromRGB(220,50,50)
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
print("Script v15.8 loaded!")
