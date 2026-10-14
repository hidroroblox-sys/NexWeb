--!strict
--[[
	ModelFactory: cria os modelos 3D de ovos e animais.

	Se existir um modelo com o nome certo em
	  ReplicatedStorage > Assets > Eggs    (ovos)
	  ReplicatedStorage > Assets > Animals (animais)
	ele é usado. Senão, cria um PLACEHOLDER simples:
	  ovo    = esfera alongada colorida com pintinhas
	  animal = "bolinha" fofa com cabeça, olhos e bico
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local ModelFactory = {}

local RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 40),
	Color3.fromRGB(255, 230, 50),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(170, 90, 255),
}

local function findAsset(kind: string, name: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = if assets then assets:FindFirstChild(kind) else nil
	local found = if folder then folder:FindFirstChild(name) else nil
	if found and found:IsA("Model") then
		return found
	end
	return nil
end

local function newPart(model: Model, name: string, size: Vector3, color: Color3, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.CFrame = cframe
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

-- Transforma a peça numa elipse (esfera esticada no tamanho da peça)
local function ellipsoid(part: Part)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
end

-- Deixa todas as peças sem colisão e define a PrimaryPart
local function prepare(model: Model, anchored: boolean)
	if not model.PrimaryPart then
		local biggest: BasePart? = nil
		local biggestVolume = -1
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
				if volume > biggestVolume then
					biggest = descendant
					biggestVolume = volume
				end
			end
		end
		model.PrimaryPart = biggest
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.CastShadow = false
		end
	end
end

-- ---------------------------------------------------------------------
-- OVO
-- ---------------------------------------------------------------------

function ModelFactory.CreateEgg(eggId: string, scale: number?): Model
	local egg = GameConfig.EggsById[eggId]
	assert(egg, "Ovo desconhecido: " .. tostring(eggId))
	local s = scale or 1
	local model: Model

	local asset = findAsset("Eggs", egg.Model)
	if asset then
		model = asset:Clone()
		prepare(model, true)
		if s ~= 1 then
			model:ScaleTo(model:GetScale() * s)
		end
	else
		model = Instance.new("Model")
		local rarity = GameConfig.RarityById[egg.Rarity]
		local body = newPart(model, "Body", Vector3.new(2.6, 3.3, 2.6) * s, egg.Color, CFrame.new())
		ellipsoid(body)
		model.PrimaryPart = body

		local spots = {
			Vector3.new(1.05, 0.4, 0.55),
			Vector3.new(-0.9, 0.9, 0.7),
			Vector3.new(-0.3, -0.5, -1.15),
			Vector3.new(0.6, 1.2, -0.75),
			Vector3.new(-1.1, -0.2, -0.5),
			Vector3.new(0.4, -0.9, 1.0),
		}
		for index, offset in spots do
			local color = if egg.Rainbow then RAINBOW[(index - 1) % #RAINBOW + 1] else egg.SpotColor
			local spot = newPart(model, "Spot", Vector3.new(0.75, 0.75, 0.75) * s, color, CFrame.new(offset * s))
			ellipsoid(spot)
		end

		-- Ovos a partir de Lendário brilham na cor da raridade
		if rarity.Order >= 5 then
			local light = Instance.new("PointLight")
			light.Color = rarity.Color
			light.Range = 10 * s
			light.Brightness = 1.5
			light.Parent = body
			body.Material = Enum.Material.Glass
			body.Reflectance = 0.15
		end
		prepare(model, true)
	end

	model.Name = eggId
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- chega inteiro no cliente
	return model
end

-- ---------------------------------------------------------------------
-- ANIMAL
-- ---------------------------------------------------------------------

function ModelFactory.CreateAnimal(animalId: string, scale: number?): Model
	local animal = GameConfig.AnimalsById[animalId]
	assert(animal, "Animal desconhecido: " .. tostring(animalId))
	local s = scale or 1
	local model: Model

	local asset = findAsset("Animals", animal.Model)
	if asset then
		model = asset:Clone()
		prepare(model, true)
		if s ~= 1 then
			model:ScaleTo(model:GetScale() * s)
		end
	else
		model = Instance.new("Model")
		local rarity = GameConfig.RarityById[animal.Rarity]
		local dark = animal.Color:Lerp(Color3.new(0, 0, 0), 0.35)
		-- Frente do animal = -Z (mesmo sentido do LookVector)
		local body = newPart(model, "Body", Vector3.new(3, 2.6, 3.4) * s, animal.Color, CFrame.new())
		ellipsoid(body)
		model.PrimaryPart = body

		local head = newPart(model, "Head", Vector3.new(2.3, 2.2, 2.2) * s, animal.Color, CFrame.new(Vector3.new(0, 1.5, -1.4) * s))
		ellipsoid(head)

		for _, side in { -1, 1 } do
			local eye = newPart(model, "Eye", Vector3.new(0.5, 0.55, 0.3) * s, Color3.fromRGB(20, 20, 25), CFrame.new(Vector3.new(0.48 * side, 1.75, -2.45) * s))
			ellipsoid(eye)
			local shine = newPart(model, "Shine", Vector3.new(0.16, 0.16, 0.1) * s, Color3.new(1, 1, 1), CFrame.new(Vector3.new(0.48 * side + 0.08, 1.88, -2.6) * s))
			ellipsoid(shine)
			local cheek = newPart(model, "Cheek", Vector3.new(0.4, 0.25, 0.1) * s, Color3.fromRGB(255, 140, 160), CFrame.new(Vector3.new(0.8 * side, 1.3, -2.38) * s))
			ellipsoid(cheek)
		end

		local snout = newPart(model, "Snout", Vector3.new(0.7, 0.45, 0.6) * s, Color3.fromRGB(255, 170, 60), CFrame.new(Vector3.new(0, 1.3, -2.6) * s))
		ellipsoid(snout)

		for _, x in { -0.85, 0.85 } do
			for _, z in { -0.9, 0.9 } do
				local foot = newPart(model, "Foot", Vector3.new(0.75, 0.6, 0.75) * s, dark, CFrame.new(Vector3.new(x, -1.2, z) * s))
				ellipsoid(foot)
			end
		end

		-- Raros ganham uma auréola brilhante
		if rarity.Order >= 5 then
			local halo = newPart(model, "Halo", Vector3.new(0.25, 2, 2) * s, rarity.Color, CFrame.new(Vector3.new(0, 3.1, -1.4) * s) * CFrame.Angles(0, 0, math.rad(90)))
			halo.Shape = Enum.PartType.Cylinder
			halo.Material = Enum.Material.Neon
			halo.Transparency = 0.2
			local light = Instance.new("PointLight")
			light.Color = rarity.Color
			light.Range = 12 * s
			light.Brightness = 1.2
			light.Parent = body
		end
		prepare(model, true)
	end

	model.Name = animalId
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return model
end

-- ---------------------------------------------------------------------
-- UTILIDADES
-- ---------------------------------------------------------------------

-- Coloca o modelo "em pé" em cima de um ponto do chão
function ModelFactory.PlaceOnGround(model: Model, ground: CFrame, lift: number?)
	local boxCFrame, size = model:GetBoundingBox()
	local pivotOffset = boxCFrame:ToObjectSpace(model:GetPivot())
	local target = ground * CFrame.new(0, size.Y / 2 + (lift or 0), 0)
	model:PivotTo(target * pivotOffset)
end

-- Prepara o modelo para ser grudado (weld) no personagem
function ModelFactory.MakeWeldable(model: Model)
	prepare(model, false)
	local root = model.PrimaryPart
	if not root then
		return
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = descendant
			weld.Parent = root
		end
	end
end

-- ---------------------------------------------------------------------
-- MUTAÇÃO: pinta o modelo, troca o material e põe brilho/partículas
-- ---------------------------------------------------------------------

function ModelFactory.ApplyMutation(model: Model, mutationId: string?)
	if not mutationId then
		return
	end
	local mutation = GameConfig.MutationsById[mutationId]
	if not mutation then
		return
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = descendant.Color:Lerp(mutation.Color, 0.6)
			if mutation.Material and descendant.Name ~= "Eye" and descendant.Name ~= "Shine" then
				descendant.Material = mutation.Material
			end
		end
	end
	local root = model.PrimaryPart
	if not root then
		return
	end
	local light = Instance.new("PointLight")
	light.Color = mutation.Color
	light.Range = 9
	light.Brightness = 1.2
	light.Parent = root
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Mutacao"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(mutation.Color)
	sparkles.LightEmission = 0.7
	sparkles.Size = NumberSequence.new(0.35, 0)
	sparkles.Lifetime = NumberRange.new(0.6, 1.2)
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Rate = 8
	sparkles.Parent = root
end

-- ---------------------------------------------------------------------
-- NINHO SURPRESA: caixa dourada com "?" (abre no celeiro)
-- ---------------------------------------------------------------------

function ModelFactory.CreateLuckyNest(rarityId: string, scale: number?): Model
	local rarity = GameConfig.RarityById[rarityId]
	local s = scale or 1
	local model = Instance.new("Model")
	model.Name = "NinhoSurpresa"
	local gold = GameConfig.LuckyNest.Color
	local body = newPart(model, "Body", Vector3.new(2.8, 2.8, 2.8) * s, rarity.Color, CFrame.new())
	body.Material = Enum.Material.SmoothPlastic
	model.PrimaryPart = body
	newPart(model, "Faixa", Vector3.new(2.9, 0.6, 2.9) * s, gold, CFrame.new())
	newPart(model, "FaixaV", Vector3.new(0.6, 2.9, 2.9) * s, gold, CFrame.new())
	for _, face in Enum.NormalId:GetEnumItems() do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.LuckiestGuy
		label.TextScaled = true
		label.Text = "?"
		label.TextColor3 = Color3.new(1, 1, 1)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(28, 22, 40)
		stroke.Parent = label
		label.Parent = gui
		gui.Parent = body
	end
	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 10 * s
	light.Brightness = 1.5
	light.Parent = body
	prepare(model, true)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return model
end

return ModelFactory
