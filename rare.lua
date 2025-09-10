local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local targetPets = {
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
    ["Las Vaquitas Saturnitas"] = true, ["Nuclearo Dinossauro"] = true, ["Agarrini la Palini"] = true, ["Los Combinasionas"] = true,
    ["Tortuginni Dragonfruitini"] = true, ["Chicleteira Bicicleira"] = true, ["Dragon Cannelloni"] = true, ["Los Hotspotsitos"] = true, ["Esok Sekolah"] = true,
    ["Chicleteira Bicicleteira"] = true, ["The Final Sigma"] = true, ["Nyan Cat"] = true, ["Girafa Celeste"] = true,
    ["Los Bombinitos"] = true, ["Espresso Signora"] = true, ["Piccione Macchina"] = true, ["Coco Elefanto"] = true,
    ["Ballerino Lololo"] = true, ["Trigoligre Frutonni"] = true, ["Los Crocodillitos"] = true, ["Trippi Troppi Troppa Trippa"] = true,
    ["Bulbito Bandito Traktorito"] = true, ["Los Tungtungtungcitos"] = true, ["Tukkano Bananno"] = true, ["Los Orcalitos"] = true,
    ["Lucky Block"] = true, ["Tob Tobi Tobi"] = true, ["Karkerkar Kurkur"] = true, ["Tracoducotulu Delapeladustuz"] = true,
    ["Tralalita tralala"] = true, ["Job Job Job Sahur"] = true, ["Tipi Topi Taco"] = true, ["Urubini Flamenguini"] = true,
    ["Los Matteos"] = true, ["Blackhole Goat"] = true, ["Tartaruga Cisterna"] = true, ["Dul Dul Dul"] = true, ["Bisonte Giuppitere"] = true,
    ["Alessio"] = true, ["Sammyni Spyderini"] = true, ["Brr es Teh Patipum"] = true
}

local function getMutationMap()
    local mutationMap = {}
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return mutationMap end
    for _, plot in ipairs(plots:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                local attachment = spawn and spawn:FindFirstChild("Attachment")
                local overhead = attachment and attachment:FindFirstChild("AnimalOverhead")
                local displayName = overhead and overhead:FindFirstChild("DisplayName")
                local mutation = overhead and overhead:FindFirstChild("Mutation")
                local generation = overhead and overhead:FindFirstChild("Generation")
                if spawn and displayName and displayName:IsA("TextLabel") then
                    local name = displayName.Text
                    local mutationText = (mutation and mutation:IsA("TextLabel") and mutation.Visible and mutation.Text ~= "" and mutation.Text ~= "Normal") and mutation.Text or "Normal"
                    local generationText = (generation and generation:IsA("TextLabel")) and generation.Text or "Unknown"
                    table.insert(mutationMap, {
                        name = name,
                        position = spawn.Position,
                        mutation = mutationText,
                        generation = generationText
                    })
                end
            end
        end
    end
    return mutationMap
end

local function parseGen(genStr)
    if not genStr or genStr == "Stolen" or genStr == "Unknown" then return 0 end
    local num = tonumber(genStr:match("%d+"))
    if not num then return 0 end
    if genStr:find("M") then
        return num * 1_000_000
    elseif genStr:find("K") then
        return num * 1_000
    else
        return num
    end
end

local function createESP(pet, mutationText, generationText)
    if pet:FindFirstChild("ESP_Tag") then return end
    local head = pet:FindFirstChild("Head") or pet:FindFirstChildWhichIsA("BasePart")
    if not head then return end
    local genValue = parseGen(generationText)
    local genColor = Color3.fromRGB(255,0,0)
    if genValue >= 1_000_000 then
        genColor = Color3.fromRGB(0,255,0)
    elseif genValue >= 500_000 then
        genColor = Color3.fromRGB(0,200,0)
    elseif genValue >= 50_000 then
        genColor = Color3.fromRGB(255,165,0)
    end
    local bill = Instance.new("BillboardGui")
    bill.Name = "ESP_Tag"
    bill.Size = UDim2.new(0, 200, 0, 60)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Parent = pet
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
    nameLabel.Position = UDim2.new(0,0,0,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "🐾 ".. pet.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextScaled = true
    nameLabel.TextWrapped = true
    nameLabel.Parent = bill
    local mutationLabel = Instance.new("TextLabel")
    mutationLabel.Size = UDim2.new(1, 0, 0.33, 0)
    mutationLabel.Position = UDim2.new(0,0,0.33,0)
    mutationLabel.BackgroundTransparency = 1
    mutationLabel.Text = "🧬: " .. mutationText
    mutationLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    mutationLabel.TextStrokeTransparency = 0
    mutationLabel.Font = Enum.Font.SourceSansBold
    mutationLabel.TextScaled = true
    mutationLabel.TextWrapped = true
    mutationLabel.Parent = bill
    local genLabel = Instance.new("TextLabel")
    genLabel.Size = UDim2.new(1, 0, 0.33, 0)
    genLabel.Position = UDim2.new(0,0,0.66,0)
    genLabel.BackgroundTransparency = 1
    genLabel.Text = "💰: " .. generationText
    genLabel.TextColor3 = genColor
    genLabel.TextStrokeTransparency = 0
    genLabel.Font = Enum.Font.SourceSansBold
    genLabel.TextScaled = true
    genLabel.TextWrapped = true
    genLabel.Parent = bill
    local att0 = Instance.new("Attachment", head)
    local att1 = Instance.new("Attachment", LocalPlayer.Character:WaitForChild("HumanoidRootPart"))
    local beam = Instance.new("Beam")
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Parent = head
end

local function showCenterMessage()
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(0.8, 0, 0.15, 0)
    msg.Position = UDim2.new(0.1, 0, 0.4, 0)
    msg.BackgroundTransparency = 1
    msg.Text = "⚠ I'm Sorry If this esp dosent work and ill try fixing it if its broken Sorry for the inconvenience. Thank you so much for the support. I love you all.❤"
    msg.TextColor3 = Color3.fromRGB(180,180,180)
    msg.TextWrapped = true
    msg.Font = Enum.Font.GothamSemibold
    msg.TextScaled = true
    msg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    task.delay(10, function()
        if msg then
            msg:Destroy()
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    showCenterMessage()
end)

local lastUpdate = 0
local UPDATE_INTERVAL = 0.5

RunService.Heartbeat:Connect(function(dt)
    lastUpdate = lastUpdate + dt
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0

    local mutationMap = getMutationMap()
    local bestPetObj, bestGenValue, bestMutation, bestGeneration = nil, -1, "Normal", "Unknown"
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and targetPets[obj.Name] then
            local mutationText, generationText = "Normal", "Unknown"
            for _, data in ipairs(mutationMap) do
                if data.name == obj.Name then
                    mutationText = data.mutation or "Normal"
                    generationText = data.generation or "Unknown"
                    break
                end
            end
            if generationText ~= "Unknown" and generationText ~= "Stolen" then
                local genValue = parseGen(generationText)
                if genValue > bestGenValue then
                    bestPetObj = obj
                    bestGenValue = genValue
                    bestMutation = mutationText
                    bestGeneration = generationText
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("ESP_Tag") then
            obj.ESP_Tag:Destroy()
        end
    end
    if bestPetObj then
        createESP(bestPetObj, bestMutation, bestGeneration)
    end
end)
