MergeRecordsTree:

select IsAMergeRecord contains "Yes" OR IsDestinationRecord contains "Yes"

case info("selected")=2
    //merge summary history with the single selected non-summary record

case info("selected")=3
    //merge with group and non group as two records
    yesno "Are you merging these as two separate accounts? One personal, and one group?"
    //check if one is a member? 

case info("selected")=1
    //summary is the merge record
endcase

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
