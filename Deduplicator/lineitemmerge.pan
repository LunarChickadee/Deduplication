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
    until info("stopped") or info("fieldname")="Updated"


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