
local function StartEarthquake(force, frequency, direction, seed)
	GlobalState.earthquake = { 
		force		or 1000.0, 
		frequency	or 3.0, 
		direction	or math.random(), 
		seed		or os.time() 
	}
end
exports("StartEarthquake", StartEarthquake)

local function StopEarthquake()
	GlobalState.earthquake = nil
end
exports("StopEarthquake", StopEarthquake)



RegisterCommand("eq", function(src, args, raw)
	if (GlobalState.earthquake) then
		StopEarthquake()
	else
		local force		= tonumber(args[1])
		local frequency	= tonumber(args[2])

		StartEarthquake(force, frequency, nil, nil)
	end
end, true)
