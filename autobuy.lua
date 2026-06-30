-- v19.0 SlotPriceReveal cached prices, filters before walking
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
print("AUTOBUY v19.0")
print(string.rep("=", 80) .. "\n")
local SETTINGS = {
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
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
    OBSTACLE_CHECK_DIST = 3.5,
    SIDE_STEP_DIST = 5,
    RARITY_BY_PRICE = {
        { min = 100000, rarity = "legendary" },
        { min = 50000,  rarity = "epic" },
        { min = 20000,  rarity = "rare" },
        { min = 5000,   rarity = "uncommon" },
        { min = 0,      rarity = "common" }
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
local priceCache = {}
local ShopRemotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
local SlotPriceReveal = ShopRemotes and ShopRemotes:FindFirstChild("SlotPriceReveal")
if SlotPriceReveal then
    SlotPriceReveal.OnClientEvent:Connect(function(payload)
        if type(payload) == "table" then
            for _, item in ipairs(payload) do
                if type(item) == "table" and item.name and item.price then
                    local name = tostring(item.name)
                    local price = tonumber(item.price)
                    if name and price then
                        priceCache[name] = price
                    end
                end
            end
        end
    end)
    print("Connected to SlotPriceReveal")
else
    print("SlotPriceReveal not found, will rely on GUI")
end

local function log(msg)
    print("[AutoBuy] " .. msg)
end
local function formatNumber(num)
    if num >= 1000000 then return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then return string.format("%.1fK", num / 1000)
    else return tostring(num) end
end
local function findPosition(obj)
    local current = obj
    for _ = 1, 6 do
        if current:IsA("BasePart") then return current.Position end
        current = current.Parent
        if not current then break end
    end
    return nil
end
local function getItemPriceFromGUI(itemName)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local labels = {}
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, el in ipairs(gui:GetDescendants()) do
                if (el:IsA("TextLabel") or el:IsA("TextBox")) and el.Text ~= "" then
                    table.insert(labels, el)
                end
            end
        end
    end
    for i, label in ipairs(labels) do
        if label.Text:lower():find(itemName:lower(), 1, true) then
            for j = i, math.min(i+5, #labels) do
                local txt = labels[j].Text
                local num = txt:match("(%d+)%s*R%$")
                if num then return tonumber(num) end
            end
        end
    end
    return nil
end
local function rarityByPrice(price)
    for _, tier in ipairs(SETTINGS.RARITY_BY_PRICE) do
        if price >= tier.min then return tier.rarity end
    end
    return "common"
end
local function shouldBuyItem(item)
    if not item.price then return false end
    if item.price < SETTINGS.MIN_PRICE or item.price > SETTINGS.MAX_PRICE then return false end
    if SETTINGS.NAME_FILTER ~= "" and not item.name:lower():find(SETTINGS.NAME_FILTER:lower()) then return false end
    if SETTINGS.SHOP_FILTER ~= "" and not item.shop:lower():find(SETTINGS.SHOP_FILTER:lower()) then return false end
    return true
end
local function findSeller()
    if seller then return seller end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local action = (obj.ActionText or ""):lower()
            if action:find("поговорить") or action:find("talk") or action:find("оплатить") or action:find("pay") then
                seller = { obj = obj, position = findPosition(obj) }
                log("Seller found: " .. obj.Parent.Name)
                return seller
            end
        end
    end
    return nil
end
local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then return false end
    local startPos = rootPart.Position
    local totalDistance = (targetPos - startPos).Magnitude
    if totalDistance <= 3 then return true end

    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER

    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentMaxSlope = 45, Costs = { Water = 20 }
    })
    pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)
    local waypoints = path:GetWaypoints()
    if #waypoints == 0 then
        humanoid:MoveTo(targetPos)
        local t = tick()
        while (rootPart.Position - targetPos).Magnitude > 3 and tick()-t < 8 do task.wait(0.2) end
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        return (rootPart.Position - targetPos).Magnitude <= 3
    end

    local lastPos = rootPart.Position
    local stuckTime = 0
    local wpIdx = 1
    local startTime = tick()
    local maxTime = math.min(totalDistance * 0.8, 60)
    while tick()-startTime < maxTime do
        if not running then break end
        local pos = rootPart.Position
        if (pos - targetPos).Magnitude <= 3 then break end
        local moved = (pos - lastPos).Magnitude
        if moved < 0.3 then stuckTime += 0.15 else stuckTime = 0 end
        lastPos = pos
        if stuckTime >= 3 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            stuckTime = 0
        end
        if wpIdx <= #waypoints then
            local wp = waypoints[wpIdx]
            if (pos - wp.Position).Magnitude <= 4 then wpIdx += 1
            else humanoid:MoveTo(wp.Position) end
        else humanoid:MoveTo(targetPos) end
        task.wait(0.1)
    end
    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    return (rootPart.Position - targetPos).Magnitude <= 3
end
local function sortByDistance()
    if not rootPart then return end
    local cur = rootPart.Position
    table.sort(clothes, function(a,b)
        return (a.position and (a.position-cur).Magnitude or 9999) < (b.position and (b.position-cur).Magnitude or 9999)
    end)
end
local function doQuickMove()
    local now = tick()
    if now - lastMoveTime >= SETTINGS.MOVE_INTERVAL then
        if humanoid and humanoid.Health > 0 then
            humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-2,2),0,math.random(-2,2)))
            lastMoveTime = now
        end
    end
end
local function findClothes()
    clothes = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local action = obj.ActionText or ""
            if action:find("Take") or action:find("Взять") then
                local parent = obj.Parent
                local rawName = parent and parent.Name or "Item"
                local position = findPosition(parent)
                local path = obj:GetFullName()
                local shopName = "Unknown"
                for name in path:gmatch("Shop_ShopZone_%d+") do shopName = name; break end
                if shopName == "Unknown" then
                    for name in path:gmatch("Shop_[%w_]+") do shopName = name; break end
                end
                local floor = "1st floor"
                if position and position.Y > 10 then floor = "2nd floor" end
                local cachedPrice = priceCache[rawName]
                if not cachedPrice then
                    for nameInCache, price in pairs(priceCache) do
                        if nameInCache:lower():find(rawName:lower(), 1, true) or rawName:lower():find(nameInCache:lower(), 1, true) then
                            cachedPrice = price
                            break
                        end
                    end
                end
                local price = cachedPrice
                local rarity = price and rarityByPrice(price) or nil
                table.insert(clothes, {
                    obj = obj, parent = parent, name = rawName,
                    position = position, shop = shopName, floor = floor,
                    taken = false, unavailable = false, failedAttempts = 0,
                    rarity = rarity, price = price, slotRef = parent
                })
            end
        end
    end
    log("Found " .. #clothes .. " items")
end
local function activatePrompt(prompt)
    if not prompt then return false end
    local pos = findPosition(prompt.Parent)
    if pos and (pos - rootPart.Position).Magnitude > SETTINGS.PROMPT_ACTIVATE_DISTANCE then
        walkTo(pos)
        task.wait(0.5)
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
            task.wait(SETTINGS.FAIL_DELAY)
            if not item.obj or not item.obj.Parent then item.unavailable = true; return false end
        end
        if activatePrompt(item.obj) then
            return true
        end
        log("Attempt " .. attempt .. " failed for " .. item.name)
    end
    item.failedAttempts = item.failedAttempts + 1
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then item.unavailable = true end
    return false
end
local function pay()
    local confirm = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirm then confirm = confirm:FindFirstChild("ConfirmPurchase") end
    if confirm and pcall(function() confirm:FireServer() end) then return true end
    if player:FindFirstChild("PlayerGui") then
        local gui = player.PlayerGui:FindFirstChild("ShopGUI")
        if gui then
            local btn = gui:FindFirstChild("BuyButton", true)
            if btn and btn:IsA("TextButton") then
                local pos = btn.AbsolutePosition
                local sz = btn.AbsoluteSize
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(pos.X + sz.X/2, pos.Y + sz.Y/2))
                return true
            end
        end
    end
    return false
end
local function goToPay()
    if takenCount == 0 then return end
    findSeller()
    if not seller then log("No seller") return end
    if seller.position then walkTo(seller.position) task.wait(1) end
    activatePrompt(seller.obj)
    task.wait(2)
    local ok = pay()
    if ok then
        paidCount = paidCount + 1
        totalItemsBought = totalItemsBought + takenCount
        cycleCount = cycleCount + 1
        takenCount = 0
    else
        task.wait(1)
        ok = pay()
        if ok then
            paidCount = paidCount + 1
            totalItemsBought = totalItemsBought + takenCount
            cycleCount = cycleCount + 1
            takenCount = 0
        else
            log("Payment failed")
        end
    end
end

-- GUI (identical to v18, insert full GUI here)
-- I'll include the essential GUI skeleton to avoid errors
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v19"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 750, 0, 880)
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
titleLabel.Text = " AutoBuy v19.0 | Cache"
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
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local function updateDrag(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UIS.InputChanged:Connect(function(input) if input == dragInput then updateDrag(input) end end)
local restockLabel = Instance.new("TextLabel")
restockLabel.Size = UDim2.new(1,-20,0,30)
restockLabel.Position = UDim2.new(0,10,0,55)
restockLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
restockLabel.TextColor3 = Color3.fromRGB(255,255,100)
restockLabel.Font = Enum.Font.GothamBold
restockLabel.TextSize = 16
restockLabel.Text = "Restock: --:--"
restockLabel.TextXAlignment = Enum.TextXAlignment.Center
restockLabel.Parent = frame
Instance.new("UICorner", restockLabel).CornerRadius = UDim.new(0,8)
local filterFrame = Instance.new("Frame")
filterFrame.Size = UDim2.new(1,-20,0,90)
filterFrame.Position = UDim2.new(0,10,0,90)
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
    local val = tonumber(priceMinInput.Text)
    if val then SETTINGS.MIN_PRICE = val updateList() end
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
    local val = tonumber(priceMaxInput.Text)
    if val then SETTINGS.MAX_PRICE = val updateList() end
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
nameInput.FocusLost:Connect(function() SETTINGS.NAME_FILTER = nameInput.Text updateList() end)
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
shopInput.FocusLost:Connect(function() SETTINGS.SHOP_FILTER = shopInput.Text updateList() end)

local filterStats = Instance.new("TextLabel")
filterStats.Size = UDim2.new(1,-10,0,20)
filterStats.Position = UDim2.new(0,10,0,185)
filterStats.BackgroundTransparency = 1
filterStats.Text = "Total: 0 | Filtered: 0"
filterStats.TextColor3 = Color3.fromRGB(200,200,200)
filterStats.Font = Enum.Font.Gotham
filterStats.TextSize = 10
filterStats.TextXAlignment = Enum.TextXAlignment.Left
filterStats.Parent = frame
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1,-20,0,80)
statsFrame.Position = UDim2.new(0,10,0,210)
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
startBtn.Position = UDim2.new(0,10,0,300)
startBtn.BackgroundColor3 = Color3.fromRGB(80,200,80)
startBtn.Text = "START"
startBtn.TextColor3 = Color3.new(0,0,0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,10)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-20,0,30)
statusLabel.Position = UDim2.new(0,10,0,360)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = Color3.fromRGB(100,255,100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1,-20,0,100)
logLabel.Position = UDim2.new(0,10,0,395)
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
scrollFrame.Size = UDim2.new(1,-20,1,-505)
scrollFrame.Position = UDim2.new(0,10,0,500)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0,8)
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0,4)
listLayout.Parent = scrollFrame

local function updateRestockDisplay()
    local text = "Restock: "
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, el in ipairs(gui:GetDescendants()) do
                    if el.Name == "TimerLabel" then
                        text = el.Text
                        break
                    end
                end
            end
        end
    end
    if text == "Restock: " then text = "Restock: --:--" end
    restockLabel.Text = text
end

local function restockTimerUpdater()
    while running do
        updateRestockDisplay()
        task.wait(1)
    end
end

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

local function waitForRestock()
    while running do
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, el in ipairs(gui:GetDescendants()) do
                        if el.Name == "TimerLabel" then
                            local min, sec = el.Text:match("(%d+):(%d+)")
                            if min and sec then
                                local remaining = tonumber(min)*60 + tonumber(sec)
                                if remaining >= 590 then
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
        doQuickMove()
        task.wait(1)
    end
end

local function mainLoop()
    task.spawn(restockTimerUpdater)
    while running do
        for _, item in ipairs(clothes) do item.taken = false item.unavailable = false item.failedAttempts = 0 end
        shopLimits = {}
        takenCount = 0
        lastMoveTime = tick()
        sortByDistance()
        updateList()
        addLog("New cycle")
        local shouldPay = false
        for _, item in ipairs(clothes) do
            if not running then break end
            if item.taken or item.unavailable then continue end
            if takenCount >= SETTINGS.MAX_TOTAL then shouldPay = true break end
            local shopCount = shopLimits[item.shop] or 0
            if shopCount >= SETTINGS.MAX_PER_SHOP then continue end

            if not item.price then
                local guiPrice = getItemPriceFromGUI(item.name)
                if guiPrice then
                    item.price = guiPrice
                    item.rarity = rarityByPrice(guiPrice)
                else
                    item.unavailable = true
                    updateList()
                    continue
                end
            end

            if not shouldBuyItem(item) then
                updateList()
                continue
            end

            if item.position then walkTo(item.position) task.wait(0.3) end

            local success = tryTakeItem(item)
            if success then
                item.taken = true
                takenCount = takenCount + 1
                shopLimits[item.shop] = (shopLimits[item.shop] or 0) + 1
                totalMoneySpent = totalMoneySpent + (item.price or 0)
                updateStats()
                updateList()
                if takenCount >= SETTINGS.MAX_TOTAL then shouldPay = true break end
                addLog("Success! Waiting " .. SETTINGS.SUCCESS_DELAY .. "s")
                local waitStart = tick()
                while tick() - waitStart < SETTINGS.SUCCESS_DELAY do
                    if not running then break end
                    doQuickMove()
                    task.wait(0.5)
                end
            else
                addLog("Failed. Waiting " .. SETTINGS.FAIL_DELAY .. "s")
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
        waitForRestock()
        findClothes()
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
        findClothes()
        sortByDistance()
        updateStats()
        updateList()
        task.spawn(mainLoop)
    end
end)
findClothes()
sortByDistance()
updateStats()
updateList()
updateRestockDisplay()
print("Script v19.0 loaded!")
