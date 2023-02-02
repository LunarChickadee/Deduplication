//___this is an edited version of picksheet print__//

global fundraiser_array, fund_choice, fund_element, find_this_fund

fundraiser_array=""
fund_choice=""

selectall 
arraybuild fundraiser_array, ¶, "", fundraisercode
arraystrip fundraiser_array,¶
arraydeduplicate fundraiser_array, fundraiser_array, ¶
;displaydata fundraiser_array

repeatask:
bigmessage "The current fundraisers are: "+¶+fundraiser_array

gettext "Which fundraiser are you printing?", fund_choice

fund_element=arraysearch(fundraiser_array, "*"+str(fund_choice)+"*",1, ¶)

find_this_fund=array(fundraiser_array, fund_element,¶)

yesno "You want to print orders for fundraiser "+find_this_fund
if clipboard()="Yes"
    select «fundraisercode» contains find_this_fund
else
    goto repeatask
endif


;;newer process where LARGE orders are reset when SMALL orders are being printed
extendedexpressionstack

if info("windowname") notcontains "seedspagecheck"
    message "This Command must be run from seedspagecheck"
    stop
endif

yesno "Would you like to use the new printing process?"
if clipboard()="No"
    call OldPicksheetPrint
    stop
endif

if info("windows") notcontains "BatchPrinter"
message "You must open the BatchPrinter File before running this"
stop
endif

//_____this suite of varables will let you set amounts of orders to "batch" for pullers on one topsheet____//
global startOfRun, endOfRun, numOfPickSheets, orderDictionary,ordersArray,startruntimer,
Left_over_loop

startruntimer=now()
startOfRun=0
endOfRun=0
numOfPickSheets=0
orderDictionary=""
ordersArray=""
Left_over_loop=0
//__________added by Lunar 10.11.22_____________///

;this prints all but Canadian orders, they have their own loop
oldfile= info("DatabaseName") //XXseedstally.pan
waswindow=info("windowname") //XXseedstally:seedspagecheck
form=info("FormName") //seedspagecheck
rayg=""

zlarge=0
Synchronize
ztime=now() ;resets sync timer  
field OrderNo
SortUp
select Order contains "0000" OR Order = "" OR (Order CONTAINS "1)"+¬+"0"+¬+¬+"0" AND OrderComments CONTAINS "empty order")
    OR (Order CONTAINS "1)"+¬+"0"+¬+¬+"0" AND OrderNo>1000000) ;6-2 change
    
selectreverse
selectwithin ShipCode≠"D"
selectwithin «9SpareText»="" ;exclude Canadians
;selectwithin TaxState≠""
;selectwithin (ztaxstates contains TaxState AND TaxRate≠0) 
;    OR (ztaxstates notcontains TaxState AND TaxRate=0) OR Taxable contains "N"
;    OR str(OrderNo) contains "."
;debug

FundraiserRange:
global fund_print_range, fund_cover_sheet

selectwithin OrderNo≥780000 and OrderNo<990000
    if info("selected")=1
        fund_cover_sheet=str(OrderNo)
    else
        message "Procedure found more than one covers sheet for this fundraiser, stopping"
        stop
     endif

select «fundraisercode» contains find_this_fund AND 
    «fundraisercode» notcontains fund_cover_sheet

arrayselectedbuild fund_print_range, ¶, "", str(OrderNo)



case OrderNo < 30000 OR (OrderNo>70000 AND OrderNo<1000000) ;6-2 change
    selectwithin PickSheet=""
    selectwithin OrderNo > 0
        if  info("Empty")
            message "Picksheets have already been printed for all the orders you selected."
            ;selectall
            stop
        endif
defaultcase 
    yesno "This program has only been tested on seed orders. Continue?"
        if clipboard()≠"Yes"
        stop
        endif
endcase   





noshow
if form="seedspagecheck"    
    openfile zcomyear+"SeedsComments linked"
        ReSynchronize
        save
        closefile
    openfile zcomyear+"SeedsComments"
    openfile "&&"+zcomyear+"SeedsComments linked"
endif
endnoshow

save

window "Hide This Window"
window waswindow

noshow
///____thise calls multiple subroutines that fill in all the data for each order___///
call ".comments"
endnoshow

//___List of all orders that will now say they are "printed"
//______i.e. they have a picksheet and the order is no longer in "orginal" state
global ordersPrintedArray
arrayselectedbuild ordersPrintedArray,¶,"",str(«OrderNo»)

//_____Batch Printing added 10-20-22 by Lunar and Gene
global math1,math2,picksheetArray,orderRange, lastOrder, batchPrint, tallyWindow, ordersizes

tallyWindow=""

selectwithin PickSheet≠"" ;this works primarily with the process in the totaller to avoid orders with items marked -avoid-.


///___Do PrintRun of selected size____//
//PrintLeftOvers:

firstrecord

global printrunList,firstPrint, batchPrintBool

 //___creates list of the orders you're doing this run__//
    printrunList=""
        arrayselectedbuild printrunList,¶,"",str(«OrderNo»)
        arraystrip printrunList,¶


CheckBatchPrint:
batchPrintBool=-1

math1=info("selected")

//____BatchPrinting Loop______________________________________//
BatchPrint:
global xNumPickSheetArray,batchPrintArray,batchDictionary

//____Loop 1 builds selection and prints all___//
BatchRepeat:
    xNumPickSheetArray=""
    batchPrintArray=""
    batchDictionary=""
     //__loop 2 build an array from x number of records picksheets__//
    if firstPrint=-1
        firstrecord
    endif
        

        //_____Loop 2 gathers math1 number of picksheets and builds the commodity sheet for them___//
        loop 
            //__gather from item number to the name common name___//
            xNumPickSheetArray=arraycolumn(arraycolumn(PickSheet,1,¶,"("),2,¶,")")
            //____append the orderNumber for checking with later___//
            arrayfilter xNumPickSheetArray,xNumPickSheetArray,¶,import()+¬+str(OrderNo)
            batchPrintArray=xNumPickSheetArray+¶+batchPrintArray
            arraystrip batchPrintArray,¶
            downrecord
        until (val(math1) or info("stopped"))

    //____Data Manipulation____//
    
     //___Uses the itemnumber to sort from smallest to largest number__//
    ;displaydata batchPrintArray
    if batchPrintArray notcontains "."
        arraynumericsort batchPrintArray,batchPrintArray,¶
    else
        arraymultisort batchPrintArray, batchPrintArray, ¶, ¬, "2n"
        endif
    ;displaydata batchPrintArray
    //__gets the list of orderNumbers this process was done for__//
    picksheetArray=arraydeduplicate(arraycolumn(batchPrintArray,4,¶,¬),¶)
    select picksheetArray contains str(«OrderNo»)
    //__lets us find the last order to loop back through with__//
    lastOrder=arraylast(picksheetArray,¶)
    //__this is for displaying the range in the form__//
    orderRange=replace(picksheetArray,¶,"/")
    //arrayfilter takes each thing on the list and formats as follows//
    // 1(AA) item to name [import()] ordernumber AA//
    arrayfilter batchPrintArray,batchPrint,¶, 
        rep(chr(32),4-length(str(seq())))+str(seq())+" "+
        import()+
        " "
       

    ///___start the printing process__//
       
    ;debug
    
 
///___force open batch printer_____
global file_names, folder_name,
    main_window, main_file

folder_name=""
file_names=""
main_window=""
main_file=""

main_window=info("windowname")
main_file=info("databasename")

folder_name=dbinfo("folder","")

file_names=listfiles(folder_name,"????KASX")

if file_names contains "BatchPrinter.pan"
    openanything "", "BatchPrinter.pan"
    goto RestOfProgram
else
    openfile "BatchPrinter"
endif

RestOfProgram:
;debug
    if info("windows") contains "BatchPrintList"
        window "BatchPrinter:BatchPrintList"
    else 
        openform "BatchPrintList"
     endif
    openfile "&&@batchPrint"
    openform "BatchPrintList"
    
    
     //Fix Group Order Issue//
     /////____note, this has a decision to make from Ryan due to how it will mess up 
        if printrunList contains "."
            ;opensheet
                field OrderandBox
                    formulafill ?(OrderandBox contains ".", pattern(val(OrderandBox),"#.###")+" "+striptoalpha(OrderandBox), OrderandBox)
                
        endif

    ;printusingform "BatchPrinter","BatchPrintList"
        message "The print dialog will now open. Make sure blank sheets are in the auxilary tray AND printer is set to Two-Sided printing!"
        print dialog


window oldfile

//____Puts the Letter Code into a field to display on the individual orders_____

yesno "Wait! Then, if coversheets have printed Press Yes AND remove blank sheets from auxilary tray."
if clipboard()="No"
    goto BatchPrint
endif

//____Print That selection of PickSheets______//

SinglePrint:
window oldfile

select printrunList contains str(OrderNo)

openform "BatchPickSheets"

    firstrecord
    PrintUsingForm "", "BatchPickSheets"
    print ""


yesno "Wait! Then, Press Yes if all PickSheets printed."
if clipboard()="No"
goto SinglePrint
endif


///______Is this still wanted?________
SelectAll
Select int(OrderNo)≥pickno ;6-2 change
selectwithin int(OrderNo)≤Numb ;6-2 change

zselect= info("Selected")   
    selectwithin OrderComments≠"" OR Notes1≠""
        if info("Selected")<zselect
            if zlarge>1
                message "Please remember to check comments and order notes on the orders currently selected. Bria thanks you!"
            endif
            if zlarge=0
                message "Please remember to check comments and order notes on the orders currently selected. Bria thanks you!"
            endif
        else
            selectall
        endif   

message "cover sheet for this fundraiser will now be selected!"

select OrderNo = val(fund_cover_sheet)