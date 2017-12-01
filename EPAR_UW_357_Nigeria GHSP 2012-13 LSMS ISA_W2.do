/*-----------------------------------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				  for the construction of a set of land tenure indicators
				  using the Nigeria General Household Survey (GHS) LSMS-ISA Wave 2 (2012-13)
*Author(s)		: Pierre Biscaye, Kirby Callaway, Emily Morton, Isabella Sun, Emma Weaver
*Acknowledgments: We acknowledge the helpful contributions of members of the World Bank's LSMS-ISA team 
				  All coding errors remain ours alone.
*Date			: 30 November 2017
----------------------------------------------------------------------------------------------------------------------------------------------------*/


*Data source
*-----------
*The Nigeria General Household Survey was collected by the Nigeria National Bureau of Statistics (NBS) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period  September - November 2012 and February - April 2013.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*http://microdata.worldbank.org/index.php/catalog/1952

*Throughout the do-file, we sometimes use the shorthand LSMS to refer to the Nigeria General Household Survey .


*Summary of Executing the Master do.file
*-----------
*This Master do.file constructs selected indicators using the Nigeria General Household Survey (NG LSMS) data set.
*First, save the raw unzipped data files from the World Bank in the "Raw DTA files" folder within the "Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)" folder.  
*The do.file constructs common and intermediate variables, saving dta files when appropriate 
*in a "\Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)\Merged Data" folder or "\Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)\Collapse Data" folder.
*These folders will need to be created. 


*The processed files include all households, individuals, and plots in the sample.
*In the middle of the do.file, a block of code estimates summary statistics of total plot ownership and plot title, restricted to the rural households only, disaggregated by gender of the plot owner.
*Those summary statistics are outputted in the excel file "NG_W2_plot_table1.rtf" in the "\Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)\Final files" folder.
*The do.file also generates other indicators not used in the summary statistics but are related to land tenure. 



/*OUTLINE OF THE DO.FILE

/////PLOT LEVEL//////
SEC_A1_11A_11B_HH_PLOT.dta
AG_indy_collapse1.dta
AG_indy_collapse2.dta
AG_indy_collapse.dta
AG_plot-level_merge.dta
W2_AG_Plot_Level_Land_Variables.dta
NG_W2_plot_table1.rtf
W2_AG_Plot_Level_Land_Variables_All.dta

////HOUSEHOLD LEVEL////
NG_W2_HH_Level.dta



*/

clear
set more off 

//set directories
*These paths correspond to the folders where the raw data files are located and where the created data and final data will be stored.

global input "Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)\Raw DTA files"
global merge "Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)\Merged Data"
global collapse "Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)\Collapse Data" 
global output "Nigeria GHSP - LSMS-ISA Wave 2 (2012-13)\Final files" 


//////////////////////////////////////////////////////////////////////////////
// 			1. Merge Post-Planting and Post-Harvest Plot Roster and Details //
//////////////////////////////////////////////////////////////////////////////


***SECTIONS A1 & 11A (PLOT ROSTER)***
clear
set more off
use "$input\Agriculture\secta1_harvestw2"

merge 1:1 hhid plotid using "$input\Agriculture\sect11a1_plantingw2", gen(_merge_SEC_A1_11A)
//305 not matched from master (only included in post-harvest questionnaire), 74 not matched from using (only included in post-planting questionnaire)
*Result is 5,819 unique plots

//merge in additional info on plots from post-planting survey
merge 1:1 hhid plotid using "$input\Agriculture\sect11b1_plantingw2", gen(_merge_SEC_A1_11B) 
//322 not matched from master (only included in post-harvest questionnaire)
*Result is 5,876 unique plots

drop if plotid==. // 0 observations deleted

save "$merge\SEC_A1_11A_11B_HH_PLOT.dta", replace


**check HH IDs of plot decision-makers, owners, and users to determine how much individual-level information to retain from AG HH Roster
{
/*
//who manages the plot 
tab sa1q2 
tab sa1q11
tab sa1q24a 
tab sa1q24b 
tab sa1q24c
tab s11aq6a
tab s11aq6b
*highest is 20

//who are decision makers
tab s11b1q11
tab s11b1q12a
tab s11b1q12b
tab s11b1q12c
tab s11b1q12d
tab s11b1q16
*highest 9

//who is/are the owners of this plot
tab sa1q14
tab sa1q14b
tab s11b1q6a
tab s11b1q6b
*highest 9

//who has right to sell/use as collateral
tab sa1q18a 
tab sa1q18b 
tab sa1q18c
tab s11b1q21
tab s11b1q22a 
tab s11b1q22b 
tab s11b1q22c
*highest 15

*/
}
***SECTION 1 (HH ROSTER)***

clear
use "$input\Agriculture\sect1_harvestw2.dta"
//Household roster using PH, as it includes more individuals than the PP HH roster

**Generate variables for gender of each HH member up to 20th (no HH member beyond #20 listed as a plot decision-maker).

foreach x of numlist 1/20 {
	gen hhmem_fem_`x'=.
	replace hhmem_fem_`x'=0 if indiv==`x' & s1q2==1 
	replace hhmem_fem_`x'=1 if indiv==`x' & s1q2==2 
} 

**Generate variables for age of each HH member up to 20th (no HH member beyond #20 listed as a plot owner) 
foreach x of numlist 1/20 {
	gen hhmem_age_`x'=.
	replace hhmem_age_`x'=s1q4 if indiv==`x'  
} 

gen hoh_fem=0
replace hoh_fem=1 if indiv==1 & s1q2==2

gen hoh_age=s1q4 if indiv==1
la var hoh_age "age of head of household" 

//HOH Education//

merge 1:1 hhid indiv using "$input\Post Planting Wave 2\Household\sect2_plantingw2.dta", generate (_merge_HH_PP_SEC_2)


*** can hoh read and write?
gen hoh_literate=1 if indiv==1 & s2q4!=. 
replace hoh_literate=0 if indiv==1 & s2q4==2 
la var hoh_literate "Can the head of household read and write?; YES=1 NO=2"

local maxvars hhmem_fem_* hhmem_age_* hoh_fem hoh_age hoh_literate
collapse (max) `maxvars', by (hhid)

save "$collapse/AG_indy_collapse1.dta", replace 

//repeat with PP HH roster as some HHs may not have been surveyed in PH survey
clear
use "$input\Post Planting Wave 2\Household\sect1_plantingw2.dta"

**Generate variables for gender of each HH member up to 20nd (no HH member beyond #20 listed as a plot decision-maker).

foreach x of numlist 1/20 {
	gen hhmem_fem_`x'_pp=.
	replace hhmem_fem_`x'_pp=0 if indiv==`x' & s1q2==1 
	replace hhmem_fem_`x'_pp=1 if indiv==`x' & s1q2==2 
} 

gen hoh_fem_pp=0
replace hoh_fem_pp=1 if indiv==1 & s1q2==2

local maxvars hhmem_fem_* hoh_fem_pp
collapse (max) `maxvars', by (hhid)

save "$collapse/AG_indy_collapse2.dta", replace 

merge 1:1 hhid using "$collapse/AG_indy_collapse1.dta", generate (_merge_HH_INDIV)
//30 not matched from master (only surveyed post-planting), 54 not matched from using (only surveyed post-harvest)

//replace missing data for HH members from PH questionnaire with data from PP questionnaire, drop PP variables
foreach x of numlist 1/20 {
	replace hhmem_fem_`x'=hhmem_fem_`x'_pp if hhmem_fem_`x'==.
	drop hhmem_fem_`x'_pp
} 

replace hoh_fem=hoh_fem_pp if hoh_fem==.
drop hoh_fem_pp

save "$collapse/AG_indy_collapse.dta", replace 


***MERGING ALL HH-PLOT LEVEL DATA TOGETHER***

clear
use "$merge\SEC_A1_11A_11B_HH_PLOT.dta"

//Merge in HH information to get HH weights
merge m:1 hhid using "$input\HHTrack.dta", generate (_merge_HH_TRACK_HH_PLOT)
*6,198 matched, 1,964 not matched from using (HHs with no plots)

drop if plotid==. //drop 1,964 observations - HHs with no plots

//Merge in HH Roster Info
merge m:1 hhid using "$collapse/AG_indy_collapse.dta", generate (_merge_AG_SEC_1_HH) 
*6,197 matched, 1,765 not matched from using (HHs with no plots)

drop if plotid==. //drop 1,765 observations - HHs with no plots

save "$merge\AG_plot-level_merge.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			2. Generate Land Tenure Variables at Plot Level				//
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge\AG_plot-level_merge.dta"
set more off

//"plotid" is the number of the plot in the HH
egen number_plots = count(plotid), by(hhid)  
la var number_plots "Total number of plots for the household"

////////LAND TITLE

// Have you or any other HH member acquired a legal title that verifies the Rights of Occupancy to this plot?
gen plot_cert=1 if s11b1q7!=. 
replace plot_cert=0 if (s11b1q7==2 & (s11b1q9==2 | s11b1q9==3)) | (s11b1q7==3 & (s11b1q9==2 | s11b1q9==3)) 
//some responses indicated that they didn't have a title, but did have another ownership document. Coded these as "1"

///////LAND AREA
{

***Convert all area units to hectares ****

**Conversions for post harvest farmer reported
gen plot_area_ph_fr = . 
//farmer reported in heaps. convert to hectares
replace plot_area_ph_fr=sa1q9a*0.00012 if zone==1 & sa1q9b==1 //0
replace plot_area_ph_fr=sa1q9a*0.00016 if zone==2 & sa1q9b==1 //0
replace plot_area_ph_fr=sa1q9a*0.00011 if zone==3 & sa1q9b==1 //0
replace plot_area_ph_fr=sa1q9a*0.00019 if zone==4 & sa1q9b==1 //184
replace plot_area_ph_fr=sa1q9a*0.00021 if zone==5 & sa1q9b==1 //103
replace plot_area_ph_fr=sa1q9a*0.00012 if zone==6 & sa1q9b==1 //16

///farmer reported in ridges
replace plot_area_ph_fr=sa1q9a*0.0027 if zone==1 & sa1q9b==2 //0
replace plot_area_ph_fr=sa1q9a*0.004 if zone==2 & sa1q9b==2 //9
replace plot_area_ph_fr=sa1q9a*0.00494 if zone==3 & sa1q9b==2 //14
replace plot_area_ph_fr=sa1q9a*0.0023 if zone==4 & sa1q9b==2 //5
replace plot_area_ph_fr=sa1q9a*0.0023 if zone==5 & sa1q9b==2 //1
replace plot_area_ph_fr=sa1q9a*0.00001 if zone==6 & sa1q9b==2 //0

///farmer reported in stands
replace plot_area_ph_fr=sa1q9a*0.00006 if zone==1 & sa1q9b==3 //0
replace plot_area_ph_fr=sa1q9a*0.00016 if zone==2 & sa1q9b==3 //19
replace plot_area_ph_fr=sa1q9a*0.00004 if zone==3 & sa1q9b==3 //0
replace plot_area_ph_fr=sa1q9a*0.00004 if zone==4 & sa1q9b==3 //16
replace plot_area_ph_fr=sa1q9a*0.00013 if zone==5 & sa1q9b==3 //248 
replace plot_area_ph_fr=sa1q9a*0.00041 if zone==6 & sa1q9b==3 //3

///farmer reported in plots
replace plot_area_ph_fr=sa1q9a*0.0667 if sa1q9b==4

///farmer reported in acres
replace plot_area_ph_fr=sa1q9a*0.4 if sa1q9b==5

/// hectares used
replace plot_area_ph_fr=sa1q9a if sa1q9b==6

///farmer reported in sq meters
replace plot_area_ph_fr=sa1q9a*0.0001 if sa1q9b==7 //0 responses for sq meters


**Conversions for post planting farmer reported
gen plot_area_pp_fr = .
//farmer reported in heaps. convert to hectares
replace plot_area_pp_fr=s11aq4a*0.00012 if zone==1 & s11aq4b==1 
replace plot_area_pp_fr=s11aq4a*0.00016 if zone==2 & s11aq4b==1
replace plot_area_pp_fr=s11aq4a*0.00011 if zone==3 & s11aq4b==1
replace plot_area_pp_fr=s11aq4a*0.00019 if zone==4 & s11aq4b==1
replace plot_area_pp_fr=s11aq4a*0.00021 if zone==5 & s11aq4b==1
replace plot_area_pp_fr=s11aq4a*0.00012 if zone==6 & s11aq4b==1

///farmer reported in ridges
replace plot_area_pp_fr=s11aq4a*0.0027 if zone==1 & s11aq4b==2
replace plot_area_pp_fr=s11aq4a*0.004 if zone==2 & s11aq4b==2
replace plot_area_pp_fr=s11aq4a*0.00494 if zone==3 & s11aq4b==2
replace plot_area_pp_fr=s11aq4a*0.0023 if zone==4 & s11aq4b==2
replace plot_area_pp_fr=s11aq4a*0.0023 if zone==5 & s11aq4b==2
replace plot_area_pp_fr=s11aq4a*0.00001 if zone==6 & s11aq4b==2

///farmer reported in stands
replace plot_area_pp_fr=s11aq4a*0.00006 if zone==1 & s11aq4b==3
replace plot_area_pp_fr=s11aq4a*0.00016 if zone==2 & s11aq4b==3
replace plot_area_pp_fr=s11aq4a*0.00004 if zone==3 & s11aq4b==3
replace plot_area_pp_fr=s11aq4a*0.00004 if zone==4 & s11aq4b==3
replace plot_area_pp_fr=s11aq4a*0.00013 if zone==5 & s11aq4b==3
replace plot_area_pp_fr=s11aq4a*0.00041 if zone==6 & s11aq4b==3

///farmer reported in plots
replace plot_area_pp_fr=s11aq4a*0.0667 if s11aq4b==4

///farmer reported in acres
replace plot_area_pp_fr=s11aq4a*0.4 if s11aq4b==5

/// hectares used
replace plot_area_pp_fr=s11aq4a if s11aq4b==6

///farmer reported in sq meters
replace plot_area_pp_fr=s11aq4a*0.0001 if s11aq4b==7

///farmer reported in "other specify"
replace plot_area_ph_fr=. if sa1q9b==8 //2 responses for "other"

**Convert GPS reported to hectares
gen plot_area_ph_gps= .
replace plot_area_ph_gps = sa1q9c*0.0001

gen plot_area_pp_gps= .
replace plot_area_pp_gps = s11aq4c*0.0001
}


/// Create plot area variable. 
/// Use PH GPS, if PH GPS missing then use PP GPS, if PP GPS missing then use PH farmer reported, if PH farmer reported missing then use PP fr. 
gen plot_area= plot_area_ph_gps
replace plot_area = plot_area_pp_gps if plot_area== . 
replace plot_area = plot_area_ph_fr if plot_area== .
replace plot_area = plot_area_pp_fr if plot_area== . 
la var plot_area "plot area measure, ha - GPS-based if they have one, farmer-report if not, PH if reported, PP if not"


////////////PLOT OWNERSHIP

// PH
gen ownership_owned=0 if sa1q12!=. 
replace ownership_owned = 1 if sa1q12==1 //10 outright purchased  

replace ownership_owned = 1 if sa1q12==4 & (sa1q15==1 | sa1q16==1 | sa1q17==1) // 0 distributed by community or family and someone can sell/use as collateral 
replace ownership_owned = 1 if sa1q12==5 & (sa1q15==1 | sa1q16==1 | sa1q17==1) //106 family/inheritance and someone can sell/use as collateral 

/// PP 
replace ownership_owned = 0 if ownership_owned== . & s11b1q4!=. 
replace ownership_owned = 1 if s11b1q4==1 //268 outright purchased

replace ownership_owned = 1 if s11b1q4==4 & (s11b1q19==1 | s11b1q20==1 | s11b1q21==1) // 3,362 distributed by community or family and someone can sell/use as collateral


gen ownership_rented=.
replace ownership_rented = 1 if s11b1q4==2 
replace ownership_rented = 0 if s11b1q4==1 | s11b1q4==3 | s11b1q4==4 | s11b1q4==5 
replace ownership_rented = 1 if sa1q12==2
replace ownership_rented = 0 if sa1q12==1 | sa1q12==3 | s11b1q4==4 | s11b1q4==5
label var ownership_rented "Did you rent this plot (sa1q12, s11b1q4)"

//584 rented plots

gen ownership_usedfree=.
replace ownership_usedfree = 1 if s11b1q4==3 
replace ownership_usedfree = 0 if s11b1q4==1 | s11b1q4==2 | s11b1q4==4 | s11b1q4==5 
replace ownership_usedfree = 1 if sa1q12==3
replace ownership_usedfree = 0 if sa1q12==1 | sa1q12==2 | s11b1q4==4 | s11b1q4==5
label var ownership_usedfree "Did you use this plot free of charge (sa1q12, s11b1q4)"
//717 used free

gen ownership_community=.
replace ownership_community = 1 if s11b1q4==4 
replace ownership_community = 0 if s11b1q4==1 | s11b1q4==2 | s11b1q4==3 | s11b1q4==5
replace ownership_community = 1 if sa1q12==4
replace ownership_community = 0 if sa1q12==1 | sa1q12==2 | s11b1q4==3 | s11b1q4==5
label var ownership_community "Was this plot distributed by community or family (sa1q12, s11b1q4)"

//////////////////PLOT OWNERSHIP BY GENDER


gen fem_plot_owner = .
la var fem_plot_owner "First listed plot owner is female"
foreach x of numlist 1/20 {
	replace fem_plot_owner = 0 if sa1q14 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_owner = 1 if sa1q14 == `x' & hhmem_fem_`x' == 1 
	replace fem_plot_owner = 0 if s11b1q6a == `x' & hhmem_fem_`x' == 0 & fem_plot_owner==.
	replace fem_plot_owner = 1 if s11b1q6a == `x' & hhmem_fem_`x' == 1 & fem_plot_owner==.
} 
// 244 male, 24 female  

gen fem_plot_co_owner = .
la var fem_plot_co_owner "Second listed plot owner is female"

foreach x of numlist 1/20 {
	replace fem_plot_co_owner = 0 if sa1q14b == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_co_owner = 1 if sa1q14b == `x' & hhmem_fem_`x' == 1 
	replace fem_plot_co_owner = 0 if s11b1q6b == `x' & hhmem_fem_`x' == 0 & fem_plot_co_owner==.
	replace fem_plot_co_owner = 1 if s11b1q6b == `x' & hhmem_fem_`x' == 1 & fem_plot_co_owner==.
} 

// 5 male, 16 female


// Plots with at least one female owner
generate fem_plot_owned = .
replace fem_plot_owned = 0 if fem_plot_owner == 0 | fem_plot_co_owner == 0
replace fem_plot_owned = 1 if fem_plot_owner == 1 | fem_plot_co_owner == 1 // 3,689 instances of female owned or co-owned plots
label variable fem_plot_owned "Plot owned or co-owned by a female"
//40

// Female only owned plots
generate fem_only_plot_own = .
replace fem_only_plot_own = 0 if (fem_plot_owner == 0 | fem_plot_co_owner == 0) 
replace fem_only_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 1) | (fem_plot_owner == 1 & fem_plot_co_owner==.) 
label variable fem_only_plot_own "Female-only owned plot"
// 23 plots

// Male only owned plots
generate male_only_plot_own = .
replace male_only_plot_own = 0 if (fem_plot_owner == 1 | fem_plot_co_owner == 1)
replace male_only_plot_own = 1 if (fem_plot_owner == 0 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == .) // females could be either missing or not listed in either case (owner or co-owner)   
label variable male_only_plot_own "Male-only owned plot"
// 228 plots 

// Mixed gender ownership plots
generate mixed_gen_plot_own = .
replace mixed_gen_plot_own = 0 if male_only_plot_own == 1 | fem_only_plot_own == 1
replace mixed_gen_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == 1) // requires two owners, of different gender (i.e., specifically one female owner)
label variable mixed_gen_plot_own "Plot with mixed gender ownership"
// 17 plots


*****Generate variables where ownership is defined also by right to sell/use as collateral


gen fem_lduse_dec_mkr_resp = . 
replace fem_lduse_dec_mkr_resp = 0 if hhmem_fem_1==0 & (s11b1q19==1 | s11b1q20==1 | s11b1q21==1) 
replace fem_lduse_dec_mkr_resp = 1 if hhmem_fem_1==1 & (s11b1q19==1 | s11b1q20==1 | s11b1q21==1)
replace fem_lduse_dec_mkr_resp = 0 if hhmem_fem_1==0 & (sa1q15==1 | sa1q16==1 | sa1q17==1)
replace fem_lduse_dec_mkr_resp = 1 if hhmem_fem_1==1 & (sa1q15==1 | sa1q16==1 | sa1q17==1)

la var fem_lduse_dec_mkr_resp "Respondent land use decision-maker is female"

gen fem_lduse_dec_mkr1 = .
la var fem_lduse_dec_mkr1 "First additional land use decision-maker is female" 

foreach x of numlist 1/20 {
	replace fem_lduse_dec_mkr1 = 0 if s11b1q22a == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr1 = 1 if s11b1q22a == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr1 = 0 if sa1q18a == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr1 = 1 if sa1q18a == `x' & hhmem_fem_`x' == 1 
}

gen fem_lduse_dec_mkr2 = .
la var fem_lduse_dec_mkr2 "Second additional land use decision-maker is female"

foreach x of numlist 1/20 {
	replace fem_lduse_dec_mkr2 = 0 if s11b1q22b == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr2 = 1 if s11b1q22b == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr2 = 0 if sa1q18b == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr2 = 1 if sa1q18b == `x' & hhmem_fem_`x' == 1 
}

gen fem_lduse_dec_mkr3 = .
la var fem_lduse_dec_mkr3 "Third additional land use decision-maker is female"

foreach x of numlist 1/20 {
	replace fem_lduse_dec_mkr3 = 0 if s11b1q22c == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr3 = 1 if s11b1q22c == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr3 = 0 if sa1q18c == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr3 = 1 if sa1q18c == `x' & hhmem_fem_`x' == 1 
}


// "Owned" Plots with at least one female decision-maker
generate fem_plot_dec = 0 if ownership_owned==1
replace fem_plot_dec = 1 if fem_lduse_dec_mkr_resp == 1 | fem_lduse_dec_mkr1 == 1 | fem_lduse_dec_mkr2 == 1 | fem_lduse_dec_mkr3 == 1 
replace fem_plot_dec = . if ownership_owned==0 | ownership_owned==.
//615

// "Owned" Plots with only female decision-makers //EW 9.29.17 is there a reason the below code is written as does not equal zero and is not blank? Why isn't it written as equals 1?
generate fem_only_plot_dec = 0 if ownership_owned==1
replace fem_only_plot_dec= 1 if (fem_lduse_dec_mkr_resp != 0 & fem_lduse_dec_mkr1 != 0 & fem_lduse_dec_mkr2 != 0 & fem_lduse_dec_mkr3 != 0) & (fem_lduse_dec_mkr_resp != . | fem_lduse_dec_mkr1 != . | fem_lduse_dec_mkr2 != . | fem_lduse_dec_mkr3 != .)
replace fem_only_plot_dec = . if ownership_owned==0 | ownership_owned==.
//201

// "Owned" Plots with only male decision-makers
generate male_only_plot_dec = 1 if ownership_owned==1
replace male_only_plot_dec = 0 if fem_plot_dec == 1
replace male_only_plot_dec = . if ownership_owned==0 | ownership_owned==.
//3,131

// "Owned" Plots with mixed gender decision-makers
generate mixed_gen_plot_dec = 1 if ownership_owned==1
replace mixed_gen_plot_dec = 0 if male_only_plot_dec == 1 | fem_only_plot_dec == 1
replace mixed_gen_plot_dec = . if ownership_owned==0 | ownership_owned==.
//414

//create land "owner" variables based on combination of owner and land use decision-maker, as appropriate
//ownership variable that uses gender of the owner where that is available, and gender of the use decision-maker where it isn't, and only cover those plots we define as "owned"

// Plots with at least one female owner
generate fem_plot_own2 = fem_plot_owned
replace fem_plot_own2=fem_plot_dec if fem_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable fem_plot_own2 "Plot owned or co-owned by a female"
//611

// Female only owned plots
generate fem_only_plot_own2 = fem_only_plot_own
replace fem_only_plot_own2=fem_only_plot_dec if fem_only_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable fem_only_plot_own2 "Female-only owned plot"
//214

// Male only owned plots
generate male_only_plot_own2 = male_only_plot_own
replace male_only_plot_own2=male_only_plot_dec if male_only_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable male_only_plot_own2 "Male-only owned plot"
//3,135

// Mixed gender ownership plots
generate mixed_gen_plot_own2 = mixed_gen_plot_own
replace mixed_gen_plot_own2=mixed_gen_plot_dec if mixed_gen_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable mixed_gen_plot_own2 "Plot with mixed gender ownership"
//397 


//create plot weights, household weight times plot area, as per World Bank practice
//use wave 2 visit 2 (PH) weights, as the PP weights do not cover all plots 
gen plot_weight = wt_w2v2*plot_area


gen clusterid=ea //first stage sampling unit

*The BID suggests that the strata are based on the zones:  "there are 12 strata consisting of urban and rural areas for the six geopolitical Zones"
gen strataid=zone //assign zone as strataid
replace strataid=zone+6 if sector==1 //create separate strataids for urban respondents

////////////////////Save plot level variables
save "$merge\W2_AG_Plot_Level_Land_Variables.dta", replace  


//////////////////////////////////////////////////////////////////////////////
// 			3. Summary Statistics at Plot Level						        //
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge\W2_AG_Plot_Level_Land_Variables.dta"

svyset clusterid [pweight=plot_weight], strata(strataid) singleunit(centered)


//Gender of Plot Owner - sample is owned plots, which we define as either plots purchased outright or those inherited/granted by community family that the HH has right to sell/use as collateral

eststo plots1: svy: mean fem_plot_own2 fem_only_plot_own2 mixed_gen_plot_own2 male_only_plot_own2 	
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]
eststo plots1a: svy, subpop(if plot_cert==1): mean fem_plot_own2 fem_only_plot_own2 mixed_gen_plot_own2 male_only_plot_own2 
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]
eststo plots1b: svy, subpop(if plot_cert==0): mean fem_plot_own2 fem_only_plot_own2 mixed_gen_plot_own2 male_only_plot_own2  
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]
esttab plots1 plots1a plots1b using "$output/NG_W2_plot_table1.rtf", cells(b(fmt(3)) & se(fmt(3) par)) label mlabels("All Owned Plots" "Owned plots with a Title/Certificate" "Owned plots with No Title/Certificate" ) collabels(none) title("Table X. Proportion of owned plots, by sex of owner and title/certificate type (Nigeria, 2010)")  /// 
note("The sample is plots acquired by the HH (1) through outright purchase, or (2) through inheritance/distributed by the community and has the right to sell these plots or use them as collateral. Plots with missing information on the sex of the owner are excluded. Estimates are plot-level cluster-weighted means, with standard errors in parentheses.") replace stats(subpop_N, label("Observations") fmt(0))



//////////////////////////////////////////////////////////////////////////////
// 			4. Other land tenure indicator variables	                    //
/////////////////////////////////////////////////////////////////////////////


/////////////PLOT SIZE/////////

gen plot_area_owned = plot_area if ownership_owned==1 
la var plot_area_owned "Plot area, owned plot, ha"

gen plot_area_notowned = plot_area if ownership_owned!=1 & ownership_owned!=. 
la var plot_area_notowned "Plot area, not owned plot, ha"

////HH CONSUMPTION////


merge m:1 hhid using "$input\cons_agg_w2.dta", gen (_merge_HHConsumption_2012)

*Expenditure per adult equivalent in the household
gen consum_per_adult = .
replace consum_per_adult=pcexp_dr_PH
replace consum_per_adult=pcexp_dr_PP if pcexp_dr_PH==.
la var consum_per_adult "regionally deflated percapita hh expenditure"

*Daily expenditure per adult equivalent in the household
gen consum_per_adult_daily = .
replace consum_per_adult_daily = consum_per_adult/365


****2016 implied PPP Conversion Rate is 94.12
****CPI in 2016 was 183.893
****CPI in in 2012 was 124.382
gen inflation=1+((183.893-124.382)/124.382)
gen usd_ngn_exchange=94.12


*Convert the expenditure values from Tanzanian Shillings to US Dollars
gen dailycons=consum_per_adult_daily*inflation/usd_ngn_exchange
label var dailycons "Daily consumption in USD per adult equivalent-convert_from WB total consumption, annual,real adjust 2016 PPP"


*Household below or above poverty line
gen poverty125 =.
replace poverty125 =1 if dailycons <= 1.25
replace poverty125 =0 if dailycons > 1.25
label var poverty125 "Daily consumption in USD per adult equivalent below $1.25, adjusted ppp"

gen poverty2 =.
replace poverty2 =1 if dailycons <= 2
replace poverty2 =0 if dailycons > 2
label var poverty2 "Daily consumption in USD per adult equivalent below $2, adjusted ppp"



//plot owner gender categorical variables 
gen plot_own_gender=.
replace plot_own_gender=1 if male_only_plot_own2==1
replace plot_own_gender=2 if fem_only_plot_own2==1
replace plot_own_gender=3 if mixed_gen_plot_own2==1
la var plot_own_gender "1 if male only, 2 if female only, 3 if mixed gender" 


save "$merge\W2_AG_Plot_Level_Land_Variables_All.dta", replace 




//////////////////////////////////////////////////////////////////////////////
// 			5. Other land tenure indicator variables at HH Level	         //
/////////////////////////////////////////////////////////////////////////////

//// Collapse plot-level data to HH level//

clear 
use "$merge\W2_AG_Plot_Level_Land_Variables_All.dta"

local sum_vars plot_cert plot_area plot_area_owned plot_area_notowned ownership_owned ownership_usedfree ownership_rented fem_plot_own2 fem_only_plot_own2 male_only_plot_own2 mixed_gen_plot_own2
local hoh_vars hoh_fem hoh_literate hoh_age
collapse `hoh_vars' (max) number_plots dailycons poverty125 poverty2 (firstnm) clusterid strataid (sum) `sum_vars', by (hhid) 

la var plot_cert "number of hh plots owned with a certificate"
la var plot_area "total area of all plots, ha"
la var plot_area_owned "total area of all plots owned, ha"
la var plot_area_notowned "total area of all plots not owned, ha"
la var ownership_owned "number of plots owned by the hh"
la var ownership_usedfree "number of plots used for free"
la var ownership_rented "number of plots rented in"
la var fem_plot_own2 "number of plots in the hh that are owned/coowned by a female"
la var fem_only_plot_own2 "number of plots in the hh that are owned by only females"
la var male_only_plot_own2 "number of plots in the hh that are owned by onle males"
la var mixed_gen_plot_own2 "number of plots in the hh that are owned by both a male and a female"
la var hoh_fem "female head of household"
la var hoh_literate "head of household can read and write"
la var hoh_age "age of head of household"


////SMALLHOLDER////

gen smallholder2 = .
replace smallholder2 = 1 if plot_area <=2
replace smallholder2 = 0 if plot_area >2 & plot_area!= . 
la var smallholder2 "total area 2ha or less"

gen smallholder2_owned = .
replace smallholder2_owned = 1 if plot_area_owned <=2
replace smallholder2_owned = 0 if plot_area_owned >2 & plot_area_owned!= . 
la var smallholder2 "total area owned 2ha or less"



save "$collapse\NG_W2_HH_Level.dta", replace
