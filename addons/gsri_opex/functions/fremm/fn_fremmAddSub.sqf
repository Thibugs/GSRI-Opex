params["_ship"];

// Submarine and teleport handles spawn
if(isServer) then {
	private ["_sub","_mk","_toSub","_toShip"];
	// Spawn and place sub
	_sub = "Submarine_01_F" createVehicle [0,0,0];
	_sub enableSimulation false;
	_ship setVariable ["GSRI_FREMM_submarine", _sub, true];
	_sub setPosASL [(getPosASL _ship select 0) + 100, (getPosASL _ship select 1) + 100, (getPosASL _ship select 2)-10];
	_sub setDir getDir _ship;
	_sub setVariable ["GSRI_FREMM_shipIndex", _ship getVariable "GSRI_FREMM_shipIndex"];

	// Add map marker
	_mk = createMarker [format["marker_submarine_%1", _sub getVariable "GSRI_FREMM_shipIndex"], _sub];
	_mk setMarkerType "flag_France";
	_mk setMarkerText "S-625 Devigny";

	// Create handle for TP to sub
	_toSub = "Land_Battery_F" createVehicle [0,0,0];
	_toSub enableSimulation false;
	_toSub attachTo [_ship,[-2.21198,13.976,7.537]];
	_ship setVariable ["GSRI_FREMM_submarine_toSub", _toSub, true];

	// Handle for TP to ship
	_toShip = "Land_Battery_F" createVehicle [0,0,0];
	_toShip enableSimulation false;
	_toShip attachTo [_ship getVariable "GSRI_FREMM_submarine", [0.0788574,-4.32037,3.1]];
	_ship setVariable ["GSRI_FREMM_submarine_toShip", _toShip, true];
};

// Adding position selection eventHandler
addMissionEventHandler ["MapSingleClick", GSRI_fnc_subSelectPos];

// Adding "abort selection" eventHandler
addMissionEventHandler ["Map", {
	// params ["_opened", "_forced"];
	params ["_opened"];
	// Detect if map is closed but do not check if the event is linked to this module
	if!(_opened) then {
		player setVariable ["GSRI_FREMM_submarine_token", false];
		if!(player getVariable ["GSRI_FREMM_submarine_hadMap",true]) then { player unlinkItem "ItemMap"; player setVariable ["GSRI_FREMM_submarine_hadMap", nil] };
	};
}];

// Clientside jobs
if!(isDedicated) then {
	// Create handle for sub movement
	private _com = "Land_Battery_F" createVehicleLocal [0,0,0];
	_com enableSimulation false;
	_com attachTo [_ship, [-2.94995,-34.0001,20.6]];

	// Add actions with map selection
	private _statement = {
		if!("ItemMap" in assignedItems player) then { player setVariable ["GSRI_FREMM_submarine_hadMap", false]; player linkItem "ItemMap" };
		// Open the map
		openMap true;

		// Set the "submarine token" for the eventHandler to fire correctly
		player setVariable ["GSRI_FREMM_submarine_token", true];

		// Help notification
		["SubmarineInfo"] call BIS_fnc_showNotification;
	};
	private _actionSelectPos = ["submarineSelectPosition",localize "STR_GSRI_FREMM_submarine_selectPos","",_statement,{true}] call ace_interact_menu_fnc_createAction;
	[_com, 0, [], _actionSelectPos] call ace_interact_menu_fnc_addActionToObject;

	// Add teleport action
	{
		// Select the handle opposite to the one the player is interacting with
		private _targetName = ["toSub", "toShip"] select (_x == "toSub");
		private _statement = {
			// params["_target", "_player", "_params"];
			params["", "_player", "_params"];
			_params params["_ship","_targetName"];
			_player setPosASL getPosASL (_ship getVariable (format["GSRI_FREMM_submarine_%1", _targetName]));
		};
		private _actionGo = [format["action_%1",_x], localize format ["STR_GSRI_FREMM_submarine_go_%1", _x], "",_statement,{true},{},[_ship, _targetName]] call ace_interact_menu_fnc_createAction;
		[(_ship getVariable format ["GSRI_FREMM_submarine_%1",_x]), 0, [], _actionGo] call ace_interact_menu_fnc_addActionToObject;
	} forEach ["toSub", "toShip"];
	
	// Add CRRC deploy/retrieve actions
	private _sub = _ship getVariable "GSRI_FREMM_submarine";
	private _spawner = "Land_HelipadEmpty_F" createVehicleLocal [0,0,0];
	_spawner attachTo [_sub, [0,17.4,5]];
	_sub setVariable ["GSRI_FREMM_sub_crrcSpawner", _spawner];

	private _handle = "Land_Battery_F" createVehicleLocal [0,0,0];
	_handle attachTo [_sub, [0,12,3.74]];
	_handle setVariable ["GSRI_FREMM_associatedSub", _sub];
	_handle setVariable ["GSRI_FREMM_associatedSpawner", _spawner];

	private _crrcActions = [
		["actionCRRC","CRRC",{}],
		["actionCRRCSpawn","Spawn CRRC",GSRI_fnc_spawnCRRC],
		["actionCRRCRetrieve","Retrieve CRRC",GSRI_fnc_retrieveCRRC]
	];
	{
		private _action = [_x select 0,_x select 1,"",_x select 2,{true}] call ace_interact_menu_fnc_createAction;
		[_handle, 0, [], _action] call ace_interact_menu_fnc_addActionToObject;
	} forEach _crrcActions;
};