--[[

nodeinfo.lua

This file contains all the various information routines related to flight nodes.

]]

-- Function: Check if player is flagged to know a flight path.
function EFM_NI_CheckReachable(myNode)
	local myDebug 		= false;
	local myContinent	= EFM_Shared_GetCurrentContinentName();

	EFM_Shared_DebugMessage("Checking if node "..myNode.." is reachable", myDebug);
	
	if (EFM_ReachableNodes ~= nil) then
		for myContinent in pairs(EFM_ReachableNodes) do
			for key, val in pairs(EFM_ReachableNodes[myContinent]) do
					EFM_Shared_DebugMessage("Key "..key.. "Val "..val, myDebug);
				if (val == myNode) then
					EFM_Shared_DebugMessage("Yes it is!", myDebug);
					return true;
				end
			end
		end
	end
	EFM_Shared_DebugMessage("Awww, no it's not!", myDebug);
	return false;
end

-- Function: Record that the player can reach this flight master.
function EFM_NI_Reachable(myContinent, myNode, status)
	if (EFM_ReachableNodes == nil) then
		EFM_ReachableNodes = {};
	end

	if (EFM_ReachableNodes[myContinent] == nil) then
		EFM_ReachableNodes[myContinent] = {};
	end

	if (not EFM_NI_CheckReachable(myContinent, myNode)) then
		table.insert(EFM_ReachableNodes[myContinent], myNode);
		--EFM_NI_AddFaction(myNode);
	end
end

-- Function: Create a base node entry.
function EFM_NI_CreateNode(continent, nodeName, nodeStyle)
	local myNodes		= EFM_Data;

	local myContinent	= EFM_Shared_GetCurrentContinentName();
	local myZone		= EFM_Shared_GetCurrentZoneName();

	if (nodeStyle == 1) then
		myNodes		= EFM_WaterNodes;
		EFM_Shared_DebugMessage("Adding Water Node.", Lys_Debug);
	end
	
	EFM_Shared_DebugMessage("Adding entry for "..nodeName, Lys_Debug);

	if (myNodes == nil) then
		myNodes = {};
	end

	if (myNodes[EFM_Global_Faction] == nil) then
		myNodes[EFM_Global_Faction] = {};
	end

	if (myNodes[EFM_Global_Faction][myContinent] == nil) then
		myNodes[EFM_Global_Faction][myContinent] = {};
	end

	if (myNodes[EFM_Global_Faction][myContinent][myZone] == nil) then
		myNodes[EFM_Global_Faction][myContinent][myZone] = {};
	end

	if (myNodes[EFM_Global_Faction][myContinent][myZone][nodeName] == nil) then
		myNodes[EFM_Global_Faction][myContinent][myZone][nodeName] = {};
	end

	myNodes[EFM_Global_Faction][myContinent][myZone][nodeName]["name"] = nodeName;
	EFM_KP_AddLocation(continent, nodeName);
end

-- Function: Return the node entry for a given node name.
function EFM_NI_GetNodeByName(searchNodeName, nodeStyle, partialSearch)
	local myDebug = false;

	local myData;

	if (nodeStyle == 1) then
		myData = EFM_WaterNodes;
		EFM_Shared_DebugMessage("Searching Water Nodes.", myDebug);
	else
		myData = EFM_Data;
		EFM_Shared_DebugMessage("Searching Land Nodes.", myDebug);
	end

	if (partialSearch ~= nil) then
		EFM_Shared_DebugMessage("partialSearch = "..partialSearch);
	end
	
	if (myData ~= nil) then
		if (myData[EFM_Global_Faction] ~= nil) then
			for myContinent in pairs(myData[EFM_Global_Faction]) do
				for myZone in pairs(myData[EFM_Global_Faction][myContinent]) do
					for myNode in pairs(myData[EFM_Global_Faction][myContinent][myZone]) do
						if (myNode == searchNodeName) then
							EFM_Shared_DebugMessage("Found Node "..searchNodeName..".", myDebug);
							return myData[EFM_Global_Faction][myContinent][myZone][myNode];
						end
						
						if (partialSearch == 1) then
							if (string.find(myNode, searchNodeName) ~= nil) then
								EFM_Shared_DebugMessage("Partial search found "..searchNodeName.." in a node named "..myNode..".", myDebug);
								return myData[EFM_Global_Faction][myContinent][myZone][myNode];
							end
						end
					end
				end
			end
		end
	end

	return nil;
end

-- Function: Get continent name from zone name
function EFM_NI_GetContinentByZone(searchZoneName)
	local myDebug	= false;
	local myData	= EFM_Data;

	if (myData ~= nil) then
		if (myData[EFM_Global_Faction] ~= nil) then
			for myContinent in pairs(myData[EFM_Global_Faction]) do
				for myZone in pairs(myData[EFM_Global_Faction][myContinent]) do
					if (myZone == searchZoneName) then
						EFM_Shared_DebugMessage("GFBZ: Found Zone "..searchZoneName..".", myDebug);
						return myContinent;
					end
				end
			end
		end
	end

	-- Error message?
	EFM_Shared_DebugMessage("GFBZ: Did not find zone "..searchZoneName, myDebug);

	-- Fallback, gives a value that should never (hopefully) equate to a continent name.
	return "NO DATA FOR ZONE NAME";
end


-- Function: Add the flight map location to a node.
function EFM_NI_AddNode_fmLoc(nodeName, X, Y, nodeStyle)
	local myNode = EFM_NI_GetNodeByName(nodeName, nodeStyle);
	if (myNode ~= nil) then
		myNode["fmLoc"] = {};
		myNode["fmLoc"]["x"] = tostring(X);
		myNode["fmLoc"]["y"] = tostring(Y);
	end
end

-- Function: Add the map location to a node, by map level
function EFM_NI_AddNodeLoc(nodeName, nodeStyle, mapLevel)
	local myNode = EFM_NI_GetNodeByName(nodeName, nodeStyle);
	local X, Y
	EFM_Shared_DebugMessage("NodeName "..nodeName.." level "..mapLevel, Lys_Debug);

	-- Crap. This should work for any locale.
	if (nodeName == C_Map.GetMapInfo(125).name and mapLevel == 3) then
		X, Y = EFM_Shared_GetCurrentMapPosition(4);
		EFM_Shared_DebugMessage("Fixing Dalaran Coords...", Lys_Debug);
	else
		X, Y = EFM_Shared_GetCurrentMapPosition(mapLevel);
	end
	if (myNode ~= nil) then
		if (mapLevel == 3) then
			X = floor(X * 10000) / 100;
			Y = floor(Y * 10000) / 100;
		end

		myNode[EFM_LocTypes[mapLevel]] = {};
		myNode[EFM_LocTypes[mapLevel]]["x"] = tostring(X);
		myNode[EFM_LocTypes[mapLevel]]["y"] = tostring(Y);
	end
end

-- Function: Add a list of routes to a node.
function EFM_NI_AddRoutes(nodeName, routeList, nodeStyle)
	local myNode = EFM_NI_GetNodeByName(nodeName, nodeStyle);
	if (myNode ~= nil) then
		if (myNode["routes"] == nil) then
			myNode["routes"] = {};
		end
		for index, route in pairs(routeList) do
			if (not EFM_SF_StringInTable(myNode["routes"], route)) then
				table.insert(myNode["routes"], route);
			end
		end
	end
end

-- Function: Add the flight duration to a node.
function EFM_NI_AddNode_FlightDuration(nodeName, destNodeName, flightDuration, nodeStyle)
	EFM_Shared_DebugMessage("Adding duration from "..nodeName.." to "..destNodeName..". Time was "..flightDuration, Lys_Debug);

	local myNode = EFM_NI_GetNodeByName(nodeName, nodeStyle);

	if (myNode["timers"] == nil) then
		myNode["timers"] = {};
	end

	-- If no timer set, add one, if one already set, average the two times.
	if (myNode["timers"][destNodeName] == nil) then
        EFM_Shared_DebugMessage("Adding a new timer", Lys_Debug);
		myNode["timers"][destNodeName] = flightDuration; 
    else
		local avgtime = floor((myNode["timers"][destNodeName] + flightDuration) / 2);
		if (avgtime > 30) then     
			-- If there are more than 30 seconds of discrepancy use the last timer without averaging
			-- The difference is so big that the recorded timer should be incomplete or has been changed by Blizzard
			EFM_Shared_DebugMessage("Replacing the previous recorded timer that was "..myNode["timers"][destNodeName] , Lys_Debug);
			myNode["timers"][destNodeName] = flightDuration;   
		else
			EFM_Shared_DebugMessage("Averaging timer to "..avgtime.." The previous recorded timer was "..myNode["timers"][destNodeName], Lys_Debug);
			myNode["timers"][destNodeName] = avgtime;
		end
	end
end

-- Function: Return the flight duration.
function EFM_NI_GetNode_FlightDuration(nodeName, destNodeName, nodeStyle)
	local myNode = EFM_NI_GetNodeByName(nodeName, nodeStyle);

	if (myNode == nil) then
		return nil;
	end

	if (myNode["timers"] == nil) then
		return nil;
	end

	if (myNode["timers"][destNodeName] == nil) then
		return nil;
	end

	return myNode["timers"][destNodeName];
end

-- Function: Return the node given by the flight master map x/y co-ordinates.
function EFM_NI_GetNode_fmLoc(X, Y, nodeStyle, myContinent)
	local myNodeName;
	local myDebug	= false;
	local myData	= EFM_Data;

	if (nodeStyle == 1) then
		myData	= EFM_WaterNodes;
	end

	EFM_Shared_DebugMessage("Searching Continent : "..myContinent, myDebug);
	
	if (myData[EFM_Global_Faction] ~= nil) then
		if (myData[EFM_Global_Faction][myContinent] ~= nil) then
			for myZone in pairs(myData[EFM_Global_Faction][myContinent]) do
				for myNode in pairs(myData[EFM_Global_Faction][myContinent][myZone]) do
					if (myData[EFM_Global_Faction][myContinent][myZone][myNode]["fmLoc"] ~= nil) then
						local nodeX = myData[EFM_Global_Faction][myContinent][myZone][myNode]["fmLoc"]["x"];
						nodeX = tonumber(nodeX);
						local nodeY = myData[EFM_Global_Faction][myContinent][myZone][myNode]["fmLoc"]["y"]
						nodeY = tonumber(nodeY);
						if ((nodeX == X) and (nodeY == Y)) then
							myNodeName = myData[EFM_Global_Faction][myContinent][myZone][myNode]["name"];
						end
					end
				end
			end
		else
			EFM_Shared_DebugMessage("Faction: "..EFM_Global_Faction..", Continent: "..myContinent, myDebug);
		end
	end

	return myNodeName;
end

-- Function: Return the list of nodes for a given continent number.
function EFM_NI_GetNode_List(myContinent)
	local myDebug		= false;
	local nodeList		= {};

	if (myContinent == nil) then 
		myContinent = "unknown";
		EFM_Shared_DebugMessage("myContinent is empty, why? ", myDebug);
	end

	if (EFM_Data == nil) then
		EFM_Shared_DebugMessage("GetNodeList: EFM_Data == nil", myDebug);
		return nil;
	end

	if (EFM_Data[EFM_Global_Faction] == nil) then
		EFM_Shared_DebugMessage("GetNodeList: EFM_Data[faction] == nil", myDebug);
		return nil;
	end

	if (EFM_Data[EFM_Global_Faction][myContinent] == nil) then
		EFM_Shared_DebugMessage("GetNodeList: EFM_Data[faction][continent] == nil", myDebug);
		EFM_Shared_DebugMessage("GetNodeList: myContinent == "..myContinent, myDebug);
		return nil;
	end

	for myZone in pairs(EFM_Data[EFM_Global_Faction][myContinent]) do
		for myNode in pairs(EFM_Data[EFM_Global_Faction][myContinent][myZone]) do
			EFM_Shared_DebugMessage("Continent Node Added: "..EFM_Data[EFM_Global_Faction][myContinent][myZone][myNode]["name"], myDebug);
			table.insert(nodeList, EFM_Data[EFM_Global_Faction][myContinent][myZone][myNode]["name"]);
		end
	end
	
	return nodeList;
end

-- Function: Return the list of nodes in a given zone.
function EFM_NI_GetNodeListByZone(zoneName)
	local myDebug		= false;
	local nodeList		= {};

	if (EFM_Data == nil) then
		return nil;
	end
	
	if (EFM_Data[EFM_Global_Faction] == nil) then
		return nil;
	end
	
	for myContinent in pairs(EFM_Data[EFM_Global_Faction]) do
		if (EFM_Data[EFM_Global_Faction][myContinent][zoneName] ~= nil) then
			for myNode in pairs(EFM_Data[EFM_Global_Faction][myContinent][zoneName]) do
				EFM_Shared_DebugMessage("Zone Node Added: "..EFM_Data[EFM_Global_Faction][myContinent][zoneName][myNode]["name"], myDebug);
				table.insert(nodeList, EFM_Data[EFM_Global_Faction][myContinent][zoneName][myNode]["name"]);
			end
		end
	end
	
	return nodeList;
end

-- Function: Return a flight node "fuzzily", as in, offset perhaps a little from where the flight master window lists it.
-- Blizzard often shoves nodes in the flight map in slightly different locations depending on if you are there or not.
-- Later patches sometimes fix these, but not always, and phasing also can affect this.
function EFM_NI_GetNode_fmLoc_Fuzzy(nodeX, nodeY, continent)
	local myNode;

	local myDebug		= false;

	local maxOffset		= 1;
	local offsetStep	= 1;

	-- Test the original co-ordinates.
	myNode = EFM_NI_GetNode_fmLoc(nodeX, nodeY, 0, continent);
	if (myNode ~= nil) then
		EFM_Shared_DebugMessage("Found Node "..myNode, myDebug);
		return myNode;
	end

	-- Test new co-ordinates to a maximum of maxOffset from original
	for offset = -maxOffset, maxOffset, offsetStep do
		local roffset = offset/100;
		EFM_Shared_DebugMessage("Testing with offset of "..roffset..".", myDebug);

		-- Adjust X
		myNode = EFM_NI_GetNode_fmLoc(nodeX + roffset, nodeY, 0, continent);
		if (myNode ~= nil) then
			EFM_Shared_DebugMessage("Found Node at "..(nodeX + roffset)..", "..nodeY..".", myDebug);
			return myNode;
		end

		-- Adjust Y
		myNode = EFM_NI_GetNode_fmLoc(nodeX, nodeY - roffset, 0, continent);
		if (myNode ~= nil) then
			EFM_Shared_DebugMessage("Found Node at "..nodeX..", "..(nodeY - roffset)..".", myDebug);
			return myNode;
		end

		-- Adjust Both
		myNode = EFM_NI_GetNode_fmLoc(nodeX + roffset, nodeY + roffset, 0, continent);
		if (myNode ~= nil) then
			EFM_Shared_DebugMessage("Found Node at "..(nodeX + roffset)..", "..(nodeY + roffset)..".", myDebug);
			return myNode;
		end

		-- Adjust Both, reversing Y
		-- This should deal with +X -Y OR -X +Y due to the values starting at a negative number
		myNode = EFM_NI_GetNode_fmLoc(nodeX + roffset, nodeY - roffset, 0, continent);
		if (myNode ~= nil) then
			EFM_Shared_DebugMessage("Found Node at "..(nodeX + roffset)..", "..(nodeY - roffset)..".", myDebug);
			return myNode;
		end
	end
end
