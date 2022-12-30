window "customer_history"

global c_h_extras, extras_data, extras_counter, fence_post1

c_h_extras=""
extras_data=""
extras_counter=1
fence_post1=0

c_h_extras="2ndAdd
CChistory
Consent
Dup?
Email
Equity
Facil1
Facil2
NewMember
Notified
OldMember
ProbCust
SpareText4
SpareText5
taxname
TIN"

fence_post1=arraysize(c_h_extras, ¶)

;displaydata c_h_extras

/*
///____method to fix datatypes____
global numeric_types

numeric_types=fieldtypes("")

arrayfilter numeric_types, numeric_types, ¶, ?(import() contains "numeric", import(), "")

displaydata numeric_types
*/


extras_data=«2ndAdd»+¶+«CChistory»+¶+«Consent»+¶+«Dup?»+¶+«Email»+¶+
            str(«Equity»)+¶+«Facil1»+¶+«Facil2»+¶+«NewMember»+¶+«Notified»+¶+
            «OldMember»+¶+«ProbCust»+¶+«SpareText4»+¶+«SpareText5»+¶+«taxname»+¶+«TIN»

;displaydata extras_data

window "DeDuplicator"

loop
field (array(c_h_extras, extras_counter, ¶))
«»=array(extras_data, extras_counter, ¶)
extras_counter=extras_counter+1
until extras_counter=17

