
local math_random = math.random
local eq = false
local forceValue = 1000.0

-- start the earthquake
function StartEarthquake(force, frequency, direction, seed)
	if (eq) then return end

	eq = true

	forceValue = force

	math.randomseed(seed)

	local inverseDirection = 1.0 - direction

	local ped = PlayerPedId()
	local isInAirOrWater = IsEntityInAir(ped) or IsEntityInWater(ped) or IsEntityInAir(GetVehiclePedIsIn(ped)) or IsEntityInWater(GetVehiclePedIsIn(ped))
	if (not isInAirOrWater) then
		ShakeGameplayCam(camShakeType, camShakeIntensity)
	end

	while (eq) do
		ped = PlayerPedId()

		-- cam shake
		local isPlayerInAir = IsEntityInAir(ped) or IsEntityInWater(ped) or IsEntityInAir(GetVehiclePedIsIn(ped)) or IsEntityInWater(GetVehiclePedIsIn(ped))
		if (not isInAirOrWater and isPlayerInAir) then
			isInAirOrWater = true
			StopGameplayCamShaking(true)
		elseif (isInAirOrWater and not isPlayerInAir) then
			isInAirOrWater = false
			ShakeGameplayCam(camShakeType, camShakeIntensity)
		end

		if (not isPlayerInAir and not isInAirOrWater and not IsGameplayCamShaking()) then
			ShakeGameplayCam(camShakeType, camShakeIntensity)
		end

		ProcessEntities(ped, direction, inverseDirection)

		Wait(1000 / frequency)

		ProcessEntities(ped, direction, inverseDirection)

		Wait(1000 / frequency)
	end

	StopGameplayCamShaking(true)

	Wait(1000)

	StopGameplayCamShaking(true)
end

-- stop the earthquake
function StopEarthquake()
	eq = false
end



-- apply forces and ragdolls to vehicles/objects/peds
local flip = -1
function ProcessEntities(ped, direction, inverseDirection)
	flip = -flip
	
	-- move vehicles
	local vehicles = GetVehicles()
	for i = 1, #vehicles do
		local appliedForce = GetRandomForceValue()
		local class = GetVehicleClass(vehicles[i])
		if (class == 8 or class == 13) then
			-- move bikes less
			ApplyForceToEntity(vehicles[i], 3,  flip * 0.2 * appliedForce * direction, flip * 0.2 * appliedForce * inverseDirection, 0.0,  0.0, 0.0, GetEntityHeight(vehicles[i]),  0, false, true, false, false, true)
		else
			ApplyForceToEntity(vehicles[i], 3,  flip * appliedForce * direction, flip * appliedForce * inverseDirection, 0.0,  0.0, 0.0, GetEntityHeight(vehicles[i]),  0, false, true, false, false, true)
		end
	end

	-- move objects
	local objects = GetObjects()
	for i = 1, #objects do
		local appliedForce = GetRandomForceValue()
		ApplyForceToEntity(objects[i], 3,  flip * appliedForce * direction * 0.001, flip * appliedForce * inverseDirection * 0.001, 0.0,  0.0, 0.0, GetEntityHeight(objects[i]),  0, false, true, true, false, true)
	end

	-- ragdoll peds
	local peds = GetPeds()
	for i = 1, #peds do
		if (math_random() < pedRagdollChance) then
			local pos = flip * GetEntityForwardVector(peds[i])
			SetPedToRagdollWithFall(peds[i], pedRagdollTime, pedRagdollRecoveryTime, 1, pos.x, pos.y, pos.z, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
		end
	end

	-- ragdoll player
	if (math_random() < playerRagdollChance and not IsPedInAnyVehicle(ped)) then
		local pos = flip * GetEntityForwardVector(ped)
		SetPedToRagdollWithFall(ped, playerRagdollTime, playerRagdollRecoveryTime, 1, pos.x, pos.y, pos.z, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	end
end

-- returns all eligible vehicles
function GetVehicles()
	local vehicles = {}

	local loadedVehicles = GetGamePool("CVehicle")
	for i = 1, #loadedVehicles do
		if (DoesEntityExist(loadedVehicles[i]) and NetworkHasControlOfEntity(loadedVehicles[i]) and not IsEntityInAir(loadedVehicles[i]) and not IsEntityInWater(loadedVehicles[i])) then
			vehicles[#vehicles + 1] = loadedVehicles[i]
		end
	end

	return vehicles
end

-- returns all eligible objects
function GetObjects()
	local objects = {}

	local position = GetFinalRenderedCamCoord()

	local loadedObjects = GetGamePool("CObject")
	for i = 1, #loadedObjects do
		if (DoesEntityExist(loadedObjects[i]) and (GetEntityShortestSideLength(loadedObjects[i]) < 1.0 or not IsEntityStatic(loadedObjects[i])) and #(position - GetEntityCoords(loadedObjects[i])) < 50.0 and not NetworkGetEntityIsNetworked(loadedObjects[i]) and not IsEntityInAir(loadedObjects[i])) then
			objects[#objects + 1] = loadedObjects[i]
		end
	end

	return objects
end

-- returns all eligible peds
function GetPeds()
	local peds = {}

	local position = GetFinalRenderedCamCoord()

	local playerPed = PlayerPedId()

	local loadedPeds = GetGamePool("CPed")
	for i = 1, #loadedPeds do
		if (playerPed ~= loadedPeds[i] and DoesEntityExist(loadedPeds[i]) and NetworkHasControlOfEntity(loadedPeds[i]) and #(position - GetEntityCoords(loadedPeds[i])) < 100.0 and not IsEntityInAir(loadedPeds[i])) then
			peds[#peds + 1] = loadedPeds[i]
		end
	end

	return peds
end

-- returns the height of an entity
function GetEntityHeight(entity)
	local min, max = GetModelDimensions(GetEntityModel(entity))
	return (max.z - min.z) * 0.5
end

-- returns the shortest side of an entity
function GetEntityShortestSideLength(entity)
	local min, max = GetModelDimensions(GetEntityModel(entity))
	local sizeX, sizeY, sizeZ = max.x - min.x, max.y - min.y, max.z - min.z
	if (sizeX < sizeY and sizeX < sizeZ) then
		return sizeX
	elseif (sizeY < sizeZ) then
		return sizeY
	end

	return sizeZ
end

-- slightly randomize force value
function GetRandomForceValue()
	return forceValue * (1.5 - math_random())
end



AddStateBagChangeHandler("earthquake", nil, function(bagName, key, value, _unused, replicated)
	if (value) then
		StartEarthquake(value[1], value[2], value[3], value[4])
	else
		StopEarthquake()
	end
end)

-- start earthquake on player that connected while it was already running
CreateThread(function()
	local earthquake = GlobalState.earthquake
	if (earthquake) then
		StartEarthquake(earthquake[1], earthquake[2], earthquake[3], earthquake[4])
		ShakeGameplayCam("ROAD_VIBRATION_SHAKE", 2.0)
	end
end)
