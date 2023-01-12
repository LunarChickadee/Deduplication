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
selectall

;debug
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

    

    ;displaydata "All Fields that were identical or had holes in the data have been added to a new merge Record (summary record)."+¶+¶+"You may manually choose which parts to move and/or use:"+¶+¶+"CMD+2 to Choose the topmost record as the new 'master record' it will inherit the oldest C# and codes"+¶+"or"+¶+"us CMD+3 or click a selection in the ChooseDesination Form to merge to that selected record."

call .BuildChoiceList   

selectall

field «C#»

/*
    //__make it it's own record
    lastrecord
    togglesummarylevel
*/







