if not math.round then
    function math.round(n)
        return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local AnimalsModule = require(ReplicatedStorage.Datas.Animals)
local TraitsModule = require(ReplicatedStorage.Datas.Traits)
local MutationsModule = require(ReplicatedStorage.Datas.Mutations)
local PlotController = require(ReplicatedStorage.Controllers:WaitForChild("PlotController", 2))

local isPetScanRunning = false
local highestGenAnimal = nil
local currentTargetPlot = nil
local transparencyConnections = {}
local INTERVAL = 0.25

local ALL_ANIMAL_NAMES = {
    ["Noobini Pizzanini"] = true, ["LirilÃ¬ LarilÃ "] = true, ["Tim Cheese"] = true, ["Fluriflura"] = true, ["Svinina Bombardino"] = true, ["Talpa Di Fero"] = true,
    ["Pipi Kiwi"] = true, ["Trippi Troppi"] = true, ["Tung Tung Tung Sahur"] = true, ["Gangster Footera"] = true, ["Boneca Ambalabu"] = true, ["Ta Ta Ta Ta Sahur"] = true,
    ["Tric Trac Baraboom"] = true, ["Bandito Bobritto"] = true, ["Cacto Hipopotamo"] = true, ["Cappuccino Assassino"] = true, ["Brr Brr Patapim"] = true,
    ["Trulimero Trulicina"] = true, ["Bananita Dolphinita"] = true, ["Brri Brri Bicus Dicus Bombicus"] = true, ["Bambini Crostini"] = true, ["Perochello Lemonchello"] = true,
    ["Burbaloni Loliloli"] = true, ["Chimpanzini Bananini"] = true, ["Ballerina Cappuccina"] = true, ["Chef Crabracadabra"] = true, ["Glorbo Fruttodrillo"] = true,
    ["Blueberrinni Octopusini"] = true, ["Lionel Cactuseli"] = true, ["Pandaccini Bananini"] = true, ["Frigo Camelo"] = true, ["Orangutini Ananassini"] = true,
    ["Bombardiro Crocodilo"] = true, ["Bombombini Gusini"] = true, ["Rhino Toasterino"] = true, ["Cavallo Virtuoso"] = true, ["Spioniro Golubiro"] = true,
    ["Zibra Zubra Zibralini"] = true, ["Tigrilini Watermelini"] = true, ["Cocofanto Elefanto"] = true, ["Tralalero Tralala"] = true, ["Odin Din Din Dun"] = true,
    ["Girafa Celestre"] = true, ["Gattatino Nyanino"] = true, ["Trenostruzzo Turbo 3000"] = true, ["Matteo"] = true, ["Tigroligre Frutonni"] = true, ["Orcalero Orcala"] = true,
    ["Statutino Libertino"] = true, ["Gattatino Neonino"] = true, ["La Vacca Saturno Saturnita"] = true, ["Los Tralaleritos"] = true, ["Graipuss Medussi"] = true,
    ["La Grande Combinasion"] = true, ["Chimpanzini Spiderini"] = true, ["Garama and Madundung"] = true, ["Torrtuginni Dragonfrutini"] = true, ["Las Tralaleritas"] = true,
    ["Pot Hotspot"] = true, ["Mythic Lucky Block"] = true, ["Brainrot God Lucky Block"] = true, ["Secret Lucky Block"] = true,
}

-- Function to check if a pet is in a vending machine
local function isPetInVendingMachine(petName)
    local plots = workspace:WaitForChild("Plots")
    for _, plot in ipairs(plots:GetChildren()) do
        for _, textlabel in ipairs(plot:GetDescendants()) do
            if textlabel:IsA("TextLabel") and textlabel.Name == "Price" then
                local parent = textlabel.Parent
                if parent:FindFirstChild("Stolen") and parent.Stolen.Text == "IN MACHINE" then
                    local displayNameLabel = parent:FindFirstChild("DisplayName")
                    local animalName = displayNameLabel and displayNameLabel:IsA("TextLabel") and displayNameLabel.Text or "Unknown"
                    if animalName == petName then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function getPlotFromPosition(pos)
    if typeof(pos) ~= "Vector3" then
        if pos:IsA("Model") then
            local root = pos:FindFirstChild("RootPart") or pos:FindFirstChildWhichIsA("BasePart")
            if not root then return nil end
            pos = root.Position
        elseif pos:IsA("BasePart") then
            pos = pos.Position
        else
            return nil
        end
    end
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end
    local closestPlot = nil
    local shortestDist = math.huge
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn and spawn:IsA("BasePart") then
                    local dist = (spawn.Position - pos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestPlot = plot
                    end
                end
            end
        end
    end
    return closestPlot
end

local function getMyPlot()
    local ok, result = pcall(function() return PlotController:GetMyPlot() end)
    if not ok or not result then return nil end
    local plotModel = result and result.PlotModel
    return typeof(plotModel) == "Instance" and plotModel or nil
end

local function isInEnemyPlot(model)
    local myPlot = getMyPlot()
    if not myPlot then return true end
    return not myPlot:IsAncestorOf(model)
end

local function isBasePet(m)
    return m:IsA("Model") and ALL_ANIMAL_NAMES[m.Name]
end

local function clearPetESP()
    for _, m in ipairs(workspace:GetChildren()) do
        if m:FindFirstChild("PetESP") then m.PetESP:Destroy() end
        if m:FindFirstChild("PetESP_Label") then m.PetESP_Label:Destroy() end
    end
end

local function startRainbow(obj, prop)
    local cycleTime = 4
    task.spawn(function()
        while obj and obj.Parent do
            local h = (tick() % cycleTime) / cycleTime
            obj[prop] = Color3.fromHSV(h, 1, 1)
            RunService.Heartbeat:Wait()
        end
    end)
end

local function formatNumber(n)
    return tostring(n):reverse():gsub('%d%d%d', '%1,'):reverse():gsub('^,', '')
end

local function getTraitMultiplier(model)
    local traitSource = model:FindFirstChild("Instance") or model
    local traitJson = traitSource:GetAttribute("Traits")
    if not traitJson then return 1 end
    local success, traitList = pcall(function()
        return HttpService:JSONDecode(traitJson)
    end)
    if not success or typeof(traitList) ~= "table" then return 1 end
    local mult = 1
    for _, traitName in ipairs(traitList) do
        local trait = TraitsModule[traitName]
        if trait and trait.MultiplierModifier then
            mult *= trait.MultiplierModifier
        end
    end
    return mult
end

local function getMutationMultiplier(model)
    local mutation = model:GetAttribute("Mutation")
    if not mutation then return 1 end
    local data = MutationsModule[mutation]
    if data and data.MultiplierModifier then
        return data.MultiplierModifier
    end
    return 1
end

local function getFinalGeneration(model)
    local animalData = AnimalsModule[model.Name]
    if not animalData then return 0 end
    local baseGen = animalData.Generation or 0
    local traitMult = getTraitMultiplier(model)
    local mutationMult = getMutationMultiplier(model)
    local total = baseGen * traitMult * mutationMult
    return math.round(total), baseGen, traitMult, mutationMult
end

local function attachPetESP(m, g)
    local root = m:FindFirstChild("RootPart") or m:FindFirstChildWhichIsA("BasePart")
    if not root then return end
    local hl = Instance.new('Highlight')
    hl.Name = "PetESP"
    hl.Adornee = m
    hl.OutlineColor = Color3.new(0, 0, 0)
    hl.FillTransparency = 0.25
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = m
    startRainbow(hl, "FillColor")
    startRainbow(hl, "OutlineColor")
    local gui = Instance.new('BillboardGui')
    gui.Name = "PetESP_Label"
    gui.Adornee = root
    gui.AlwaysOnTop = true
    gui.Size = UDim2.new(0, 400, 0, 80)
    gui.StudsOffset = Vector3.new(0, 6.5, 0)
    gui.Parent = m
    local n = Instance.new('TextLabel')
    n.Size = UDim2.new(1, 0, 0.5, 0)
    n.Position = UDim2.new(0.5, 0, 0.35, 0)
    n.AnchorPoint = Vector2.new(0.5, 0.5)
    n.BackgroundTransparency = 1
    n.Font = Enum.Font.GothamBlack
    n.TextSize = 22
    n.Text = m.Name:upper()
    n.TextXAlignment = Enum.TextXAlignment.Center
    n.Parent = gui
    local ns = Instance.new('UIStroke')
    ns.Thickness = 4.5
    ns.Color = Color3.new(0, 0, 0)
    ns.Parent = n
    local nso = Instance.new('UIStroke')
    nso.Thickness = 5.5
    nso.Color = Color3.new(1, 1, 1)
    nso.Parent = n
    local gL = Instance.new('TextLabel')
    gL.Size = UDim2.new(1, 0, 0.5, 0)
    gL.Position = UDim2.new(0.5, 0, 0.75, 0)
    gL.AnchorPoint = Vector2.new(0.5, 0.5)
    gL.BackgroundTransparency = 1
    gL.Font = Enum.Font.GothamBlack
    gL.TextSize = 32
    gL.Text = '$' .. formatNumber(g) .. '/s'
    gL.TextXAlignment = Enum.TextXAlignment.Center
    gL.Parent = gui
    local gs = Instance.new('UIStroke')
    gs.Thickness = 6
    gs.Color = Color3.new(0, 0, 0)
    gs.Parent = gL
    local gso = Instance.new('UIStroke')
    gso.Thickness = 7
    gso.Color = Color3.new(1, 1, 1)
    gso.Parent = gL
    startRainbow(n, 'TextColor3')
    startRainbow(gL, 'TextColor3')
end

local function runPetScanLoop()
    if isPetScanRunning then return end
    isPetScanRunning = true
    while true do
        local highest, bestGen = nil, -1
        for _, m in ipairs(workspace:GetChildren()) do
            if isBasePet(m) and isInEnemyPlot(m) then
                -- Skip pets that are in vending machines
                if not isPetInVendingMachine(m.Name) then
                    local g = getFinalGeneration(m)
                    if g > bestGen then
                        bestGen = g
                        highest = m
                    end
                end
            end
        end
        highestGenAnimal = highest
        clearPetESP()
        if highest then
            attachPetESP(highest, bestGen)
        end
        task.wait(INTERVAL)
    end
end

task.spawn(runPetScanLoop)
