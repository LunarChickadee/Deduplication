___ PROCEDURE .Initialize ______________________________________________________

//______This is to set users for deduplication and other specific funtions_______//
global special_user_list,DedupOn, mailing_list_window
permanent username

DedupOn=0

define username,"None"
special_user_list="Bria
Kate
NoneOfTheAbove"

//____uncomment this if you need user control for deduplication_____//
/*
if username="None" or username=""
    
superchoicedialog special_user_list,username,
{caption="This should only run the first time you run this file. 
Please choose NoneOfTheAbove unless you see your name here." 
captionheight=2 title="User Name Choice"}
endif
*/

///______end uncomment_____////


mailing_list_window=""

mailing_list_window=info("databasename")

//_________________________________end username______//

call .AutomaticFY

global New, Num, Numb, enter, place, ID, CC, ED, credit, orders, ship, Flag, waswindow, vfindcurrent, vGlobeSerialNum
fileglobal searchcust, findcust, getcust, searchname, findname, getname, findcurrent, vSerialNum

vSerialNum=""

expressionstacksize 75000000
Num=0
findname=""
searchname=""
searchcust=""
vGlobeSerialNum="0"
gosheet
noshow
call "listsortcomplete/1"
endnoshow
waswindow = info("DatabaseName") 

case lower(folderpath(dbinfo("folder",""))) contains "dedup"
vSerialNum="2074269900"
vGlobeSerialNum="2074269900"
endcase


Openfile "customer_history"
local findcurrent
;, vSerialNum  //FLAG
vfindcurrent=0



global findcurrent
case folderpath(dbinfo("folder","")) CONTAINS "ogs" or folderpath(dbinfo("folder","")) CONTAINS "walk"
    makesecret
    goform "Add Walkin Customer"
    waswindow = info("windowname")
case lower(folderpath(dbinfo("folder",""))) contains "dedup"
    bigmessage "This is a deduplication specific Mailing List, please don't use it for order entry"
defaultcase
    ;openfile "fcmadc"   ///UNCOMMENT THIS
    ;makesecret
    
    Openfile "44orders"
    save
    Openfile "45orders"
    save
    openfile "ZipCodeList"
    save
    makesecret
endcase


//////#Change this to a folder specific
if vGlobeSerialNum contains "2074269900"
setwindow  290,127,800,1059,""
openform "customeractivity"
window  waswindow
zoomwindow 26,429,346,1280,"" //I think this was causing issues
showpage
endif
///#edit this one too
if vGlobeSerialNum notcontains "2074269900"
Openfile "44orders"
Openfile "45orders"
Openfile "Customer#"
endif


window  waswindow
//zoomwindow 26,429,346,1280,"" //I think this was causing issues
//showpage

//openfile "ZipCodeList"
//makesecret
//window waswindow



message "All Done Loading Mailing List!"




/*'#######################################Old Code############## 

moved 3/11/22
SerialNumberFind for an old way of doing deduplication
vGlobeSerialNum=grabfilevariable("45 mailing list", vSerialNum)
//added to get the customeractivity form to open for those doing mailing list deduplicaiton work -rach

//vSerialNum="73229.osmegmce, 81405.swjgkecx, 81408.H%v"

'#######################################Old Code##############*/

___ ENDPROCEDURE .Initialize ___________________________________________________

___ PROCEDURE .addmember _______________________________________________________

 
///____________________________________________________________________________________________________________________________________
///____________________________________________________________________________________________________________________________________
///________________________________This is the .FileChecker macro in GetMacros_________________________________________________________
///____________________________________________________________________________________________________________________________________
///____________________________________________________________________________________________________________________________________


local fileNeeded,folderArray,smallFolderArray,sizeCheck,
procList,sizeCheck,procNames,procDBs,mostRecentProc 

///________________________EDITME_____________
//replace this with whatever file you're error checking
//----------------------//
fileNeeded="members"    //
//----------------------//


////_____Got the file, but it's not open?_______________

case info("files") notcontains fileNeeded and listfiles(folder(""),"????KASX") contains fileNeeded
    openfile fileNeeded

///________Don't got the file?__________________

case listfiles(folder(""),"????KASX") notcontains fileNeeded


    procList=arraystrip(info("procedurestack"),¶)
    sizeCheck=arraysize(procList,¶)
        if sizeCheck>1
            procList=arrayrange(procList,2,sizeCheck,¶) //this is to exclude getting recursive info about this macro, especially while testing
        else
            procList=arraystrip(info("procedurestack"),¶)
        endif

    procNames=arraycolumn(procList,1,¶,¬)
    procDBs=arraycolumn(procList,2,¶,¬)
    mostRecentProc=array(procNames,1,¶) 
    folderArray=folderpath(folder(""))
    sizeCheck=arraysize(folderArray,":")
    smallFolderArray=arrayrange(folderArray,4,sizeCheck,":")

displaydata "Error:"
+¶+
"You are missing the '"+fileNeeded+
"' Panorama file in this folder 
and can't continue the '"+mostRecentProc+"' procedure without it. 
Please move a copy of '"+fileNeeded+
"' to the appropriate folder and try the procedure again"
+¶+¶+¶+
"folder you're currently running from is: "
+¶+
smallFolderArray
+¶+¶+¶+
"current Pan files in that folder are: "
+¶+
listfiles(folder(""),"????KASX")
+¶+¶+¶+
"Pressing 'Ok' will open the Finder to your current folder"
+¶+¶+
"Press 'Stop' will stop this procedure", “title="Missing File!!!!" captionwidth=900 size=17 height=500 width=800” //note: these are "SmartQuotes" Ctrl+[ and Ctrl+opt+[

    revealinfinder folder(""),""
    stop

///_______File is open, but not active?______

defaultcase
window fileNeeded

endcase

call .appendCustomer,"member"

___ ENDPROCEDURE .addmember ____________________________________________________

___ PROCEDURE NewRecord ________________________________________________________
if info("trigger") ="New.Return"
    insertrecord
else
    Synchronize
    beep
endif
___ ENDPROCEDURE NewRecord _____________________________________________________

___ PROCEDURE .DeleteRecord ____________________________________________________
global cNumVal,hasAnAddress,hasACon

cNumVal=0
hasACon=""
hasAnAddress=""

field «C#»
    copycell
    cNumVal=val(clipboard())

hasAnAddress=?(MAd≠"",MAd+" "+str(St),"No Mailing Address")

case «Con»="" and «Group»=""
    hasACon = "No Name or Group"
case «Con»≠"" and «Group»≠""
    hasACon = «Con»+"|"+«Group»
defaultcase
    hasACon =«Con»
endcase

YesNo "Delete Customer #:"+str(«C#»)+"?"+¶+"Con: "+hasACon+¶+"MAd: "+hasAnAddress
    if clipboard()="No"
    stop
    endif
deleterecord

if cNumVal>0
    window "customer_history:customeractivity"
        //___checks if they have information_________________
        case «Con»="" and «Group»=""
            hasACon = "No Name or Group"
        case «Con»≠"" and «Group»≠""
            hasACon = «Con»+"|"+«Group»
        defaultcase
            hasACon =«Con»
        endcase

        hasAnAddress=?(MAd≠"",MAd+" "+str(St),"No Mailing Address")

        //___________________________________________________
        
    if «C#»≠cNumVal
        find «C#»=cNumVal
            if info("found")=0
                window thisFYear+" mailing list"
                stop
            else
                YesNo "delete in customer history?"+¶+str(«C#»)+" "+hasACon+¶+hasAnAddress
                if clipboard()="Yes"
                    deleterecord
                endif
            endif
    endif
endif

window thisFYear+" mailing list"
if info("selected")<info("records")
    downrecord
endif




___ ENDPROCEDURE .DeleteRecord _________________________________________________

___ PROCEDURE .KeyDown _________________________________________________________
local KeyStroke
KeyStroke=info("trigger")[5,-1]
case KeyStroke=chr(31)
;if info("formName")="customer history" and info("selected")<info("records")
;downrecord
;if  info("Files") notcontains "inquiries&changes"
;openfile "inquiries@changes"
;endif
;window "inquiries&changes:change"
;downrecord
;window thisFYear+" mailing list:customer history"
;else
;downrecord
;endif
if info("formname")="addresschecker"
downrecord
window thisFYear+"orders:seedsinput"
downrecord
window thisFYear+" mailing list:addresschecker"
endif
defaultcase
    key info("modifiers"), KeyStroke
    endcase
___ ENDPROCEDURE .KeyDown ______________________________________________________

___ PROCEDURE .customer ________________________________________________________
OpenFile thisFYear+"orders"
Case Numb>300000 And Numb<400000
    GoForm "ogsinput"
Case Numb>400000 And Numb<500000
    GoForm "treesinput"
Case Numb>500000 And Numb<600000
    GoForm "bulbsinput"
Case Numb>600000 And Numb<700000
    GoForm "seedsinput"
Case Numb>700000
    GoForm "seedsinput"
EndCase
call ".customerfill"

___ ENDPROCEDURE .customer _____________________________________________________

___ PROCEDURE .findcustomer ____________________________________________________
if info("trigger")="Button.Find Customer"
if info("files") contains thisFYear+"orders"
goto continue
else
opensecret thisFYear+"orders"
endif
continue:
endif
loop
getscrap "Name contains"
find Con contains clipboard()
if info("found")=0
beep
endif
repeatloopif info("found")=0
stoploopif info("found")
while forever
Stop

___ ENDPROCEDURE .findcustomer _________________________________________________

___ PROCEDURE .tab _____________________________________________________________
If info("trigger")="Key.Return"
Field «C#»
EndIf
___ ENDPROCEDURE .tab __________________________________________________________

___ PROCEDURE .holdit __________________________________________________________
global VC
VC=«C#»
If «C#»=0
field «Group»
editcellstop
endif
If info("changes")≠0
CancelOk "Do you mean to change the C#?"
If clipboard()="Cancel"
«C#»=VC
EndIf
EndIf


___ ENDPROCEDURE .holdit _______________________________________________________

___ PROCEDURE .closewindow _____________________________________________________
CloseWindow
___ ENDPROCEDURE .closewindow __________________________________________________

___ PROCEDURE .MAd _____________________________________________________________
if «C#»=0
stop
endif
;if info("trigger")="Key.Tab"
;right
;endif
if info("trigger")="Key.Return"
Num=«C#»
openfile "customer_history"
find «C#»=Num
if info("found")=0
insertrecord
«C#»=Num
Con=grabdata(thisFYear+" mailing list", Con)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
endif
;Con=grabdata(thisFYear+" mailing list", Con)
;«Group»=grabdata(thisFYear+" mailing list", «Group»)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
Notes=replace(Notes, "Bad Address","")
Num=0
endif
window thisFYear+" mailing list"
___ ENDPROCEDURE .MAd __________________________________________________________

___ PROCEDURE .newzip __________________________________________________________
// from editing C# -> calls .custnumber -> if its empty -> calls this

fileglobal listzip, thiszip, findher, findzip, findcity, newcity, findname,findname1, findname2, thisname, firstname, lastname
serverlookup "off" 
;waswindow=info("windowname")
listzip=""
thiszip=""
newcity=""


again:
findher=addressArray


///____gets address from Order user was on or lets user type it in___///
supergettext findher, {caption="Enter Address.Zip" height=100 width=400 captionfont=Courier New captionsize=14 captioncolor="cornflowerblue"
    buttons="Find;Redo;Cancel"}
    if info("dialogtrigger") contains "Find"
        findzip=extract(findher,".",2)
        findzip=strip(findzip)
            if length(findzip)=4
            findzip="0"+findzip
            endif
        findcity=extract(findher,".",1)
        liveclairvoyance findzip,listzip,¶,"","45 mailing list",pattern(Zip,"#####"),"=",str(«C#»)+¬+rep(" ",7-length(str(«C#»)))+Con+rep(" ",max(20-length(Con),1))+¬+MAd+¬+City+¬+St+¬+pattern(Zip,"#####"),0,0,""
        arraysubset listzip, listzip, ¶, import() contains findcity
            if listzip=""
            goto lastzip
            endif
            
        //___if only one is found, then ask the user if they want to enter it___//
    
        if arraysize(listzip,¶)=1
        find MAd contains findcity and pattern(Zip,"#####") contains findzip
        

        AlertYesNo "Enter this one?"
            if info("dialogtrigger") contains "Yes"
           goto lastline
            ;stop
            else
            AlertOkCancel "Try by zipcode?"
                if info("dialogtrigger") contains "OK"
                call "getzip/Ω"
                endif
             endif
           endif
    endif
    
    if info("dialogtrigger") contains "Redo"
    findher=""
    goto again
    endif
    
    if info("dialogtrigger") contains "Cancel"
    window waswindow
    stop
    endif


superchoicedialog listzip, thiszip, {height=400 width=800 font=Courier caption="Click on one and then hit OK or New for new entry" 
        captionfont=Times captionsize=12 captioncolor=red size=14 buttons="OK:100;Try Name:150;Cancel:100"}
if info("dialogtrigger") contains "OK"
    find «C#» = val(strip(extract(thiszip, ¬,1))) and MAd=extract(thiszip, ¬,3) and City contains extract(thiszip, ¬,4)
    ;;find MAd=extract(thiszip, ¬,2) and City contains extract(thiszip, ¬,3)
    showpage

    call "enter/e"
endif

if info("dialogtrigger") contains "Try Name"
    goto tryname
    gettext "Which town?", newcity
    if newcity≠""
        find Z=val(findzip) and City contains newcity
        insertbelow
    else
        find Zip=val(findzip)
        insertbelow
    endif
endif
showpage
serverlookup "on"

tryname:
    firstname=""
    lastname=""
    findname=""
    findname1=""
    findname2=""
    findname=rayj
    supergettext findname, {caption="Enter First and Last Name" height=100 width=400 captionfont=Times captionsize=14 captioncolor="limegreen"
    buttons="Find;Redo;Cancel"}
    firstname=extract(findname," ",1)
     lastname=extract(findname," ",2)
    if info("dialogtrigger") contains "Find"
        liveclairvoyance lastname,findname1,¶,"","45 mailing list",Con,"contains",Con+¬+MAd+¬+City+¬+St+¬+pattern(Zip,"#####")+¬+phone,0,0,""
        message findname1
    endif
    
    if info("dialogtrigger") contains "Redo"
        goto tryname
    endif
    
    if info("dialogtrigger") contains "Cancel"
        stop
    endif
    
    arraysubset findname1,findname1,¶,import() contains firstname
    if arraysize(findname1,¶)=1
        find Con contains firstname and Con contains lastname
        AlertYesNo "Enter this one?"
        if info("dialogtrigger") contains "Yes"
            call "enter/e"
            stop
        else
            lastzip:
            getscrap "What zip code?"
            find Zip=val(clipboard())
            insertbelow
            stop
        endif
    endif
    superchoicedialog findname1,thisname, {height=400 width=500 font=Helvetica caption="Click on one and then hit OK or New for new entry" 
        captionfont=Times captionsize=12 captioncolor=green size=14 buttons="OK:100;New:100;Cancel:100"}
     if info("dialogtrigger") contains "OK"
        find Con contains extract(thisname, ¬,1) and City contains extract(thisname, ¬,3)
        call "enter/e"
     endif
     
     if info("dialogtrigger") contains "New"
        gettext "Which town?", newcity
        if newcity≠""
            window "45 mailing list"
            find Z=val(findzip) and City contains newcity
            insertbelow
        else
            find Zip=val(findzip)
            insertbelow
        endif
    endif
    
    showpage
    serverlookup "on"
    stop

    lastline:
    serverlookup "on"
    call "enter/e"

___ ENDPROCEDURE .newzip _______________________________________________________

___ PROCEDURE .sendemail _______________________________________________________
local mailarray
mailarray=""
case mailcopies≠""
mailarray=mailaddress+","+mailcopies
sendarrayemail "", mailarray, mailheader, messageBody
case mailcopies=""
sendoneemail "", mailaddress, mailheader, messageBody
endcase
___ ENDPROCEDURE .sendemail ____________________________________________________

___ PROCEDURE .customerhistory _________________________________________________
         if «C#»>0
            Numb=«C#»
            window "customer_history:customer history"
            find «C#»=Numb
            window waswindow
            endif
___ ENDPROCEDURE .customerhistory ______________________________________________

___ PROCEDURE .tab1 ____________________________________________________________

//not sure if these should be re-enabled
;if info("fieldname")="C#"
;style "record black"
;endif

//_______User Edits C#,Con, or Group____
    //______If they have a customer number, see if they are in customer history already
    //______If not there, create a record for them
Numb=0
if «C#»>0
    Numb=«C#»
    window "customer_history"
    Find «C#» = Numb
    if (not info("found"))
        OpenSheet
        lastrecord
        insertbelow
    endif
    «C#»=grabdata(thisFYear+" mailing list", «C#»)
    Con=grabdata(thisFYear+" mailing list", Con)
    «Group»=grabdata(thisFYear+" mailing list", «Group»)
    MAd=grabdata(thisFYear+" mailing list", MAd)
    City=grabdata(thisFYear+" mailing list", City)
    St=grabdata(thisFYear+" mailing list", St)
    Zip=grabdata(thisFYear+" mailing list", Zip)
    «SpareText2»=grabdata(thisFYear+" mailing list", «SpareText2»)
    ;closewindow
    ;window "customer_history:customeractivity"

    window thisFYear+" mailing list"
endif


___ ENDPROCEDURE .tab1 _________________________________________________________

___ PROCEDURE .member __________________________________________________________
if «Mem?»≠"Y"
    stop
endif

if «C#»=0
    Code= thisFYear+"mem"
    openfile "Customer#"
    call "newnumber"

    window thisFYear+" mailing list"
        Field «C#»
        Paste
        SpareText2=str(«C#»)
        if S=0 or T=0 or Bf=0
        call "filler/¬"
endif

field inqcode

window "customer_history"
    insertbelow
    «C#»=grabdata(thisFYear+" mailing list", «C#»)
    «Group»=grabdata(thisFYear+" mailing list", «Group»)
    Con=grabdata(thisFYear+" mailing list", Con)
    MAd=grabdata(thisFYear+" mailing list", MAd)
    City=grabdata(thisFYear+" mailing list", City)
    St=grabdata(thisFYear+" mailing list", St)
    Zip=grabdata(thisFYear+" mailing list", Zip)
    Email=grabdata(thisFYear+" mailing list", email)
    SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
    ;CloseWindow

window thisFYear+" mailing list"
    field Notes
    field «inqcode»
    endif
    Num=«C#»

window "customer_history:secret"
    find «C#»=Num
    if NewMember notcontains "joined"
    NewMember=NewMember+"joined on "+datepattern(today(),"mm/dd/yy")
    endif
    field «Equity»
    getscrap "How much equity?"
    «Equity»=val(clipboard())

window thisFYear+" mailing list"
    call .addmember
___ ENDPROCEDURE .member _______________________________________________________

___ PROCEDURE listsortcomplete/1 _______________________________________________
Hide
//___added this to stop showing mostly empty records on initialize
select str(«C#»)+Con+MAd+City ≠ "0"
//___  -L 8/22
Field "MAd"
SortUp
Field "City"
SortUp
Field "St"
SortUp
Field "Zip"
SortUp
Show
Field «C#»


___ ENDPROCEDURE listsortcomplete/1 ____________________________________________

___ PROCEDURE hidewindow/h _____________________________________________________
Window "Hide This Window"


___ ENDPROCEDURE hidewindow/h __________________________________________________

___ PROCEDURE (Entering) _______________________________________________________

___ ENDPROCEDURE (Entering) ____________________________________________________

___ PROCEDURE createcustomer/µ _________________________________________________
local waswindow
waswindow = info("windowname")

if «C#»≠0
    stop 
endif

Code= "I45s"
openfile "Customer#"
call "newnumber"
window waswindow
Field «C#»
Paste
SpareText2=str(«C#»)
If inqcode=""
    Field inqcode
    inqcode=?(inqcode contains "17", inqcode[3,-1], inqcode)
    EditCell
    field «C#»
EndIf
if S=0
    call "filler/¬"
endif
window "customer_history:secret"
opensheet
insertbelow
«C#»=grabdata(thisFYear+" mailing list", «C#»)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
Con=grabdata(thisFYear+" mailing list", Con)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
Email=grabdata(thisFYear+" mailing list", email)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
;CloseWindow
window waswindow
___ ENDPROCEDURE createcustomer/µ ______________________________________________

___ PROCEDURE cc rider/ç _______________________________________________________
waswindow=info("windowname")
serverlookup "off"
if info("trigger")="Button.Find Customer #"
if info("files") contains thisFYear+"orders"
goto continue
else
opensecret thisFYear+"orders"
endif
continue:
endif
NoUndo
GetScrap "enter the customer number"
Find «C#» = val(clipboard())
window "customer_history:secret"
Find «C#» = val(clipboard())
window waswindow
if info("fieldname") notcontains "Mem?"
field «C#»
field MAd
endif
serverlookup "on"
___ ENDPROCEDURE cc rider/ç ____________________________________________________

___ PROCEDURE entering/√ _______________________________________________________
getscrap "Next! (all 6 digits, please)"
Numb=val(clipboard())
OpenFile thisFYear+"orders"
ReSynchronize
field OrderNo
sortup
Case Numb<300000
    GoForm "seedsinput"
Case Numb>300000 And Numb<400000
    GoForm "ogsinput"
Case Numb>400000 And Numb<500000
    GoForm "treesinput"
Case Numb>500000 And Numb<600000
    GoForm "bulbsinput"
Case Numb>600000 And Numb<700000
    GoForm "mtinput"
Case Numb>700000
    GoForm "seedsinput"
EndCase
waswindow=info("windowname")
window waswindow
find OrderNo=val(clipboard())
field «C#»


___ ENDPROCEDURE entering/√ ____________________________________________________

___ PROCEDURE enter/e __________________________________________________________
//gets num from record found on mailing list
Num=«C#»

//___missing number?__//
If Num=0
    call "numberNeeded"
    //adds number to chosen record in ML
    //this also puts them in customer history under their new number
endif

//put that num into Orders
window (thisFYear+"orders")
    «C#»=Num
    «C#Text»=str(Num)
//originally checked if it was an internet order and had an empty name, then stopped

    call ".IsInternetOrder"

    call ".customerfill"
___ ENDPROCEDURE enter/e _______________________________________________________

___ PROCEDURE sameship/2 _______________________________________________________
if «C#»=0
stop
endif
if MAd contains "PO " and Z=Zip
stop
else if MAd contains "PO " and Z≠Zip
SAd=""
else SAd=MAd
endif
endif
Cit=City
Sta=St
Z=Zip
___ ENDPROCEDURE sameship/2 ____________________________________________________

___ PROCEDURE seedy/ß __________________________________________________________
if «C#»≠0
stop 
endif
Code= "I45s"
openfile "Customer#"
call "newnumber"
window thisFYear+" mailing list"
Field «C#»
Paste
SpareText2=str(«C#»)
If inqcode=""
Field inqcode
inqcode=?(inqcode contains "17", inqcode[3,-1], inqcode)
EditCell
field «C#»
EndIf
if S=0
call "filler/¬"
endif
window "customer_history:secret"
opensheet
insertbelow
«C#»=grabdata(thisFYear+" mailing list", «C#»)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
Con=grabdata(thisFYear+" mailing list", Con)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
Email=grabdata(thisFYear+" mailing list", email)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
;CloseWindow
window thisFYear+" mailing list"
Call "enter/e"

___ ENDPROCEDURE seedy/ß _______________________________________________________

___ PROCEDURE ogsity/ø _________________________________________________________
if «C#»≠0
stop 
endif
Code="I45o"
openfile "Customer#"
call "newnumber"
window thisFYear+" mailing list"
Field «C#»
Paste
SpareText2=str(«C#»)
If inqcode=""
Field inqcode
EditCell
field «C#»
EndIf
if S=0
call "filler/¬"
endif
window "customer_history:secret"
opensheet
insertbelow
«C#»=grabdata(thisFYear+" mailing list", «C#»)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
Con=grabdata(thisFYear+" mailing list", Con)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
Email=grabdata(thisFYear+" mailing list", email)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
;CloseWindow
window thisFYear+" mailing list"
Call "enter/e"



___ ENDPROCEDURE ogsity/ø ______________________________________________________

___ PROCEDURE moosed/µ _________________________________________________________
if «C#»≠0
stop 
endif
Code= "I45m"
openfile "Customer#"
call "newnumber"
window thisFYear+" mailing list"
Field «C#»
Paste
SpareText2=str(«C#»)
If inqcode=""
Field inqcode
EditCell
field «C#»
EndIf
if S=0
call "filler/¬"
endif
window "customer_history:secret"
opensheet
insertbelow
«C#»=grabdata(thisFYear+" mailing list", «C#»)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
Con=grabdata(thisFYear+" mailing list", Con)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
Email=grabdata(thisFYear+" mailing list", email)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
;CloseWindow
window thisFYear+" mailing list"
Call "enter/e"




___ ENDPROCEDURE moosed/µ ______________________________________________________

___ PROCEDURE treed/† __________________________________________________________
if «C#»≠0
stop 
endif
Code="I45t"
openfile "Customer#"
call "newnumber"
window thisFYear+" mailing list"
Field «C#»
Paste
SpareText2=str(«C#»)
If inqcode=""
Field inqcode
EditCell
field «C#»
EndIf
if S=0
call "filler/¬"
endif
if T=0
T=1
endif
window "customer_history:secret"
opensheet
insertbelow
«C#»=grabdata(thisFYear+" mailing list", «C#»)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
Con=grabdata(thisFYear+" mailing list", Con)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
Email=grabdata(thisFYear+" mailing list", email)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
;CloseWindow
window thisFYear+" mailing list"
Call "enter/e"

___ ENDPROCEDURE treed/† _______________________________________________________

___ PROCEDURE bulbous/∫ ________________________________________________________
if «C#»≠0
stop 
endif
Code= "I45b"
openfile "Customer#"
call "newnumber"
window thisFYear+" mailing list"
Field «C#»
Paste
SpareText2=str(«C#»)
If inqcode=""
Field inqcode
EditCell
field «C#»
EndIf
if S=0
call "filler/¬"
endif
If Bf=0
Bf=1
endif
window "customer_history:secret"
opensheet
insertbelow
«C#»=grabdata(thisFYear+" mailing list", «C#»)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
Con=grabdata(thisFYear+" mailing list", Con)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
Email=grabdata(thisFYear+" mailing list", email)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
;CloseWindow
window thisFYear+" mailing list"
Call "enter/e"

___ ENDPROCEDURE bulbous/∫ _____________________________________________________

___ PROCEDURE writeemail/5 _____________________________________________________
local mailaddress, mailcopies, mailheader, messageBody
applescript |||
tell application "Finder"
	activate
	tell application "Mail"
		activate
	end tell
end tell
tell application "Panorama"
	activate
end tell
|||
mailaddress=""
mailcopies=""
mailheader=""
messageBody=""
setwindowrectangle
rectanglesize(59, 107, 689, 663), ""
OpenForm "Emailform"
___ ENDPROCEDURE writeemail/5 __________________________________________________

___ PROCEDURE (Inquiries) ______________________________________________________


___ ENDPROCEDURE (Inquiries) ___________________________________________________

___ PROCEDURE getzip/Ω _________________________________________________________

///called from .newzip and .customerfill
fileglobal listzip, thiszip, findher, findzip, findaddress, newcity, arraynumb,sortzip, sortcity
serverlookup "off" 
sortzip=""
sortcity=""
arraynumb=0
listzip=""
thiszip=""
newcity=""
again:
findher=""
waswindow=info("windowname")



supergettext findher, {caption="Enter Address.Zip or .Zip to find everyone" height=100 width=400 captionfont=Times captionsize=14 captioncolor="cornflowerblue"
    buttons="Find;Redo;Cancel"}
    if info("dialogtrigger") contains "Find"
        findzip=extract(findher,".",2)
        findzip=strip(findzip)
        if length(findzip)=4
            findzip="0"+findzip
        endif
        findaddress=extract(findher,".",1)
        liveclairvoyance findzip,listzip,¶,"",thisFYear+" mailing list",pattern(Zip,"#####"),"=",str(«C#»)+¬+rep(" ",7-length(str(«C#»)))+Con+rep(" ",max(20-length(Con),1))+¬+MAd+¬+City+¬+St+¬+pattern(Zip,"#####"),0,0,""
        if findaddress=""
            sortzip=listzip
        else
            arraysubset listzip, listzip, ¶, import() contains findaddress
            loop arraynumb=arraynumb+1
            stoploopif arraynumb>arraysize(listzip,¶)
                sortzip=sortzip+?(extract(extract(listzip,¶,arraynumb),¬,3) contains findaddress,extract(listzip,¶,arraynumb)+¶,"")
            until arraynumb=arraysize(listzip,¶)+1
        endif
        if info("found")=0
            beep
            NoYes "No one in that zip. Try another?"
            findher=""
            If clipboard()="Yes"
                goto again
            else
                insertbelow
                stop
            endif
        endif
        if arraysize(listzip,¶)=1
            find MAd contains findaddress and pattern(Zip,"#####") contains findzip
            field MAd
            if «C#»>0
                CC=«C#»
                window "customer_history:customeractivity"
                find «C#»=CC
                window waswindow
            endif
            stop
        endif
    endif
    if info("dialogtrigger") contains "Redo"
        findher=""
        goto again
    endif
    if info("dialogtrigger") contains "Cancel"
        stop
    endif

superchoicedialog sortzip, thiszip, {height=400 width=800 font=Courier caption="Click on one and then hit Choose or New for new entry" 
    captionfont=Times captionsize=12 captioncolor=red size=16 buttons="OK:100;New:100;Cancel:100"}
if info("dialogtrigger") contains "OK"
    
    find «C#» = val(strip(extract(thiszip, ¬,1))) and MAd=extract(thiszip, ¬,3) and City contains extract(thiszip, ¬,4)
    ;;find MAd=extract(thiszip, ¬,3) and City contains extract(thiszip, ¬,4)
    field MAd
    if «C#»>0
        CC=«C#»
        window "customer_history:customeractivity"
        find «C#»=CC
        window waswindow
    endif
endif
if info("dialogtrigger") contains "New"
    arrayfilter sortzip, sortcity, ¶, extract(extract(sortzip,¶,seq()),¬,4)
    arraydeduplicate sortcity,  sortcity, ¶

    if (findaddress≠"" and arraysize(sortcity,¶)>2) or (findaddress="" and arraysize(sortcity,¶)>1)
        gettext "Which town?", newcity
    endif
    if newcity≠""
        find Z=val(findzip) and City contains newcity
        insertbelow
        field Con
    else
        find Zip=val(findzip)
        insertbelow
        field Con
    endif
endif
showpage
serverlookup "on"
___ ENDPROCEDURE getzip/Ω ______________________________________________________

___ PROCEDURE insert below/i ___________________________________________________
InsertBelow
Field «Con»
___ ENDPROCEDURE insert below/i ________________________________________________

___ PROCEDURE noforward/0 ______________________________________________________
Numb=«C#»
S=0
Bf=0
T=0
«M?»=«M?»+"E"
RedFlag="no forward, bulbs"+¶+RedFlag
SpareText1=datepattern(today(), "mm/yy")
if «C#»=0
field «C#»
stop
endif
waswindow=info("windowname")
window "customer_history:customeractivity"
Find «C#» = Numb
Notes=?(Notes="", "Bad address", Notes+¶+"Bad Address")
window waswindow
___ ENDPROCEDURE noforward/0 ___________________________________________________

___ PROCEDURE no mail/µ ________________________________________________________
Numb=«C#»
S=0
Bf=0
T=0
«M?»=«M?»+"R"
RedFlag="no mail receptacle"+¶+RedFlag
SpareText1=datepattern(today(), "mm/yy")
if «C#»=0
field «C#»
stop
endif
waswindow=info("windowname")
window "customer_history:customeractivity"
Find «C#» = Numb
Notes=?(Notes="", "No mail receptacle", Notes+¶+"Bad Address")
window waswindow
___ ENDPROCEDURE no mail/µ _____________________________________________________

___ PROCEDURE tempaway/y _______________________________________________________
Numb=«C#»
S=0
Bf=0
T=0
«M?»=«M?»+"E"
RedFlag="temporarily away"+¶+RedFlag
SpareText1=datepattern(today(), "mm/yy")
if «C#»=0
field «C#»
stop
endif
waswindow=info("windowname")
window "customer_history:customeractivity"
Find «C#» = Numb
Notes=?(Notes="" or Notes="Bad address", "Away", Notes+¶+"Away")
window waswindow
___ ENDPROCEDURE tempaway/y ____________________________________________________

___ PROCEDURE copy city/3 ______________________________________________________
local address
UpRecord
arraylinebuild address,¬,thisFYear+" mailing list", City+¬+St+¬+str(Zip)+¬+str(adc)+¶
DownRecord
City=extract(address, ¬,1)
St=extract(address, ¬,2)
Zip=val(extract(address, ¬,3))
adc=val(extract(address, ¬,4))
call "filler/¬"
___ ENDPROCEDURE copy city/3 ___________________________________________________

___ PROCEDURE filler/¬ _________________________________________________________
local hasBranchInfo
/* 
added 8/22 by Lunar
*/


window thisFYear+" mailing list"

if S+T+Bf=0 and RedFlag=""
    yesno "- Customer has no catalogs requested"+¶+"- Customer has no RedFlag(s)"+¶+¶+"Autofill catalog requests by Zip/Order?"
    if clipboard()="Yes"
        Case Zip < 19000  And Zip>1000
            S=1
            «M?»=?(«M?» notcontains "X","X"+«M?»,«M?»)
            T=1
            «M?»=?(«M?» notcontains "W","W"+«M?»,«M?»)
            Bf=1
            «M?»=?(«M?» notcontains "Z","Z"+«M?»,«M?»)
        Case (Zip > 43000 And Zip < 46000) 
        or (Zip > 48000 And Zip < 50000) 
        or (Zip > 53000 And Zip < 57000) 
        or Zip>97000
            S=1
            «M?»=?(«M?» notcontains "X","X"+«M?»,«M?»)
            T=1
            «M?»=?(«M?» notcontains "W","W"+«M?»,«M?»)
            Bf=?(fromBranch contains "OGS",1,0)
            «M?»=?(«M?» contains "Z",replace(«M?»,"Z",""),«M?»)
        DefaultCase
            S=1
            «M?»=?(«M?» notcontains "X","X"+«M?»,«M?»)
            T=?(fromBranch contains "Trees",1,0)
            //same for trees and bulbs here
            «M?»=?(«M?» contains "W",replace(«M?»,"W",""),«M?»)
            Bf=?(fromBranch contains "OGS",1,0)
            «M?»=?(«M?» contains "Z",replace(«M?»,"Z",""),«M?»)
        endcase     
    endif 
else 
    case RedFlag≠""
        message "Customer has a RedFlag."+¶+"Catalog requests will be set to zero"
            S=0
            T=0
            Bf=0
            «M?»=""
    defaultcase 
    noyes "Update Catalog Requests?"
    +¶+
    "Currently, Customer is set to receive"
    +¶+
    "Seeds:"+str(S)+" Bulbs:"+str(Bf)+" Trees:"+str(T)
    
    //make this smart enough to only say whaty they're getting?
        if clipboard()="Yes"

        ///this loop is from .UpdateCats
            loop
                rundialog
                “Form="CatalogRequest"
                    Movable=yes
                    okbutton=Update
                    Menus=normal
                    WindowTitle={CatalogRequest}
                    Height=264 Width=190
                    AutoEdit="Text Editor"
                    Variable:"val(«dS»)=val(«S»)"
                    Variable:"val(«dBf»)=val(«Bf»)"
                    Variable:"val(«dT»)=val(«T»)"”
                stoploopif info("trigger")="Dialog.Close"
            while forever 
              message "Customer is now set to receive"
                        +¶+
                        "Seeds:"+str(S)+" Bulbs:"+str(Bf)+" Trees:"+str(T)
                if S≥1 and «M?» notcontains "X"
                    «M?»="X"+«M?»
                else 
                    if S=0
                    «M?»=?(«M?» contains "X",replace(«M?»,"X",""),«M?»)
                    endif
                endif

                if T≥1 and «M?» notcontains "W"
                    «M?»="W"+«M?»
                else 
                    if T=0
                    «M?»=?(«M?» contains "W",replace(«M?»,"W",""),«M?»)
                    endif
                endif

                if Bf≥1 and «M?» notcontains "Z"
                    «M?»="Z"+«M?»
                else 
                    if Bf=0
                    «M?»=?(«M?» contains "Z",replace(«M?»,"Z",""),«M?»)
                    endif
                endif
        endif
    endcase
endif 

___ ENDPROCEDURE filler/¬ ______________________________________________________

___ PROCEDURE moved/` __________________________________________________________
;«M?»=«M?»+"U"
«M?»=«M?»+"E"
;«M?»=«M?»+"R"
;if inqcode contains "onl"
;S=0
;Bf=0
;T=0
;endif
SpareText1=datepattern(today(),"mm/yy")
call "filler/¬"
___ ENDPROCEDURE moved/` _______________________________________________________

___ PROCEDURE inq/œ ____________________________________________________________
field inqcode
editcell
S=1
field Con
___ ENDPROCEDURE inq/œ _________________________________________________________

___ PROCEDURE needseeds/6 ______________________________________________________
;If S=0
;S=1
;endif
«M?»=«M?»+"S"
___ ENDPROCEDURE needseeds/6 ___________________________________________________

___ PROCEDURE needtrees/® ______________________________________________________
if T=0
T=1
endif
«M?»=«M?»+"W"
___ ENDPROCEDURE needtrees/® ___________________________________________________

___ PROCEDURE needbulbs/4 ______________________________________________________
if Bf=0
Bf=1
«M?»=«M?»+"Z"
endif
___ ENDPROCEDURE needbulbs/4 ___________________________________________________

___ PROCEDURE (Extras) _________________________________________________________


___ ENDPROCEDURE (Extras) ______________________________________________________

___ PROCEDURE window ___________________________________________________________
Num=  info("WindowBox") 
message  Num
___ ENDPROCEDURE window ________________________________________________________

___ PROCEDURE deletem __________________________________________________________
lastrecord
loop
repeatloopif «Mem?»="Y"
deleterecord
until info("selected")=1
field Con
copy
selectall
find Con=clipboard()
deleterecord
___ ENDPROCEDURE deletem _______________________________________________________

___ PROCEDURE checktowns _______________________________________________________
select Cit contains chr(13) or Cit endswith chr(32) or Cit contains chr(44)

___ ENDPROCEDURE checktowns ____________________________________________________

___ PROCEDURE deleter __________________________________________________________
NoUndo
Hide
GetScrapOK "what code?"
Select inqcode contains clipboard()
SelectWithin «C#» = 0
Show
___ ENDPROCEDURE deleter _______________________________________________________

___ PROCEDURE check ____________________________________________________________
GetScrap "vat iz de zip code?"
Find Zip = val(clipboard())
message info("found")
___ ENDPROCEDURE check _________________________________________________________

___ PROCEDURE inq&change _______________________________________________________
WindowBox "22 324 219 915"
openfile "37inquiries&changes"
window "change"
select «C#»>0
field «C#»
sortup
Window "37mailing list:customer history"
Select lookupselected("37inquiries&changes","C#",«C#»,"C#",0,0)
field «C#»
sortup 
___ ENDPROCEDURE inq&change ____________________________________________________

___ PROCEDURE Find Return ______________________________________________________
Select Con Contains Chr(13)
SelectAdditional «Group» Contains Chr(13)
SelectAdditional MAd Contains Chr(13)
SelectAdditional City Contains Chr(13)
SelectAdditional St Contains Chr(13)
___ ENDPROCEDURE Find Return ___________________________________________________

___ PROCEDURE lookupcustomers __________________________________________________
serverlookup "off"
select «C#»=lookup("30seedspatronage","C#",«C#»,"C#",0,0)
serverlookup "on"

___ ENDPROCEDURE lookupcustomers _______________________________________________

___ PROCEDURE forceunlock ______________________________________________________
forceunlockrecord
___ ENDPROCEDURE forceunlock ___________________________________________________

___ PROCEDURE fixphone _________________________________________________________
local newphone
newphone=""
field phone
loop
newphone=phone
newphone=replace(newphone, " ","")
newphone=replace(newphone, "-","")
newphone=replace(newphone, ".","")
newphone=replace(newphone, "+","")
newphone=replace(newphone, "(","")
newphone=replace(newphone, ")","")
phone=newphone[1,3]+"-"+newphone[4,6]+"-"+newphone[7,-1]
;phone=arraychange(phone,"-",4,"")
downrecord
;stop
until info("eof")
newphone=phone
newphone=replace(newphone, " ","")
newphone=replace(newphone, "-","")
newphone=replace(newphone, ".","")
newphone=replace(newphone, "+","")
newphone=replace(newphone, "(","")
newphone=replace(newphone, ")","")
phone=newphone[1,3]+"-"+newphone[4,6]+"-"+newphone[7,-1]
___ ENDPROCEDURE fixphone ______________________________________________________

___ PROCEDURE forcesynchronize _________________________________________________
forcesynchronize
call "listsortcomplete/1"
___ ENDPROCEDURE forcesynchronize ______________________________________________

___ PROCEDURE openall __________________________________________________________
Openfile "customer_hIstory"
Hide
Openfile thisFYear+"orders"
Openfile "Customer#"
Opensecret thisFYear+"orders"
Hide

window  waswindow

___ ENDPROCEDURE openall _______________________________________________________

___ PROCEDURE tabdown __________________________________________________________
field Zip
firstrecord
loop
copycell
pastecell
downrecord
stoploopif info("eof")
while forever
copycell
pastecell
___ ENDPROCEDURE tabdown _______________________________________________________

___ PROCEDURE message __________________________________________________________
message str(val(MAd))
___ ENDPROCEDURE message _______________________________________________________

___ PROCEDURE selecttrees ______________________________________________________
serverlookup "off"
select «C#»>0 and «C#»=lookupselected("customer_history", "C#",«C#», "C#",0,0) and T>0 and T<5
serverlookup "on"
___ ENDPROCEDURE selecttrees ___________________________________________________

___ PROCEDURE checkadc's _______________________________________________________
select adc≠lookup("fcmadc","Zip3",val(pattern(Zip,"#####")[1,3]),"adc",0,0) and Zip>0
field adc
formulafill
lookup("fcmadc","Zip3",val(pattern(Zip,"#####")[1,3]),"adc",0,0)
___ ENDPROCEDURE checkadc's ____________________________________________________

___ PROCEDURE deleteunwanted ___________________________________________________
lastrecord
loop
deleterecord
until info("selected")=1
field Con
copy
selectall
find Con=clipboard()
___ ENDPROCEDURE deleteunwanted ________________________________________________

___ PROCEDURE selectduplicates _________________________________________________
field Zip
sortup
field MAd
sortupwithin
selectduplicates MAd+" "+Zip
___ ENDPROCEDURE selectduplicates ______________________________________________

___ PROCEDURE checksize ________________________________________________________
local addressblock
addressblock=""
addressblock=?(Group≠"",«Group»+¶+Con, Con)+¶+MAd+¶+City+¬+St+¬+pattern(Zip,"#####")
select arraysize(addressblock,¶)>4
___ ENDPROCEDURE checksize _____________________________________________________

___ PROCEDURE newfind __________________________________________________________
case searchcust≠""
liveclairvoyance searchcust, findcust, ¶, "CustomerList",thisFYear+" mailing list", str(«C#»), "beginswith", str(«C#»), 10, 0, ""
case searchname≠""
liveclairvoyance searchname, findname, ¶, "NameList",thisFYear+" mailing list", Con, "match", str(«C#»)+": "+Con, 10, 0, ""
endcase
___ ENDPROCEDURE newfind _______________________________________________________

___ PROCEDURE newget ___________________________________________________________
gosheet
find «C#»=val(getcust)
searchcust=""
___ ENDPROCEDURE newget ________________________________________________________

___ PROCEDURE getname __________________________________________________________
gosheet
find Con=extract(getname,": ",2)
searchname=""
call .tab1
___ ENDPROCEDURE getname _______________________________________________________

___ PROCEDURE (DeDuplication) __________________________________________________

___ ENDPROCEDURE (DeDuplication) _______________________________________________

___ PROCEDURE StartDeduplication _______________________________________________
global DedupOn, mailing_list_window

mailing_list_window=""

mailing_list_window=info("databasename")

Define DedupOn,0
//DedupOn=-1

global DedupList,SortThis, con_email_dups,Group_Dups,Phone_Dups,Con_Email_Group_Phone

define con_email_dups,""
define Group_Dups,""
define Phone_Dups,""
define Con_Email_Group_Phone,""

DedupList="Find Same Con&Email [default setup]
Find Same Group Name 
Find Same Phone Number and Con
Find Same Con,Email, Group, and Phone"


superchoicedialog DedupList,SortThis,
{caption="Please choose how to sort for duplicates. 
Please choose NoneOfTheAbove unless you see your name here." captionheight=2 title="User Name Choice"}

;displaydata SortThis

Case SortThis contains "Con&Email"
selectall
Field Con
    sortup
    field email
    sortupwithin
selectduplicates Con+email
selectwithin email ≠ ""
//arrayselectedbuild con_email_dups,¶,"",str(«C#»)+¬+Con
lastrecord


case SortThis contains "Group Name"
selectall
Field Group
    sortup
    field Con
    sortupwithin
selectduplicates Group
selectwithin Group≠""
////arrayselectedbuild Group_Dups,¶,"",str(«C#»)+¬+Con
lastrecord

case SortThis contains "Phone Number"
selectall 
Field phone
    sortup
    field Con
    sortupwithin
selectduplicates phone+Con
selectwithin phone≠""
//arrayselectedbuild Phone_Dups,¶,"",str(«C#»)+¬+Con
lastrecord

case SortThis contains "Con,Email, Group"
selectall 
Field Con
    sortup
    field phone
    sortupwithin
    field email
    sortupwithin
    field Group
    sortupwithin
selectduplicates Con+phone+email+«Group»
selectwithin Con≠"" and phone≠"" and email≠"" 
//arrayselectedbuild Con_Email_Group_Phone,¶,"",str(«C#»)+¬+Con
Field «C#»
lastrecord
endcase


selectwithin «SpareText1» notcontains "duplicate"
lastrecord



___ ENDPROCEDURE StartDeduplication ____________________________________________

___ PROCEDURE SortAndSelect ____________________________________________________
selectall
Field Con
    sortup
    field email
    sortupwithin
selectduplicates Con+email
selectwithin email ≠ ""
lastrecord
___ ENDPROCEDURE SortAndSelect _________________________________________________

___ PROCEDURE SelectSourceRecord/d _____________________________________________
global inq_set,online_set, back_to_ML, ML_Num, dedup_counter_num

define dedup_counter_num, 999999

back_to_ML=info("windowname")
if val(«C#»)=0
    dedup_counter_num=val(dedup_counter_num-1)
    «C#»=val(dedup_counter_num)
endif
copyrecord


window "DeDuplicator"

pasterecord

«C#»=rep(chr(48),6-length(«C#»))+«C#»
LastUpdateSortable=date(Updated[1,"@"][1,-2])
inq_set=?(val(striptonum(inqcode))<30, val(striptonum(inqcode)), val(striptonum(inqcode)[3,4]))
InqCodeNum=inq_set
online_set=val(?(inqcode contains "onl" or inqcode contains "webrequest", "1.2", "1"))
Online=online_set

call "FindMostRecent"

loop
window back_to_ML
until info("windowname") = back_to_ML

___ ENDPROCEDURE SelectSourceRecord/d __________________________________________

___ PROCEDURE MergeToDestination/å _____________________________________________
if vSerialNum notcontains "2074269900" 
message "Sorry, you can not use CMD+Opt+a (DeDuplication) without approval."
stop
endif


global vtargetcust
global vS45, vS44, vS43, vS42, vS41, vS40, vS39, vS38, vS37, vS36, vS35, vS34, vS33, vS32, vS31, vS30, vS29, 
vS28, vS27, vS26, vS25, vS24, vS23, vS22, vS21, vS20, vS19, 
vBf45, vBf44, vBf43, vBf42, vBf41, vBf40, vBf39, vBf38, vBf37, vBf36, vBf35, vBf34, vBf33, vBf32, vBf31, vBf30, vBf29, vBf28, vBf27, vBf26, vBf25, 
vBf24, vBf23, vBf22, vBf21, vBf20, vBf19, 
vM45, vM44, vM43, vM42, vM41, vM40, vM39, vM38, vM37, vM36, vM35, vM34, vM33, vM32, vM31, vM30, 
vM29, vM28, vM27, vM26, vM25, vM24, vM23, vM22, vM21, vM20, vM19,
vOGS45, vOGS44, vOGS43, vOGS42, vOGS41, vOGS40, vOGS39, vOGS38, vOGS37, vOGS36, vOGS35, vOGS34, vOGS33, 
vOGS32, vOGS31, vOGS30, vOGS29, vOGS28, vOGS27, vOGS26, vOGS25, vOGS24, vOGS23, 
vOGS22, vOGS21, vOGS20, 
vT42, vT43, vT44, vT45, vT41, vT40, vT39, vT38, vT37, vT36, vT35, vT34, vT33, vT32, vT31, vT30, 
vT29, vT28, vT27, vT26, vT25, vT24, vT23, vT22, vT21, vT20, vT19,
vTaxName, vTIN, vConsent, vNotified, vEquity

///we should be able to shorten this with the SET command
//____________________________________NOtes____________
vtargetcust=«C#»

if «Mem?»=""
    «Mem?»=vMem
    ;stop
endif

if «TaxEx»=""
    «TaxEx»=vTaxEx
    ;stop
endif

if «resale»=""
    «resale»=vResale
    ;stop
endif



window "customer_history:customeractivity"
if «C#»≠vsourcecust
    find «C#»=vsourcecust
        if info("found")=0
            window thisFYear+" mailing list"
            
             "Nothing found!"
            Stop
        ;else
            ;Message "found source record"
        endif
endif

farcall (thisFYear+" mailing list"), .SetVariables
//**** This if clause may be an unnecessary diplication of the step above**//
if «C#»≠vtargetcust
    find «C#»=vtargetcust
        if info("found")=0
            message "target not found! Process stopped, nothing merged."
            Stop
        else
            ;Message "found target record" 
        endif
endif
//**************************//
if CChistory=""
    CChistory=str(vsourcecust)
        else
            CChistory=CChistory+", "+str(vsourcecust)
endif

if vTaxName≠""
    if taxname=""
    taxname=vTaxName
        else 
            taxname=vTaxName+", "+taxname
    endif
endif

if vTIN≠""
   if TIN=""
    TIN=vTIN
        else 
            TIN=vTIN+", "+TIN
    endif
endif

if vConsent≠""
   if Consent=""
    Consent=vConsent
        else 
            Consent=vConsent+", "+Consent
    endif
endif

if vNotified≠""
   if Notified=""
    Notified=vNotified
        else 
            Notified=vNotified+", "+Notified
    endif
endif

if vEquity≠0
   if Equity=0
    Equity=vEquity
    endif
endif

farcall (thisFYear+" mailing list"), .FillTargetFields

«45Total»=S45+Bf45+M45+T45
«44Total»=S44+Bf44+M44+T44
«43Total»=S43+Bf43+M43+T43
«42Total»=S42+Bf42+M42+T42
«41Total»=S41+Bf41+M41+T41
«40Total»=S40+Bf40+M40+OGS40+T40
«39Total»=S39+Bf39+M39+OGS39+T39
«38Total»=S38+Bf38+M38+OGS38+T38
«37Total»=S37+Bf37+M37+OGS37+T37
«36Total»=S36+Bf36+M36+OGS36+T36
«35Total»=S35+Bf35+M35+OGS35+T35
«34Total»=S34+Bf34+M34+OGS34+T34
«33Total»=S33+Bf33+M33+OGS33+T33
«32Total»=S32+Bf32+M32+OGS32+T32
«31Total»=S31+Bf31+M31+OGS31+T31
«30Total»=S30+Bf30+M30+OGS30+T30
«29Total»=S29+Bf29+M29+OGS29+T29
«28Total»=S28+Bf28+M28+OGS28+T28
«27Total»=S27+Bf27+M27+OGS27+T27
«26Total»=S26+Bf26+M26+OGS26+T26
«25Total»=S25+Bf25+M25+OGS25+T25
«24Total»=S24+Bf24+M24+OGS24+T24
«23Total»=S23+Bf23+M23+OGS23+T23
«22Total»=S22+Bf22+M22+OGS22+T22
«21Total»=S21+Bf21+M21+OGS21+T21
«20Total»=S20+Bf20+M20+OGS20+T20
«19Total»=S19+Bf19+M19+T19
;Message "Totals run"
window thisFYear+" mailing list"

find «C#» = vsourcecust
field «C#»
    copycell
YESNO "do you want to delete the customer number " + str(vsourcecust)+" "+Con+" from the mailinglist?"
    if clipboard()="Yes"
    field «C#»
    copycell
        deleterecord
        call .HistoryDelete
    endif
;vsourcecust i
___ ENDPROCEDURE MergeToDestination/å __________________________________________

___ PROCEDURE .FindMostRecentOrder _____________________________________________

window "customer_history"
/*
;select val(lineitemarray("SΩ",¬))>0

global seeds_history
seeds_history=""

/*
arrayfilter lineitemarray("SΩ",¬),seeds_history,¬,
?(val(import())>0,info("fieldname"),"")
*/

//goal:
//give me the first thing that isn't a zero in this array then tell me what field it was in

seeds_history=arraysearch(lineitemarray("SΩ",¬),/////


displaydata seeds_history
*/
___ ENDPROCEDURE .FindMostRecentOrder __________________________________________

___ PROCEDURE .FillTargetFields ________________________________________________

if vS45>0
S45=vS45+S45
endif
if vS44>0
S44=vS44+S44
endif
if vS43>0
S43=vS43+S43
endif
if vS42>0
S42=vS42+S42
endif
if vS41>0
S41=vS41+S41
endif
if vS40>0
S40=vS40+S40
endif
if vS39>0
S39=vS39+S39
endif
if vS38>0
S38=vS38+S38
endif
if vS37>0
S37=vS37+S37
endif
if vS36>0
S36=vS36+S36
endif
if vS35>0
S35=vS35+S35
endif
if vS34>0
S34=vS34+S34
endif
if vS33>0
S33=vS33+S33
endif
if vS32>0
S32=vS32+S32
endif
if vS31>0
S31=vS31+S31
endif
if vS30>0
S30=vS30+S30
endif
if vS29>0
S29=vS29+S29
endif
if vS28>0
S28=vS28+S28
endif
if vS27>0
S27=vS27+S27
endif
if vS26>0
S26=vS26+S26
endif
if vS25>0
S25=vS25+S25
endif
if vS24>0
S24=vS24+S24
endif
if vS23>0
S23=vS23+S23
endif
if vS22>0
S22=vS22+S22
endif
if vS21>0
S21=vS21+S21
endif
if vS20>0
S20=vS20+S20
endif
if vS19>0
S19=vS19+S19
endif

if vBf45>0
Bf45=vBf45+Bf45
endif
if vBf44>0
Bf44=vBf44+Bf44
endif
if vBf43>0
Bf43=vBf43+Bf43
endif
if vBf42>0
Bf42=vBf42+Bf42
endif
if vBf41>0
Bf41=vBf41+Bf41
endif
if vBf40>0
Bf40=vBf40+Bf40
endif
if vBf39>0
Bf39=vBf39+Bf39
endif
if vBf38>0
Bf38=vBf38+Bf38
endif
if vBf37>0
Bf37=vBf37+Bf37
endif
if vBf36>0
Bf36=vBf36+Bf36
endif
if vBf35>0
Bf35=vBf35+Bf35
endif
if vBf34>0
Bf34=vBf34+Bf34
endif
if vBf33>0
Bf33=vBf33+Bf33
endif
if vBf32>0
Bf32=vBf32+Bf32
endif
if vBf31>0
Bf31=vBf31+Bf31
endif
if vBf30>0
Bf30=vBf30+Bf30
endif
if vBf29>0
Bf29=vBf29+Bf29
endif
if vBf28>0
Bf28=vBf28+Bf28
endif
if vBf27>0
Bf27=vBf27+Bf27
endif
if vBf26>0
Bf26=vBf26+Bf26
endif
if vBf25>0
Bf25=vBf25+Bf25
endif
if vBf24>0
Bf24=vBf24+Bf24
endif
if vBf23>0
Bf23=vBf23+Bf23
endif
if vBf22>0
Bf22=vBf22+Bf22
endif
if vBf21>0
Bf21=vBf21+Bf21
endif
if vBf20>0
Bf20=vBf20+Bf20
endif
if vBf19>0
Bf19=vBf19+Bf19
endif


if vOGS40>0
OGS40=vOGS40+OGS40
endif
if vOGS39>0
OGS39=vOGS39+OGS39
endif
if vOGS38>0
OGS38=vOGS38+OGS38
endif
if vOGS37>0
OGS37=vOGS37+OGS37
endif
if vOGS36>0
OGS36=vOGS36+OGS36
endif
if vOGS35>0
OGS35=vOGS35+OGS35
endif
if vOGS34>0
OGS34=vOGS34+OGS34
endif
if vOGS33>0
OGS33=vOGS33+OGS33
endif
if vOGS32>0
OGS32=vOGS32+OGS32
endif
if vOGS31>0
OGS31=vOGS31+OGS31
endif
if vOGS30>0
OGS30=vOGS30+OGS30
endif
if vOGS29>0
OGS29=vOGS29+OGS29
endif
if vOGS28>0
OGS28=vOGS28+OGS28
endif
if vOGS27>0
OGS27=vOGS27+OGS27
endif
if vOGS26>0
OGS26=vOGS26+OGS26
endif
if vOGS25>0
OGS25=vOGS25+OGS25
endif
if vOGS24>0
OGS24=vOGS24+OGS24
endif
if vOGS23>0
OGS23=vOGS23+OGS23
endif
if vOGS22>0
OGS22=vOGS22+OGS22
endif
if vOGS21>0
OGS21=vOGS21+OGS21
endif
if vOGS20>0
OGS20=vOGS20+OGS20
endif

if vM45>0
M45=vM45+M45
endif
if vM44>0
M44=vM44+M44
endif
if vM43>0
M43=vM43+M43
endif
if vM42>0
M42=vM42+M42
endif
if vM41>0
M41=vM41+M41
endif
if vM40>0
M40=vM40+M40
endif
if vM39>0
M39=vM39+M39
endif
if vM38>0
M38=vM38+M38
endif
if vM37>0
M37=vM37+M37
endif
if vM36>0
M36=vM36+M36
endif
if vM35>0
M35=vM35+M35
endif
if vM34>0
M34=vM34+M34
endif
if vM33>0
M33=vM33+M33
endif
if vM32>0
M32=vM32+M32
endif
if vM31>0
M31=vM31+M31
endif
if vM30>0
M30=vM30+M30
endif
if vM29>0
M29=vM29+M29
endif
if vM28>0
M28=vM28+M28
endif
if vM27>0
M27=vM27+M27
endif
if vM26>0
M26=vM26+M26
endif
if vM25>0
M25=vM25+M25
endif
if vM24>0
M24=vM24+M24
endif
if vM23>0
M23=vM23+M23
endif
if vM22>0
M22=vM22+M22
endif
if vM21>0
M21=vM21+M21
endif
if vM20>0
M20=vM20+M20
endif
if vM19>0
M19=vM19+M19
endif

if vT45>0
T45=vT45+T45
endif
if vT44>0
T44=vT44+T44
endif
if vT43>0
T43=vT43+T43
endif
if vT42>0
T42=vT42+T42
endif
if vT41>0
T41=vT41+T41
endif
if vT40>0
T40=vT40+T40
endif
if vT39>0
T39=vT39+T39
endif
if vT38>0
T38=vT38+T38
endif
if vT37>0
T37=vT37+T37
endif
if vT36>0
T36=vT36+T36
endif
if vT35>0
T35=vT35+T35
endif
if vT34>0
T34=vT34+T34
endif
if vT33>0
T33=vT33+T33
endif
if vT32>0
T32=vT32+T32
endif
if vT31>0
T31=vT31+T31
endif
if vT30>0
T30=vT30+T30
endif
if vT29>0
T29=vT29+T29
endif
if vT28>0
T28=vT28+T28
endif
if vT27>0
T27=vT27+T27
endif
if vT26>0
T26=vT26+T26
endif
if vT25>0
T25=vT25+T25
endif
if vT24>0
T24=vT24+T24
endif
if vT23>0
T23=vT23+T23
endif
if vT22>0
T22=vT22+T22
endif
if vT21>0
T21=vT21+T21
endif
if vT20>0
T20=vT20+T20
endif
if vT19>0
T19=vT19+T19
endif

;Message "targets filled" 
___ ENDPROCEDURE .FillTargetFields _____________________________________________

___ PROCEDURE .HistoryDelete ___________________________________________________
window "customer_history:customeractivity"
find «C#»=vsourcecust

YesNo "delete this record in customer history?" +" "+ str(«C#») + " "+ Con
if clipboard()="Yes"
deleterecord
endif
window thisFYear+" mailing list"

___ ENDPROCEDURE .HistoryDelete ________________________________________________

___ PROCEDURE .SetVariables ____________________________________________________
vTaxName =""
vTIN=""
vConsent=""
vNotified=""
vMem=""
vEquity=0


vTaxName=taxname
vTIN=TIN
vConsent=Consent
vNotified=Notified
vEquity=Equity

vS45=0
vS44=0
vS43=0
vS42=0
vS41=0
vS40=0
vS39=0
vS38=0
vS37=0
vS36=0
vS35=0
vS34=0
vS33=0
vS32=0
vS31=0
vS30=0
vS29=0
vS28=0
vS27=0
vS26=0
vS25=0
vS24=0
vS23=0
vS22=0
vS21=0
vS20=0
vS19=0

vBf45=0
vBf44=0
vBf43=0
vBf42=0
vBf41=0
vBf40=0
vBf39=0
vBf38=0
vBf37=0
vBf36=0
vBf35=0
vBf34=0
vBf33=0
vBf32=0
vBf31=0
vBf30=0
vBf29=0
vBf28=0
vBf27=0
vBf26=0
vBf25=0
vBf24=0
vBf23=0
vBf22=0
vBf21=0
vBf20=0
vBf19=0

vM45=0
vM44=0
vM43=0
vM42=0
vM41=0
vM40=0
vM39=0
vM38=0
vM37=0
vM36=0
vM35=0
vM34=0
vM33=0
vM32=0
vM31=0
vM30=0
vM29=0
vM28=0
vM27=0
vM26=0
vM25=0
vM24=0
vM23=0
vM22=0
vM21=0
vM20=0
vM19=0

//No longer relevant, do not add new ones
vOGS40=0
vOGS39=0
vOGS38=0
vOGS37=0
vOGS36=0
vOGS35=0
vOGS34=0
vOGS33=0
vOGS32=0
vOGS31=0
vOGS30=0
vOGS29=0
vOGS28=0
vOGS27=0
vOGS26=0
vOGS25=0
vOGS24=0
vOGS23=0
vOGS22=0
vOGS21=0
vOGS20=0

vT45=0
vT44=0
vT43=0
vT42=0
vT41=0
vT40=0
vT39=0
vT38=0
vT37=0
vT36=0
vT35=0
vT34=0
vT33=0
vT32=0
vT31=0
vT30=0
vT29=0
vT28=0
vT27=0
vT26=0
vT25=0
vT24=0
vT23=0
vT22=0
vT21=0
vT20=0
vT19=0

vS45=S45
vS44=S44
vS43=S43
vS42=S42
vS41=S41
vS40=S40
vS39=S39
vS38=S38
vS37=S37
vS36=S36
vS35=S35
vS34=S34
vS33=S33
vS32=S32
vS31=S31
vS30=S30
vS29=S29
vS28=S28
vS27=S27
vS26=S26
vS25=S25
vS24=S24
vS23=S23
vS22=S22
vS21=S21
vS20=S20
vS19=S19

//No longer Needing to be added to each year. In 43, bulbs became part of OGS
vBf45=Bf45
vBf44=Bf44
vBf43=Bf43
vBf42=Bf42
vBf41=Bf41
vBf40=Bf40
vBf39=Bf39
vBf38=Bf38
vBf37=Bf37
vBf36=Bf36
vBf35=Bf35
vBf34=Bf34
vBf33=Bf33
vBf32=Bf32
vBf31=Bf31
vBf30=Bf30
vBf29=Bf29
vBf28=Bf28
vBf27=Bf27
vBf26=Bf26
vBf25=Bf25
vBf24=Bf24
vBf23=Bf23
vBf22=Bf22
vBf21=Bf21
vBf20=Bf20
vBf19=Bf19

vOGS40=OGS40
vOGS39=OGS39
vOGS38=OGS38
vOGS37=OGS37
vOGS36=OGS36
vOGS35=OGS35
vOGS34=OGS34
vOGS33=OGS33
vOGS32=OGS32
vOGS31=OGS31
vOGS30=OGS30
vOGS29=OGS29
vOGS28=OGS28
vOGS27=OGS27
vOGS26=OGS26
vOGS25=OGS25
vOGS24=OGS24
vOGS23=OGS23
vOGS22=OGS22
vOGS21=OGS21
vOGS20=OGS20 

vM45=M45
vM44=M44
vM43=M43
vM42=M42
vM41=M41
vM40=M40
vM39=M39
vM38=M38
vM37=M37
vM36=M36
vM35=M35
vM34=M34
vM33=M33
vM32=M32
vM31=M31
vM30=M30
vM29=M29
vM28=M28
vM27=M27
vM26=M26
vM25=M25
vM24=M24
vM23=M23
vM22=M22
vM21=M21
vM20=M20
vM19=M19

vT45=T45
vT44=T44
vT43=T43
vT42=T42
vT41=T41
vT40=T40
vT39=T39
vT38=T38
vT37=T37
vT36=T36
vT35=T35
vT34=T34
vT33=T33
vT32=T32
vT31=T31
vT30=T30
vT29=T29
vT28=T28
vT27=T27
vT26=T26
vT25=T25
vT24=T24
vT23=T23
vT22=T22
vT21=T21
vT20=T20
vT19=T19

;Message "variables set" +" - " +str(vS45)
___ ENDPROCEDURE .SetVariables _________________________________________________

___ PROCEDURE .CurrentRecord ___________________________________________________
/*

global FindCust

FindCust=0

if vSerialNum contains info("serialnumber") or username contains "Kate"
    if DedupOn=-1
        local KeyStroke
        KeyStroke=info("trigger")[5,-1]
        ;message KeyStroke //for debugging

        waswindow = info("DatabaseName") 
        if info("files") notcontains "customer_history"
            stop
        endif

        FindCust=«C#»

        window "customer_history:customeractivity"
        find «C#»=FindCust
        window waswindow
        ////__Looks like this was designed to use tab1 to insert a new line? 
        //but tab1 does more than that......likely dup culprit
        ;KeyStroke=info("trigger")[5,1]
        if KeyStroke=chr(3)
            call ".tab1"
        endif
    endif
endif

*/


___ ENDPROCEDURE .CurrentRecord ________________________________________________

___ PROCEDURE .SerialNumber ____________________________________________________


;vSerialNum="" //uncomment this to clear serial numbers
vSerialNum=?(vSerialNum="",info("serialnumber"),vSerialNum+", "+info("serialnumber"))
rudemessage vSerialNum
___ ENDPROCEDURE .SerialNumber _________________________________________________

___ PROCEDURE .Bria's mass delete ______________________________________________
local vCount, vLength
save
saveacopyas "mailinglist backup"
vLength=info("selected")

addrecord

firstrecord

vCount=0

if info("selected")≠info("records")

loop

deleterecord

vCount=vCount+1

until vCount=vLength

selectall

lastrecord

deleterecord

endif
___ ENDPROCEDURE .Bria's mass delete ___________________________________________

___ PROCEDURE (CommonFunctions) ________________________________________________

___ ENDPROCEDURE (CommonFunctions) _____________________________________________

___ PROCEDURE ExportMacros _____________________________________________________
local Dictionary1, ProcedureList
//this saves your procedures into a variable
exportallprocedures "", Dictionary1
clipboard()=Dictionary1

message "Macros are saved to your clipboard!"
___ ENDPROCEDURE ExportMacros __________________________________________________

___ PROCEDURE ImportMacros _____________________________________________________
local Dictionary1,Dictionary2, ProcedureList
Dictionary1=""
Dictionary1=clipboard()
yesno "Press yes to import all macros from clipboard"
if clipboard()="No"
stop
endif
//step one
importdictprocedures Dictionary1, Dictionary2
//changes the easy to read macros into a panorama readable file

 
//step 2
//this lets you load your changes back in from an editor and put them in
//copy your changed full procedure list back to your clipboard
//now comment out from step one to step 2
//run the procedure one step at a time to load the new list on your clipboard back in
//Dictionary2=clipboard()
loadallprocedures Dictionary2,ProcedureList
message ProcedureList //messages which procedures got changed

___ ENDPROCEDURE ImportMacros __________________________________________________

___ PROCEDURE Symbol Reference _________________________________________________
bigmessage "Option+7= ¶  [in some functions use chr(13)
Option+= ≠ [not equal to]
Option+\= « || Option+Shift+\= » [chevron]
Option+L= ¬ [tab]
Option+Z= Ω [lineitem or Omega]
Option+V= √ [checkmark]
Option+M= µ [nano]
Option+<or>= ≤or≥ [than or equal to]"


___ ENDPROCEDURE Symbol Reference ______________________________________________

___ PROCEDURE GetDBInfo ________________________________________________________
local DBChoice, vAnswer1, vClipHold

Message "This Procedure will give you the names of Fields, procedures, etc in the Database"
//The spaces are to make it look nicer on the text box
DBChoice="fields
forms
procedures
permanent
folder
level
autosave
fileglobals
filevariables
fieldtypes
records
selected
changes"
superchoicedialog DBChoice,vAnswer1,“caption="What Info Would You Like?"
captionheight=1”


vClipHold=dbinfo(vAnswer1,"")
bigmessage "Your clipboard now has the name(s) of "+str(vAnswer1)+"(s)"+¶+
"Preview: "+¶+str(vClipHold)
Clipboard()=vClipHold

___ ENDPROCEDURE GetDBInfo _____________________________________________________

___ PROCEDURE .CheckCode _______________________________________________________
local countRecords
selectduplicates ""
groupup

firstrecord

countRecords=0

loop
if info("summary")<1
downrecord
countRecords=countRecords+1
else

«»=str(countRecords)
countRecords=0
downrecord
endif
until info("stopped")
___ ENDPROCEDURE .CheckCode ____________________________________________________

___ PROCEDURE UpdateEmpty ______________________________________________________
select Updated=""
formulafill datepattern(regulardate(Modified),"mm/dd/yy")+"@"+timepattern(regulartime(Modified),"hh:mm am/pm")
___ ENDPROCEDURE UpdateEmpty ___________________________________________________

___ PROCEDURE .UpdateCats ______________________________________________________
            loop
                rundialog
                “Form="CatalogRequest"
                    Movable=yes
                    okbutton=Update
                    Menus=normal
                    WindowTitle={CatalogRequest}
                    Height=264 Width=190
                    AutoEdit="Text Editor"
                    Variable:"val(«dS»)=val(«S»)"
                    Variable:"val(«dBf»)=val(«Bf»)"
                    Variable:"val(«dT»)=val(«T»)"”
                stoploopif info("trigger")="Dialog.Close"
            while forever 
___ ENDPROCEDURE .UpdateCats ___________________________________________________

___ PROCEDURE .test2 ___________________________________________________________
;if info("fieldname")="C#"
style "record black"
;endif
Numb=0
if «C#»>0
    Numb=«C#»
    ;displaydata Numb
    window "customer_history"
    Find str(«C#») contains str(Numb)
    if info("found")≠-1
        OpenSheet
        lastrecord
        insertbelow
    endif
    «C#»=grabdata(thisFYear+" mailing list", «C#»)
    Con=grabdata(thisFYear+" mailing list", Con)
    «Group»=grabdata(thisFYear+" mailing list", «Group»)
    MAd=grabdata(thisFYear+" mailing list", MAd)
    City=grabdata(thisFYear+" mailing list", City)
    St=grabdata(thisFYear+" mailing list", St)
    Zip=grabdata(thisFYear+" mailing list", Zip)
    «SpareText2»=grabdata(thisFYear+" mailing list", «SpareText2»)
    ;closewindow
    ;window "customer_history:customeractivity"

    window thisFYear+" mailing list"
endif

___ ENDPROCEDURE .test2 ________________________________________________________

___ PROCEDURE .appendCustomer __________________________________________________
global appendChoice

appendChoice="default"
appendChoice=str(parameter(1))
if error
appendChoice=appendChoice
endif

////____debug________
;displaydata appendChoice
//__________________

case appendChoice contains "member"
window "members"
lastrecord
insertbelow
«C#»=grabdata("45 mailing list", «C#»)
Con=grabdata("45 mailing list", Con)
Group=grabdata("45 mailing list", Group)
MAd=grabdata("45 mailing list", MAd)
City=grabdata("45 mailing list", City)
St=grabdata("45 mailing list", St)
Zip=grabdata("45 mailing list", Zip)
SAd=grabdata("45 mailing list", SAd)
Cit=grabdata("45 mailing list", Cit)
Sta=grabdata("45 mailing list", Sta)
Z=grabdata("45 mailing list", Z)
phone=grabdata("45 mailing list", phone)
email=grabdata("45 mailing list", email)
inqcode=grabdata("45 mailing list", inqcode)
«Mem?»=grabdata("45 mailing list", «Mem?»)
windowtoback "members"
window thisFYear+" mailing list"

endcase
___ ENDPROCEDURE .appendCustomer _______________________________________________

___ PROCEDURE .hasInfo _________________________________________________________
global cNumVal,hasAnAddress,hasACon

cNumVal=0
hasACon=""
hasAnAddress=""

field «C#»
    copycell
    cNumVal=val(clipboard())

hasAnAddress=?(MAd≠"",MAd+" "+str(Zip),"No Mailing Address")

ç
___ ENDPROCEDURE .hasInfo ______________________________________________________

___ PROCEDURE .TestNewZip ______________________________________________________
// from editing C# -> calls .custnumber -> if its empty -> calls this

fileglobal listzip, thiszip, findher, findzip, findcity, newcity, findname,findname1, findname2, thisname, firstname, lastname
serverlookup "off" 
;waswindow=info("windowname")
listzip=""
thiszip=""
newcity=""


again:
findher=addressArray


///____gets address from Order user was on or lets user type it in___///
supergettext findher, {caption="Enter Address.Zip" height=100 width=400 captionfont=Courier New captionsize=14 captioncolor="cornflowerblue"
    buttons="Find;Redo;Cancel"}
    if info("dialogtrigger") contains "Find"
        findzip=extract(findher,".",2)
        findzip=strip(findzip)
            if length(findzip)=4
            findzip="0"+findzip
            endif
        findcity=extract(findher,".",1)
        liveclairvoyance findzip,listzip,¶,"","45 mailing list",pattern(Zip,"#####"),"=",str(«C#»)+¬+rep(" ",7-length(str(«C#»)))+Con+rep(" ",max(20-length(Con),1))+¬+MAd+¬+City+¬+St+¬+pattern(Zip,"#####"),0,0,""
        arraysubset listzip, listzip, ¶, import() contains findcity
            if listzip=""
            goto lastzip
            endif
            
        //___if only one is found, then ask the user if they want to enter it___//
    
        if arraysize(listzip,¶)=1
        find MAd contains findcity and pattern(Zip,"#####") contains findzip
        

        AlertYesNo "Enter this one?"
            if info("dialogtrigger") contains "Yes"
           goto lastline
            ;stop
            else
            AlertOkCancel "Try by zipcode?"
                if info("dialogtrigger") contains "OK"
                call "getzip/Ω"
                endif
             endif
           endif
    endif
    
    if info("dialogtrigger") contains "Redo"
    findher=""
    goto again
    endif
    
    if info("dialogtrigger") contains "Cancel"
    window waswindow
    stop
    endif


superchoicedialog listzip, thiszip, {height=400 width=800 font=Courier caption="Click on one and then hit OK or New for new entry" 
        captionfont=Times captionsize=12 captioncolor=red size=14 buttons="OK:100;Try Name:150;Cancel:100"}
if info("dialogtrigger") contains "OK"
    find «C#» = val(strip(extract(thiszip, ¬,1))) and MAd=extract(thiszip, ¬,3) and City contains extract(thiszip, ¬,4)
    ;;find MAd=extract(thiszip, ¬,2) and City contains extract(thiszip, ¬,3)
    showpage

    call "enter/e"
endif

if info("dialogtrigger") contains "Try Name"
    goto tryname
    gettext "Which town?", newcity
    if newcity≠""
        find Z=val(findzip) and City contains newcity
        insertbelow
    else
        find Zip=val(findzip)
        insertbelow
    endif
endif
showpage
serverlookup "on"

tryname:
    firstname=""
    lastname=""
    findname=""
    findname1=""
    findname2=""
    findname=rayj
    supergettext findname, {caption="Enter First and Last Name" height=100 width=400 captionfont=Times captionsize=14 captioncolor="limegreen"
    buttons="Find;Redo;Cancel"}
    firstname=extract(findname," ",1)
     lastname=extract(findname," ",2)
    if info("dialogtrigger") contains "Find"
        liveclairvoyance lastname,findname1,¶,"","45 mailing list",Con,"contains",Con+¬+MAd+¬+City+¬+St+¬+pattern(Zip,"#####")+¬+phone,0,0,""
        message findname1
    endif
    
    if info("dialogtrigger") contains "Redo"
        goto tryname
    endif
    
    if info("dialogtrigger") contains "Cancel"
        stop
    endif
    
    arraysubset findname1,findname1,¶,import() contains firstname
    if arraysize(findname1,¶)=1
        find Con contains firstname and Con contains lastname
        AlertYesNo "Enter this one?"
        if info("dialogtrigger") contains "Yes"
            call "enter/e"
            stop
        else
            lastzip:
            getscrap "What zip code?"
            find Zip=val(clipboard())
            insertbelow
            stop
        endif
    endif
    superchoicedialog findname1,thisname, {height=400 width=500 font=Helvetica caption="Click on one and then hit OK or New for new entry" 
        captionfont=Times captionsize=12 captioncolor=green size=14 buttons="OK:100;New:100;Cancel:100"}
     if info("dialogtrigger") contains "OK"
        find Con contains extract(thisname, ¬,1) and City contains extract(thisname, ¬,3)
        call "enter/e"
     endif
     
     if info("dialogtrigger") contains "New"
        gettext "Which town?", newcity
        if newcity≠""
            window "45 mailing list"
            find Z=val(findzip) and City contains newcity
            insertbelow
        else
            find Zip=val(findzip)
            insertbelow
        endif
    endif
    
    showpage
    serverlookup "on"
    stop

    lastline:
    serverlookup "on"
    call "enter/e"

___ ENDPROCEDURE .TestNewZip ___________________________________________________

___ PROCEDURE vGetName _________________________________________________________
gosheet
find Con=extract(getname,": ",2)
searchname=""
call .tab1
___ ENDPROCEDURE vGetName ______________________________________________________

___ PROCEDURE numberNeeded _____________________________________________________
//if you got here, but they have a number, skip this whole process and go back to enter
if «C#»≠0 
    goto End
endif

//gives them an First Year and Branch of Order code
    case fromBranch contains ";"
        if fromBranch contains "Bulb"
            Code="I"+thisFYear+"b"
        endif
        if fromBranch contains "POE"
            Code="I"+thisFYear+"p"
        endif
    case fromBranch contains "Seeds"
    Code = "I"+thisFYear+"s"
    case fromBranch contains "OGS"
    Code = "I"+thisFYear+"o"
    case fromBranch contains "Trees"
    Code = "I"+thisFYear+"t"
    endcase

//gets a new number
openfile "Customer#"
call "newnumber"
window thisFYear+" mailing list"
Field «C#»
    Paste

//saves the C# in sparetext2
SpareText2=str(«C#»)

//Get InqCode
If inqcode=""

Field inqcode
    //autofill internet entry
    case internet_order=-1
        inqcode=str(yearvalue(today()))[3,4]+"onl"

    defaultcase
        editcell
        //if it has this year twice e.g. "2222", then just make it the 22 then inqcode
        inqcode=?(inqcode contains str(yearvalue(today()))[3,4]+str(yearvalue(today()))[3,4],inqcode[3,-1],inqcode)
        //if someone types 2022 goes to 7th character because it'll autofill as 222022onl
        inqcode=?(inqcode contains str(yearvalue(today())),str(yearvalue(today()))[3,4]+inqcode[7,-1],inqcode)
    endcase
field «C#»
EndIf

//fills in catalog requests based on order/location/redflags
call "filler/¬"

If inqcode=""
field inqcode
editcell
endif


//_______give them customer history________________________//
window "customer_history:secret"
opensheet
insertbelow
«C#»=grabdata(thisFYear+" mailing list", «C#»)
«Group»=grabdata(thisFYear+" mailing list", «Group»)
Con=grabdata(thisFYear+" mailing list", Con)
MAd=grabdata(thisFYear+" mailing list", MAd)
City=grabdata(thisFYear+" mailing list", City)
St=grabdata(thisFYear+" mailing list", St)
Zip=grabdata(thisFYear+" mailing list", Zip)
Email=grabdata(thisFYear+" mailing list", email)
SpareText2=grabdata(thisFYear+" mailing list", SpareText2)
;CloseWindow

End:
window thisFYear+" mailing list"
Call "enter/e"

___ ENDPROCEDURE numberNeeded __________________________________________________

___ PROCEDURE .OpenOrderSearch/¬ _______________________________________________
window thisFYear+"orders"
call NewSearch/¬
___ ENDPROCEDURE .OpenOrderSearch/¬ ____________________________________________

___ PROCEDURE .getequations ____________________________________________________
global eqArray
arraybuild eqArray, ¶,"", ?(Equation≠"","~~"+«Field Name»+"~~"+¶+Equation+¶,"")
clipboard()=eqArray 
___ ENDPROCEDURE .getequations _________________________________________________

___ PROCEDURE .test ____________________________________________________________
message info("datatype")
___ ENDPROCEDURE .test _________________________________________________________

___ PROCEDURE .test3 ___________________________________________________________
global Con_Email_Group_Phone
selectall 
Field Con
    sortup
    field phone
    sortupwithin
    field email
    sortupwithin
    field Group
    sortupwithin
selectduplicates Con+phone+email+«Group»
;selectwithin Con≠"" and phone≠"" and email≠"" 
arrayselectedbuild Con_Email_Group_Phone,¶,"",str(«C#»)+¬+Con
Field «C#»
lastrecord


___ ENDPROCEDURE .test3 ________________________________________________________

___ PROCEDURE .AutomaticFY _____________________________________________________
global dateHold, dateMath, intYear, 
thisFYear,lastFYear,nextFYear,intMonth,fileDate

fileDate=val(striptonum(info("databasename")))
nextFYear=""
thisFYear=""
lastFYear=""

//get the date
dateHold = datepattern(today(),"mm/yyyy")

//gets the current month and year
intMonth = val(dateHold[1,"/"][1,-2])
intYear = val(dateHold["/",-1][2,-1])

//assigns FY numbers for years

case val(intMonth)>6
    nextFYear=str(intYear-1976)
    thisFYear=str(intYear-1977)
    lastFYear=str(intYear-1978)

case val(intMonth)<7
    nextFYear=str(intYear-1977)
    thisFYear=str(intYear-1978)
    lastFYear=str(intYear-1979)

endcase

//checks if this is an older file and needs older FYs
if fileDate ≤ val(lastFYear) and fileDate > 0
    message "This file is older than 2 years and will try to open older order files, etc"
    nextFYear=str(fileDate+1)
    thisFYear=str(fileDate)
    lastFYear=str(fileDate-1)
endif

//tallmessage str(nextFYear)+¬+str(thisFYear)+¬+str(lastFYear)


/*

///////~~~~~~~
Programmer Notes
~~~~~~~~~//////////
The danger of this procedure is that come July 1st of the year, it will automatically set
to open the newest files of a non-numbered Panorama file. And if those don't exist, you're 
gonna see errors. Also, a non numbered Panorama file that needs to call older files shouldn't
use this macro



To use these variables please note the following Panorama syntax rules:


filenames using variables:
    can just concatenate as a string
    
    ex:
        
    openfile str(variable)+"filename" 


field calls using variables:
    best to be only one variable and nothing else
    must be surrounded by ( )
    
    ex:
    
    field (VariableFieldName)
    
do your math and/or concatenation into the variable before calling it
    VariableFieldName=str(variable)+"fieldname"
 
field (str(variable)+"fieldname") will work but can cause errors
    
for assignments to that variable'd field 
    use «» for "current field/current cell" 
    
    ex: 
   
    «» = "10"
  
    
*/
___ ENDPROCEDURE .AutomaticFY __________________________________________________

___ PROCEDURE .SetDedupCounter _________________________________________________

___ ENDPROCEDURE .SetDedupCounter ______________________________________________
