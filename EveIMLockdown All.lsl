///
/// EveIMLockdown (ALL)
/// Made by Evelin ❤
///
/// Check out the Github page for documentation:
/// https://github.com/evelinsl/EveIMLockdown
/// 

float range = 1.0;  // Meters
float interval = 5; // Seconds

// Don't change this one!
integer personInRange = -1;


updateRange(integer inRange)
{
    if(inRange == personInRange)
        return;

    personInRange = inRange;
    updateRestrictions();
}


updateRestrictions()
{    

    if(personInRange == -1)
        return;

    string allowIM = "n";
    if(personInRange == 0)
        allowIM = "y";
                                   
    llOwnerSay("@sendim_sec=" + allowIM);
    llOwnerSay("@startim=" + allowIM);
    llOwnerSay("@recvim_sec=" + allowIM);
}


default
{

    state_entry()
    {
        llOwnerSay("Starting detector VERSION 2 POINT OOOW");
        llSensorRepeat("", NULL_KEY, AGENT, range, PI, interval);
    }
    
    
    on_rez(integer start_param)
    {
        updateRestrictions(); 
    }
    
    
    sensor(integer num_detected)
    {
        if(num_detected > 0)
            updateRange(1);
    }
    
    
    no_sensor()
    {
        updateRange(0);
    }
    
}
