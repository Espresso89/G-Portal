private["_refObj","_size","_vel","_speed","_hunger","_thirst","_array","_unsaved","_timeOut","_result","_lastSave"];
disableSerialization;
_timeOut = 	0;
_messTimer = 0;
_lastSave = 0;
_lastTemp = dayz_temperatur;
_debug = getMarkerpos "respawn_west";
_isBandit = false;
_isHero = false;

player setVariable ["temperature",dayz_temperatur,true];

dayz_myLoad = (((count dayz_myBackpackMags) * 0.2) + (count dayz_myBackpackWpns)) +  (((count dayz_myMagazines) * 0.1) + (count dayz_myWeapons * 0.5));

	//player addMagazine "Hatchet_swing";
	//player addWeapon "MeleeHatchet";

while {true} do {
	//Initialize
	_refObj = 	vehicle player;
	_size = 	(sizeOf typeOf _refObj) * 0.6;
	_vel = 		velocity player;
	_speed = 	round((_vel distance [0,0,0]) * 3.5);
	_saveTime = (playersNumber west * 2) + 10;
		
	//reset position
	_randomSpot = true;
	_tempPos = getPosATL player;
	_distance = _debug distance _tempPos;
	if (_distance < 2000) then {
		_randomSpot = false;
	};	
	_distance = [0,0,0] distance _tempPos;
	if (_distance < 500) then {
		_randomSpot = false;
	};
	_distance = _mylastPos distance _tempPos;
	if (_distance > 400) then {
		_randomSpot = false;
	};
	
	if (_randomSpot) then {
		_mylastPos = _tempPos;
	};
	
	dayz_mylastPos = _mylastPos;
	dayz_areaAffect = _size;
	
	//CheckVehicle
	/*
	if (_refObj != player) then {
		_isSync =_refObj getVariable ["ObjectID",0] > 0;
		if (!_isSync) then {
			_veh allowDamage true;
			_veh setDamage 1;
			player setDamage 1;			
		};
	};
	*/
	
	if (_speed > 0.1) then {
		_timeOut = _timeOut + 1;
	};
	
	_humanity = player getVariable ["humanity",0];
	if (_timeOut > 150) then {
		_timeOut = 0;
		if (_humanity < 2500) then {
			_humanity = _humanity + 150;
			_humanity = _humanity min 2500;
			player setVariable ["humanity",_humanity,true];
		};
	};
	
	if (_humanity < -2000 and !_isBandit) then {
		_isBandit = true;
		_model = typeOf player;
		if (_model == "Survivor2_DZ") then {
			[dayz_playerUID,dayz_characterID,"Bandit1_DZ"] spawn player_humanityMorph;
		};
		if (_model == "SurvivorW2_DZ") then {
			[dayz_playerUID,dayz_characterID,"BanditW1_DZ"] spawn player_humanityMorph;
		};
	};
	
	if (_humanity > 0 and _isBandit) then {
		_isBandit = false;
		_model = typeOf player;
		if (_model == "Bandit1_DZ") then {
			[dayz_playerUID,dayz_characterID,"Survivor2_DZ"] spawn player_humanityMorph;
		};
		if (_model == "BanditW1_DZ") then {
			[dayz_playerUID,dayz_characterID,"SurvivorW2_DZ"] spawn player_humanityMorph;
		};
	};
	
	if (_humanity > 5000 and !_isHero) then {
		_isBandit = false;
		_model = typeOf player;
		if (_model == "Survivor2_DZ") then {
			[dayz_playerUID,dayz_characterID,"Survivor3_DZ"] spawn player_humanityMorph;
		};
	};
	
	//Has infection?
	//if (r_player_infected) then {
	//	[player,"cough",8,false] call dayz_zombieSpeak;
	//};

	//Record Check
	_lastUpdate = 	time - dayZ_lastPlayerUpdate;
	if (_lastUpdate > 8) then {
		//POSITION?
		_distance = dayz_myPosition distance player;
		if (_distance > 10) then {
			//Player has moved
			dayz_myPosition = getPosATL player;
			player setVariable["posForceUpdate",true,true];
			dayz_unsaved = true;
			dayZ_lastPlayerUpdate = time;
		};
	};

	//Hunger
	_hunger = +((((r_player_bloodTotal - r_player_blood) / r_player_bloodTotal) * 5) + _speed + dayz_myLoad) * 3;
	if (time - dayz_panicCooldown < 120) then {
		_hunger = _hunger * 2;
	};
	dayz_hunger = dayz_hunger + (_hunger / 60);

	//Thirst
	_thirst = 2;
	if (_refObj == player) then {
		_thirst = (_speed + 4) * 3;
	};
	dayz_thirst = dayz_thirst + (_thirst / 60) * (dayz_temperatur / dayz_temperaturnormal);	//TeeChange Temperatur effects added Max Effects: -25% and + 16.6% waterloss

	//Temperatur
	2 call player_temp_calculation; //2 = sleep time of this loop		//TeeChange
	if ((_lastTemp - dayz_temperatur) > 0.75 or (_lastTemp - dayz_temperatur) < -0.75 ) then {
		player setVariable ["temperature",dayz_temperatur,true];
		_lastTemp = dayz_temperatur;
	};
	
	//can get nearby infection
	if (!r_player_infected) then {
		//	Infectionriskstart
		if (dayz_temperatur < ((80 / 100) * (dayz_temperaturnormal - dayz_temperaturmin) + dayz_temperaturmin)) then {	//TeeChange
			_listTalk = _mylastPos nearEntities ["CAManBase",8];
			{
				if (_x getVariable["USEC_infected",false]) then {
					_rnd = (random 1) * (((dayz_temperaturnormal - dayz_temperatur) * (100 /(dayz_temperaturnormal - dayz_temperaturmin)))/ 50);	//TeeChange
					if (_rnd < 0.1) then {
						_rnd = random 1;
						if (_rnd > 0.7) then {
							r_player_infected = true;
							//player setVariable["USEC_infected",true];
						};
					};
				};
			} forEach _listTalk;
			if (dayz_temperatur < ((50 / 100) * (dayz_temperaturnormal - dayz_temperaturmin) + dayz_temperaturmin)) then {	//TeeChange
				_rnd = (random 1) * (((dayz_temperaturnormal - dayz_temperatur) * (100 /(dayz_temperaturnormal - dayz_temperaturmin)))/ 25);	//TeeChange
				if (_rnd < 0.05) then {
					_rnd = random 1;
					if (_rnd > 0.95) then {
						r_player_infected = true;
						//player setVariable["USEC_infected",true];
					};
				};
			};
		};
	};
	
	//If has infection reduce blood cough and add shake
	if (r_player_infected) then {
		if !(player getVariable["USEC_infected",false]) then { 
			player setVariable["USEC_infected",true,true];  
		};
		
		_rnd = ceil (random 8);
		[player,"cough",_rnd,false,9] call dayz_zombieSpeak;
		
		if (_rnd < 3) then {
			addCamShake [2, 1, 25];
		};
		if (r_player_blood > 3000) then {
			r_player_blood = r_player_blood - 3;
			player setVariable["USEC_BloodQty",r_player_blood];
		};
	};
	
	//Pain Shake Effects
	if (r_player_inpain and !r_player_unconscious) then {
		playSound "breath_1";
		addCamShake [2, 1, 25];
	};
	
	//Hunger Effect
	_foodVal = 		dayz_statusArray select 0;
	_thirstVal = 	dayz_statusArray select 1;
	if (_thirstVal <= 0) then {
		_result = r_player_blood - 10;
		if (_result < 0) then {
			_id = [player,"dehyd"] spawn player_death;
		} else {
			r_player_blood = _result;
		};
	};
	if (_foodVal <= 0) then {
		_result = r_player_blood - 10;
		if (_result < 0) then {
			_id = [player,"starve"] spawn player_death;
		} else {
			r_player_blood = _result;
		};
	};
	
	//Record low bloow
	_lowBlood = player getVariable ["USEC_lowBlood", false];
	if ((r_player_blood < r_player_bloodTotal) and !_lowBlood) then {
		player setVariable["USEC_lowBlood",true,true];
	};
	
	//Broadcast Hunger/Thirst
	_messTimer = _messTimer + 1;
	if (_messTimer > 15) then {
		_messTimer = 0;
		player setVariable ["messing",[dayz_hunger,dayz_thirst],true];
	};
	
	//check if can disconnect
	if (!dayz_canDisconnect) then {
		if ((time - dayz_damageCounter) > 180) then {
			if (!r_player_unconscious) then {
				dayz_canDisconnect = true;
				//["dayzDiscoRem",getPlayerUID player] call callRpcProcedure;
				dayzDiscoRem = getPlayerUID player;
				publicVariable "dayzDiscoRem";
				
				//Ensure Control is hidden
				_display = uiNamespace getVariable 'DAYZ_GUI_display';
				_control = 	_display displayCtrl 1204;
				_control ctrlShow false;
			};
		};
	};

	//Save Checker
	if (dayz_unsaved) then {
		if ((time - dayz_lastSave) > _saveTime) then {
			//["dayzPlayerSave",[player,dayz_Magazines,false]] call callRpcProcedure;
			
			dayzPlayerSave = [player,dayz_Magazines,false];
			publicVariableServer "dayzPlayerSave";
			
			if (isServer) then {
				dayzPlayerSave call server_playerSync;
			};
						
			dayz_lastSave = time;
			dayz_Magazines = [];
		};
		_lastSave = _lastSave + 2;
	} else {
		dayz_lastSave = time;
		_lastSave = 0;
	};

	if (!dayz_unsaved) then {
		dayz_lastSave = time;
	};

	//Attach Trigger Current Object
	//dayz_playerTrigger attachTo [_refObj,[0,0,0]];
	//dayz_playerTrigger setTriggerArea [_size,_size,0,false];

	//Debug Info
	_headShots =    player getVariable["headShots",0];
	_kills =                player getVariable["zombieKills",0];
	_killsH =               player getVariable["humanKills",0];
	_killsB =               player getVariable["banditKills",0];
	_humanity =             player getVariable["humanity",0];
	_fps = 									round(diag_fps);
	_zombies =              count entities "zZombie_Base";
	_zombiesA =     {alive _x} count entities "zZombie_Base";
	//_groups =             count allGroups;
	_dead =                       count allDead;
	dayz_zombiesLocal =           {local _x} count entities "zZombie_Base";
	//_loot =               count allMissionObjects "WeaponHolder";
	//_wrecks =             count allMissionObjects "Wreck_Base";
	//_lootL =              {local _x} count allMissionObjects "WeaponHolder";
	//_speed = (_vel distance [0,0,0]);
	if ((getPlayerUID player) in ["38789638"]) then {
		hintSilent parseText format["
			<t size='1.25' font='Bitstream' >%14<br /><br /></t>
			
			<t size='1' font='Bitstream' align='left' >Blood: </t><t size='1' font='Bitstream' align='right' >%4</t>
			<t size='1' font='Bitstream' align='left' ><br />Temperature: </t><t size='1' font='Bitstream' align='right' >%5</t>
			<t size='1' font='Bitstream' align='left' ><br />FPS: </t><t size='1' font='Bitstream' align='right' >%16</t>
			<t size='1' font='Bitstream' align='left' ><br />Zombies: </t><t size='1' font='Bitstream' align='right' >%17/%15/%8</t>
			<t size='1' font='Bitstream' align='left' ><br /><br />Murders:  </t><t size='1' font='Bitstream' align='right' >%10</t>
			<t size='1' font='Bitstream' align='left' ><br />Bandits Killed: </t><t size='1' font='Bitstream' align='right' >%12</t>
			<t size='1' font='Bitstream' align='left' ><br />Zombies Killed: </t><t size='1' font='Bitstream' align='right' >%1</t>
			<t size='1' font='Bitstream' align='left' ><br />Humanity: </t><t size='1' font='Bitstream' align='right' >%10</t>
			<t size='1' font='Bitstream' align='left' ><br />Players: </t><t size='1' font='Bitstream' align='right' >%18/%19</t>
			<t size='1' font='Bitstream' align='left' ><br />Server Uptime: </t><t size='1' font='Bitstream' align='right' >%6</t>
			<t size='1' font='Bitstream' align='left' >",_kills,_headShots,_speed,r_player_blood,round(dayz_temperatur),time,dayz_inside,_zombies,_lastSave,_killsH,round(_humanity),_killsB,_freeTarget,dayz_playerName,_zombiesA,_fps,dayz_zombiesLocal,(count playableUnits),_dead];
	} else {
		hintSilent parseText format["
			<t size='1.25' font='Bitstream' >%14<br /><br /></t>
			
			<t size='1' font='Bitstream' align='left' >Blood: </t><t size='1' font='Bitstream' align='right' >%4</t>
			<t size='1' font='Bitstream' align='left' ><br />Temperature: </t><t size='1' font='Bitstream' align='right' >%5</t>
			<t size='1' font='Bitstream' align='left' ><br />FPS: </t><t size='1' font='Bitstream' align='right' >%16</t>
			<t size='1' font='Bitstream' align='left' ><br /><br />Murders:  </t><t size='1' font='Bitstream' align='right' >%10</t>
			<t size='1' font='Bitstream' align='left' ><br />Bandits Killed: </t><t size='1' font='Bitstream' align='right' >%12</t>
			<t size='1' font='Bitstream' align='left' ><br />Zombies Killed: </t><t size='1' font='Bitstream' align='right' >%1</t>
			<t size='1' font='Bitstream' align='left' ><br />Players InGame: </t><t size='1' font='Bitstream' align='right' >%17</t>
			<t size='1' font='Bitstream' align='center' ><br />DE991 by Dayzforum.net </t><t size='1' font='Bitstream' align='right' ></t>
			<t size='1' font='Bitstream' align='left' >",_kills,_headShots,_speed,r_player_blood,round(dayz_temperatur),r_player_infected,dayz_inside,_zombies,_lastSave,_killsH,round(_humanity),_killsB,_freeTarget,dayz_playerName,_zombiesA,_fps,(count playableUnits)];
	};


	// If in combat, display counter and restrict logout
	_startcombattimer      = player getVariable["startcombattimer",0];
	if (_startcombattimer == 1) then {
		player setVariable["combattimeout", time + 30, true];
		player setVariable["startcombattimer", 0, true];
		dayz_combat = 1;
		player setVariable["incombat", 1, true];
	};

	_combattimeout = player getVariable["combattimeout",0];
	if (_combattimeout > 0) then {
		_timeleft = _combattimeout - time;
		if (_timeleft > 0) then {
			//hintSilent format["In Combat: %1",round(_timeleft)];
			player setVariable["incombat", 1, true];
		} else {
			//hintSilent "Not in Combat";
			player setVariable["combattimeout", 0, true];
			player setVariable["incombat", 0, true];
			dayz_combat = 0;
			_combatdisplay = uiNamespace getVariable 'DAYZ_GUI_display';
			_combatcontrol = 	_combatdisplay displayCtrl 1307;
			_combatcontrol ctrlShow true;
		};
	} else {
		//hintSilent "Not in Combat";
		player setVariable["incombat", 0, true];
		dayz_combat = 0;
		_combatdisplay = uiNamespace getVariable 'DAYZ_GUI_display';
		_combatcontrol = 	_combatdisplay displayCtrl 1307;
		_combatcontrol ctrlShow true;
	};
	
	/*
	setGroupIconsVisible [false,false];
	clearGroupIcons group player;
	*/
	"colorCorrections" ppEffectAdjust [1, 1, 0, [1, 1, 1, 0.0], [1, 1, 1, (r_player_blood/r_player_bloodTotal)],  [1, 1, 1, 0.0]];
	"colorCorrections" ppEffectCommit 0;
	sleep 2;
	
	_myPos = player getVariable["lastPos",[]];
	if (count _myPos > 0) then {
		player setVariable["lastPos",_mylastPos, true];
		player setVariable["lastPos",[]];
	};
	
	_lastPos = getPosATL player;	
	if (player == vehicle player) then {
		if (_mylastPos distance _lastPos > 200) then {
			if (alive player) then {
				player setPosATL _mylastPos;
			};
		};
	} else {
		if (_mylastPos distance _lastPos > 800) then {
			if (alive player) then {
				player setPosATL _mylastPos;
			};
		};
	};
	
	//Hatchet ammo fix	
	//"MeleeHatchet" call dayz_meleeMagazineCheck;
	
	//Crowbar ammo fix	
	//"MeleeCrowbar" call dayz_meleeMagazineCheck;
};