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

//____Change history only if it has history, otherwise, if another record does have history
///____lets use that instead for our new "lowest" CNumber
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
    else 
        delete_MLs_noNum=Con+¬+Group+¬+MAd+¶+delete_MLs_noNum
    endif
    downrecord
    until info("stopped")

    arraystrip delete_these_histories,¶
    arraystrip delete_these_MLs,¶
    arraystrip delete_MLs_noNum,¶
    
    if delete_these_histories≠""
        deletion_counter=1

        window "customer_history"

        loop
        select «C#»=val(array(delete_these_histories,deletion_counter,¶))
        if (not info("empty"))
            deleterecord
            nop
        endif
        deletion_counter=deletion_counter+1
        until deletion_counter=arraysize(delete_these_histories,¶)+1
    endif

if delete_these_MLs≠""
        deletion_counter=1

        window mailing_list_window

        loop
        select «C#»=val(array(delete_these_MLs,deletion_counter,¶))
        if (not info("empty"))
            deleterecord
            nop
        endif
        deletion_counter=deletion_counter+1
        until deletion_counter=arraysize(delete_these_MLs,¶)+1
    endif

if delete_MLs_noNum""
        deletion_counter=1

        window mailing_list_window

        loop
        select exportline() contains array(delete_MLs_noNum,deletion_counter,¶) and val(«C#»)=0
        if (not info("empty"))
            deleterecord
            nop
        endif
        deletion_counter=deletion_counter+1
        until deletion_counter=arraysize(delete_MLs_noNum,¶)+1
endif

selectall