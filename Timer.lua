﻿--[[

Timer routines for flight timers.

Code inspired by Kwarz's flightpath.

]]

-- Function: Update
function EFM_Timer_EventFrame_OnUpdate()
	if (EFM_MyConf ~= nil) then
		local ctime;
		
		-- Timer Setup/End
		if (UnitOnTaxi("player")) then
--			EFM_Shared_DebugMessage("Player is currently on a taxi", Lys_Debug)

			if (EFM_Timer_StartRecording == true) then
				EFM_Shared_DebugMessage("We should start recording the flight time.", Lys_Debug);

				EFM_Timer_StartRecording	= false;
				EFM_Timer_Recording	    	= true;
				EFM_Timer_OrigContinent 	= EFM_Shared_GetCurrentContinentName();
			end
		else
			-- Hide timers
			EFM_FlightStatus:Hide();
		

			if (EFM_Timer_Recording == true) then
				EFM_Shared_DebugMessage("End flight time recording.", Lys_Debug);

				-- End of the road, stop recording
				EFM_Timer_Recording		= false;
				EFM_Timer_StartRecording	= false;

				EFM_NI_AddNode_FlightDuration(EFM_TaxiOrigin, EFM_TaxiDestination, (time() - EFM_Timer_StartTime), EFM_Timer_NodeStyle);
				EFM_TaxiDestination		= nil;

			end
		end

		if (EFM_MyConf.Timer == true) then
			if (UnitOnTaxi("player")) then
				ctime = time();
--				EFM_Shared_DebugMessage("We're recording a time, current time elapsed is "..ctime, Lys_Debug)

				if(ctime ~= EFM_Timer_LastTime) then
					-- Calculate elapsed time.
					local timeElapsed = ctime - EFM_Timer_LastTime;
					
--					EFM_Shared_DebugMessage("We're recording a time, current time elapsed is "..(time() - EFM_Timer_StartTime), Lys_Debug);

					-- Decrease in flight time remaining.
					EFM_Timer_TimeRemaining = EFM_Timer_TimeRemaining - timeElapsed;

					-- Show timer window.
					EFM_Timer_ShowInFlightTimer(EFM_Timer_TimeRemaining);

					-- Set the last time to the current time.
					EFM_Timer_LastTime = ctime;
				end
			else
				EFM_FlightStatus:Hide();
			end
		else
			EFM_FlightStatus:Hide();
		end
	end
end

-- Function: Determine remote location from taxi node
function EFM_Timer_TakeTaxiNode(nodeID)
	EFM_TaxiDestination	= TaxiNodeName(nodeID);
	EFM_Timer_TimeRemaining	= 0;
	EFM_Timer_StartTime	= time();
	EFM_Timer_LastTime	= EFM_Timer_StartTime;

	EFM_Shared_DebugMessage("We're flying to "..EFM_TaxiDestination, Lys_Debug);
	
	-- Check if swimming, if so, set node style to match
	if (IsSwimming() == 1) then
		EFM_Timer_NodeStyle = 1;
	end

	local flightTime		= EFM_NI_GetNode_FlightDuration(EFM_TaxiOrigin, EFM_TaxiDestination, EFM_Timer_NodeStyle);

	-- If there is a known flight time, calculate the duration estimate
	if (flightTime ~= nil) then
		EFM_Timer_TimeRemaining	= flightTime;
		EFM_Timer_FlightTime	= flightTime;
		EFM_Timer_TimeKnown	= true;
	else
		EFM_Timer_TimeKnown 	= false;
		EFM_Timer_FlightTime	= 0;
	end

	EFM_Timer_StartRecording    = true;
end

-- Function: In flight timer
function EFM_Timer_ShowInFlightTimer(timeLeft)
	if (EFM_TaxiDestination ~= nil) then
		EFM_FlightStatus_DestLabel:SetText(EFM_FT_DESTINATION..EFM_TaxiDestination);
	else
		EFM_FlightStatus:Hide();
		return;
	end

	-- Position the destination line of the timer frame as per the configuration.
	EFM_FlightStatus:ClearAllPoints();
	EFM_FlightStatus:SetPoint("CENTER", UIParent, "CENTER", 0, EFM_MyConf.TimerPosition);
	EFM_FlightStatus:Show();

	-- Hide the Status Bar as we might not wish to be displaying it all the time.
	EFM_FlightStatusPanel1:Hide();

	-- Reset the timer window scaling, as this can easily change.
	EFM_FlightStatus_TimerLabel:SetText("");
	EFM_FlightStatus_Timer:SetScale(EFM_MyConf.TimerSize);
	EFM_FlightStatusPanel1:SetScale(EFM_MyConf.TimerSize);

	-- Unfortunately WoW UI Designer does not let me set a panel location relative to another frame/panel, this corrects that oversight.
	EFM_FlightStatus_Timer:ClearAllPoints();
	EFM_FlightStatus_Timer:SetPoint("CENTER", EFM_FlightStatus, "CENTER", 0, -10);
	EFM_FlightStatusPanel1:ClearAllPoints();
	EFM_FlightStatusPanel1:SetPoint("CENTER", EFM_FlightStatus, "CENTER", 0, -10);

	if(EFM_Timer_TimeRemaining > 0) then
		-- Show text status
		EFM_FlightStatus_TimerLabel:SetText(EFM_FT_ARRIVAL_TIME..EFM_SF_FormatTime(timeLeft));

		-- Handle the Status Bar
		if (EFM_MyConf.ShowTimerBar) then
			EFM_FlightStatus_StatusBar:SetMinMaxValues(0, EFM_Timer_FlightTime);

			-- Handle the grow right/left option.
			if (EFM_MyConf.ShrinkStatusBar == true) then
				EFM_FlightStatus_StatusBar:SetValue(timeLeft);
			else
				EFM_FlightStatus_StatusBar:SetValue(EFM_Timer_FlightTime - timeLeft);
			end

			-- Show the status bar if we are showing it.
			EFM_FlightStatusPanel1:Show();
		end
	else
		if (not EFM_Timer_TimeKnown) then
			-- Display the flight timer screen if the time to destination is unknown as that way people will see it is online.
			EFM_FlightStatus_TimerLabel:SetText(EFM_FT_ARRIVAL_TIME..UNKNOWN);
		else
			-- Display the flight timer as incorrect
			EFM_FlightStatus_TimerLabel:SetText(EFM_FT_INCORRECT);
		end
	end
end

--[[
-- DO NOTE REMOVE, WE MIGHT HANDLE THESE ONCE AGAIN IN THE FUTURE! --

-- Function: Replacement GossipTitleButton_OnClick to check for flightpath options.
function EFM_GossipTitleButton_OnClick()
	if ( this.type == "Available" ) then
		SelectGossipAvailableQuest(self:GetID());
	elseif ( this.type == "Active" ) then
		SelectGossipActiveQuest(self:GetID());
	else
		local button_text	= self:GetText();
--		DEFAULT_CHAT_FRAME:AddMessage(button_text);
--		DEFAULT_CHAT_FRAME:AddMessage(EFM_TEST_NIGHTHAVEN);

		if (string.find(button_text, EFM_TEST_NIGHTHAVEN) ~= nil) then
--			DEFAULT_CHAT_FRAME:AddMessage("EFM: Nighthaven Flight Path option");
		
			local orig		= EFM_NIGHTHAVEN;
			local destNode	= nil;
			local routeList	= {};

			EFM_FN_AddNode(orig, "0.549", "0.807", "44.34", "45.91");
            SetMapToCurrentZone();
			EFM_KP_AddLocation(GetCurrentMapContinent(), orig);

			if (UnitFactionGroup("player") == FACTION_HORDE) then
				destNode	= EFM_FN_GetNodeByName("Thunder Bluff, Mulgore", "enUS");
				local _, _, tempRouteData = string.find(EFM_FN_GetRouteDataByName("Thunder Bluff, Mulgore"), ".*~(.*)");
				routeList["Thunder Bluff, Mulgore"] = tempRouteData;
			elseif (UnitFactionGroup("player") == FACTION_ALLIANCE) then
				destNode	= EFM_FN_GetNodeByName("Rut'theran Village, Teldrassil", "enUS");
				local _, _, tempRouteData = string.find(EFM_FN_GetRouteDataByName("Rut'theran Village, Teldrassil"), ".*~(.*)");
				routeList["Rut'theran Village, Teldrassil"] = tempRouteData;				
			end
			EFM_FN_AddRoutes(orig, routeList);

			if (destNode ~= nil) then
--				DEFAULT_CHAT_FRAME:AddMessage("EFM: Destination node known.");
				EFM_TaxiDestination		= destNode[GetLocale()];
				EFM_TaxiOrigin			= orig;

				EFM_Timer_TimeRemaining	= 0;
				EFM_Timer_StartTime		= time();
				EFM_Timer_LastTime		= EFM_Timer_StartTime;

				local flightTime			= EFM_FN_GetFlightDuration(EFM_TaxiOrigin, EFM_TaxiDestination);

				-- If there is a known flight time, calculate the duration estimate
				if (flightTime ~= nil) then
					EFM_Timer_TimeRemaining	= flightTime;
					EFM_Timer_FlightTime		= flightTime;
					EFM_Timer_TimeKnown		= true;
				else
					EFM_Timer_TimeKnown	= false;
					EFM_Timer_FlightTime	= 0;
				end

				EFM_Timer_StartRecording = true;
			end
		end

		SelectGossipOption(self:GetID());
	end
end
]]

