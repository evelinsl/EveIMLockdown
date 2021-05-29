///
/// EveIMLockdown, version 4.1 already!
/// Made by Evelin ❤ 
///
/// Check out the Github page for documentation:
/// https://github.com/evelinsl/EveIMLockdown
///  

float range = 20.0;           // Radius in meters around your avatar
float interval = 20;          // Update interval, do not set it to low!
integer dialogChannel = 333;  // Type "/666 menu" to open the menu (or change the channel)

// Do not edit anything belong this line!


// List of blocked avatars

list blockedAvatars = [];

// Owner stuff 

key ownerKey = NULL_KEY;

// Dialog stuff

key dialogUser = NULL_KEY;
integer dialogListenHandler;

string DIALOG_TAKE_KEY = "Become owner";
string DIALOG_LEAVE_THE_KEY = "Stop owning";
string DIALOG_EXIT = "Close";

integer coldBoot = 1;


///
/// Loops the given list of persons and either 
/// adds or removes the IM restrictions
///
updateRestrictions(integer add, list persons)
{
    integer count = llGetListLength(persons);
    integer index = 0;
    
    for(; index < count; index++) 
        updateRestriction(add, llList2Key(persons, index));
}


///
/// Update the IM restrictions of a single person
///
updateRestriction(integer add, key person)
{
    // Allow/prevent sending instant messages to someone in particular : "@sendimto:<UUID_or_group_name>=<y/n>"
    // Allow/prevent starting an IM session with someone in particular : "@startimto:<UUID>=<y/n>"
    // Allow/prevent receiving instant messages from someone in particular : "@recvimfrom:<UUID_or_group_name>=<y/n>"

    string allowIM = "y";
    if(add == 1)
        allowIM = "n";
    
    //llOwnerSay("updateRestrictions: " + (string)person + " - " + llGetDisplayName(person) + " = " + (string)add);
                                   
    llOwnerSay("@sendimto:" + (string)person + "=" + allowIM);
    llOwnerSay("@startimto:" + (string)person + "=" + allowIM);
    llOwnerSay("@recvimfrom:" + (string)person + "=" + allowIM);
}
   

///
/// Clears all IM restrictions
///
clearRestrictions()
{
    updateRestrictions(0, blockedAvatars);
    blockedAvatars = [];
} 


///
/// Adds or removes the owner exceptions
///
updateOwnerRestrictions(integer adding)
{
    string add = "add";
    if(adding == 0)
        add = "rem"; 
        
    //llOwnerSay("Owned? " + add);    
        
    llOwnerSay("@sendim:" + (string)ownerKey + "=" + add);
    llOwnerSay("@startim:" + (string)ownerKey + "=" + add);
    llOwnerSay("@recvim:" + (string)ownerKey + "=" + add);
    
    // Remove owner
    
    if(adding == 1)
    {
        integer ownerIndex = llListFindList(blockedAvatars, [ownerKey]);
        if(ownerIndex != -1)
            blockedAvatars = llDeleteSubList(blockedAvatars, ownerIndex, ownerIndex + 1);
        
        updateRestriction(FALSE, ownerKey);
    }
}


///
/// Shows the menu with owner settings
///
showMenu()
{
    string wearer = llGetDisplayName(llGetOwner());
    string owner = "(nobody)";
    
    if(isOwned())
        owner = llGetDisplayName(ownerKey);
    
    string message = "EveIMLockdown\nWorn by: " + wearer + "\n";
    message += "Owner: " + owner + "\n";
    
    llDialog(dialogUser, message, getMenuButtons(), dialogChannel);
}


///
/// Returns true when owned
///
integer isOwned()
{
    return ownerKey != NULL_KEY;
}


///
/// Checks if the current menu user is the owner
/// 
integer currentUserIsOwner()
{
    return isOwned() && dialogUser == ownerKey;
}


///
/// Returns a list of buttons to be displayed
/// 
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


///
/// Owner takes the key!
///
takeKeys()
{
    if(isOwned())
        return;
    
    ownerKey = dialogUser;
    
    if(ownerKey != NULL_KEY)
        llSay(0, llGetDisplayName(ownerKey) + " is now the owner.");
    
    updateOwnerRestrictions(TRUE);
}


///
/// Owner stops being an owner :(
///
leaveKey()
{
    if(!currentUserIsOwner())
    {
        llSay(0, "You are not the owner");   
        return;   
    }
    
    updateOwnerRestrictions(FALSE);
    
    llSay(0, llGetDisplayName(ownerKey) + " is not an owner anymore.");
    
    ownerKey = NULL_KEY;
}


///
/// Dialog cleanup 
///
freeDialog()
{
    llSetTimerEvent(0);
    dialogUser = NULL_KEY;
}


init()
{
    llOwnerSay("@clear");
    
    if(isOwned())
        llOwnerSay(llGetDisplayName(ownerKey) + " owns your IM lockdown settings :D");
    else
        llOwnerSay("Nobody owns your IM lockdown settings :(");     
    
    updateRestrictions(1, blockedAvatars);
    updateOwnerRestrictions(isOwned());      
}


///
/// Returns a list of avatar keys in the given range
///
list getAvatarsInRange(float range)
{
    list result = [];
    
    list agents = llGetAgentList(AGENT_LIST_PARCEL, []);
    integer index = llGetListLength(agents) - 1;
    
    vector position = llGetPos();
    key ourSelfs = llGetOwner();

    for(; index > -1; index--)
    {
        key agentKey = llList2Key(agents, index);
        if(ourSelfs != agentKey)
        {
            vector agentPosition = llList2Vector(llGetObjectDetails(agentKey, [OBJECT_POS]), 0);
            float distance = llVecDist(position, agentPosition);
            
            if(distance <= range)
                result += agentKey;
        }
    }
    
    return result;
}


///
/// Updates the internal block list and RLV settings
///
processDetectedAvatars(list avatars)
{
    integer detected = llGetListLength(avatars);
    list remove = [];
    list add = [];
    list found = [];
    integer index = 0;
    
    // Find new persons 
    
    if(detected > 0)
    {
        for(; index < detected; index++) 
        {
            key avatar = llList2Key(avatars, index);
            
            if(ownerKey != avatar) // ignore owner
            {
                found += avatar;
             
                // Already known?
                
                if(~llListFindList(blockedAvatars, [avatar]) == 0)
                {
                    add += avatar;
                    blockedAvatars += avatar;
                }
            }
        }
    }
    
    // Remove persons that are gone

    integer avatarCount = llGetListLength(blockedAvatars) - 1;
    
    for(; avatarCount >= 0; avatarCount--)
    {
        key avatar = llList2String(blockedAvatars, avatarCount);
        
        if(avatar != NULL_KEY && ownerKey != avatar)
        {
            if(~llListFindList(found, [avatar]) == 0)
            {
                remove += avatar;
                blockedAvatars = llDeleteSubList(blockedAvatars, avatarCount, avatarCount);
            }
        }
    }
    
    updateRestrictions(TRUE, add);
    updateRestrictions(FALSE, remove);
    
    list testList = [];
    
    
    //llOwnerSay(llList2Json(JSON_ARRAY, blockedAvatars));
    

    //llOwnerSay("Detected: " + (string)detected
    //    + " - Result:   " + (string)llGetListLength(blockedAvatars)
    //    + " - Found:    " + (string)llGetListLength(found)
    //    + " - Added:    " + (string)llGetListLength(add)
    //    + " - Removed:  " + (string)llGetListLength(remove)
    //);
}


///
/// Called from the maintimer. It looks up the avatars 
/// in range and then pushed them to the block list processor
///
tick()
{
    //llOwnerSay("TICK!");
    
    list avatars = getAvatarsInRange(range);

    if(llGetListLength(avatars) == 0)
        clearRestrictions();
    else
        processDetectedAvatars(avatars);    
}


default
{
    state_entry()
    {
        if(coldBoot == 1)
        {
            llOwnerSay("EveIMLockdown v4, activating...");    
            init();
        }
       
        llSetTimerEvent(interval);
        dialogListenHandler = llListen(dialogChannel, "", "", "");

        if(coldBoot == 1)
        {
            llOwnerSay("EveIMLockdown v4, done!");
            coldBoot = 0;
        }
    }
    
    
    timer()
    {
        tick();
    }

    
    on_rez(integer param)
    {
        init();
    }
    
    
    listen(integer channel, string name, key id, string message)
    {
        if(channel != dialogChannel)
            return;
            
        if(message == "menu")
        {
            if(dialogUser != NULL_KEY && dialogUser != id)
            {
                llSay(0, "Sorry " + llGetDisplayName(id) + " , but " + llGetDisplayName(dialogUser) + " is using the menu. Please wait");
                return;
            }
        
            llSetTimerEvent(0);
            dialogUser = id;

            state dialog;
        }
    }
}


state dialog
{
    
    state_entry()
    {
        llSetTimerEvent(15);
        dialogListenHandler = llListen(dialogChannel, "", "", "");
        
        showMenu();
    }
    
    
    listen(integer channel, string name, key id, string message)
    {
        if(channel != dialogChannel)
            return;
            
        if(message == DIALOG_TAKE_KEY)
        {
            takeKeys();
            
        } else if(message == DIALOG_LEAVE_THE_KEY)
        {
            leaveKey();
            
        } else if(message == DIALOG_EXIT)
        {
            freeDialog();  
            state default;
        }
    } 
    
        
    timer()
    {
        freeDialog();
        state default;
    }

}
