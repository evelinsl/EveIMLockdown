string findUser = "cce363c7-9f86-4d11-a0fd-78e2d82fbfe8"; 
float range = 2.0;  // Meters
float interval = 5; // Seconds

// Don't change this one!
integer ownerInRange = -1;


updateRange(integer inRange)
{
	if(inRange == ownerInRange)
		return;
		 
	//llSay(0, "Detector: is owner in range? " + (string)inRange);    
	
	ownerInRange = inRange;
	updateRestrictions();
}


updateRestrictions()
{
	if(ownerInRange == -1)
		return;

	string allowIM = "n";
	if(ownerInRange)
		allowIM = "y"
					
	llOwnerSay("@sendimto:" + findUser + "=" + allowIM);
	llOwnerSay("@startimto:" + findUser + "=n" + allowIM);
	llOwnerSay("@recvimfrom:" + findUser + "=n" + allowIM);
}


default
{

	state_entry()
	{
		llOwnerSay("Starting detector...pew pew pew");
		llSensorRepeat("", findUser, AGENT, range, PI, interval);
	}
	
	
	on_rez(integer start_param)
	{
		updateRestrictions(); 
	}
	
	
	sensor(integer num_detected)
	{
		if(num_detected < 1)
			return;
			
		if(llDetectedKey(0) == findUser)
			updateRange(1);
	}
	
	
	no_sensor()
	{
		updateRange(0);
	}
	
}
