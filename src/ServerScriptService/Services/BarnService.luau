--!strict
--[[
	BarnService: os 8 celeiros (bases).
	  • cada jogador ganha um celeiro livre ao entrar (placa com o nome)
	  • ao ENTRAR no próprio celeiro, os ovos carregados vão sozinhos para os slots livres
	  • ovos chocam com o tempo (os.time, continua offline) e viram animais
	  • animais geram $/s que acumula no COLETOR (botão no chão) de cada slot
	  • pisar no coletor = recebe o dinheiro
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Billboards = require(script.Parent.Billboards)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)
local ModelFactory = require(script.Parent.ModelFactory)
local NotifyService = require(script.Parent.NotifyService)
local SyncService = require(script.Parent.SyncService)
local Wallet = require(script.Parent.Wallet)
local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)

type SlotVisual = {
	Index: number,
	Pen: Part,
	Pad: Part,
	PadLabel: TextLabel,
	PadPosition: Vector3,
	Content: Model?,
	ShownStored: number,
	LastCollect: number,
}

type Barn = {
	Index: number,
	CFrame: CFrame,
	Model: Model,
	Owner: Player?,
	OwnerLabel: TextLabel,
	FacadeLabel: TextLabel,
	Spawn: SpawnLocation,
	Slots: { SlotVisual },
}

local BarnService = {}

local Map = GameConfig.Map
local barns: { Barn } = {}
local barnOf: { [Player]: Barn } = {}
local lastFullMessage: { [Player]: number } = {}

local COLORS = {
	Red = Color3.fromRGB(200, 45, 45),
	RedDark = Color3.fromRGB(150, 30, 30),
	Trim = Color3.fromRGB(250, 245, 235),
	Floor = Color3.fromRGB(165, 115, 65),
	Hay = Color3.fromRGB(235, 200, 100),
	Locked = Color3.fromRGB(90, 80, 70),
	Pad = Color3.fromRGB(70, 210, 90),
	PadLocked = Color3.fromRGB(70, 70, 75),
}

-- ---------------------------------------------------------------------
-- Construção de um celeiro
-- ---------------------------------------------------------------------

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function buildBarn(index: number, origin: CFrame, parent: Instance): Barn
	local model = Instance.new("Model")
	model.Name = "Celeiro" .. index
	local size = Map.BarnSize
	local w, h, d = size.X, size.Y, size.Z

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	-- Chão de madeira
	part(model, "Chao", Vector3.new(w, 1, d), at(0, -0.4, 0), COLORS.Floor, Enum.Material.WoodPlanks)

	-- Paredes: fundo (+Z local) e laterais. A frente (-Z) fica aberta.
	part(model, "ParedeFundo", Vector3.new(w, h, 1), at(0, h / 2, d / 2 - 0.5), COLORS.Red, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		part(model, "ParedeLado", Vector3.new(1, h * 0.6, d), at(side * (w / 2 - 0.5), h * 0.3, 0), COLORS.Red, Enum.Material.WoodPlanks)
		part(model, "Pilar", Vector3.new(2, h + 2, 2), at(side * (w / 2 - 1), (h + 2) / 2, -d / 2 + 1), COLORS.Trim)
	end
	-- "Telhado" escalonado no fundo (visual de celeiro)
	for step = 1, 3 do
		local stepWidth = w - step * 10
		part(model, "Frontao", Vector3.new(stepWidth, 3, 1.2), at(0, h + (step - 0.5) * 3, d / 2 - 0.5), if step % 2 == 0 then COLORS.RedDark else COLORS.Red, Enum.Material.WoodPlanks)
	end
	-- Viga da frente com o nome
	local beam = part(model, "Viga", Vector3.new(w, 4, 1.5), at(0, h + 2, -d / 2 + 1), COLORS.Trim)
	local facadeLabel = Billboards.SurfaceText(beam, Enum.NormalId.Front, "Celeiro livre", COLORS.RedDark)

	-- Placa flutuante com o nome do dono
	local signAnchor = part(model, "PlacaDono", Vector3.new(1, 1, 1), at(0, h + 9, 0), COLORS.Trim)
	signAnchor.Transparency = 1
	signAnchor.CanCollide = false
	signAnchor.CanQuery = false
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Dono"
	billboard.Size = UDim2.fromScale(26, 5)
	billboard.MaxDistance = 400
	billboard.LightInfluence = 0
	billboard.Parent = signAnchor
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Size = UDim2.fromScale(1, 1)
	ownerLabel.Font = Enum.Font.LuckiestGuy
	ownerLabel.TextScaled = true
	ownerLabel.TextColor3 = Color3.new(1, 1, 1)
	ownerLabel.Text = "Celeiro livre"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(28, 22, 40)
	stroke.Parent = ownerLabel
	ownerLabel.Parent = billboard

	-- Ponto de nascimento (na porta, no corredor central)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Nascimento"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 0.4, 5)
	spawn.CFrame = at(0, 0.05, -d / 2 + 5)
	spawn.CanCollide = false
	spawn.Color = COLORS.Trim
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = model

	-- Slots: ninho de feno + coletor
	local slots: { SlotVisual } = {}
	for slotIndex = 1, GameConfig.Barn.MaxSlots do
		local penOffset, padOffset = MapLayout.GetSlotOffsets(slotIndex)
		local pen = part(model, "Slot" .. slotIndex, Map.PenSize, origin * CFrame.new(penOffset + Vector3.new(0, 0.05, 0)), COLORS.Hay, Enum.Material.Fabric)
		pen.CanCollide = false
		local pad = part(model, "Coletor" .. slotIndex, Map.PadSize, origin * CFrame.new(padOffset + Vector3.new(0, 0.05, 0)), COLORS.Pad, Enum.Material.SmoothPlastic)
		pad.CanCollide = false
		local padLabel = Billboards.SurfaceText(pad, Enum.NormalId.Top, "", Color3.fromRGB(110, 255, 80), Enum.Font.FredokaOne)
		table.insert(slots, {
			Index = slotIndex,
			Pen = pen,
			Pad = pad,
			PadLabel = padLabel,
			PadPosition = pad.Position,
			Content = nil,
			ShownStored = -1,
			LastCollect = 0,
		})
	end

	model.Parent = parent
	return {
		Index = index,
		CFrame = origin,
		Model = model,
		Owner = nil,
		OwnerLabel = ownerLabel,
		FacadeLabel = facadeLabel,
		Spawn = spawn,
		Slots = slots,
	}
end

-- ---------------------------------------------------------------------
-- Desenho dos slots
-- ---------------------------------------------------------------------

local function updatePadLabel(slot: SlotVisual, stored: number?)
	if stored == nil then
		if slot.ShownStored ~= -2 then
			slot.PadLabel.Text = ""
			slot.ShownStored = -2
		end
		return
	end
	local value = math.floor(stored)
	if value ~= slot.ShownStored then
		slot.ShownStored = value
		slot.PadLabel.Text = Format.Money(value)
	end
end

local function renderSlot(barn: Barn, slotIndex: number)
	local slot = barn.Slots[slotIndex]
	if not slot then
		return
	end
	if slot.Content then
		slot.Content:Destroy()
		slot.Content = nil
	end

	local owner = barn.Owner
	local profile = if owner then DataService.Get(owner) else nil
	local unlocked = profile ~= nil and slotIndex <= profile.Data.BarnSlots
	slot.Pen.Color = if unlocked then COLORS.Hay else COLORS.Locked
	slot.Pad.Color = if unlocked then COLORS.Pad else COLORS.PadLocked
	slot.Pen.Transparency = if profile and not unlocked then 0.5 else 0

	local data = if profile then profile.Data.Slots[tostring(slotIndex)] else nil
	if not profile or not data then
		updatePadLabel(slot, nil)
		return
	end

	local ground = slot.Pen.CFrame * CFrame.new(0, Map.PenSize.Y / 2, 0)
	if data.Hatched then
		local model = ModelFactory.CreateAnimal(data.AnimalId, 1)
		ModelFactory.PlaceOnGround(model, ground, 0.1)
		local root = model.PrimaryPart
		if root then
			Billboards.Animal(data.AnimalId, Formulas.AnimalIncome(data.AnimalId, profile.Data.Rebirths)).Parent = root
		end
		CollectionService:AddTag(model, "IdleAnimal")
		model.Parent = barn.Model
		slot.Content = model
		updatePadLabel(slot, data.Stored)
	else
		local model = ModelFactory.CreateEgg(data.EggId, 1)
		ModelFactory.PlaceOnGround(model, ground, 0.1)
		local root = model.PrimaryPart
		if root then
			Billboards.Hatching(data.EggId, data.HatchAt, data.HatchDuration).Parent = root
		end
		CollectionService:AddTag(model, "HatchingEgg")
		model.Parent = barn.Model
		slot.Content = model
		updatePadLabel(slot, nil)
	end
end

local function renderAll(barn: Barn)
	for slotIndex = 1, GameConfig.Barn.MaxSlots do
		renderSlot(barn, slotIndex)
	end
end

-- ---------------------------------------------------------------------
-- Regras do celeiro
-- ---------------------------------------------------------------------

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function findFreeSlot(data: DataService.PlayerData): number?
	for slotIndex = 1, data.BarnSlots do
		if not data.Slots[tostring(slotIndex)] then
			return slotIndex
		end
	end
	return nil
end

-- Coloca os ovos carregados nos slots livres
local function placeCarried(barn: Barn, player: Player)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local data = profile.Data
	local placed = 0
	while CarryService.Count(player) > 0 do
		local free = findFreeSlot(data)
		if not free then
			local now = os.clock()
			if now - (lastFullMessage[player] or 0) > GameConfig.Barn.FullMessageCooldown then
				lastFullMessage[player] = now
				NotifyService.Notify(player, "Celeiro cheio! Venda um animal ou compre mais slots", "warning")
			end
			break
		end
		local item = CarryService.TakeOne(player)
		if not item then
			break
		end
		local egg = GameConfig.EggsById[item.EggId]
		local rarity = GameConfig.RarityById[egg.Rarity]
		data.Slots[tostring(free)] = {
			EggId = item.EggId,
			AnimalId = item.AnimalId,
			HatchAt = os.time() + rarity.HatchTime,
			HatchDuration = rarity.HatchTime,
			Hatched = false,
			Stored = 0,
		}
		renderSlot(barn, free)
		placed += 1
	end
	if placed > 0 then
		local text = if placed == 1 then "Ovo colocado no celeiro! 🥚" else string.format("%d ovos colocados no celeiro! 🥚", placed)
		NotifyService.Notify(player, text, "success")
		SyncService.Push(player)
	end
end

local function hatch(barn: Barn, player: Player, profile: DataService.Profile, slotIndex: number, data: DataService.SlotData)
	data.Hatched = true
	local animal = GameConfig.AnimalsById[data.AnimalId]
	local rarity = GameConfig.RarityById[animal.Rarity]
	local isNew = not profile.Data.Index[data.AnimalId]
	profile.Data.Index[data.AnimalId] = true
	profile.Data.Stats.EggsHatched += 1

	local slot = barn.Slots[slotIndex]
	renderSlot(barn, slotIndex)
	NotifyService.EffectAll("Hatch", {
		Position = slot.Pen.Position + Vector3.new(0, 2, 0),
		Color = rarity.Color,
		Order = rarity.Order,
	})
	NotifyService.Notify(player, string.format("Seu ovo chocou: %s %s (%s)!", animal.Icon, animal.Name, rarity.Name), "rarity", rarity.Color)
	if isNew then
		NotifyService.Notify(player, "Novo animal no Índice! 📖", "success")
	end
	SyncService.Push(player)
end

local function collect(barn: Barn, player: Player, slotIndex: number)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local data = profile.Data.Slots[tostring(slotIndex)]
	if not data or not data.Hatched then
		return
	end
	local amount = math.floor(data.Stored)
	if amount < 1 then
		return
	end
	data.Stored -= amount
	Wallet.Add(player, amount)
	local slot = barn.Slots[slotIndex]
	updatePadLabel(slot, data.Stored)
	NotifyService.Effect(player, "Collect", { Position = slot.PadPosition, Amount = amount })
end

-- ---------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------

function BarnService.Assign(player: Player): boolean
	for _, barn in barns do
		if barn.Owner == nil then
			barn.Owner = player
			barnOf[player] = barn
			barn.OwnerLabel.Text = "🏠 " .. player.DisplayName
			barn.FacadeLabel.Text = "Celeiro de " .. player.DisplayName
			player:SetAttribute("BarnIndex", barn.Index)
			player.RespawnLocation = barn.Spawn
			renderAll(barn)
			return true
		end
	end
	return false
end

function BarnService.Release(player: Player)
	local barn = barnOf[player]
	if not barn then
		return
	end
	barnOf[player] = nil
	lastFullMessage[player] = nil
	barn.Owner = nil
	barn.OwnerLabel.Text = "Celeiro livre"
	barn.FacadeLabel.Text = "Celeiro livre"
	renderAll(barn)
end

function BarnService.GetSpawnCFrame(player: Player): CFrame?
	local barn = barnOf[player]
	if not barn then
		return nil
	end
	return barn.Spawn.CFrame + Vector3.new(0, 3.5, 0)
end

-- Depois de comprar slot (ou rebirth), redesenha tudo
function BarnService.Refresh(player: Player)
	local barn = barnOf[player]
	if barn then
		renderAll(barn)
	end
end

function BarnService.SellSlot(player: Player, slotIndex: number): (boolean, string)
	local barn = barnOf[player]
	local profile = DataService.Get(player)
	if not barn or not profile then
		return false, "Seu celeiro ainda está carregando."
	end
	local key = tostring(slotIndex)
	local data = profile.Data.Slots[key]
	if not data then
		return false, "Esse lugar está vazio."
	end
	if not data.Hatched then
		return false, "Esse ovo ainda está chocando."
	end
	local animal = GameConfig.AnimalsById[data.AnimalId]
	local price = Formulas.SellPrice(data.AnimalId)
	local stored = math.floor(data.Stored)
	profile.Data.Slots[key] = nil
	Wallet.Add(player, price + stored)
	renderSlot(barn, slotIndex)
	SyncService.Push(player)
	return true, string.format("Você vendeu %s %s por %s!", animal.Icon, animal.Name, Format.Money(price))
end

function BarnService.Init()
	local folder = Instance.new("Folder")
	folder.Name = "Celeiros"
	folder.Parent = Workspace:FindFirstChild("Mapa") or Workspace

	for _, layout in MapLayout.Barns do
		table.insert(barns, buildBarn(layout.Index, layout.CFrame, folder))
	end

	-- Loop rápido: entrar no celeiro (guardar ovos) e pisar nos coletores
	task.spawn(function()
		while true do
			task.wait(0.2)
			for _, barn in barns do
				local owner = barn.Owner
				local root = if owner then getRoot(owner) else nil
				if owner and root then
					local localPosition = barn.CFrame:PointToObjectSpace(root.Position)
					if MapLayout.IsInsideBarn(localPosition) then
						if CarryService.Count(owner) > 0 then
							placeCarried(barn, owner)
						end
						for _, slot in barn.Slots do
							local offset = root.Position - slot.PadPosition
							if math.abs(offset.X) <= Map.PadSize.X / 2 + 1 and math.abs(offset.Z) <= Map.PadSize.Z / 2 + 1 and offset.Y < 7 then
								collect(barn, owner, slot.Index)
							end
						end
					end
				end
			end
		end
	end)

	-- Loop de 1 s: chocar ovos e gerar dinheiro
	task.spawn(function()
		while true do
			local dt = task.wait(1)
			local now = os.time()
			for _, barn in barns do
				local owner = barn.Owner
				local profile = if owner then DataService.Get(owner) else nil
				if owner and profile then
					local multiplier = Formulas.IncomeMultiplier(profile.Data.Rebirths)
					for key, data in profile.Data.Slots do
						local slotIndex = tonumber(key)
						if slotIndex then
							if not data.Hatched and now >= data.HatchAt then
								hatch(barn, owner, profile, slotIndex, data)
							elseif data.Hatched then
								local animal = GameConfig.AnimalsById[data.AnimalId]
								data.Stored += animal.Income * multiplier * dt
								updatePadLabel(barn.Slots[slotIndex], data.Stored)
							end
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastFullMessage[player] = nil
	end)
end

return BarnService
