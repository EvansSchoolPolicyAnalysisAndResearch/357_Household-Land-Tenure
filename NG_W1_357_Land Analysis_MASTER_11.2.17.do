*Title/Purpose of Do File: NIGERIA LSMS-ISA (2015-16) - Land Tenure Analysis (Project #357)
*Author(s): Emma Weaver, Emily Morton, Isabella Sun, Kirby Callaway, Pierre Biscaye

clear

global input "\\evansfiles\files\Project\EPAR\Nigeria LSMS-ISA\Analysis\357 Land Tenure Indicators\2010-2011\Data"
global merge "\\evansfiles\files\Project\EPAR\Nigeria LSMS-ISA\Analysis\357 Land Tenure Indicators\2010-2011\Merged Data"
global collapse "\\evansfiles\files\Project\EPAR\Nigeria LSMS-ISA\Analysis\357 Land Tenure Indicators\2010-2011\Collapse Data"
global output "R:\Project\EPAR\Working Files\357 - Land Reform Review\Output" 


//////////////////////////////////////////////////////////////////////////////
// 			1. Merge Post-Planting and Post-Harvest Plot Roster and Details //
//////////////////////////////////////////////////////////////////////////////


***SECTIONS A1 & 11A (PLOT ROSTER)***
clear
set more off
use "$input\Post Harvest Wave 1\Agriculture\secta1_harvestw1"

merge 1:1 hhid plotid using "$input\Post Planting Wave 1\Agriculture\sect11a1_plantingw1", gen(_merge_SEC_A1_11A) 
* Matched: 5,885
* not matched: 632
* from master: 431(only included in post-harvest questionnaire)
* from using : 201(only included in post-planting questionnaire)

//merge in additional info on plots from post-planting survey
merge 1:1 hhid plotid using "$input\Post Planting Wave 1\Agriculture\sect11b_plantingw1", gen(_merge_SEC_A1_11B) 
* matched: 5,997
* not matched: 520

drop if plotid==. // 0 observations deleted

save "$merge\SEC_A1_11A_11B_HH_PLOT.dta", replace


**check HH IDs of plot decision-makers, owners, and users to determine how much individual-level information to retain from AG HH Roster
{
/*
//who manages the plot 
// Who in the household manages this plot
tab sa1q2 
tab sa1q11
tab sa1q24a 
tab sa1q24b 
tab sa1q24c
tab s11aq6
*highest is 16

//who are decision makers
tab sa1q16a
tab sa1q16b
tab sa1q16c
tab sa1q16d
tab s11bq8a
tab s11bq8b
tab s11bq8c
tab s11bq8d
*hightest 14

//who has right to sell/use as collateral
tab sa1q22a
tab sa1q22b
tab sa1q22c
tab s11bq14a
tab s11bq14b
tab s11bq14c
*highest 15

//who is/are the owners of this plot
tab sa1q14
tab s11bq6
*highest 7 

*/
}
***SECTION 1 (HH ROSTER)***

clear
use "$input\Post Harvest Wave 1\Household\sect1_harvestw1.dta"
//Household roster using PH, as it includes more individuals than the PP HH roster

**Generate variables for gender of each HH member up to 16th (no HH member beyond #16 listed as a plot decision-maker).

foreach x of numlist 1/16 {
	gen hhmem_fem_`x'=.
	replace hhmem_fem_`x'=0 if indiv==`x' & s1q2==1 
	replace hhmem_fem_`x'=1 if indiv==`x' & s1q2==2 
} 

**Generate variables for age of each HH member up to 32nd (no HH member beyond #14 listed as a plot owner) 
foreach x of numlist 1/16 {
	gen hhmem_age_`x'=.
	replace hhmem_age_`x'=s1q4 if indiv==`x'  
} 

gen hoh_fem=0
replace hoh_fem=1 if indiv==1 & s1q2==2

gen hoh_age=s1q4 if indiv==1
la var hoh_age "age of head of household" 

//HOH Education//

merge 1:1 hhid indiv using "$input\Post Planting Wave 1\Household\sect2_plantingw1.dta", generate (_merge_HH_PH_SEC_2)


*** can hoh read and write?
gen hoh_literate=1 if indiv==1 & s2q3!=. 
replace hoh_literate=0 if indiv==1 & s2q3==2 
la var hoh_literate "Can the head of household read and write?; YES=1 NO=2"

local maxvars hhmem_fem_* hhmem_age_* hoh_fem hoh_age hoh_literate
collapse (max) `maxvars', by (hhid)

save "$collapse/AG_indy_collapse1.dta", replace 

//repeat with PP HH roster as some HHs may not have been surveyed in PH survey
clear
use "$input\Post Planting Wave 1\Household\sect1_plantingw1.dta"

**Generate variables for gender of each HH member up to 16th (no HH member beyond #16 listed as a plot decision-maker).

foreach x of numlist 1/16 {
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
* matched: 4916
* not matched: 82
* from master: 81
* from using: 1 

//replace missing data for HH members from PH questionnaire with data from PP questionnaire, drop PP variables
foreach x of numlist 1/16 {
	replace hhmem_fem_`x'=hhmem_fem_`x'_pp if hhmem_fem_`x'==.
	drop hhmem_fem_`x'_pp
} 

replace hoh_fem=hoh_fem_pp if hoh_fem==.
drop hoh_fem_pp

save "$collapse/AG_indy_collapse.dta", replace 


***MERGING ALL HH-PLOT LEVEL DATA TOGETHER***

clear
use "$merge\SEC_A1_11A_11B_HH_PLOT.dta"

//Merge in HH information to get HH weights (using wave 1 weights included in wave 3 dta file)
merge m:1 hhid using "\\evansfiles\files\Project\EPAR\Nigeria LSMS-ISA\Wave 3 (2015-16)\Data\HHTrack.dta", generate (_merge_HH_TRACK_HH_PLOT)
* matched: 6,947
* not matched: 1,876
* not matched from using: 1,876

drop if plotid==. //drop 1876 observations - HHs with no plots

//Merge in HH Roster Info
merge m:1 hhid using "$collapse/AG_indy_collapse.dta", generate (_merge_AG_SEC_1_HH)
* matched: 6,517
* not matched : 1,874 
* not matched from using: 1,874

drop if plotid==. //drop 1,874 observations - HHs with no plots

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
{
//there is no certificate informtaion in wave 1
}

////////////Plot size 
{
**** Convert all area units to hectares ****

**Conversions for post harvest farmer reported
gen plot_area_ph_fr = . 
//farmer reported in heaps. convert to hectares
replace plot_area_ph_fr=sa1q9a*0.00012 if zone==1 & sa1q9b==1 
replace plot_area_ph_fr=sa1q9a*0.00016 if zone==2 & sa1q9b==1 
replace plot_area_ph_fr=sa1q9a*0.00011 if zone==3 & sa1q9b==1
replace plot_area_ph_fr=sa1q9a*0.00019 if zone==4 & sa1q9b==1 
replace plot_area_ph_fr=sa1q9a*0.00021 if zone==5 & sa1q9b==1 
replace plot_area_ph_fr=sa1q9a*0.00012 if zone==6 & sa1q9b==1 

///farmer reported in ridges
replace plot_area_ph_fr=sa1q9a*0.0027 if zone==1 & sa1q9b==2 
replace plot_area_ph_fr=sa1q9a*0.004 if zone==2 & sa1q9b==2
replace plot_area_ph_fr=sa1q9a*0.00494 if zone==3 & sa1q9b==2 
replace plot_area_ph_fr=sa1q9a*0.0023 if zone==4 & sa1q9b==2
replace plot_area_ph_fr=sa1q9a*0.0023 if zone==5 & sa1q9b==2
replace plot_area_ph_fr=sa1q9a*0.00001 if zone==6 & sa1q9b==2

///farmer reported in stands
replace plot_area_ph_fr=sa1q9a*0.00006 if zone==1 & sa1q9b==3
replace plot_area_ph_fr=sa1q9a*0.00016 if zone==2 & sa1q9b==3
replace plot_area_ph_fr=sa1q9a*0.00004 if zone==3 & sa1q9b==3
replace plot_area_ph_fr=sa1q9a*0.00004 if zone==4 & sa1q9b==3
replace plot_area_ph_fr=sa1q9a*0.00013 if zone==5 & sa1q9b==3 
replace plot_area_ph_fr=sa1q9a*0.00041 if zone==6 & sa1q9b==3

///farmer reported in plots
replace plot_area_ph_fr=sa1q9a*0.0667 if sa1q9b==4

///farmer reported in acres
replace plot_area_ph_fr=sa1q9a*0.4 if sa1q9b==5

/// hectares used
replace plot_area_ph_fr=sa1q9a if sa1q9b==6

///farmer reported in sq meters
replace plot_area_ph_fr=sa1q9a*0.0001 if sa1q9b==7


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


**Convert GPS reported to hectares
gen plot_area_ph_gps= .
replace plot_area_ph_gps = sa1q9d*0.0001

gen plot_area_pp_gps= .
replace plot_area_pp_gps = s11aq4d*0.0001
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
replace ownership_owned = 1 if sa1q12==1 //23 outright purchased  

replace ownership_owned = 1 if sa1q12==4 & (sa1q19==1 | sa1q20==1 | sa1q21==1) //9 distributed by community or family and someone can sell/use as collateral 
replace ownership_owned = 1 if sa1q12==5 & (sa1q19==1 | sa1q20==1 | sa1q21==1) //121 family/inheritance and someone can sell/use as collateral 

/// PP 
replace ownership_owned = 0 if ownership_owned==. & s11bq4!=1 & s11bq4!=.
replace ownership_owned = 1 if s11bq4==1 //350 outright purchased

replace ownership_owned = 1 if s11bq4==4 & (s11bq11==1 | s11bq12==1 | s11bq13==1) //3,342 distributed by community or family and someone can sell/use as collateral
//There is no option 5 "family inheritance" in wave 1 PP


gen ownership_rented=.
replace ownership_rented = 1 if s11bq4==2 
replace ownership_rented = 0 if s11bq4==1 | s11bq4==3 | s11bq4==4 | s11bq4==5 
replace ownership_rented = 1 if sa1q12==2
replace ownership_rented = 0 if sa1q12==1 | sa1q12==3 | s11bq4==4 | s11bq4==5
label var ownership_rented "Did you rent this plot (sa1q12, s11bq4)"

//653 rented plots

gen ownership_usedfree=.
replace ownership_usedfree = 1 if s11bq4==3 
replace ownership_usedfree = 0 if s11bq4==1 | s11bq4==2 | s11bq4==4 | s11bq4==5 
replace ownership_usedfree = 1 if sa1q12==3
replace ownership_usedfree = 0 if sa1q12==1 | sa1q12==2 | s11bq4==4 | s11bq4==5
label var ownership_usedfree "Did you use this plot free of charge (sa1q12, s11bq4)"
//659 used free


//////////////////PLOT OWNERSHIP BY GENDER

gen fem_plot_owner = .
la var fem_plot_owner "First listed plot owner is female"
foreach x of numlist 1/16 {
	replace fem_plot_owner = 0 if sa1q14 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_owner = 1 if sa1q14 == `x' & hhmem_fem_`x' == 1 
	replace fem_plot_owner = 0 if s11bq6 == `x' & hhmem_fem_`x' == 0 & fem_plot_owner==.
	replace fem_plot_owner = 1 if s11bq6 == `x' & hhmem_fem_`x' == 1 & fem_plot_owner==.
} 
// 379 male, 37 female  


///Respondents can indicate a hh member in sa1q14 if they responded "rented" in sa1q12 (How was this plot acquired?), so we need to limit ownership gender by our definition of own///
///Respondents can also indicate a hh member in s11bq6 if they responded "rented in s11bq4 (How was this plot acquired?)///

// Plots with at least one female owner
generate fem_plot_owned = . 
replace fem_plot_owned = 0 if fem_plot_owner == 0 & ownership_owned==1
replace fem_plot_owned = 1 if fem_plot_owner == 1 & ownership_owned==1 
label variable fem_plot_owned "Plot owned or co-owned by a female" 
//32

// Female only owned plots
generate fem_only_plot_own = .
replace fem_only_plot_own = 0 if fem_plot_owner == 0  & ownership_owned==1
replace fem_only_plot_own = 1 if fem_plot_owner == 1  & ownership_owned==1
label variable fem_only_plot_own "Female-only owned plot"
//32

// Male only owned plots
generate male_only_plot_own = .
replace male_only_plot_own = 0 if fem_plot_owner == 1 & ownership_owned==1
replace male_only_plot_own = 1 if fem_plot_owner == 0  & ownership_owned==1  
label variable male_only_plot_own "Male-only owned plot" 
//343

// Mixed gender ownership plots ***EW 9.29.17 created the variable with all values as missing. 
generate mixed_gen_plot_own = 0 if male_only_plot_own == 1 | fem_only_plot_own == 1
*replace mixed_gen_plot_own = 0 if male_only_plot_own == 1 | fem_only_plot_own == 1
*replace mixed_gen_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == 1) // requires two owners, of different gender (i.e., specifically one female owner)
label variable mixed_gen_plot_own "Plot with mixed gender ownership"
//0


*****Generate variables where ownership is defined also by right to sell/use as collateral

gen fem_lduse_dec_mkr_resp = . 
replace fem_lduse_dec_mkr_resp = 0 if hhmem_fem_1==0 & (s11bq11==1 | s11bq12==1 |s11bq13==1) 
replace fem_lduse_dec_mkr_resp = 1 if hhmem_fem_1==1 & (s11bq11==1 | s11bq12==1 |s11bq13==1)
replace fem_lduse_dec_mkr_resp = 0 if hhmem_fem_1==0 & (sa1q19==1 | sa1q20==1 |sa1q21==1)
replace fem_lduse_dec_mkr_resp = 1 if hhmem_fem_1==1 & (sa1q19==1 | sa1q20==1 |sa1q21==1)
la var fem_lduse_dec_mkr_resp "Respondent land use decision-maker is female"

gen fem_lduse_dec_mkr1 = .
la var fem_lduse_dec_mkr1 "First additional land use decision-maker is female" 

foreach x of numlist 1/16 {
	replace fem_lduse_dec_mkr1 = 0 if s11bq14a == `x' & hhmem_fem_`x' == 0 
	replace fem_lduse_dec_mkr1 = 1 if s11bq14a == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr1 = 0 if sa1q22a == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr1 = 1 if sa1q22a == `x' & hhmem_fem_`x' == 1 
}

gen fem_lduse_dec_mkr2 = .
la var fem_lduse_dec_mkr2 "Second additional land use decision-maker is female"

foreach x of numlist 1/16 {
	replace fem_lduse_dec_mkr2 = 0 if s11bq14b == `x' & hhmem_fem_`x' == 0 
	replace fem_lduse_dec_mkr2 = 1 if s11bq14b == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr2 = 0 if sa1q22b == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr2 = 1 if sa1q22b == `x' & hhmem_fem_`x' == 1 
}

gen fem_lduse_dec_mkr3 = .
la var fem_lduse_dec_mkr3 "Third additional land use decision-maker is female"

foreach x of numlist 1/16 {
	replace fem_lduse_dec_mkr3 = 0 if s11bq14c == `x' & hhmem_fem_`x' == 0 
	replace fem_lduse_dec_mkr3 = 1 if s11bq14c == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr3 = 0 if sa1q22c == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr3 = 1 if sa1q22c == `x' & hhmem_fem_`x' == 1 
}


// "Owned" Plots with at least one female decision-maker
generate fem_plot_dec = 0 if ownership_owned==1
replace fem_plot_dec = 1 if fem_lduse_dec_mkr_resp == 1 | fem_lduse_dec_mkr1 == 1 | fem_lduse_dec_mkr2 == 1 | fem_lduse_dec_mkr3 == 1 
replace fem_plot_dec = . if ownership_owned==0 | ownership_owned==.
//572

// "Owned" Plots with only female decision-makers 
generate fem_only_plot_dec = 0 if ownership_owned==1
replace fem_only_plot_dec= 1 if (fem_lduse_dec_mkr_resp != 0 & fem_lduse_dec_mkr1 != 0 & fem_lduse_dec_mkr2 != 0 & fem_lduse_dec_mkr3 != 0) & (fem_lduse_dec_mkr_resp != . | fem_lduse_dec_mkr1 != . | fem_lduse_dec_mkr2 != . | fem_lduse_dec_mkr3 != .)
replace fem_only_plot_dec = . if ownership_owned==0 | ownership_owned==.
//214

// "Owned" Plots with only male decision-makers
generate male_only_plot_dec = 1 if ownership_owned==1
replace male_only_plot_dec = 0 if fem_plot_dec == 1
replace male_only_plot_dec = . if ownership_owned==0 | ownership_owned==. 
//3,273

// "Owned" Plots with mixed gender decision-makers 
generate mixed_gen_plot_dec = 1 if ownership_owned==1
replace mixed_gen_plot_dec = 0 if male_only_plot_dec == 1 | fem_only_plot_dec == 1
replace mixed_gen_plot_dec = . if ownership_owned==0 | ownership_owned==.
//358

//create land "owner" variables based on combination of owner and land use decision-maker, as appropriate
//ownership variable that uses gender of the owner where that is available, and gender of the use decision-maker where it isn't, and only cover those plots we define as "owned"

// Plots with at least one female owner
generate fem_plot_own2 = fem_plot_owned
replace fem_plot_own2=fem_plot_dec if fem_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable fem_plot_own2 "Plot owned or co-owned by a female"
//567

// Female only owned plots
generate fem_only_plot_own2 = fem_only_plot_own
replace fem_only_plot_own2=fem_only_plot_dec if fem_only_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable fem_only_plot_own2 "Female-only owned plot"
// 234

// Male only owned plots
generate male_only_plot_own2 = male_only_plot_own
replace male_only_plot_own2=male_only_plot_dec if male_only_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable male_only_plot_own2 "Male-only owned plot"
//3,886

// Mixed gender ownership plots
generate mixed_gen_plot_own2 = mixed_gen_plot_own
replace mixed_gen_plot_own2=mixed_gen_plot_dec if mixed_gen_plot_own2==. //only replace if there is no data on ownership, since we want to use that data where available
label variable mixed_gen_plot_own2 "Plot with mixed gender ownership"
//333


//create plot weights, household weight times plot area, as per World Bank practice
//use wave 3 visit 1 (PP) weights, as the PH weights do not cover all plots

gen plot_weight = wt_wave1*plot_area

//generate strata and cluster variables for analysis with survey weights

gen clusterid=ea //first stage sampling unit

*The BID suggests that the strata are based on the zones:  "there are 12 strata consisting of urban and rural areas for the six geopolitical Zones"
gen strataid=zone //assign zone as strataid
replace strataid=zone+6 if sector==1 //create separate strataids for urban respondents

////////////////////Save plot level variables
save "$merge\W1_AG_Plot_Level_Land_Variables.dta", replace 

  
//////////////////////////////////////////////////////////////////////////////
// 			3. Summary Statistics at Plot Level						        //
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge\W1_AG_Plot_Level_Land_Variables.dta"

svyset clusterid [pweight=plot_weight], strata(strataid) singleunit(centered)

//Gender of Plot Owner - sample is owned plots, which we define as either plots purchased outright or those inherited/granted by community family that the HH has right to sell/use as collateral

eststo plots1: svy, subpop(if ownership_owned==1): mean fem_plot_own2 fem_only_plot_own2 mixed_gen_plot_own2 male_only_plot_own2
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]
esttab plots1 using "$output/NIG_w1_plot_table1.rtf", cells(b(fmt(3)) & se(fmt(3) par)) label mlabels("All Owned Plots") collabels(none) title("Table X. Proportion of owned plots, by sex of owner and title/certificate type (Nigeria, 2010)")  /// 
note("The sample excludes plots rented in, used free of charge, borrowed from a family member, allocated from the village council, or squatted on, and three owned plots with missing data on gender of the plot owner. Estimates are plot-level cluster-weighted means, with standard errors in parentheses.") replace stats(subpop_N, label("Observations") fmt(0))

//////////////////////////////////////////////////////////////////////////////
// 			4. Other land tenure indicator variables	                    //
/////////////////////////////////////////////////////////////////////////////


/////////////PLOT SIZE/////////

gen plot_area_owned = plot_area if ownership_owned==1 
la var plot_area_owned "Plot area, owned plot, ha"

gen plot_area_notowned = plot_area if ownership_owned!=1 & ownership_owned!=. 
la var plot_area_notowned "Plot area, not owned plot, ha"


////HH CONSUMPTION////

merge m:1 hhid using "$input\cons_agg_w1.dta", gen (_merge_HHConsumption_2010)

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
****CPI in in 2010 was 100
gen inflation=1+((183.893-100)/100)
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


save "$merge\W1_AG_Plot_Level_Land_Variables_All.dta", replace 

gen plot_cert=.
gen wave=1



//create categorical variables 
gen plot_own_gender=.
replace plot_own_gender=1 if male_only_plot_own2==1
replace plot_own_gender=2 if fem_only_plot_own2==1
replace plot_own_gender=3 if mixed_gen_plot_own2==1
la var plot_own_gender "1 if male only, 2 if female only, 3 if mixed gender" 



////PLOT LEVEL EXPORT TO EXCEL FOR TABLEAU
export excel hhid plotid state plot_cert hoh_fem hoh_age hoh_literate ///
plot_area plot_area_owned plot_area_notowned  ///
plot_own_gender fem_plot_own2 fem_only_plot_own2 male_only_plot_own2 mixed_gen_plot_own2 ownership_owned ///
dailycons poverty125 poverty2 wave using "\\evansfiles\files\Project\EPAR\Working Files\357 - Land Reform Review\Tableau\Excel\NG_W1_Plot.xls", sheetmodify firstrow(varlabel)

keep hhid plotid state plot_cert hoh_fem hoh_age hoh_literate ///
plot_area plot_area_owned plot_area_notowned  ///
plot_own_gender fem_plot_own2 fem_only_plot_own2 male_only_plot_own2 mixed_gen_plot_own2 ownership_owned ///
dailycons poverty125 poverty2 wave

save "$merge\NG_W1_tableau.dta", replace 

//////////////////////////////////////////////////////////////////////////////
// 			5. Other land tenure indicator variables at HH Level	         //
/////////////////////////////////////////////////////////////////////////////

//// Collapse plot-level data to HH level//
clear
use "$merge\W1_AG_Plot_Level_Land_Variables_All.dta"

local sum_vars plot_area plot_area_owned plot_area_notowned ownership_owned ownership_usedfree ownership_rented fem_plot_own2 fem_only_plot_own2 male_only_plot_own2 mixed_gen_plot_own2
local hoh_vars hoh_fem hoh_literate hoh_age
collapse `hoh_vars' (max) number_plots (firstnm) clusterid strataid (sum) `sum_vars', by (hhid) 


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


save "$collapse\W1_Plot_HH_sum_collapse.dta", replace
