#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/zombies/_zm_sidequests;
#include maps/mp/zm_buried_sq;
#include maps/mp/zm_buried_sq_ip;
#include maps/mp/zm_buried_sq_ows;

main()
{
	replaceFunc( ::sq_bp_set_current_bulb, ::sq_bp_current_bulb ); 
	replaceFunc( ::ows_target_delete_timer, ::new_ows_target_delete_timer );
	replaceFunc( ::ows_targets_start, ::new_ows_targets_start);
	replaceFunc( ::sndhit, ::sndhitnew);
	level.targettohit = 19;
	level thread playertracker_onlast_step();
}

init()
{
	level.inital_spawn = true;
	thread onplayerconnect();
}

onplayerconnect()
{
	while(true)
	{
		level waittill("connecting", player);
		player thread onplayerspawned();
	}
}

onplayerspawned()
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self.initial_spawn = true;
	for(;;)
	{
		self waittill( "spawned_player" );
		if(level.inital_spawn)
		{
			level.inital_spawn = false;
		}
		if (self.initial_spawn)
		{
			self.initial_spawn = false;	
		}
	}
}

sq_bp_current_bulb( str_tag )
{
	level endon( "sq_bp_correct_button" );
	level endon( "sq_bp_wrong_button" );
	level endon( "sq_bp_timeout" );
	if ( isDefined( level.m_sq_bp_active_light ) )
	{
		level.str_sq_bp_active_light = "";
	}
	level.m_sq_bp_active_light = sq_bp_light_on( str_tag, "yellow" );
	level.str_sq_bp_active_light = str_tag;
	wait 1;
	sq_bp_light_on( str_tag, "green" );
	level notify( "sq_bp_correct_button" ); 
}

//sharpshooter functions - author: nathan31973
playertracker_onlast_step()
{
	// when the players are on the last step of rich EE we are going
	// to check how many players are in the lobby when this step is activated
	// and change the target require to be hit base on how many players are in
	// the session.
	level endon("game_end"); //kill this function on game end
	level endon("step_done"); //kill this function when the step is done (fail or sucess)
	for(;;)
	{
		wait 1;
		flag_wait("sq_ows_start");
		players = getPlayers();
		if(players.size == 1)
		{
			level.targettohit = 19; // Saloon has 19 target 
		}
		else if(players.size == 2)
		{
			level.targettohit = 39; // Saloon + outside the candy store (20)
		}
		else if(players.size == 3)
		{
			level.targettohit = 61; //Saloon + outside the candy store + Myster box area (big guy area 22)
		}
		else if(players.size >= 4) //All 4 areas of the map
		{
			level.targettohit = 84;
		}
		wait 45;
		// in game the players can miss some targets depending on what area they choose.
		if(level.targettohit >= 1) // resetting if the player hasn't hit all the target that is required
		{
			flag_set( "sq_ows_target_missed" );
			flag_clear("sq_ows_start");
		}
	}
}

//When a target spawn it has alive timer then it will despawn
new_ows_target_delete_timer()
{
	self endon( "death" );
	wait 5; // change this if you want the target to stay alive longer (3arc had this set to 4)
	self notify( "ows_target_timeout" );	
}

//when a target is hit play a sound
sndhitnew()
{
	self endon( "ows_target_timeout" );
	self waittill( "damage" );
	level.targettohit--; // target to hit does down
	//AllClientsPrint("target left to hit:" + level.targettohit); //debug
	self playsound( "zmb_sq_target_hit" );
}

//rip from 3arc but with some changes
new_ows_targets_start()
{
	n_cur_second = 0;
	flag_clear( "sq_ows_target_missed" );
	level thread sndsidequestowsmusic();
	a_sign_spots = getstructarray( "otw_target_spot", "script_noteworthy" );
	while ( n_cur_second < 40 )
	{
		a_spawn_spots = ows_targets_get_cur_spots( n_cur_second );
		if ( isDefined( a_spawn_spots ) && a_spawn_spots.size > 0 )
		{
			ows_targets_spawn( a_spawn_spots );
		}
		wait 1;
		n_cur_second++;
	}
	//AllClientsPrint("Waiting for target to stop spawning");
	if ( !flag( "sq_ows_target_missed" ) )
	{
		level notify("step_done"); // this allow us to close any function that have this on endon
		flag_set( "sq_ows_success" );
		playsoundatposition( "zmb_sq_target_success", ( 0, 0, 0 ) );
	}
	else
	{
		level notify("step_done"); // this allow us to close any function that have this on endon
		level thread playertracker_onlast_step();
		playsoundatposition( "zmb_sq_target_fail", ( 0, 0, 0 ) );
	}
	level notify( "sndEndOWSMusic" );
}