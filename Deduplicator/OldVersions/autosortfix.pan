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

/*
if count_runs<2
displaydata "This Procedure will put the record it guesses to have the most recent information as the first record, then gives you options for merging records. (Note: It may also put an older record higher if the customer has given a legal address for patronage dividends)

The summary (purple/blue shaded) record it creates is meant to be used as the new 'merged' record. 

You can do this entire process from the data sheet, but, there is also a form called 'ChooseDestination' that will make records easier to read and pick out key info from included most recent sales entered and from what branch. 

All merged records that do not go back into the Mailing list or Customer history will go to a file called DedupArchive, which is a linked file

This message will come up the first time you run this procedure after closing the file, but shouldn't come up after using CMD-1 during this session."
endif 
*/


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
    


//fix this not resetting the numbers back if run again
    
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

