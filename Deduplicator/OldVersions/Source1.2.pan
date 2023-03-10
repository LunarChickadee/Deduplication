___ PROCEDURE .Initialize ______________________________________________________
global dedup_window, dedup_form_window, count_runs, lowest_code

count_runs=0

dedup_window=info("databasename")

openform "ChooseDestination"

dedup_form_window=info("formname")

call .BuildChoiceList

if info("formname")≠""
drawobjects
endif

showvariables list_of_records

opensheet
___ ENDPROCEDURE .Initialize ___________________________________________________

___ PROCEDURE AutoSort/1 _______________________________________________________
Global Deduplicate_Selected_Array, Update_Weight, Last_Order_Weight, Was_Online, Total_Weight,
    highest_inq_code, highest_year, fivecount, recent_inq, has_redflag, newest_inq, newest_inq_onl, has_sales,
    entered_recently, recently_updated_ML, has_taxname, has_consent, hits_multiple
        
    count_runs=count_runs+1
    fivecount=0

    
    highest_inq_code=0
    highest_year=0
    ///____Weights Variables_____
        //___These are from 1-5 and get multiplied later on. 5 being biggest influence, and 1 being smallest__//
    recent_inq=2
    has_redflag=""
    newest_inq=4
    newest_inq_onl=5
    has_sales=3
    entered_recently=4
    recently_updated_ML=3
    has_taxname=4
    has_consent=3
    hits_multiple=5
    
    Deduplicate_Selected_Array=""

selectwithin striptoalpha(exportline())≠""
removeunselected

if count_runs<2
displaydata "This Procedure will put the record it guesses to have the most recent information as the first record, then gives you options for merging records. (Note: It may also put an older record higher if the customer has given a legal address for patronage dividends)

The summary (purple/blue shaded) record it creates is meant to be used as the new 'merged' record. 

You can do this entire process from the data sheet, but, there is also a form called 'ChooseDestination' that will make records easier to read and pick out key info from included most recent sales entered and from what branch. 

All merged records that do not go back into the Mailing list or Customer history will go to a file called DedupArchive, which is a linked file

This message will come up the first time you run this procedure after closing the file, but shouldn't come up after using CMD-1 during this session."
endif 


///___was most recently updated
    field LastUpdateSortable
    selectwithin «» > 0
    sortdown
    firstrecord
    field «UpdateWeight» 
    formulafill 0

    fivecount=5
    //fills them in reverse order
    
    loop
        «UpdateWeight»=fivecount
        downrecord
        fivecount=fivecount-1
    until info("stopped") or fivecount=0


    field «UpdateWeight»
        formulafill «»*val(recently_updated_ML)
    
selectall

///____has most recent inqcode
    field InqCodeNum
    select InqCodeNum>0

    if (not info("empty"))
        sortdown
        firstrecord
        highest_inq_code=«»
    field InqWeight
    formulafill 0
        fivecount=5
        loop
                case InqCodeNum=highest_inq_code
                    «»=fivecount
                    downrecord
                defaultcase
                    fivecount=fivecount-1
                    «»=fivecount
                    downrecord
                endcase
        until info("stopped") or fivecount=0

        field InqWeight
            formulafill «»*val(newest_inq)

    endif

selectall

///_____Has a sale that was entered most recently____

    field EnteredWeight
        formulafill 0
    select «MostRecentEntered»>0
    
    if (not info("empty"))
        field «MostRecentEntered»
        sortdown
        
            firstrecord
            highest_year=«»
        field EnteredWeight
            fivecount=5
                loop
                    case «MostRecentEntered»=highest_year
                        «»=fivecount
                        downrecord
                    defaultcase 
                        fivecount=fivecount-1
                        «»=fivecount
                        downrecord
                    endcase
                until info("stopped") or fivecount=0
            formulafill «»*entered_recently
    endif
    

selectall

//fix this not resetting the numbers back if run again
    debug
field ConsentWeight
    formulafill «»*has_consent

    
field OnlineWeight
    formulafill Online*5

///____Do multiplication
field HowLikelyWeight
formulafill ConsentWeight+EnteredWeight+«UpdateWeight»+InqWeight

debug ///_______________________
call .Maximum

field HowLikelyWeight
sortdown
firstrecord

//_____Number all Records____
    field «CountSequence»
    lastrecord
    togglesummarylevel
    firstrecord
    sequence "1"
    lastrecord
    togglesummarylevel

//___get back to C#

field «C#»
___ ENDPROCEDURE AutoSort/1 ____________________________________________________

___ PROCEDURE .Maximum _________________________________________________________
global max_score, score_array, score_range, in_both, lowest_Cust_Num, compare_records, compare_records_again, compare_field, total_records

max_score=0
score_range=""


//count how many times to loop
total_records=info("records")


//__Get Highest Weight__//
field HowLikelyWeight
maximum
max_score=«»


score_range=str(max_score-3)+¶+
    str(max_score-2)+¶+
    str(max_score-1)+¶+
    str(max_score+1)+¶+
    str(max_score+2)+¶+
    str(max_score+3)
    
;////displaydata score_range

removeallsummaries

selectwithin score_range contains str(HowLikelyWeight)
if (not info("empty"))
    bigmessage "Scores are really close on this one. Please merge by hand."
    goto CheckGroup
endif

selectwithin str(HowLikelyWeight) contains str(max_score)

if (not info("empty"))
    case info("selected")>1
    message "Scores are really close on this one. Please merge by hand."
    endcase
endif


CheckGroup:
selectall

debug
Field «Group»
    emptyfill "No Group"
    arraybuild compare_records, ¶, "", «»
    arraydeduplicate compare_records, compare_records_again, ¶
    if arraycontains(compare_records,"No Group",¶)=-1 and linecount(compare_records_again)>1
        bigmessage "One of these Records Might be for a separate 'Group' or Business account. If so, use CMD+3 and follow the prompts. Otherwise, choose your destination record with CMD+4"
    endif
    
    select «Group» contains "No Group"
        Formulafill ""
    selectall

CreateMergeRecord:
    //__get lowest C# and Code (first order) __//
    field «C#»
    minimum
    lowest_Cust_Num=«»


lowest_code=""
    field Code
    minimum
    lowest_code=«»



    //___flag as a merge record___//
    IsAMergeRecord="Yes"

    //__Fill all info that's identical to the merge record___//
    
    field «Con»
    
    loop
    compare_field=info("fieldname")
    arraybuild compare_records, ¶, "", «»
    arraydeduplicate compare_records, compare_records, ¶
    
    if linecount(compare_records)=1
    «»=compare_records
    endif
    right
    until info("fieldname")="Updated"

    displaydata "All Fields that were identical or had holes in the data have been added to a new merge Record (summary record)."+¶+¶+"You may manually choose which parts to move and/or use:"+¶+¶+"CMD+2 to Choose the topmost record as the new 'master record' it will inherit the oldest C# and codes"+¶+"or"+¶+"us CMD+3 or click a selection in the ChooseDesination Form to merge to that selected record."

call .BuildChoiceList   

selectall
    debug

/*
    //__make it it's own record
    lastrecord
    togglesummarylevel
*/
debug 






___ ENDPROCEDURE .Maximum ______________________________________________________

___ PROCEDURE .BuildChoiceList _________________________________________________

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

//__Get nonsummary records, and make them into a list__?/
select info("summary")<1

global list_of_records, record_count
record_count=info("selected")
//____Makes a readable, stackable display for the user on the ChooseDestination form_____//
arrayselectedbuild list_of_records, ¶,"",arrayrange(exportline(),1, 7,¬)+¶+arrayrange(exportline(),15, 20,¬)+¶+
"Last Entered Sale: Seeds:"+str(LastSeeds)+¬+" Trees:"+str(LastTrees)+" OGS:"+str(LastNewOGS)+" Bulbs:"+str(LastBulbs)+¶+
"______________________________~"

arrayfilter list_of_records, list_of_records, "~",
?(seq()=1,"Record "+str(seq())+":     "+¶+import(),
        ?(seq()≤info("selected"),¶+"Record "+str(seq())+":     "+import(),""))

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

___ ENDPROCEDURE .BuildChoiceList ______________________________________________

___ PROCEDURE AutoMerge/2 ______________________________________________________
yesno "Automatically merge all selected records to the topmost (likely most recent) record? Oldest C#, and Code will be chosen. History will be merged."

if clipboard()="No"
    Stop
endif

firstrecord
fileglobal auto_merge_record
auto_merge_record=""

field IsDestinationRecord
formulafill ""

IsDestinationRecord="Yes"

auto_merge_record=exportline()
lastrecord

call .LineItemMerge
    
///___code should merge all the line item stuff, then make the top record be the new merge record with proper numbers

field SeedsHistory

loop
move_history_up=«»
firstrecord
«»=move_history_up
right
lastrecord
until info("fieldname") = "CountSequence"

firstrecord 
«Code»=lowest_code

«OldCNums»=«C#»

«C#»=lowest_Cust_Num

lastrecord
deleterecord
firstrecord
togglesummarylevel








___ ENDPROCEDURE AutoMerge/2 ___________________________________________________

___ PROCEDURE .LineItemMerge ___________________________________________________
Global Return_To, New_Master_Record, New_Master_CNum, DedupWindow,
    Seeds_Merged, Seeds_Hist1, Seeds_Hist2, Seeds_Rec1, Seeds_Rec2, Seeds_Done


DedupWindow=info("databasename")
New_Master_Record=0
Return_To=0
Seeds_Merged=0
Seeds_Rec1=""
Seeds_Rec2=""
New_Master_CNum=0


//_____Number all Records____
    field «CountSequence»
    lastrecord
    togglesummarylevel
    firstrecord
    sequence "1"
    lastrecord
    togglesummarylevel
    

//__get MergeNumber for CustomerHistory
lastrecord
if info("summary")>0
    New_Master_CNum=«C#»
    New_Master_Record=«CountSequence»
endif

///____Begin Cycle____
 global Seeds_Merged, Seeds_Hist1,
        Trees_Merged, Trees_Hist1,
        OGS_Merged, OGS_Hist1,
        Moose_Merged, Moose_Hist1,
        Bulbs_Merged, Bulbs_Hist1

        


//____Seeds Merge_____
    Seeds_Merged=""
    Seeds_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Seeds_Hist1=«SeedsHistory»
        arrayfilter Seeds_Hist1, Seeds_Merged, ",", val(import())+val(array(Seeds_Merged, seq(), ","))
        ////displaydata Seeds_Merged
    endif
    downrecord

    until info("summary")>0

    SeedsHistory=Seeds_Merged

//____Trees Merge_____
    Trees_Merged=""
    Trees_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Trees_Hist1=«TreesHistory»
        arrayfilter Trees_Hist1, Trees_Merged, ",", val(import())+val(array(Trees_Merged, seq(), ","))
        ////displaydata Trees_Merged
    endif
    downrecord

    until info("summary")>0

    TreesHistory=Trees_Merged

//____Bulbs Merge_____
    Bulbs_Merged=""
    Bulbs_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Bulbs_Hist1=«BulbsHistory»
        arrayfilter Bulbs_Hist1, Bulbs_Merged, ",", val(import())+val(array(Bulbs_Merged, seq(), ","))
        ////displaydata Bulbs_Merged
    endif
    downrecord

    until info("summary")>0

    BulbsHistory=Bulbs_Merged

//____OGS Merge_____
    OGS_Merged=""
    OGS_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        OGS_Hist1=«OGSHistory»
        arrayfilter OGS_Hist1, OGS_Merged, ",", val(import())+val(array(OGS_Merged, seq(), ","))
        ////displaydata OGS_Merged
    endif
    downrecord

    until info("summary")>0

    OGSHistory=OGS_Merged

//____Moose Merge_____
    Moose_Merged=""
    Moose_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Moose_Hist1=«MooseHistory»
        arrayfilter Moose_Hist1, Moose_Merged, ",", val(import())+val(array(Moose_Merged, seq(), ","))
        ////displaydata Moose_Merged
    endif
    downrecord

    until info("summary")>0

    MooseHistory=Moose_Merged

/*
yesno "stop?"
if clipboard()="Yes"
stop
endif
*/

;call .MergeToHistory
___ ENDPROCEDURE .LineItemMerge ________________________________________________

___ PROCEDURE ChooseMergeRecord/4 ______________________________________________
yesno "Choose as Master Record?: "+arrayrange(exportline(),1, 7,¬)+¶+arrayrange(exportline(),15, 20,¬)

if clipboard()="Yes"
IsDestinationRecord="Yes"

else
stop
endif

lastrecord
togglesummarylevel

___ ENDPROCEDURE ChooseMergeRecord/4 ___________________________________________

___ PROCEDURE .UserChoice ______________________________________________________
global matrix_row_chosen

matrix_row_chosen=arrayrange(array(list_of_records,info("matrixrow"),"~"), 2, 3,¶)

;displaydata arraystrip(matrix_row_chosen[¶,-1],¶)

yesno "Choose: "+matrix_row_chosen+"  to be the master record?"

if clipboard()="Yes"
    find CountSequence=info("matrixrow")
        //___this checks to make sure the data is where it expects to be___//
        if exportline() notcontains arraystrip(matrix_row_chosen[¶,-1],¶)
            message "error, could not confirm correct record. Procedure will stop"
            stop
        endif
    IsDestinationRecord="Yes"
endif

if clipboard()="No"
    message "OK. Procedure will stop."
    stop
endif

___ ENDPROCEDURE .UserChoice ___________________________________________________

___ PROCEDURE FindMostRecent ___________________________________________________
global Dedup_form, Branch_with_most_recent, Field_Nums_Array, most_recent_year,reference_num,
    seed_dict, new_ogs_dict, old_ogs_dict, bulbs_dict, trees_dict, default_seeds, default_trees, 
    default_ogs, default_moose, default_bulbs

Branch_with_most_recent=""

Dedup_form=info("windowname")

seed_dict=""
new_ogs_dict=""
old_ogs_dict=""
bulbs_dict=""
trees_dict=""

reference_num=val(«C#»)

window "customer_history"

//___This creates a blank array of commas to make adding things up easier for records that have zero sales
default_seeds=rep(chr(44), arraysize(lineitemarray(SΩ, ","),",")-1)
default_trees=rep(chr(44), arraysize(lineitemarray(TΩ, ","),",")-1)
default_ogs=rep(chr(44), arraysize(lineitemarray(OGSΩ, ","),",")-1)
default_moose=rep(chr(44), arraysize(lineitemarray(MΩ, ","),",")-1)
default_bulbs=rep(chr(44), arraysize(lineitemarray(BfΩ, ","),",")-1)

///____If we don't have a matching customer_history Record, set everything to zero____//
case reference_num > 0
    find «C#»=reference_num
        if (not info("found"))
            window Dedup_form
                LastBulbs=0
                LastNewOGS=0
                LastOldOGS=0
                LastSeeds=0
                LastTrees=0
                HasConsent=0
                most_recent_year="0"
                goto FillHistories
        endif
defaultcase
    window Dedup_form
            LastBulbs=0
            LastNewOGS=0
            LastOldOGS=0
            LastSeeds=0
            LastTrees=0
            HasConsent=0
            most_recent_year="0"
            goto FillHistories
endcase

window "customer_history"

//____Find out if they've done a consent form_____///
if Consent contains "y"
    has_consent=1
else 
    has_consent=0
endif


///Find Seed info
    global Seeds_History, Recent_Seeds, Last_Seeds, Seeds_Fields,Field_Seeds, Seeds_Num, Seeds_Sales

    Seeds_Sales=""
    Seeds_History=""
    Recent_Seeds=""
    Last_Seeds=""
    Seeds_Fields=""
    Field_Seeds=""
    Seeds_Num=""

    //__This just Fill the history on the Deduplicator
    Seeds_Sales=lineitemarray(SΩ, ",")
    ///___Counts fields for the array, finds the non-zero ones, gives those counts and amounts
    arrayfilter lineitemarray(SΩ,¶), Seeds_History, ¶, str(Seq())+¬+import()
    arrayfilter Seeds_History,Recent_Seeds, ¶, ?(val(import()[¬,-1][2,-1])>0, import(),"")
    arraystrip Recent_Seeds, ¶
    ////_____ex: 2      122.55________

    ///___get the fieldnames to reference that count to_________
    arrayfilter dbinfo("fields", ""), Seeds_Fields, ¶, ?(import() match "S??" and val(import()[2,-1])>0,import(),"")
    arraystrip Seeds_Fields, ¶

    //______Attach that info together to let the user know the most recent order
    Field_Seeds=array(Seeds_Fields,val(arrayfirst(Recent_Seeds, ¶)[1, ¬][1,-2]), ¶)
    Seeds_Num=striptonum(Field_Seeds)
    Last_Seeds=Field_Seeds+¬+arrayfirst(Recent_Seeds, ¶)[¬,-1][2,-1]

//Find Bulbs Info

    global Bulbs_History, Recent_Bulbs, Last_Bulbs, Bulbs_Fields,Field_Bulbs, Bulbs_Num, Bulbs_Sales

    Bulbs_History=""
    Recent_Bulbs=""
    Last_Bulbs=""
    Bulbs_Fields=""
    Field_Bulbs=""
    Bulbs_Num=""
    Bulbs_Sales=""

    Bulbs_Sales=lineitemarray(BfΩ, ",")
    ///___Counts fields for the array, finds the non-zero ones, gives those counts and amounts
    arrayfilter lineitemarray(BfΩ,¶), Bulbs_History, ¶, str(Seq())+¬+import()
    arrayfilter Bulbs_History,Recent_Bulbs, ¶, ?(val(import()[¬,-1][2,-1])>0, import(),"")
    arraystrip Recent_Bulbs, ¶
    ////_____ex: 2      122.55________

    ///___get the fieldnames to reference that count to_________
    arrayfilter dbinfo("fields", ""), Bulbs_Fields, ¶, ?(import() match "Bf??" and val(import()[3,-1])>0,import(),"")
    arraystrip Bulbs_Fields, ¶

    //______Attach that info together to let the user know the most recent order
    Field_Bulbs=array(Bulbs_Fields,val(arrayfirst(Recent_Bulbs, ¶)[1, ¬][1,-2]), ¶)
    Bulbs_Num=striptonum(Field_Bulbs)
    Last_Bulbs=Field_Bulbs+¬+arrayfirst(Recent_Bulbs, ¶)[¬,-1][2,-1]

//Find "Moose" now OGS info

    global Moose_History, Recent_Moose, Last_Moose, Moose_Fields,Field_Moose, Moose_Num, Moose_Sales

    Moose_History=""
    Recent_Moose=""
    Last_Moose=""
    Moose_Fields=""
    Field_Moose=""
    Moose_Num=""
    Moose_Sales=""

    Moose_Sales=lineitemarray(MΩ, ",")

    ///___Counts fields for the array, finds the non-zero ones, gives those counts and amounts
    arrayfilter lineitemarray(MΩ,¶), Moose_History, ¶, str(Seq())+¬+import()
    arrayfilter Moose_History,Recent_Moose, ¶, ?(val(import()[¬,-1][2,-1])>0, import(),"")
    arraystrip Recent_Moose, ¶
    ////_____ex: 2      122.55________

    ///___get the fieldnames to reference that count to_________
    arrayfilter dbinfo("fields", ""), Moose_Fields, ¶, ?(import() match "M??" and val(import()[2,-1])>0,import(),"")
    arraystrip Moose_Fields, ¶

    //______Attach that info together to let the user know the most recent order
    Field_Moose=array(Moose_Fields,val(arrayfirst(Recent_Moose, ¶)[1, ¬][1,-2]), ¶)
    Moose_Num=striptonum(Field_Moose)
    Last_Moose=Field_Moose+¬+arrayfirst(Recent_Moose, ¶)[¬,-1][2,-1]


//Find Historical OGS info
    global OGS_History, Recent_OGS, Last_OGS, OGS_Fields,Field_OGS, OGS_Num, OGS_Sales

    OGS_History=""
    Recent_OGS=""
    Last_OGS=""
    OGS_Fields=""
    Field_OGS=""
    OGS_Num=""
    OGS_Sales=""

    OGS_Sales=lineitemarray(OGSΩ, ",")

    ///___Counts fields for the array, finds the non-zero ones, gives those counts and amounts
    arrayfilter lineitemarray(OGSΩ,¶), OGS_History, ¶, str(Seq())+¬+import()
    arrayfilter OGS_History,Recent_OGS, ¶, ?(val(import()[¬,-1][2,-1])>0, import(),"")
    arraystrip Recent_OGS, ¶
    ////_____ex: 2      122.55________

    ///___get the fieldnames to reference that count to_________
    arrayfilter dbinfo("fields", ""), OGS_Fields, ¶, ?(import() match "OGS??" and val(import()[4,-1])>0,import(),"")
    arraystrip OGS_Fields, ¶

    //______Attach that info together to let the user know the most recent order
    Field_OGS=array(OGS_Fields,val(arrayfirst(Recent_OGS, ¶)[1, ¬][1,-2]), ¶)
    OGS_Num=striptonum(Field_OGS)
    Last_OGS=Field_OGS+¬+arrayfirst(Recent_OGS, ¶)[¬,-1][2,-1]

//Find Trees Info
global Trees_History, Recent_Trees, Last_Trees, Trees_Fields,Field_Trees, Trees_Num, Trees_Sales

Trees_History=""
Recent_Trees=""
Last_Trees=""
Trees_Fields=""
Field_Trees=""
Trees_Num=""
Trees_Sales=""

Trees_Sales=lineitemarray(TΩ, ",")

///___Counts fields for the array, finds the non-zero ones, gives those counts and amounts
arrayfilter lineitemarray(TΩ,¶), Trees_History, ¶, str(Seq())+¬+import()
arrayfilter Trees_History,Recent_Trees, ¶, ?(val(import()[¬,-1][2,-1])>0, import(),"")
arraystrip Recent_Trees, ¶
////_____ex: 2      122.55________

///___get the fieldnames to reference that count to_________
arrayfilter dbinfo("fields", ""), Trees_Fields, ¶, ?(import() match "T??" and val(import()[2,-1])>0,import(),"")
arraystrip Trees_Fields, ¶

//______Attach that info together to let the user know the most recent order
Field_Trees=array(Trees_Fields,val(arrayfirst(Recent_Trees, ¶)[1, ¬][1,-2]), ¶)
Trees_Num=striptonum(Field_Trees)
Last_Trees=Field_Trees+¬+arrayfirst(Recent_Trees, ¶)[¬,-1][2,-1]

//_____Find Most Recent Branch Ordered From____
Field_Nums_Array=Seeds_Num+¬+Bulbs_Num+¬+Moose_Num+¬+Trees_Num+¬+OGS_Num
if val(Field_Nums_Array)>0
most_recent_year=arraylast(arraynumericsort(Field_Nums_Array, ¬),¬)
Branch_with_most_recent=
    ?(Field_Seeds contains str(most_recent_year), "Seeds: "+most_recent_year+" ","")+
    ?(Field_Bulbs contains str(most_recent_year), "Bulbs: "+most_recent_year+" ","")+
    ?(Field_Moose contains str(most_recent_year), "Moose: "+most_recent_year+" ","")+
    ?(Field_Trees contains str(most_recent_year), "Trees: "+most_recent_year+" ","")+
    ?(Field_OGS   contains str(most_recent_year), "OGS: "+most_recent_year+" ","")
else
    most_recent_year="0"
    Branch_with_most_recent="0"
    endif





///_____SetDictionaries for archive_____
    if val(striptonum(Seeds_Sales))>0
        setdictionaryvalue seed_dict, Last_Seeds, Seeds_Sales
        endif
    if val(striptonum(Trees_Sales))>0
        setdictionaryvalue trees_dict, Last_Trees, Trees_Sales
        endif
    if val(striptonum(Bulbs_Sales))>0
        setdictionaryvalue bulbs_dict, Last_Bulbs, Bulbs_Sales
        endif
    if val(striptonum(OGS_Sales))>0
        setdictionaryvalue old_ogs_dict, Last_OGS, OGS_Sales ///Reminder that the M## field carries up to date OGS info
        endif
    if val(striptonum(Moose_Sales))>0
        setdictionaryvalue new_ogs_dict, Last_Moose, Moose_Sales
    endif


//////displaydata seed_dict+¶+trees_dict+¶+bulbs_dict+¶+old_ogs_dict+¶+new_ogs_dict

FillHistories:

window Dedup_form

opensheet
«MostRecentEntered»=val(most_recent_year)
LastBulbs=val(Seeds_Num)
LastNewOGS=val(Moose_Num)
LastOldOGS=val(OGS_Num)
LastSeeds=val(Seeds_Num)
LastTrees=val(Trees_Num)
SeedsHistory=?(val(LastSeeds)>0, Seeds_Sales,default_seeds)
OGSHistory=?(val(LastOldOGS)>0, OGS_Sales,default_ogs)
TreesHistory= ?(val(LastTrees)>0, Trees_Sales,default_trees)
BulbsHistory= ?(val(LastBulbs)>0, Bulbs_Sales,default_bulbs)
MooseHistory=?(val(LastNewOGS)>0, Moose_Sales,default_moose)
HasConsent=?(has_consent≠1, 0, 1)


//____Clear all those variables used so that we don't copy all that again when skipping steps____//
Seeds_Sales=""
Seeds_History=""
Recent_Seeds=""
Last_Seeds=""
Seeds_Fields=""
Field_Seeds=""
Seeds_Num=""


Bulbs_History=""
Recent_Bulbs=""
Last_Bulbs=""
Bulbs_Fields=""
Field_Bulbs=""
Bulbs_Num=""
Bulbs_Sales=""

Moose_History=""
Recent_Moose=""
Last_Moose=""
Moose_Fields=""
Field_Moose=""
Moose_Num=""
Moose_Sales=""

OGS_History=""
Recent_OGS=""
Last_OGS=""
OGS_Fields=""
Field_OGS=""
OGS_Num=""
OGS_Sales=""

Trees_History=""
Recent_Trees=""
Last_Trees=""
Trees_Fields=""
Field_Trees=""
Trees_Num=""
Trees_Sales=""




showvariables Branch_with_most_recent

selectwithin striptoalpha(exportline())≠""
if (not info("empty"))
removeunselected
endif
___ ENDPROCEDURE FindMostRecent ________________________________________________

___ PROCEDURE AddDate __________________________________________________________
InqCodeNum=?(val(striptonum(inqcode))<30, val(striptonum(inqcode)), val(striptonum(inqcode)[3,4]))
___ ENDPROCEDURE AddDate _______________________________________________________

___ PROCEDURE Search Address ___________________________________________________

___ ENDPROCEDURE Search Address ________________________________________________

___ PROCEDURE MergeToMostRecent ________________________________________________

___ ENDPROCEDURE MergeToMostRecent _____________________________________________

___ PROCEDURE (Common Functions) _______________________________________________

___ ENDPROCEDURE (Common Functions) ____________________________________________

___ PROCEDURE ExportMacros _____________________________________________________
local Dictionary1, ProcedureList
//this saves your procedures into a variable
exportallprocedures "", Dictionary1
clipboard()=Dictionary1

message "Macros for "+info("databasename")+" are saved to your clipboard!"
___ ENDPROCEDURE ExportMacros __________________________________________________

___ PROCEDURE ImportMacros _____________________________________________________
local Dictionary1,Dictionary2, ProcedureList
Dictionary1=""
Dictionary1=clipboard()
yesno "Press yes to import all macros from clipboard to: "+info("databasename")
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

___ PROCEDURE .TestMath ________________________________________________________
Global Return_To, New_Master_Record, New_Master_CNum, DedupWindow,
    Seeds_Merged, Seeds_Hist1, Seeds_Hist2, Seeds_Rec1, Seeds_Rec2, Seeds_Done


DedupWindow=info("databasename")
New_Master_Record=0
Return_To=0
Seeds_Merged=0
Seeds_Rec1=""
Seeds_Rec2=""
New_Master_CNum=0


Field Con
    loop
        ;if «»=""
            find IsDestinationRecord="Yes"
            copy
            lastrecord
            paste
        ;endif
        right
    until info("stopped") or info("fieldname")="EntrySequence"
    
    DEBUG


//_____Number all Records____
    field «CountSequence»
    lastrecord
    togglesummarylevel
    firstrecord
    sequence "1"
    lastrecord
    togglesummarylevel
    

//__get MergeNumber for CustomerHistory
lastrecord
if info("summary")>0
    New_Master_CNum=«C#»
    New_Master_Record=«CountSequence»
endif

///____Begin Cycle____
 global Seeds_Merged, Seeds_Hist1,
        Trees_Merged, Trees_Hist1,
        OGS_Merged, OGS_Hist1,
        Moose_Merged, Moose_Hist1,
        Bulbs_Merged, Bulbs_Hist1


//____Seeds Merge_____
    Seeds_Merged=""
    Seeds_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Seeds_Hist1=«SeedsHistory»
        arrayfilter Seeds_Hist1, Seeds_Merged, ",", val(import())+val(array(Seeds_Merged, seq(), ","))
        ////displaydata Seeds_Merged
    endif
    downrecord

    until info("summary")>0

    SeedsHistory=Seeds_Merged
___ ENDPROCEDURE .TestMath _____________________________________________________

___ PROCEDURE .MergeToHistory __________________________________________________
if info("windows") notcontains "customeractivity" and info("files") contains "customer_history"
    openform "customeractivity"
endif

Window "customer_history:customeractivity"



find «C#»=New_Master_Record

if (not info("found"))
    message "Procedure couldn't find C#: "+str(New_Master_Record)+". It will now stop. Notify Tech Team."
endif

///____Fill Sales History


//____Seeds_____
Global Seeds_Start, Seeds_Counter

Seeds_Start=""

arrayfilter dbinfo("fields", ""), Seeds_Fields, ¶, 
    ?(import() match "S??" and val(import()[3,-1])>0,import(),"") //__Change Letter for others__//
    arraystrip Seeds_Fields, ¶
    
    Seeds_Start=arrayfirst(Seeds_Fields,¶)
    
    gosheet
    field (Seeds_Start)

    if info("fieldname") contains Seeds_Start
        goto FillSeeds
    else
        message "Did not find proper field, procedure stopped"
    endif 

    debug
    FillSeeds:
    Seeds_Counter=1
    loop
        «»=val(array(Seeds_Merged,Seeds_Counter, ","))
        right
        Seeds_Counter=Seeds_Counter+1
    until info("fieldname") notmatch "S??"  //__Change Letter for others__//

///_____Trees______
Global Trees_Start, Trees_Counter

Trees_Start=""

arrayfilter dbinfo("fields", ""), Trees_Fields, ¶, 
    ?(import() match "T??" and val(import()[3,-1])>0,import(),"") //__Change Letter for others__//
    arraystrip Trees_Fields, ¶
    
    Trees_Start=arrayfirst(Trees_Fields,¶)
    
    gosheet
    field (Trees_Start)

    if info("fieldname") contains Trees_Start
        goto FillTrees
    else
        message "Did not find proper field, procedure stopped"
    endif 

    debug
    FillTrees:
    Trees_Counter=1
    loop
        «»=val(array(Trees_Merged,Trees_Counter, ","))
        right
        Trees_Counter=Trees_Counter+1
    until info("fieldname") notmatch "T??" //__Change Letter for others__//

    ///_____Historical OGS______
Global OGS_Start, OGS_Counter

OGS_Start=""

arrayfilter dbinfo("fields", ""), OGS_Fields, ¶, 
    ?(import() match "OGS??" and val(import()[3,-1])>0,import(),"") //__Change Letter for others__//
    arraystrip OGS_Fields, ¶
    
    OGS_Start=arrayfirst(OGS_Fields,¶)
    
    gosheet
    field (OGS_Start)

    if info("fieldname") contains OGS_Start
        goto FillOGS
    else
        message "Did not find proper field, procedure stopped"
    endif 

    debug
    FillOGS:
    OGS_Counter=1
    loop
        «»=val(array(OGS_Merged,OGS_Counter, ","))
        right
        OGS_Counter=OGS_Counter+1
    until info("fieldname") notmatch "OGS??" //__Change Letter for others__//

        ///_____Current OGS i.e. Moose______
Global Moose_Start, Moose_Counter

Moose_Start=""

arrayfilter dbinfo("fields", ""), Moose_Fields, ¶, 
    ?(import() match "M??" and import() notcontains "MAd" and val(import()[3,-1])>0,import(),"") //__Change Letter for others__//
    arraystrip Moose_Fields, ¶
    
    Moose_Start=arrayfirst(Moose_Fields,¶)
    
    gosheet
    field (Moose_Start)

    if info("fieldname") contains Moose_Start
        goto FillMoose
    else
        message "Did not find proper field, procedure stopped"
    endif 

    debug
    FillMoose:
    Moose_Counter=1
    loop
        «»=val(array(Moose_Merged,Moose_Counter, ","))
        right
        Moose_Counter=Moose_Counter+1
    until info("fieldname") notmatch "M??" and info("fieldname") notcontains "MAd" //__Change Letter for others__//

            ///_____Current OGS i.e. Moose______
Global Bulbs_Start, Bulbs_Counter

Bulbs_Start=""

arrayfilter dbinfo("fields", ""), Bulbs_Fields, ¶, 
    ?(import() match "Bf??" and val(import()[3,-1])>0,import(),"") //__Change Letter for others__//
    arraystrip Bulbs_Fields, ¶
    
    Bulbs_Start=arrayfirst(Bulbs_Fields,¶)
    
    gosheet
    field (Bulbs_Start)

    if info("fieldname") contains Bulbs_Start
        goto FillBulbs
    else
        message "Did not find proper field, procedure stopped"
    endif 

    debug
    FillBulbs:
    Bulbs_Counter=1
    loop
        «»=val(array(Bulbs_Merged,Bulbs_Counter, ","))
        right
        Bulbs_Counter=Bulbs_Counter+1
    until info("fieldname") notmatch "Bf??" //__Change Letter for others__//


    ///___Update the screen___    
        
        Window "customer_history:customeractivity"
    drawobjects
___ ENDPROCEDURE .MergeToHistory _______________________________________________

___ PROCEDURE ClearRecords/5 ___________________________________________________
yesno "Ready to clear records in the Deduplicator?"

//___add a check to see if they've been merged and a yes
//no to continue

deleteall

call .BuildChoiceList

window back_to_ML


___ ENDPROCEDURE ClearRecords/5 ________________________________________________

___ PROCEDURE MergeMasterRecord ________________________________________________
fileglobal lowest_C, merge_to_this, merge_sequence_num

merge_sequence_num=0
merge_to_this=""

//grabs currently selected record as the master record
merge_sequence_num=CountSequence
merge_to_this=exportline()

//__finds the last line where we've already gottent he lowest C# or given them one if there wasn't one
selectall
field «C#»
lastrecord
if info("summary")>0
lowest_C=«»
else
message "No summary with customer number found. Procedure will stop:"
stop
endif

call .LineItemMerge,"user"
___ ENDPROCEDURE MergeMasterRecord _____________________________________________

___ PROCEDURE .MergeHistory ____________________________________________________
///____Begin Cycle____
 global Seeds_Merged, Seeds_Hist1,
        Trees_Merged, Trees_Hist1,
        OGS_Merged, OGS_Hist1,
        Moose_Merged, Moose_Hist1,
        Bulbs_Merged, Bulbs_Hist1


//____Seeds Merge_____
    Seeds_Merged=""
    Seeds_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Seeds_Hist1=«SeedsHistory»
        arrayfilter Seeds_Hist1, Seeds_Merged, ",", val(import())+val(array(Seeds_Merged, seq(), ","))
        ////displaydata Seeds_Merged
    endif
    downrecord

    until info("summary")>0

    SeedsHistory=Seeds_Merged

//____Trees Merge_____
    Trees_Merged=""
    Trees_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Trees_Hist1=«TreesHistory»
        arrayfilter Trees_Hist1, Trees_Merged, ",", val(import())+val(array(Trees_Merged, seq(), ","))
        ////displaydata Trees_Merged
    endif
    downrecord

    until info("summary")>0

    TreesHistory=Trees_Merged

//____Bulbs Merge_____
    Bulbs_Merged=""
    Bulbs_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Bulbs_Hist1=«BulbsHistory»
        arrayfilter Bulbs_Hist1, Bulbs_Merged, ",", val(import())+val(array(Bulbs_Merged, seq(), ","))
        ////displaydata Bulbs_Merged
    endif
    downrecord

    until info("summary")>0

    BulbsHistory=Bulbs_Merged

//____OGS Merge_____
    OGS_Merged=""
    OGS_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        OGS_Hist1=«OGSHistory»
        arrayfilter OGS_Hist1, OGS_Merged, ",", val(import())+val(array(OGS_Merged, seq(), ","))
        ////displaydata OGS_Merged
    endif
    downrecord

    until info("summary")>0

    OGSHistory=OGS_Merged

//____Moose Merge_____
    Moose_Merged=""
    Moose_Hist1=""

    firstrecord 

    loop
    if info("summary")<1
        Moose_Hist1=«MooseHistory»
        arrayfilter Moose_Hist1, Moose_Merged, ",", val(import())+val(array(Moose_Merged, seq(), ","))
        ////displaydata Moose_Merged
    endif
    downrecord

    until info("summary")>0

    MooseHistory=Moose_Merged
___ ENDPROCEDURE .MergeHistory _________________________________________________

___ PROCEDURE .CodeTest ________________________________________________________
MergeRecordsTree:

select IsAMergeRecord contains "Yes" OR IsDestinationRecord contains "Yes"

case info("selected")=2
//merge summary history with the single selected non-summary record
goto MoveToSingle

case info("selected")=3
//merge with group and non group as two records
yesno "Are you merging these as two separate accounts? One personal, and one group?"
//check if one is a member? 

case info("selected")=1
//summary is the merge record
endcase


MoveToSingle:

    global move_history_up
    move_history_up=""

    field SeedsHistory

    loop
    find IsAMergeRecord="Yes"
    move_history_up=«»
    find IsDestinationRecord="Yes"
    «»=move_history_up
    right
    until info("fieldname") = "CountSequence"

    find IsAMergeRecord="Yes"
    «Code»=lowest_code

    «OldCNums»=«C#»

    «C#»=lowest_Cust_Num

if info("selected")=2
    lastrecord
    deleterecord
    firstrecord
    togglesummarylevel
else
    nop
endif 

___ ENDPROCEDURE .CodeTest _____________________________________________________

___ PROCEDURE .MergeSummaryTo __________________________________________________
find IsAMergeRecord="Yes" 
if info("summary")<1
    message "Error, this should only merge from a summary record, does a non-summary record say 'Yes' on field IsAMergeRecord?"
    stop
endif

global move_history_up

field SeedsHistory

loop
move_history_up=«»
firstrecord
«»=move_history_up
right
lastrecord
until info("fieldname") = "CountSequence"
___ ENDPROCEDURE .MergeSummaryTo _______________________________________________

___ PROCEDURE GroupAndIndividual/3 _____________________________________________
message "If wish to have two records. One personal, and one business--Select the personal record, Then press CMD+7. Otherwise, merge to one record with CMD+4."
___ ENDPROCEDURE GroupAndIndividual/3 __________________________________________

___ PROCEDURE IndividualRecord/7 _______________________________________________
fileglobal individual_note, business_note

individual_note=""
business_note=""

IsDestinationRecord="Yes"

MergeAsTwoRecords="Individual"

individual_note="Has a business mailing list entry under: "
business_note="Has a personal mailing list entry under: "+str(«C#»)+" "+Con

message "Select the Business Account and press CMD+8"


___ ENDPROCEDURE IndividualRecord/7 ____________________________________________

___ PROCEDURE BusinessRecord/8 _________________________________________________
IsDestinationRecord="Yes"

MergeAsTwoRecords="Individual"

notes_to_append=notes_to_append

«Notes»=?(Notes="", business_note,Notes+","+business_note)

individual_note=individual_note+str(«C#»)+" "+Con+" "+«Group»

find MergeAsTwoRecords="Individual"
if info("found")
«Notes»=?(Notes="", individual_note,Notes+","+individual_note)
endif

___ ENDPROCEDURE BusinessRecord/8 ______________________________________________

___ PROCEDURE .MergeSingle _____________________________________________________
find IsDestinationRecord="Yes"
if (not info("found"))
    message "No Record is labed as destination record. Procedure will stop."
    stop
endif

global check_dest_num
check_dest_num=""
arraybuild check_dest_num, ¶,"", IsDestinationRecord
;displaydata check_dest_num
check_dest_num=arraystrip(check_dest_num, ¶)
;displaydata check_dest_num
if arraysize(check_dest_num, ¶)>1
goto MultiMerge
endif


Field Con
    loop
        ;if «»=""
            find IsDestinationRecord="Yes"
            copy
            lastrecord
            paste
        ;endif
        right
    until info("stopped") or info("fieldname")="EntrySequence"
    goto Skip
   
   
   MultiMerge:
   message "You are not supposed to use this function for merging two destination records. Procedure will stop."
   
   Skip:
___ ENDPROCEDURE .MergeSingle __________________________________________________
