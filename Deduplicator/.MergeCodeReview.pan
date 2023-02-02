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
    ______________________________
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
                    ___________________________________________
                                            ___ PROCEDURE .MergeMasterRecord _______________________________________________



                            if info("windows") notcontains "customeractivity" and info("files") contains "customer_history"
                                openform "customeractivity"
                            else 
                                openfile "customer_history"
                                openform "customeractivity"
                            endif

                            Window "customer_history:customeractivity"
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
                                    
                                    Window "customer_history:customeractivity"
                                drawobjects
                                




                        ___ ENDPROCEDURE .MergeMasterRecord ____________________________________________
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
            arraystrip delete_MLs_noNum
            
            if delete_these_histories≠""
                deletion_counter=1

                window "customer_history"

                loop
                select «C#»=val(array(delete_these_histories,deletion_counter,¶))
                if not(info("empty"))
                    deleterecord
                    nop
                endif
                deletion_counter=deletion_counter+1
                until deletion_counter=arraysize(delete_these_histories)+1
            endif

        if delete_these_MLs≠""
                deletion_counter=1

                window mailing_list_window

                loop
                select «C#»=val(array(delete_these_MLs,deletion_counter,¶))
                if not(info("empty"))
                    deleterecord
                    nop
                endif
                deletion_counter=deletion_counter+1
                until deletion_counter=arraysize(delete_these_MLs)+1
            endif

        if delete_MLs_noNum""
                deletion_counter=1

                window mailing_list_window

                loop
                select exportline() contains array(delete_MLs_noNum,deletion_counter,¶) and val(«C#»)=0
                if not(info("empty"))
                    deleterecord
                    nop
                endif
                deletion_counter=deletion_counter+1
                until deletion_counter=arraysize(delete_MLs_noNum)+1
        endif

        selectall


        __________________________________________
    SkipHistory:

    call .BuildFieldArray
        __________________________________________
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
                case info("datatype") = 5 OR info("datatype") = 6
                    «»=val(to_merge)
                defaultcase
                «»=to_merge
                endcase
                        to_merge=""
                
                        
                merge_counter=merge_counter+1
            until merge_counter=arraysize(ML_merge_list,",")+1

            //___skip history fill in if it doesn't have one to update__
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


            EndOfMerge:

            window "DeDuplicator"


            message "Merged and archived! Use CMD-5 to clear these records from Deduplicator and start again!"







    ___ ENDPROCEDURE .MergeCustHis

    ____________________________________________



field «C#»

lastrecord
