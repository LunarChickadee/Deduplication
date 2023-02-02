_________________________________________________
MergeSingle

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
until info("stopped")
goto MergeCustomerHistory

MultiMerge:
message "You are not supposed to use this function for merging two destination records. Procedure will stop."
stop

MergeCustomerHistory:
call .ArchiveOldInfo  //__________THIS WAS MOVED TO GET THE PROPER DATA IN THE 2ND ADDRESS FIELD AND ARCHIVE DATA BEFORE DOING ANYTHING ELSE

call .MergeCustHist
    _________________________________________________
    call .LineItemMerge
        __________________________________________
        moves all the totals for the order years
        _________________________________________

//__Do any records have history?
Global records_with_history
select info("summary")<1
    arrayselectedbuild records_with_history, ¶,"", «HasHistory»
if records_with_history notcontains "Yes"
    goto SkipHistory
endif

    call .MergeSingleToHistory
 
    SkipHistory:

    call .BuildFieldArray
        
    ___ ENDPROCEDURE .MergeCustHis

    ____________________________________________



field «C#»

lastrecord
