___ PROCEDURE .Initialize ______________________________________________________
global dedup_window, dedup_form_window, count_runs, lowest_code

Global Deduplicate_Selected_Array, Update_Weight, Last_Order_Weight, Was_Online, Total_Weight,
    highest_inq_code, highest_year, fivecount, recent_inq, has_redflag, newest_inq, newest_inq_onl, has_sales,
    entered_recently, recently_updated_ML, has_taxname, has_consent, hits_multiple

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

selectall

openfile "DedupArchive"

window dedup_window

call "ToDo"
___ ENDPROCEDURE .Initialize ___________________________________________________

___ PROCEDURE AutoSort/1 _______________________________________________________
/*
This Procedure will put the record it guesses 
to have the most recent information as the first record, 
then gives you options for merging records. 
(Note: It may also put an older record higher 
if certain conditions are met)

*/
        
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
        selectall
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
        select info("summary")<1
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
;  debug
field ConsentWeight
    formulafill «»*has_consent

    
field OnlineWeight
    formulafill Online*5

///____Do multiplication
field HowLikelyWeight
formulafill ConsentWeight+EnteredWeight+«UpdateWeight»+InqWeight

;debug ///_______________________
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

call .BuildChoiceList
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
    
;////;displaydata score_range

removeallsummaries

selectwithin score_range contains str(HowLikelyWeight)
if (not info("empty"))
    bigmessage "Scores are really close on this one. Please double check before merging."
    goto CheckGroup
endif

selectwithin str(HowLikelyWeight) contains str(max_score)

if (not info("empty"))
    case info("selected")>1
    message "Scores are really close on this one. Please double check before merging."
    endcase
endif

select Flagged≠""
    if (not info("empty"))
        message "one of these records has a redflag and these should be audited by the user."
    endif


CheckGroup:
select info("summary")<1
global group_history,personal_history

group_history=0
personal_history=0
firstrecord

loop

if «Group»≠"" and HasHistory contains "Y"
    group_history=-1
endif
if «Group»="" and HasHistory contains "Y"
personal_history=-1
endif
downrecord
until info("stopped")

selectall

;debug
Field «Group»
    emptyfill "No Group"
    arraybuild compare_records, ¶, "", «»
    arraydeduplicate compare_records, compare_records_again, ¶
    if arraycontains(compare_records,"No Group",¶)=-1 and linecount(compare_records_again)>1 and group_history=-1 and personal_history=-1
        bigmessage "One of these Records Might be for a separate 'Group' or Business account. If so, use CMD+3 and follow the prompts. Otherwise, choose your destination record with CMD+4"
    endif
    
    select «Group» contains "No Group"
        Formulafill ""
    selectall

CreateMergeRecord:
    //__get lowest C# and Code (first order) __//
    field «C#»
    minimum
     RepeatCnumCheck:
    case val(«C#»)=0
            SortUp
            firstrecord
                loop
                    downrecord
                until val(«C#»)>0
                goto RepeatCnumCheck
    defaultcase
    lowest_Cust_Num=«»
        lastrecord
        «»=lowest_Cust_Num
    endcase
   

lowest_code=""
    field Code
    minimum
    lowest_code=«»



    //___flag as a merge record___//
    IsAMergeRecord="Yes"

    //__Fill all info that's identical to the merge record___//
    
    field «Con»
    
    ///____Mailing List info Loop
    loop
    compare_field=info("fieldname")
    arraybuild compare_records, ¶, "", «»
    arraydeduplicate compare_records, compare_records, ¶
    
    if (info("fieldname")≠"Group" AND info("fieldname")≠"RedFlag") AND linecount(compare_records)=1
    «»=compare_records
    endif
    right
    until info("fieldname")="EntrySequence"

compare_field=""
compare_records=""

    field «Group»
    firstrecord

    loop
    compare_records=«»+¶+compare_records
    downrecord
    until info("stopped") or info("summary")>0

    arraystrip compare_records, ¶
    if linecount(compare_records)>1
        arraydeduplicate compare_records, compare_records, ¶
            if linecount(compare_records)=1
                find info("summary")=1
                    «»=compare_records
            endif
    endif

 //__Fill all info that's identical to the merge record, but for Customer_history info___//
    
    field «CHNotes»
    
    ///____Mailing List info Loop
    loop
    compare_field=info("fieldname")
    arraybuild compare_records, ¶, "", «»
    arraydeduplicate compare_records, compare_records, ¶
    
    if info("fieldname")≠"Equity" AND linecount(compare_records)=1
    «»=compare_records
    endif

    if info("fieldname")="Equity"
    arraybuild compare_records, ¶, "", «»
    arraynumerictotal compare_records, ¶,compare_records
    «»=str(compare_records)
    endif 

    right
    until info("stopped")

call .BuildChoiceList   

selectall

field «C#»

___ ENDPROCEDURE .Maximum ______________________________________________________

___ PROCEDURE .BuildChoiceList _________________________________________________

//__differenciates between whether this was from a button press or from another call__//
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
select info("summary")<1

global list_of_records, record_count
record_count=""
record_count=info("selected")


//____Makes a readable, stackable display for the user on the ChooseDestination form_____//
arrayselectedbuild list_of_records, ¶,"","Score: "+str(HowLikelyWeight)+?(info("summary")>0, ¶+"This is the current merge record:"+¶,"")+¶
+?(Flagged≠"", "RedFlagged!!!! Check Closely"+¶,"")+¶
+arrayrange(exportline(),1, 2,¬)+¶
+?(«Group»="","No Group",«Group»)+¶
+arrayrange(exportline(),4, 7,¬)+¶
+arrayrange(exportline(),15, 16,¬)+¶
+"Member: "+?(«Mem?»≠"",«Mem?»,"no")+"   Inquiry: "+?(«inqcode»≠"",inqcode,"none")+"   First order: "+«Code»+¶
+¶
+?(«Notes»≠"","Mailing List Notes: --- "+«Notes»+" --- "+¶,"")
+?(«RedFlag»≠"","RedFlag(s): --- "+«RedFlag»+" --- "+¶,"")
+"Last Entered Sale: "+str(«MostRecentEntered»)+¶
+"Seeds:"+str(LastSeeds)+¬+" Trees:"+str(LastTrees)+" OGS:"+str(LastNewOGS)+" Bulbs:"+str(LastBulbs)+¶
+?(Consent≠"", "Consent: "+str(Consent)+" TaxName: "+taxname+¶,"")
+?(Flagged≠"", "Flagged: --- "+str(Flagged)+" --- "+¶,"")
+?(CHNotes≠"","customer_history Notes: --- "+str(CHNotes)+" --- "+¶,"")
+"Taxexempt: "+?(TaxEx≠"", str(TaxEx)+" Resale: "+¶,"No"+¶)
+"______________________________~"

//____adds a record count to the above list____
arrayfilter list_of_records, list_of_records, "~",
    ?(seq()=1,"Record "+str(seq())+":     "+¶+import(),
    ?(seq()≤info("selected"),¶+"Record "+str(seq())+":     "+import(),
    ""))


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
___ ENDPROCEDURE .BuildChoiceList ______________________________________________

___ PROCEDURE AutoMerge/2 ______________________________________________________
///___Make sure user is doing things in the correct order, or else it'll break___///
selectall
lastrecord
if info("summary")<1
message "This can't be run until after CMD+1 has been run"
stop
endif

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
//loop 


call .MergeSingle
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
        arrayfilter Seeds_Hist1, Seeds_Merged, ",", 
            pattern(val(import())+val(array(Seeds_Merged, seq(), ",")),"#.##")
        ////;displaydata Seeds_Merged
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
        arrayfilter Trees_Hist1, Trees_Merged, ",", 
            pattern(val(import())+val(array(Trees_Merged, seq(), ",")),"#.##")
        ////;displaydata Trees_Merged
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
        arrayfilter Bulbs_Hist1, Bulbs_Merged, ",", 
            pattern(val(import())+val(array(Bulbs_Merged, seq(), ",")),"#.##")
        ////;displaydata Bulbs_Merged
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
        arrayfilter OGS_Hist1, OGS_Merged, ",", 
            pattern(val(import())+val(array(OGS_Merged, seq(), ",")),"#.##")
        ////;displaydata OGS_Merged
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
        arrayfilter Moose_Hist1, Moose_Merged, ",", 
            pattern(val(import())+val(array(Moose_Merged, seq(), ",")),"#.##")
        ////;displaydata Moose_Merged
    endif
    downrecord

    until info("summary")>0

    MooseHistory=Moose_Merged

//____commented out due to testing____
;call .MergeToHistory
___ ENDPROCEDURE .LineItemMerge ________________________________________________

___ PROCEDURE ChooseMergeRecord/4 ______________________________________________
///___Make sure user is doing things in the correct order, or else it'll break___///
selectall
lastrecord
if info("summary")<1
message "This can't be run until after CMD+1 has been run"
stop
endif

yesno "Choose as Master Record?: "+arrayrange(exportline(),1, 7,¬)+¶+arrayrange(exportline(),15, 20,¬)

if clipboard()="Yes"
IsDestinationRecord="Yes"

else
stop
endif

call .MergeSingle

___ ENDPROCEDURE ChooseMergeRecord/4 ___________________________________________

___ PROCEDURE .UserChoice ______________________________________________________
///___Make sure user is doing things in the correct order, or else it'll break___///
selectall
lastrecord
if info("summary")<1
message "This can't be run until after CMD+1 has been run"
stop
endif

global matrix_row_chosen

matrix_row_chosen=arrayrange(array(list_of_records,info("matrixrow"),"~"), 2, 3,¶)

find CountSequence=info("matrixrow")

yesno "Choose: "+arrayrange(exportline(),1, 7,¬)+¶+arrayrange(exportline(),15, 20,¬)+"  to be the destination record?"

if clipboard()="Yes"
    find CountSequence=info("matrixrow")
        //___this checks to make sure the data is where it expects to be___//
        if (not info("found"))
            message "Could not find record, sorry!"
         endif
    field IsDestinationRecord
        formulafill ""
    IsDestinationRecord="Yes"
endif

if clipboard()="No"
    message "OK. Procedure will stop."
    stop
endif


call .MergeSingle
___ ENDPROCEDURE .UserChoice ___________________________________________________

___ PROCEDURE FindMostRecent ___________________________________________________
//___this is a lot of code to do somethign that feels simple___//
global Dedup_form, Branch_with_most_recent, Field_Nums_Array, most_recent_year,reference_num,
    has_consent,
    seed_dict, new_ogs_dict, old_ogs_dict, bulbs_dict, trees_dict, default_seeds, default_trees, 
    default_ogs, default_moose, default_bulbs, any_cust_window,
    Seeds_History, Recent_Seeds, Last_Seeds, Seeds_Fields,Field_Seeds, Seeds_Num, Seeds_Sales,
    Bulbs_History, Recent_Bulbs, Last_Bulbs, Bulbs_Fields,Field_Bulbs, Bulbs_Num, Bulbs_Sales,
    Moose_History, Recent_Moose, Last_Moose, Moose_Fields,Field_Moose, Moose_Num, Moose_Sales,
    Trees_History, Recent_Trees, Last_Trees, Trees_Fields,Field_Trees, Trees_Num, Trees_Sales,
    OGS_History, Recent_OGS, Last_OGS, OGS_Fields,Field_OGS, OGS_Num, OGS_Sales

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

Trees_History=""
Recent_Trees=""
Last_Trees=""
Trees_Fields=""
Field_Trees=""
Trees_Num=""
Trees_Sales=""


OGS_History=""
Recent_OGS=""
Last_OGS=""
OGS_Fields=""
Field_OGS=""
OGS_Num=""
OGS_Sales=""

Branch_with_most_recent=""
has_consent=0

Dedup_form=info("windowname")

seed_dict=""
new_ogs_dict=""
old_ogs_dict=""
bulbs_dict=""
trees_dict=""

reference_num=val(«C#»)

openfile "customer_history"

opensheet

//___This creates a blank array of commas to make adding things up easier for records that have zero sales
default_seeds=rep(chr(44), arraysize(lineitemarray(SΩ, ","),",")-1)
default_trees=rep(chr(44), arraysize(lineitemarray(TΩ, ","),",")-1)
default_ogs=rep(chr(44), arraysize(lineitemarray(OGSΩ, ","),",")-1)
default_moose=rep(chr(44), arraysize(lineitemarray(MΩ, ","),",")-1)
default_bulbs=rep(chr(44), arraysize(lineitemarray(BfΩ, ","),",")-1)

///____If we don't have a matching customer_history Record, set everything to zero____//
//____They got a number? And we find it, skip past the cases__//
//___They don't got a number, set everything to zero_____//
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
                HasHistory="No"
                goto FillHistories
        else
            window Dedup_form
            HasHistory="Yes"
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
            HasHistory="No"
            goto FillHistories
endcase

call .ExtraFieldsCH

window "customer_history"



//____Find out if they've done a consent form_____///
if Consent contains "y"
    has_consent=1
else 
    has_consent=0
endif


///Find Seed info

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

window Dedup_form
call .memcheck
window "customer_history"



////_____Note, i think i shifted from dictionaries to straight records due to difficulty with summing dictionaries__//
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


//////;displaydata seed_dict+¶+trees_dict+¶+bulbs_dict+¶+old_ogs_dict+¶+new_ogs_dict

FillHistories:

window Dedup_form

opensheet
«Flagged»=?(RedFlag≠"","User Audit Needed: "+RedFlag,"")
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


showvariables Branch_with_most_recent


//___gets rid of the blank records you always have from emptying files___//
selectwithin striptoalpha(exportline())≠""
    if (not info("empty"))
        removeunselected
    endif

Field «C#»
___ ENDPROCEDURE FindMostRecent ________________________________________________

___ PROCEDURE .ArchiveOldInfo __________________________________________________
if info("windows") notcontains "DedupArchive"
    message "Please Open the DedupArchive File when doing deduplications. Procedure will stop. "
    stop
endif


fileglobal address_main, old_addresses_array, c_num_main, old_cnum_array

address_main=""
old_addresses_array=""
c_num_main=""
old_cnum_array=""

lastrecord

c_num_main=str(«C#»)
address_main=MAd+¬+St+¬+str(pattern(val(Zip),"#####"))

firstrecord
select info("summary")<1

loop 
    if MAd+¬+St+¬+str(pattern(val(Zip),"#####")) notcontains address_main
        old_addresses_array=MAd+¬+St+¬+str(pattern(val(Zip),"#####"))+¶+old_addresses_array
    endif
    if str(«C#») notcontains c_num_main
        old_cnum_array=str(«C#»)+¶+old_cnum_array
    endif
    if «IsDestinationRecord»≠"Yes"
        «MergedWith»=c_num_main
    endif
downrecord
until info("stopped")

selectall
lastrecord

old_addresses_array=arraystrip(old_addresses_array, ¶)
old_cnum_array=arraystrip(old_cnum_array, ¶)

;;displaydata old_addresses_array

OldAddresses=old_addresses_array
OldCNums=old_cnum_array

//___Put the old address in with the 2nd addresses in Customer History
if «2ndAdd» = "" 
    «2ndAdd»=«OldAddresses»
else
    «2ndAdd»=«2ndAdd»+¶+«OldAddresses»
endif


//___Put the old Cnums in with the CCHistory in Customer History
if «CChistory» = "" 
    «CChistory»=«OldCNums»
else
    «CChistory»=«CChistory»+¶+«OldCNums»
endif

field MergedOn
formulafill datepattern(today(), "mm/dd/yy")

firstrecord
select info("summary")<1
loop
openfile "Deduplicator"

if IsDestinationRecord≠"Yes" 
copyrecord

openfile "DedupArchive"
pasterecord
endif
openfile "Deduplicator"
downrecord
until info("stopped")

;message "Archived!"

selectall

___ ENDPROCEDURE .ArchiveOldInfo _______________________________________________

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

___ ENDPROCEDURE .TestMath _____________________________________________________

___ PROCEDURE .MergeSingleToHistory ____________________________________________
Global check_history
    check_history=""

    //__
    window dedup_window
    //__

    select info("summary")>0
    field «C#» 
    New_Master_Record=«C#» 
    

    select (info("summary")<1 AND «C#»=New_Master_Record)
    check_history=HasHistory

    selectall

debug 
//____Change history only if it has history, otherwise, if another record does have history
///____lets use that instead for our new "lowest" CNumber
lastrecord
    if check_history="Yes" 
        call .MergeMasterRecord
    else
        SortUp
        firstrecord
        downrecord
        
        FindNewNum:
           if val(«C#»)>0
                case HasHistory contains "Y"
                    New_Master_Record=«C#»
                    field IsDestinationRecord
                        formulafill ""
                        «»="Yes"
                defaultcase
                    downrecord
                    goto FindNewNum
                endcase ////finish cases so taht if it doesn't find one with history, this continues. and then merges to that record. 
            else 
                downrecord
                goto FindNewNum
            endif
        find info("summary")>0
        «C#»=New_Master_Record
        HasHistory="Yes"
    endif


    //__
    window dedup_window
    //__
   
debug

___ ENDPROCEDURE .MergeSingleToHistory _________________________________________

___ PROCEDURE ClearRecords/5 ___________________________________________________
yesno "Ready to clear records in the Deduplicator?"

if clipboard()≠"Yes"
stop
endif
//___add a check to see if they've been merged and a yes
//no to continue

deleteall

call .BuildChoiceList

window mailing_list_window

field «C#»
___ ENDPROCEDURE ClearRecords/5 ________________________________________________

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
        ////;displaydata Seeds_Merged
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
        ////;displaydata Trees_Merged
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
        ////;displaydata Bulbs_Merged
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
        ////;displaydata OGS_Merged
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
        ////;displaydata Moose_Merged
    endif
    downrecord

    until info("summary")>0

    MooseHistory=Moose_Merged
___ ENDPROCEDURE .MergeHistory _________________________________________________

___ PROCEDURE .CodeTest ________________________________________________________
global merge_field1, merge_info1, Dedup_fieldnames, CH_fieldnames

Dedup_fieldnames=""
CH_fieldnames=""
merge_field1=""

window "DeDuplicator"
Dedup_fieldnames=dbinfo("fields", "")

window "45 mailing list"
CH_fieldnames=dbinfo("fields", "")

arrayboth Dedup_fieldnames, CH_fieldnames, ¶, merge_field1

clipboard()=merge_field1

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
select info("summary")<1
    if info("selected")≠2
        message "Sorry, this can only be done with two records. Procedure will stop."
        stop
    endif

if personal_history≠-1 or group_history≠-1
bigmessage "Sorry, one of these records doesn't have customer history, please merge as one record as per usual"
stop
endif
    
Global matched_array

matched_array=""

///___Get Numbers for matched pair___//
field «C#»
firstrecord
matched_array=str(«C#»)
downrecord
matched_array=matched_array+"^"+str(«C#»)
;displaydata matched_array

window "customer_history"
find «C#» = val(array(matched_array,1,"^"))
«Dup?» = "Not a duplicate"+matched_array+" are a paired business and personal account"
find «C#» = val(array(matched_array,2,"^"))
«Dup?» = "Not a duplicate"+matched_array+" are a paired business and personal account"

window mailing_list_window
find «C#» = val(array(matched_array,1,"^"))
SpareText1="Not a duplicate"+matched_array+" are a paired business and personal account"
find «C#» = val(array(matched_array,2,"^"))
SpareText1="Not a duplicate"+matched_array+" are a paired business and personal account"

window "DeDuplicator"
message "These will now not show up the next time you run 'StartDeduplication'"


     
     

    
    
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

//__Count destination records____
global check_dest_num
check_dest_num=""
arraybuild check_dest_num, ¶,"", «IsDestinationRecord»

check_dest_num=arraystrip(check_dest_num, ¶)

    if arraysize(check_dest_num, ¶)>1
        goto MultiMerge
    endif


SingleMerge:
Field Con

//____Fills in all the summary records that are empty 
    //__val(«»)≠0 or str(«»)≠"" is the only thing I found to work consistently
loop
find «IsAMergeRecord» = "Yes"
    case val(«»)≠0 or str(«»)≠""
        right
    case info("fieldname") contains "IsDestinationRecord" or info("fieldname") contains "IsAMergeRecord"
        right
    defaultcase
        find IsDestinationRecord = "Yes"   
            copy
                lastrecord
                    paste
                        right
    endcase
until info("stopped") //OR info("fieldname")="TIN"
debug
goto MergeCustomerHistory
debug
MultiMerge:
message "You are not supposed to use this function for merging two destination records. Procedure will stop."
stop

MergeCustomerHistory:
debug
call .ArchiveOldInfo  //__________THIS WAS MOVED TO GET THE PROPER DATA IN THE 2ND ADDRESS FIELD AND ARCHIVE DATA BEFORE DOING ANYTHING ELSE
debug
call .MergeCustHist

field «C#»

lastrecord
___ ENDPROCEDURE .MergeSingle __________________________________________________

___ PROCEDURE .fineEdit ________________________________________________________
gosheet

find info("summary")>0

message "edit this summary record, then use CMD+4 to merge all other records to it."
___ ENDPROCEDURE .fineEdit _____________________________________________________

___ PROCEDURE .MergeMasterRecord _______________________________________________
if info("windows") notcontains "customer_history" and info("files") contains "customer_history"
    openfile "customer_history"
else 
    window "customer_history"
endif

Window "customer_history"
    noshow
    selectall


find «C#»=val(New_Master_Record)

if (not info("found"))
    message "Procedure couldn't find C#: "+str(New_Master_Record)+". It will now stop. Notify Tech Team."
    stop
endif

///____Fill Sales History


//____Seeds_____
Global Seeds_Start, Seeds_Counter, Seeds_Fields

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
Global Trees_Start, Trees_Counter, Trees_Fields

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
Global OGS_Start, OGS_Counter, OGS_Fields

OGS_Start=""

arrayfilter dbinfo("fields", ""), OGS_Fields, ¶, 
    ?(import() contains "OGS",import(),"") //__Change Letter for others__//
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
Global Moose_Start, Moose_Counter, Moose_Fields

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
Global Bulbs_Start, Bulbs_Counter, Bulbs_Fields

Bulbs_Start=""


//___add into this an or for match Bs due to two incorrect fields
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
    
    endnoshow
        
        Window "customer_history"
    ;drawobjects
    




___ ENDPROCEDURE .MergeMasterRecord ____________________________________________

___ PROCEDURE .ExtraFieldsCH ___________________________________________________
window "customer_history"

global c_h_extras, extras_data, extras_counter, fence_post1

c_h_extras=""
extras_data=""
extras_counter=1
fence_post1=0

c_h_extras="CHNotes
2ndAdd
CChistory
Consent
Dup?
Email
Equity
Facil1
Facil2
NewMember
Notified
OldMember
ProbCust
SpareText4
SpareText5
taxname
TIN"

fence_post1=arraysize(c_h_extras, ¶)


extras_data=«Notes»+","+«2ndAdd»+","+«CChistory»+","+«Consent»+","+«Dup?»+","+«Email»+","+
            str(«Equity»)+","+«Facil1»+","+«Facil2»+","+«NewMember»+","+«Notified»+","+
            «OldMember»+","+«ProbCust»+","+«SpareText4»+","+«SpareText5»+","+«taxname»+","+«TIN»



window "DeDuplicator"

loop
field (array(c_h_extras, extras_counter, ¶))
«»=array(extras_data, extras_counter, ",")
extras_counter=extras_counter+1
until info("fieldname")="TIN"


___ ENDPROCEDURE .ExtraFieldsCH ________________________________________________

___ PROCEDURE .MergeCustHist ___________________________________________________

selectall
call .LineItemMerge

//__Do any records have history?
Global records_with_history
select info("summary")<1
    arrayselectedbuild records_with_history, ¶,"", «HasHistory»
if records_with_history notcontains "Yes"
    goto SkipHistory
endif

call .MergeSingleToHistory



 SkipHistory:
 
 window "DeDuplicator"
selectall
lastrecord
    New_Master_Record=«C#» 
    
    ///___Get everyone to the right record___
    window "customer_history"
    find «C#»=val(New_Master_Record)
    window mailing_list_window
    find «C#»=val(New_Master_Record)
    window "DeDuplicator"
    
    call .BuildFieldArray
    
    call .DeletionLoop
    
    
 message "Merged and archived! Use CMD-5 to clear these records from Deduplicator and start again!"




___ ENDPROCEDURE .MergeCustHist ________________________________________________

___ PROCEDURE accents __________________________________________________________

___ ENDPROCEDURE accents _______________________________________________________

___ PROCEDURE ToDo _____________________________________________________________
displaydata "

Next up:

- Make the .BuildFieldArray do the entirety of the Mailing List Fields
    - add that functionality into .MergeSingle and/or .MergeMaster Record
        - within that, there's a check if it has customer history, if so, do the same run for customer_history
    -Triple check that all fields necessary to move forward correctly merge
- double check that the arrays that search for which records to delete work correctly
        -Test Run deleting all non-merge records
- Test the full Dedup and Celebrate
    

"
___ ENDPROCEDURE ToDo __________________________________________________________

___ PROCEDURE .memcheck ________________________________________________________
global verify_member
verify_member=0

if «Mem?» notcontains "Y"
    goto End1
else
    verify_member=val(«C#»)
    
    openfile "members"
    
        find val(«C#»)=verify_member
            case (not info("found"))
                goto Error1
            defaultcase
                goto End1
            endcase
endif

Error1:
    window "DeDuplicator"
    message "Membership is stated for this user, but not found under this C#, will be flagged as needing an audit."
                «Flagged»=«Flagged»+¶+"MemberShip not found in members file"
                arraydeduplicate «Flagged», «Flagged», ¶
                arraystrip «Flagged», ¶
                arraystrip «Mem?», "?"
                «Mem?»=«Mem?»+"?"

End1:

openfile "customer_history"
___ ENDPROCEDURE .memcheck _____________________________________________________

___ PROCEDURE .BuildFieldArray _________________________________________________
        global CH_merge_list, ML_merge_list, on_both, merge_counter,
            length_count, to_merge

            to_merge=""
            CH_merge_list=""
            ML_merge_list=""
            on_both=""
            merge_counter=0
            length_count=0

            CH_merge_list="2ndAdd,C#,CChistory,City,Con,Consent,Dup?,Email,EntrySequence,Equity,Group,MAd,Modified,NewMember,Notes,Notified,OldMember,SpareText2,SpareText5,St,taxname,TIN,Updated,Zip"

            ML_merge_list="adc,Bf,C#,CG,Cit,City,Code,Con,email,EntrySequence,Group,inqcode,M?,MAd,Mem?,Modified,Notes,Outstanding,phone,RedFlag,resale,S,SAd,SpareText2,SpareText3,St,Sta,T,TaxEx,Updated,UPS?,Z,Zip"

            on_both="C#,City,Con,EntrySequence,Group,MAd,Modified,St,Updated,Zip,SpareText2"

            /*
            Chnotes
            and Mlnotes have the same field name, differenciate them in the algo
            */

            //Move the common fields

            window "DeDuplicator"
            length_count=arraysize(ML_merge_list,",")
            merge_counter=1

            loop
                window "DeDuplicator"
                field (array(ML_merge_list,merge_counter,","))
                    to_merge=«»

                window mailing_list_window
                field (array(ML_merge_list,merge_counter,","))
                case info("datatype") = 5 OR info("datatype") = 6 OR info("datatype") = 8
                    «»=val(to_merge)
                defaultcase
                «»=to_merge
                endcase
                        to_merge=""
                
                        
                merge_counter=merge_counter+1
            until merge_counter=arraysize(ML_merge_list,",")+1

            //___skip history fill in if it doesn't have one to update__
            window "DeDuplicator"
            if «HasHistory» notcontains "Yes"
                goto EndOfMerge
            endif

            ///__Merge to Customer_History
            window "DeDuplicator"
            length_count=arraysize(CH_merge_list,",")
            merge_counter=1

            loop
                window "DeDuplicator"
                field (array(CH_merge_list,merge_counter,","))
                    to_merge=«»

                window "customer_history"
                field (array(CH_merge_list,merge_counter,","))
                case info("datatype") = 5 OR info("datatype") = 6
                    «»=val(to_merge)
                defaultcase
                «»=to_merge
                endcase
                        to_merge=""
                
                        
                merge_counter=merge_counter+1
            until merge_counter=arraysize(CH_merge_list,",")+1
            field «C#»


            EndOfMerge:

            window "DeDuplicator"


           
___ ENDPROCEDURE .BuildFieldArray ______________________________________________

___ PROCEDURE .DeletionLoop ____________________________________________________


//__
    window dedup_window
    //__

    ///___Make this below into it's own method?


    //___Find and delete all customer history and Mailing List entries that aren't the master record___//
        select (info("summary")<1 AND «C#»≠New_Master_Record)
    firstrecord

    global delete_these_histories, delete_these_MLs,delete_MLs_noNum, deletion_counter

    delete_these_histories=""
    delete_these_MLs=""
    delete_MLs_noNum=""
    deletion_counter=0



    loop 

    if HasHistory="Yes"
    delete_these_histories=str(«C#»)+¶+delete_these_histories
    endif 
    
    if val(«C#»)>0
        delete_these_MLs=str(«C#»)+¶+delete_these_MLs
    endif
    downrecord
    until info("stopped")

    arraystrip delete_these_histories,¶
    arraystrip delete_these_MLs,¶
    ;arraystrip delete_MLs_noNum,¶
    ;displaydata delete_these_histories
    ;displaydata delete_these_MLs
    
    if delete_these_histories≠""
        deletion_counter=1

        window "customer_history"

        loop
        find «C#»=val(array(delete_these_histories,deletion_counter,¶))
        if info("found")
            deleterecord
            nop
        endif
        deletion_counter=deletion_counter+1
        until deletion_counter=arraysize(delete_these_histories,¶)+1
    endif
debug
if delete_these_MLs≠""
        deletion_counter=1

        window mailing_list_window

        loop
        find «C#»=val(array(delete_these_MLs,deletion_counter,¶))
        if info("found")
            deleterecord
            nop
        endif
        deletion_counter=deletion_counter+1
        until deletion_counter=arraysize(delete_these_MLs,¶)+1
    endif
debug
///Replaced this with assigning "999999" to blank records, might break if there are more of them?
/*
if delete_MLs_noNum=""
        deletion_counter=1

        window mailing_list_window

        loop
        find exportline() contains array(delete_MLs_noNum,deletion_counter,¶) and val(«C#»)=0
        if info("found")
            clearrecord
        endif
        deletion_counter=deletion_counter+1
        until deletion_counter=arraysize(delete_MLs_noNum,¶)+1
endif
*/

window "DeDuplicator"
___ ENDPROCEDURE .DeletionLoop _________________________________________________
