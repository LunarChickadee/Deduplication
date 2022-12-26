global inq_set,online_set, back_to_ML

back_to_ML=info("windowname")
copyrecord

window "DeDuplicator"

pasterecord

LastUpdateSortable=date(Updated[1,"@"][1,-2])
inq_set=?(val(striptonum(inqcode))<30, val(striptonum(inqcode)), val(striptonum(inqcode)[3,4]))
InqCodeNum=inq_set
online_set=val(?(inqcode contains "onl" or inqcode contains "webrequest", "1.2", "1"))
Online=online_set



_______________
call "FindMostRecent"

global Dedup_form, Branch_with_most_recent, Field_Nums_Array, most_recent_year,reference_num,
    seed_dict, new_ogs_dict, old_ogs_dict, bulbs_dict, trees_dict

Branch_with_most_recent=""

Dedup_form=info("windowname")

seed_dict=""
new_ogs_dict=""
old_ogs_dict=""
bulbs_dict=""
trees_dict=""

reference_num=val(«C#»)

window "customer_history"

///____If we don't have a matching customer_history Record, set everything to zero____//
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
        endif
defaultcase
    window Dedup_form
            LastBulbs=0
            LastNewOGS=0
            LastOldOGS=0
            LastSeeds=0
            LastTrees=0
            HasConsent=0
endcase


///Find Seed info
    global Seeds_History, Recent_Seeds, Last_Seeds, Seeds_Fields,Field_Seeds, Seeds_Num, Seeds_Sales

    Seeds_Sales=""
    Seeds_History=""
    Recent_Seeds=""
    Last_Seeds=""
    Seeds_Fields=""
    Field_Seeds=""
    Seeds_Num=""

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

    global Bulbs_History, Recent_Bulbs, Last_Bulbs, Bulbs_Fields,Field_Bulbs, Bulbs_Num, Bulbs_Sales

    Bulbs_History=""
    Recent_Bulbs=""
    Last_Bulbs=""
    Bulbs_Fields=""
    Field_Bulbs=""
    Bulbs_Num=""
    Bulbs_Sales=""

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

    global Moose_History, Recent_Moose, Last_Moose, Moose_Fields,Field_Moose, Moose_Num, Moose_Sales

    Moose_History=""
    Recent_Moose=""
    Last_Moose=""
    Moose_Fields=""
    Field_Moose=""
    Moose_Num=""
    Moose_Sales=""

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
    global OGS_History, Recent_OGS, Last_OGS, OGS_Fields,Field_OGS, OGS_Num, OGS_Sales

    OGS_History=""
    Recent_OGS=""
    Last_OGS=""
    OGS_Fields=""
    Field_OGS=""
    OGS_Num=""
    OGS_Sales=""

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
global Trees_History, Recent_Trees, Last_Trees, Trees_Fields,Field_Trees, Trees_Num, Trees_Sales

Trees_History=""
Recent_Trees=""
Last_Trees=""
Trees_Fields=""
Field_Trees=""
Trees_Num=""
Trees_Sales=""

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
most_recent_year=arraylast(arraynumericsort(Field_Nums_Array, ¬),¬)
Branch_with_most_recent=
    ?(Field_Seeds contains str(most_recent_year), "Seeds: "+most_recent_year+" ","")+
    ?(Field_Bulbs contains str(most_recent_year), "Bulbs: "+most_recent_year+" ","")+
    ?(Field_Moose contains str(most_recent_year), "Moose: "+most_recent_year+" ","")+
    ?(Field_Trees contains str(most_recent_year), "Trees: "+most_recent_year+" ","")+
    ?(Field_OGS   contains str(most_recent_year), "OGS: "+most_recent_year+" ","")

//____Find out if they've done a consent form_____///
if «Consent» contains "y"
    has_consent=1
endif



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


//////displaydata seed_dict+¶+trees_dict+¶+bulbs_dict+¶+old_ogs_dict+¶+new_ogs_dict

FillHistories:

window Dedup_form

opensheet
«MostRecentEntered»=val(most_recent_year)
LastBulbs=val(Seeds_Num)
LastNewOGS=val(Moose_Num)
LastOldOGS=val(OGS_Num)
LastSeeds=val(Seeds_Num)
LastTrees=val(Trees_Num)
SeedsHistory=?(val(LastSeeds)>0, Seeds_Sales,"0,")
OGSHistory=?(val(LastOldOGS)>0, OGS_Sales,"0,")
TreesHistory= ?(val(LastTrees)>0, Trees_Sales,"0,")
BulbsHistory= ?(val(LastBulbs)>0, Bulbs_Sales,"0,")
MooseHistory=?(val(LastNewOGS)>0, Moose_Sales,"0,")


//____Clear all those variables used so that we don't copy all that again when skipping steps____//
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

OGS_History=""
Recent_OGS=""
Last_OGS=""
OGS_Fields=""
Field_OGS=""
OGS_Num=""
OGS_Sales=""

Trees_History=""
Recent_Trees=""
Last_Trees=""
Trees_Fields=""
Field_Trees=""
Trees_Num=""
Trees_Sales=""




showvariables Branch_with_most_recent

selectwithin striptoalpha(exportline())≠""
if (not info("empty"))
removeunselected
endif
_______________




loop
window back_to_ML
until info("windowname") = back_to_ML
