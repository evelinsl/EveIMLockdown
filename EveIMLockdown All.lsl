///
/// EveIMLockdown (ALL)
/// Made by Evelin ❤
///
/// Check out the Github page for documentation:
/// https://github.com/evelinsl/EveIMLockdown
/// 

float range = 20.0;  // Meters
float interval = 5; // Seconds

// Don't change this one!
integer personInRange = -1;

// Owner stuff 

key ownerKey = NULL_KEY;

// Dialog stuff

key dialogUser = NULL_KEY;
integer dialogListenHandler;
integer dialogChannel = 666;
integer startTime;

string DIALOG_TAKE_KEY = "Become owner";
string DIALOG_LEAVE_THE_KEY = "Stop owning";
string DIALOG_EXIT = "Close";


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
    
    if(ownerKey != NULL_KEY)
        updateOwnerRestrictions(TRUE);
}


removeOwnerException()
{
    updateOwnerRestrictions(FALSE);
}


updateOwnerRestrictions(integer adding)
{
    string add = "add";
    if(adding == 0)
        add = "rem";
        
    llSay(0, "Add? " + add);    
        
    llOwnerSay("@sendim:" + (string)ownerKey + "=" + add);
    llOwnerSay("@startim:" + (string)ownerKey + "=" + add);
    llOwnerSay("@recvim:" + (string)ownerKey + "=" + add);
}


showMenu()
{
    string wearer = llGetDisplayName(llGetOwner());
    string owner = "(nobody)";
    
    if(isOwned())
        owner = llGetDisplayName(ownerKey);
    
    string message = "Worn by: " + wearer + "\n";
    message += "Owner: " + owner + "\n";
    
    llDialog(dialogUser, message, getMenuButtons(), dialogChannel);
}


integer isOwned()
{
    return ownerKey != NULL_KEY;
}


integer currentUserIsOwner()
{
    return isOwned() && dialogUser == ownerKey;
}


list getMenuButtons()
{
    list keys = [];
        
    // The owner can return the key    
    
    if(isOwned() && dialogUser == ownerKey)
        keys = keys + [DIALOG_LEAVE_THE_KEY];

    if(!isOwned())
        keys = keys + [DIALOG_TAKE_KEY];  
        
    keys += [DIALOG_EXIT];
        
    return keys;
}


takeKeys()
{
    if(isOwned() && !currentUserIsOwner())
    {
        llSay(0, "Ow no! You cant become the owner");   
        return;
    }
    
    ownerKey = dialogUser;
    llSay(0, llGetDisplayName(ownerKey) + " is now the owner.");
    
    updateRestrictions();
}


leaveKey()
{
    if(!currentUserIsOwner())
    {
        llSay(0, "You cannot leave a key if you are not the owner");   
        return;   
    }
    
    removeOwnerException();
    
    llSay(0, llGetDisplayName(ownerKey) + " is not an owner anymore.");
    ownerKey = NULL_KEY;
    
    updateRestrictions();
}



freeDialog()
{
    llSetTimerEvent(0);
    dialogUser = NULL_KEY;
}


default
{

    state_entry()
    {
        //llOwnerSay("@clear");

        llOwnerSay("Listening on channel " + (string)dialogChannel);
        
        llSensorRepeat("", NULL_KEY, AGENT, range, PI, interval);
        
        dialogListenHandler = llListen(dialogChannel, "", "", "");
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
    
    
    listen(integer channel, string name, key id, string message)
    {
        if(channel != dialogChannel)
            return;
            
        if(message == "open")
        {
            if(dialogUser != NULL_KEY && dialogUser != id)
            {
                llSay(0, llGetDisplayName(id) + " is using the menu, please wait");
                return;
            }
        
            dialogUser = id;
            
            llSetTimerEvent(30);
            llListen(dialogChannel, "", dialogUser, "");
            
            showMenu();
            
        } else if(message == DIALOG_TAKE_KEY)
        {
            takeKeys();
            
        } else if(message == DIALOG_LEAVE_THE_KEY)
        {
            leaveKey();
            
        } else if(message == DIALOG_EXIT)
        {
            freeDialog();
        }
    }

    
}
