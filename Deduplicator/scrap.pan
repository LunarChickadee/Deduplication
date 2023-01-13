
//__differenciates between whether this was from a form press or from another call__//
fileglobal refresh_pressed

refresh_pressed=0

if info("trigger") contains "Refresh"
    refresh_pressed=-1
endif

//___if a form is currently the top window, open the datasheet, or bring it to the front___//

if info("windowtype")=5
    opensheet
endif

//__Get records, and make them into a list__/
//select info("summary")<1

global list_of_records, record_count
record_count=""
record_count=info("selected")
//____Makes a readable, stackable display for the user on the ChooseDestination form_____//
arrayselectedbuild list_of_records, ¶,"",?(Flagged≠"", "RedFlagged!!!! Check Closely"+¶,"")+?(info("summary")>0, "Merged Preview is below:"+¶,"")+arrayrange(exportline(),1, 7,¬)+¶
+arrayrange(exportline(),15, 16,¬)+arrayrange(exportline(),18, 19,¬)+¶
+upper(«Notes»)+upper(«RedFlag»)+¶
+"Last Entered Sale: Seeds:"+str(LastSeeds)+¬+" Trees:"+str(LastTrees)+" OGS:"+str(LastNewOGS)+" Bulbs:"+str(LastBulbs)+¶
+?(Consent≠"", "Consent: "+str(Consent),"")+" "+?(Flagged≠"", "Flagged: "+str(Flagged),"")+" "+?(CHNotes≠"", ¶+"CHNotes: "+str(CHNotes),"")+" "+¶
+"______________________________~"

arrayfilter list_of_records, list_of_records, "~",
?(seq()=1,"Record "+str(seq())+":     "+¶+import(),
        ?(seq()≤info("selected"),¶+"Record "+str(seq())+":     "+import(),""))
        
        ;displaydata list_of_records

//________Makes everything update for the form______
            
showvariables list_of_records, record_count

openform dedup_form_window

if info("formname")≠""
drawobjects
endif

///___if this came from the from, go back there for ease of use by the user___//
if refresh_pressed =-1
    nop
else
    //if you did't come from a form, go back to the data sheet
    window dedup_window
endif

selectall