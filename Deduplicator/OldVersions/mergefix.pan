fileglobal check_history
check_history=""

select info("summary")<1 AND «C#»=New_Master_Record
check_history=HasHistory

selectall

find «IsAMergeRecord»="Yes"

if info("summary")<1
    message "This is not supposed to run on non-summary merge records. Procdedure will stop."
endif

New_Master_Record=«C#»

//____Change history only if it has history, else just look for it in the Mailing List
//____because it has to be there, since that's where this file got it from
if check_history="Yes"

    if info("windows") notcontains "customeractivity" and info("files") contains "customer_history"
        openform "customeractivity"
    else 
        openfile "customer_history"
        openform "customeractivity"
    endif

    Window "customer_history:customeractivity"



    find «C#»=val(New_Master_Record)

    if (not info("found"))
        message "Procedure couldn't find C#: "+str(New_Master_Record)+". It will now stop. Notify Tech Team."
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

    debug

    arrayfilter dbinfo("fields", ""), OGS_Fields, ¶, 
        ?(import() match "OGS??" and val(import()[2,-1])>0,import(),"") //__Change Letter for others__//
        arraystrip OGS_Fields, ¶
        
        OGS_Start=arrayfirst(OGS_Fields,¶)
        
        displaydata OGS_Start
        
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
        
endif
 
 window dedup_window