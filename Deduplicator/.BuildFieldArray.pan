global CH_merge_list, ML_merge_list, on_both, merge_counter,
length_count, to_merge

to_merge=""
CH_merge_list=""
ML_merge_list=""
on_both=""
merge_counter=0
length_count=0

CH_merge_list="2ndAdd,C#,CChistory,City,Con,Consent,Dup?,Email,EntrySequence,Equity,Facil1,Facil2,Group,MAd,Modified,NewMember,Notes,Notified,OldMember,ProbCust,SpareNumb1,SpareNumb2,SpareText2,SpareText4,SpareText5,St,taxname,TIN,Updated,Zip"

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
