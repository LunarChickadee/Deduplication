/*
________________________\

note: 

This was to test getting out design sheet elements and saving field types
then taking that saved variable and recreating a design sheet in a new file automatically


*/



///___backup design sheet_____///

global fields_and_datatypes, all_fieldnames, design_sheet_backup

all_fieldnames=""
fields_and_datatypes=""
design_sheet_backup=""

all_fieldnames=dbinfo("fields","")

fields_and_datatypes=fieldtypes("")

;displaydata fields_and_datatypes
;displaydata all_fieldnames

godesignsheet
firstrecord
loop
design_sheet_backup=design_sheet_backup+"^"+exportline()
downrecord
until info("stopped")
arraystrip design_sheet_backup, "^"
displaydata design_sheet_backup

/*

these variables need to output to a text file using 
the export/import suite to fill a variable in 
getMacros for the restore process

*/


////_______restore design sheet______///

godesignsheet
global design_field_count, design_line
all_fieldnames=info("fieldname")
;displaydata all_fieldnames


design_field_count=1

loop
    design_line=array(design_sheet_backup, design_field_count, "^")
    «Field Name»=array(design_line,1,¬)
    «Type»=array(design_line,2,¬)
    «Digits»=array(design_line,3,¬)
    «Align»=array(design_line,4,¬)
    «Output Pattern»=array(design_line,5,¬)
    «Input Pattern»=array(design_line,6,¬)
    «Range»=array(design_line,7,¬)
    «Choices»=array(design_line,8,¬)
    «Link»=array(design_line,9,¬)
    «Clairvoyance»=array(design_line,10,¬)
    «Tabs»=array(design_line,11,¬)
    «Caps»=array(design_line,12,¬)
    «Dups»=array(design_line,13,¬)
    «Default Value»=array(design_line,14,¬)
    «Equation»=array(design_line,15,¬)
    «Read»=val(array(design_line,16,¬))
    «Write»=val(array(design_line,17,¬))
    «Width»=val(array(design_line,18,¬))
    «Notes»=array(design_line,19,¬)
    design_field_count=design_field_count+1
    downrecord
        if info("stopped")
            addrecord
        endif
until design_field_count=arraysize(design_sheet_backup,"^")+1
