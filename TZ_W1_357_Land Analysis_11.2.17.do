*Title/Purpose of Do File: Tanzania LSMS-ISA (2008-13) - Land Tenure Analysis (Project #357)
*Author(s): Maggie Beetstra, Max McDonald, Emily Morton, Pierre Biscaye

clear
set more off
global input1 "\\evansfiles\Files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2008\Raw Data\Data - Agricultural Module Original" 
global input2 "\\evansfiles\Files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2008\Raw Data\Data - Household Module Original"
global input3 "\\evansfiles\Files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2008\Raw Data\Data - Community Module Original"
global input4 "\\evansfiles\Files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2008\Raw Data\Data - Geovariables"
global merge "\\evansfiles\files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2008\Merged Data"
global collapse "\\evansfiles\files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2008\Collapse Data" 
global output "R:\Project\EPAR\Working Files\357 - Land Reform Review\Output" 

//////////////////////////////////////////////////////////////////////////////
// 			1. Merge LRS and SRS Plot Roster and Details 					//
//////////////////////////////////////////////////////////////////////////////

***SECTIONS 2A & 2B (PLOT ROSTER)***
clear
use "$input1\SEC_2B"

//Dropping households that did not list unique plots in the SRS so we can merge this with 2A. Since no observations match, we are appending these data onto section 2A.
drop if plotnum=="" //86 unique observations remain, 0 observations deleted

append using "$input1\SEC_2A", gen(_merge_SEC_2A_2B)

*merge m:1 hhid plotnum using "$input1\AG_SEC_2A", generate (_merge_SEC_2A_2B) 
*0 matched, 86 not matched from master (2B), 5,128 not matched from using (2A) 
*Result is 5,214 unique plots

save "$merge\SEC_2A_2B_HH_PLOT.dta", replace

***SECTIONS 3A & 3B (PLOT DETAILS)***

clear 
use "$input1\SEC_3B"

// Dropping households that did not list unique plots in the SRS so we can merge this with 3A. Since no observations match, we are appending these data onto section 3A.
drop if plotnum!="V1" & plotnum!="V2" //27 unique observations remain 

*append using "$input1\SEC_3A", generate (_merge_SEC_3A_3B) 

merge m:1 hhid plotnum using "$input1\SEC_3A", generate (_merge_SEC_3A_3B) 
*0 matched, 80 not matched from master (3B), 5,126 not matched from using (3A) 
*Result is 5,206 unique plots 

**check HH IDs of plot decision-makers, owners, and users to determine how much individual-level information to retain from AG HH Roster
//who decided what to plant 
tab s3aq6_1
tab s3aq6_2
tab s3aq6_3
tab s3bq6_1
tab s3bq6_2
tab s3bq6_3
*highest is 9
//who owns the plot
tab s3aq27_1
tab s3aq27_2
tab s3bq27_1
tab s3bq27_1
*highest is 10 
//who has rights to use plot - Not availale in wave 1


save "$merge\SEC_3A_3B_HH_PLOT.dta", replace

***SECTION 1 (AG HH ROSTER)***

clear
use "$input1\SEC_1_ALL"

**Generate variables for gender of each HH member up to #10
foreach x of numlist 1/10 {
	gen hhmem_fem_`x'=.
	replace hhmem_fem_`x'=0 if rosterid==`x' & s1q3==1 
	replace hhmem_fem_`x'=1 if rosterid==`x' & s1q3==2 
} 

**Generate variables for age of each HH member up to 22nd (no HH member beyond #22 listed as a plot owner)
foreach x of numlist 1/10 {
	gen hhmem_age_`x'=.
	replace hhmem_age_`x'=s1q2 if rosterid==`x'  
} 

gen hoh_fem=0
replace hoh_fem=1 if rosterid==1 & s1q3==2


gen hoh_age=s1q2 if rosterid==1
 

local maxvars hhmem_fem_* hhmem_age_* hoh_fem hoh_age
collapse (max) `maxvars', by (hhid)

save "$collapse/AG_indy_collapse.dta", replace

***MERGING ALL HH-PLOT LEVEL DATA TOGETHER***

clear
use "$merge\SEC_3A_3B_HH_PLOT.dta"

//Merge in sections 2A & 2B
merge 1:1 hhid plotnum using "$merge\SEC_2A_2B_HH_PLOT", generate (_merge_SEC_2A_2B_Final)
*5,198 matched, 8 not matched 

//Merge in HH information
merge m:1 hhid using "\\evansfiles\Files\Project\EPAR\Tanzania LSMS-ISA 2012-13 DATA\357 Land Tenure Reform\2008 data\Data - Household Module Original\SEC_A_T.dta", generate (_merge_HH_SEC_A_HH_PLOT)
*5,214 matched, 968 not matched (from using) 

//Merge in HH Plot Roster
merge m:1 hhid using "$collapse/AG_indy_collapse.dta", generate (_merge_AG_SEC_1_HH) keep(3)
*5,346 matched; 0 not matched

save "$merge\AG_plot-level_merge.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			2. Generate Land Tenure Variables	at Plot Level				//
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge\AG_plot-level_merge.dta"

generate number_plots = 1

gen plot_cultivated =1 if s3aq36==1
replace plot_cultivated =0 if s3aq36==2
la var plot_cultivated "plot cultivated during LRS 2008 (s3aq36)"

////////LAND TITLE

gen plot_title_proportion = s3aq26
replace plot_title_proportion = s3bq26 if plot_title_proportion==. & s3bq26!=.
la var plot_title_proportion "Type of title held for plot, 2008"

**Title Held
gen plot_title_held = .
replace plot_title_held = 0 if s3aq25==2 | s3bq25==2 
replace plot_title_held = 1 if  s3aq25==1 | s3bq25==1 
la var plot_title_held "HH has a title for plot, 2008"


////////////Plot size 

gen plotsize_acres = s2aq4
la var plotsize_acres "(s2a4q) farmer reported plot size in acres"

gen plotsize_ha = plotsize_acres* 0.404685642
la var plotsize_ha "(s2aq4) farmer reported plot size in hectares"

gen plotsize_acres_SRS = s2bq9
la var plotsize_acres_SRS "(s2aq9) farmer reported plot size in acres for SRS"

gen plotsize_ha_SRS = plotsize_acres_SRS* 0.404685642
la var plotsize_ha_SRS "(s2aq9) farmer reported plot size in hectares"


** make the area measure we will use for yield and area calculations:
gen plot_area = plotsize_ha //218 missing
replace plot_area = plotsize_ha_SRS if plot_area==. //86 changes
la var plot_area "plot area measure, LRS and SRS, 2008"

////////////PLOT OWNERSHIP

gen ownership_owned=.
replace ownership_owned = 1 if s3aq22==1
replace ownership_owned = 0 if s3aq22!=1 & s3aq22!=.
replace ownership_owned = 1 if s3aq22==1
replace ownership_owned = 0 if s3aq22!=1 & s3bq22!=.
label var ownership_owned "Did you own this plot (s3aq22, s3bq22)"

gen ownership_usedfree=.
replace ownership_usedfree = 1 if s3aq22==2
replace ownership_usedfree = 0 if s3aq22!=2 & s3aq22!=.
replace ownership_usedfree = 1 if s3bq22==2
replace ownership_usedfree = 0 if s3bq22!=2 & s3bq22!=.
label var ownership_usedfree "Did you use this plot free of charge (s3aq22, s3bq22)"

gen ownership_rentedin=.
replace ownership_rentedin = 1 if s3aq22==3
replace ownership_rentedin = 0 if s3aq22!=3 & s3aq22!=.
replace ownership_rentedin = 1 if s3bq22==3
replace ownership_rentedin = 0 if s3bq22!=3 & s3bq22!=.
label var ownership_rentedin "Did you rent in this plot (s3aq22, s3bq22)"

gen ownership_sharedrent=.
replace ownership_sharedrent = 1 if s3aq22==4
replace ownership_sharedrent = 0 if s3aq22!=4 & s3aq22!=.
replace ownership_sharedrent = 1 if s3bq22==4
replace ownership_sharedrent = 0 if s3bq22!=4 & s3bq22!=.
label var ownership_sharedrent "Did you share rent on this plot (s3aq22, s3bq22)"

gen ownership_sharedown=.
replace ownership_sharedown = 1 if s3aq22==5
replace ownership_sharedown = 0 if s3aq22!=5 & s3aq22!=.
replace ownership_sharedown = 1 if s3bq22==5
replace ownership_sharedown = 0 if s3bq22!=5 & s3bq22!=.
label var ownership_sharedown "Did you share ownership on this plot (s3aq22, s3bq22)"

gen ownership_rent2=.
replace ownership_rent2=1 if ownership_sharedrent==1 | ownership_rentedin==1
replace ownership_rent2=0 if ownership_sharedrent==0 & ownership_rentedin==0
label var ownership_rent2 "Plot is rented in or shared rented in (s3aq22, s3bq22)"

gen ownership_own2=.
replace ownership_own2=1 if ownership_owned==1 | ownership_sharedown==1
replace ownership_own2=0 if ownership_owned==0 & ownership_sharedown==0
label var ownership_own2 "Plot is owned or shared owned (s3aq22, s3bq22)"

//////////////////PLOT OWNERSHIP BY GENDER

gen fem_plot_owner = .
la var fem_plot_owner "First listed plot owner is female"
foreach x of numlist 1/10 {
	replace fem_plot_owner = 0 if s3aq27_1 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_owner = 1 if s3aq27_1 == `x' & hhmem_fem_`x' == 1 
	replace fem_plot_owner = 0 if s3bq27_1 == `x' & hhmem_fem_`x' == 0
	replace fem_plot_owner = 1 if s3bq27_1 == `x' & hhmem_fem_`x' == 1
} 

gen fem_plot_co_owner = .
la var fem_plot_co_owner "Second listed plot owner is female"

foreach x of numlist 1/10 {
	replace fem_plot_co_owner = 0 if s3aq27_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_co_owner = 1 if s3aq27_2 == `x' & hhmem_fem_`x' == 1 
	replace fem_plot_co_owner = 0 if s3bq27_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_co_owner = 1 if s3bq27_2 == `x' & hhmem_fem_`x' == 1 
} 

// Plots with at least one female owner
generate fem_plot_owned = .
replace fem_plot_owned = 0 if fem_plot_owner == 0 | fem_plot_co_owner == 0
replace fem_plot_owned = 1 if fem_plot_owner == 1 | fem_plot_co_owner == 1 //  instances of female owned or co-owned plots
label variable fem_plot_owned "Plot owned or co-owned by females"

// Female only owned plots
generate fem_only_plot_own = .
replace fem_only_plot_own = 0 if (fem_plot_owner == 0 | fem_plot_co_owner == 0) 
replace fem_only_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 1) | (fem_plot_owner == 1 & fem_plot_co_owner==.) 
label variable fem_only_plot_own "Female-only owned plot"


// Male only owned plots
generate male_only_plot_own = .
replace male_only_plot_own = 0 if (fem_plot_owner == 1 | fem_plot_co_owner == 1)
replace male_only_plot_own = 1 if (fem_plot_owner == 0 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == .) // females could be either missing or not listed in either case (owner or co-owner)   
label variable male_only_plot_own "Male-only owned plot"

// Mixed gender ownership plots
generate mixed_gen_plot_own = .
replace mixed_gen_plot_own = 0 if male_only_plot_own == 1 | fem_only_plot_own == 1
replace mixed_gen_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == 1) // requires two owners, of different gender (i.e., specifically one female owner)
label variable mixed_gen_plot_own "Plot with mixed gender ownership"



//create plot weights, household weight (hh_weight) times plot area, as per World Bank practice 
gen plot_weight = hh_weight*plot_area

////////////////////Save plot level variables
save "$merge\TZ_W1_AG_Plot_Level_Land_Variables.dta", replace  


//////////////////////////////////////////////////////////////////////////////
// 			3. Summary Statistics at Plot Level						        //
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge\TZ_W1_AG_Plot_Level_Land_Variables.dta"
svyset clusterid [pweight=plot_weight], strata(strataid)


**Summary stats for fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own

eststo plots1: svy: mean fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own						
eststo plots1a: svy: mean fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own if plot_title_held==1		
eststo plots1b: svy: mean fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own if plot_title_held==0		
esttab plots1 plots1a plots1b using "$output/TZ_w1_plot_table1.rtf", cells(b(fmt(3)) & se(fmt(3) par)) label mlabels("All Owned Plots" "Owned plots with a Legal Title" "Owned plots with No Legal Title" ) collabels(none) title("Table 1. Proportion of owned plots by gender and title")  /// 
note("Respondents were asked to specify up to two household members as plot owners, typically with the head of household listed first. The sample excludes plots rented in or used free of charge, and two owned plots with missing data on gender of the plot owner. Estimates are plot-level cluster-weighted means, with standard errors in parentheses.") replace


//////////////////////////////////////////////////////////////////////////////
// 			4. Other land tenure indicator variables	                    //
/////////////////////////////////////////////////////////////////////////////

/////////////LAND TITLE//////////
//Posession of title by title type
***Creating dummy variables for each category of land title

gen title_granted_right_occupancy = .
replace title_granted_right_occupancy = 1 if plot_title_proportion==1
replace title_granted_right_occupancy = 0 if plot_title_proportion!=1 & plot_title_proportion!=.
replace title_granted_right_occupancy = 0 if s3aq25==2| s3bq25==2 
la var title_granted_right_occupancy "HH was granted right of occupancy for plot, 2008"

gen title_customary_right_occupancy = . 
replace title_customary_right_occupancy = 1 if plot_title_proportion==2
replace title_customary_right_occupancy = 0 if plot_title_proportion!=2 & plot_title_proportion!=.
replace title_customary_right_occupancy = 0 if s3aq25==2| s3bq25==2 
la var title_customary_right_occupancy "HH has certificate of customary right of occupancy for plot, 2008"

gen title_resid_license = .
replace title_resid_license = 1 if plot_title_proportion==3
replace title_resid_license = 0 if plot_title_proportion!=3 & plot_title_proportion!=.
replace title_resid_license = 0 if s3aq25==2| s3bq25==2 
la var title_resid_license "HH has residential license for plot, 2008"

gen title_village_gov_agreement = . 
replace title_village_gov_agreement = 1 if plot_title_proportion==4
replace title_village_gov_agreement = 0 if plot_title_proportion!=4 & plot_title_proportion!=.
replace title_village_gov_agreement = 0 if s3aq25==2| s3bq25==2 
la var title_village_gov_agreement "HH has village govt-witnessed purchase agreement for plot, 2008"

gen title_court_cert_agreement = .
replace title_court_cert_agreement = 1 if plot_title_proportion==5
replace title_court_cert_agreement = 0 if plot_title_proportion!=5 & plot_title_proportion!=.
replace title_court_cert_agreement = 0 if s3aq25==2| s3bq25==2 
la var title_court_cert_agreement "HH has local court-certified purchase agreement for plot, 2008"

gen title_inheritance_ltr = . 
replace title_inheritance_ltr = 1 if plot_title_proportion==6
replace title_inheritance_ltr = 0 if plot_title_proportion!=6 & plot_title_proportion!=.
replace title_inheritance_ltr = 0 if s3aq25==2| s3bq25==2 
la var title_inheritance_ltr "HH has inheritance letter for plot, 2008"

gen title_allocation_ltr = . 
replace title_allocation_ltr = 1 if plot_title_proportion==7
replace title_allocation_ltr = 0 if plot_title_proportion!=7 & plot_title_proportion!=.
replace title_allocation_ltr = 0 if s3aq25==2| s3bq25==2 
la var title_allocation_ltr "HH has village govt letter of allocation for plot, 2008"

gen title_other_gov_doc = . 
replace title_other_gov_doc = 1 if plot_title_proportion==8
replace title_other_gov_doc = 0 if plot_title_proportion!=8 & plot_title_proportion!=.
replace title_other_gov_doc = 0 if s3aq25==2| s3bq25==2 
la var title_other_gov_doc "HH has other govt document for plot, 2008"

gen title_official_corres = . 
replace title_official_corres = 1 if plot_title_proportion==9
replace title_official_corres = 0 if plot_title_proportion!=9 & plot_title_proportion!=.
replace title_official_corres = 0 if s3aq25==2| s3bq25==2 
la var title_official_corres "HH has official correspondence for plot, 2008"

gen title_utility_bill = .
replace title_utility_bill = 1 if plot_title_proportion==10
replace title_utility_bill = 0 if plot_title_proportion!=10 & plot_title_proportion!=.
replace title_utility_bill = 0 if s3aq25==2 | s3bq25==2 
la var title_utility_bill "HH has utility or other bill for plot, 2008"

gen no_title = .
replace no_title = 0 if  s3aq25==1 | s3bq25==1 
replace no_title = 1 if s3aq25==2 | s3bq25==2 
la var no_title "HH has no title for plot, 2008"

/////////////PLOT SIZE/////////

**Plot area by ownership status
gen plot_area_owned = plot_area if s3aq22 == 1 | s3aq22 == 5 | s3bq22 == 1 | s3bq22 == 5
la var plot_area_owned "Plot area, owned plot, ha, 2008"

gen plot_area_notowned = plot_area if s3aq22 != 1 & s3aq22 != 5 & s3bq22 != 1 & s3bq22 != 5
la var plot_area_notowned "Plot area, not owned plot, ha, 2008"

gen plot_area_rentedin = plot_area if s3aq22 == 3 | s3aq22 == 4 | s3bq22 == 3 | s3bq22 == 4
la var plot_area_rentedin "Plot area, rented in plot, ha, 2008"

gen plot_area_usedfree = plot_area if s3aq22 == 2 | s3aq22 == 2
la var plot_area_usedfree "Plot area, used free of charge plot, ha, 2008"

gen plot_area_rentedout = plot_area if s3aq3 == 2 | s3aq3 == 2
la var plot_area_rentedout "Plot area, rented out, ha, 2008"


////////////VALUE OF PLOTS//////

// Value of owned plots - Respondent's estimate
// Values should be captured only for plots that are counted as owned or shared
// -owned (i.e., if s3aq22 == 1 or s3aq22 == 2). 

generate value_owned_plot= .
replace value_owned_plot= s3aq21 if s3aq22 == 1 | s3aq22 == 5
replace value_owned_plot= s3bq21 if s3bq22 == 1 | s3bq22 == 5
la var value_owned_plot "Estimated value of plot if sold today, TSH"


///////////NUMBER OF SECURE PLOTS OWNED
generate plot_security = . 
replace plot_security = 0 if s3aq35 == 2 | s3bq35 == 2
replace plot_security = 1 if s3aq35 == 1 | s3bq35 == 1
la var plot_security "Respondent comfortable leaving plot uncultivated several months"


//////Number of plots owned where owner has right to sell or use as collateral: LRS and SRS
generate plot_right_sell = . 
replace plot_right_sell = 0 if s3aq28 == 2 | s3bq28 == 2
replace plot_right_sell = 1 if s3aq28 == 1 | s3bq28 == 1
la var plot_right_sell "HH has right to sell plot or use as collateral"

/////////////PLOT OWNERSHIP BY AGE //////////////////
gen age_plot_owner = .
la var age_plot_owner "Age of first listed plot owner"
foreach x of numlist 1/10 {
	replace age_plot_owner=hhmem_age_`x' if s3aq27_1 == `x' 
	replace age_plot_owner=hhmem_age_`x' if s3bq27_1 == `x' 
} 

gen age_plot_co_owner = .
la var age_plot_co_owner "Age of second listed plot owner"
foreach x of numlist 1/10 {
	replace age_plot_co_owner=hhmem_age_`x' if s3aq27_2 == `x' 
	replace age_plot_co_owner=hhmem_age_`x' if s3bq27_2 == `x' 
} 

gen age_plot_owner_fem=age_plot_owner if fem_plot_owner == 1
replace age_plot_owner_fem=age_plot_co_owner if fem_plot_co_owner == 1 & age_plot_owner_fem==.
la var age_plot_owner_fem "Age of first listed female owner, if any"

gen age_plot_owner_male=age_plot_owner if fem_plot_owner == 0
replace age_plot_owner_male=age_plot_co_owner if fem_plot_co_owner == 0 & age_plot_owner_male==.
la var age_plot_owner_male "Age of first listed male owner, if any"

*Generating dummy variable for first position plot owner age categories
generate age_plot_owner_10_24 = .
replace age_plot_owner_10_24=0 if (age_plot_owner <10 | age_plot_owner>24) & age_plot_owner!=.
replace age_plot_owner_10_24=1 if age_plot_owner >=10 & age_plot_owner <= 24
label variable age_plot_owner_10_24 "First listed plot owner between the ages of 10 and 24, 2008"

generate age_plot_owner_25_34 = .
replace age_plot_owner_25_34=0 if (age_plot_owner<25 | age_plot_owner>34) & age_plot_owner!=.
replace age_plot_owner_25_34=1 if age_plot_owner >=25 & age_plot_owner <= 34
label variable age_plot_owner_25_34 "First listed plot owner between the ages of 25 and 34, 2008"

generate age_plot_owner_35_44 = .
replace age_plot_owner_35_44=0 if (age_plot_owner<35 | age_plot_owner>44) & age_plot_owner!=.
replace age_plot_owner_35_44=1 if age_plot_owner >=35 & age_plot_owner <= 44
label variable age_plot_owner_35_44 "First listed plot owner between the ages of 35 and 44, 2008"

generate age_plot_owner_45_54 = .
replace age_plot_owner_45_54=0 if (age_plot_owner<45 | age_plot_owner>54) & age_plot_owner!=.
replace age_plot_owner_45_54=1 if age_plot_owner >=45 & age_plot_owner <= 54
label variable age_plot_owner_45_54 "First listed plot owner between the ages of 45 and 54, 2008"

generate age_plot_owner_55_over = .
replace age_plot_owner_55_over=0 if (age_plot_owner<55)
replace age_plot_owner_55_over=1 if age_plot_owner >=55 & age_plot_owner != .
label variable age_plot_owner_55_over "First listed plot owner aged 55 and above, 2008"

*Generating dummy variable for either position plot owner age categories
generate age_plot_any_owner_10_24 = .
replace age_plot_any_owner_10_24=0 if ((age_plot_owner <10 | age_plot_owner>24) & age_plot_owner!=.) | ((age_plot_co_owner <10 | age_plot_co_owner>24) & age_plot_owner!=.)
replace age_plot_any_owner_10_24=1 if (age_plot_owner >=10 & age_plot_owner <= 24) | (age_plot_co_owner >=10 & age_plot_co_owner <= 24)
label variable age_plot_any_owner_10_24 "Plot owners between the ages of 10 and 24"

generate age_plot_any_owner_25_34 = .
replace age_plot_any_owner_25_34=0 if ((age_plot_owner <25 | age_plot_owner>34) & age_plot_owner!=.) | ((age_plot_co_owner <25 | age_plot_co_owner>34) & age_plot_owner!=.)
replace age_plot_any_owner_25_34=1 if (age_plot_owner >=25 & age_plot_owner <= 34) | (age_plot_co_owner >=25 & age_plot_co_owner <= 34) 
label variable age_plot_any_owner_25_34 "Plot owners between the ages of 25 and 34"

generate age_plot_any_owner_35_44 = .
replace age_plot_any_owner_35_44=0 if ((age_plot_owner <35 | age_plot_owner>44) & age_plot_owner!=.) | ((age_plot_co_owner <35 | age_plot_co_owner>44) & age_plot_owner!=.)
replace age_plot_any_owner_35_44=1 if (age_plot_owner >=35 & age_plot_owner <= 44) | (age_plot_co_owner >=35 & age_plot_co_owner <= 44)
label variable age_plot_any_owner_35_44 "Plot owners between the ages of 35 and 44"

generate age_plot_any_owner_45_54 = .
replace age_plot_any_owner_45_54=0 if ((age_plot_owner <45 | age_plot_owner>54) & age_plot_owner!=.) | ((age_plot_co_owner <45 | age_plot_co_owner>54) & age_plot_owner!=.)
replace age_plot_any_owner_45_54=1 if (age_plot_owner >=45 & age_plot_owner <= 54) | (age_plot_co_owner >=45 & age_plot_co_owner <= 54)
label variable age_plot_any_owner_45_54 "Plot owners between the ages of 45 and 54"

generate age_plot_any_owner_55_over = .
replace age_plot_any_owner_55_over=0 if (age_plot_owner <55 & age_plot_owner !=. ) | (age_plot_co_owner <55 & age_plot_co_owner != .)
replace age_plot_any_owner_55_over=1 if (age_plot_owner >=55 & age_plot_owner !=. ) | (age_plot_co_owner >=55 & age_plot_co_owner != .)
label variable age_plot_any_owner_55_over "Plot owners aged 55 and above"


//////////////PLOT CULTIVATION DECISION MAKER BY GENDER 
gen fem_cult_dec_mkr = .
la var fem_cult_dec_mkr "First cultivation decision-maker is female"
foreach x of numlist 1/10 {
	replace fem_cult_dec_mkr = 0 if s3aq6_1 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr = 1 if s3aq6_1 == `x' & hhmem_fem_`x' == 1 
	replace fem_cult_dec_mkr = 0 if s3bq6_1 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr = 1 if s3bq6_1 == `x' & hhmem_fem_`x' == 1 
} 

gen fem_cult_dec_mkr2 = .
la var fem_cult_dec_mkr2 "Second cultivation decision-maker is female"

foreach x of numlist 1/10 {
	replace fem_cult_dec_mkr2 = 0 if s3aq6_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr2 = 1 if s3aq6_2 == `x' & hhmem_fem_`x' == 1
	replace fem_cult_dec_mkr2 = 0 if s3bq6_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr2 = 1 if s3bq6_2 == `x' & hhmem_fem_`x' == 1
} 

gen fem_cult_dec_mkr3 = .
la var fem_cult_dec_mkr3 "Third cultivation decision-maker is female"

foreach x of numlist 1/10 {
	replace fem_cult_dec_mkr3 = 0 if s3aq6_3 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr3 = 1 if s3aq6_3 == `x' & hhmem_fem_`x' == 1
	replace fem_cult_dec_mkr3 = 0 if s3bq6_3 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr3 = 1 if s3bq6_3 == `x' & hhmem_fem_`x' == 1
} 

// Generate # of female decision makers for what is planted 
egen fem_cult_dec_mkr_obs = rowtotal(fem_cult_dec_mkr fem_cult_dec_mkr2 fem_cult_dec_mkr3)
replace fem_cult_dec_mkr_obs=. if fem_cult_dec_mkr==. & fem_cult_dec_mkr2==. & fem_cult_dec_mkr3==.
tab fem_cult_dec_mkr_obs //  no females,  1 female,  2 females,  3 females
la var fem_cult_dec_mkr_obs "Number of female cultivation decision-makers on plot"



//////////////LAND USE DECISION MAKER BY GENDER 
**question not asked in Wave 1

////////////////COST OF RENTED IN PLOTS 
// We want to use ag3a_32 (How much in t-shillings?), ag3a_33_1 (frequency paid)
// and ag3a_33_2 (period: 1 = months, 2 = years).
// Working assumption here is that missing values means that the household paid zero rent to use a plot. 

generate rent_in_plot_LRS = s3aq30 
replace rent_in_plot_LRS = 0 if rent_in_plot_LRS == . // 6,007 real changes made; 0 to missing
replace rent_in_plot_LRS = (rent_in_plot_LRS/s3aq31_idadi) if s3aq31_meas== 2 //replace with annual average if payment covered more than 1 year; leave payment total as is if reported period covered is in months

generate rent_in_plot_SRS = s3bq30
replace rent_in_plot_SRS = 0 if rent_in_plot_SRS == .
replace rent_in_plot_SRS = (rent_in_plot_SRS/(s3bq31_idadi)) if s3bq31_meas == 2 //replace with annual average if payment covered more than 1 year; leave payment total as is if reported period covered is in months

gen rent_in_plot_cost = rent_in_plot_SRS + rent_in_plot_LRS
la var rent_in_plot_cost "Cost to rent in plot in last year"

//////////////////INCOME FROM RENTING OUT PLOTS

gen plot_rented_out=.
replace plot_rented_out=1 if s3aq3==2 
replace plot_rented_out=1 if s3bq3==2
replace plot_rented_out=0 if (s3aq3!=2 & s3aq3!=.) | (s3bq3!=2 & s3bq3!=.)
la var plot_rented_out "Plot was rented out during LRS or SRS"

generate plot_rental_income_LRS = 0
replace plot_rental_income_LRS = s3aq4 if s3aq4 != .

generate plot_rental_income_SRS = 0
replace plot_rental_income_SRS = s3bq4 if s3bq4 != .

gen plot_rental_income_total=plot_rental_income_SRS+plot_rental_income_LRS
la var plot_rental_income_total "Income from renting out plot in last year"


////////OTHER PLOT CLASSIFICATION VARIABLES
gen plot_own_title=0
replace plot_own_title=1 if plot_title_held==1
replace plot_own_title=0 if s3aq25==. & s3bq25==.
la var plot_own_title "HH owns plot and has a title"

gen plot_own_notitle=0
replace plot_own_notitle=1 if no_title==1
replace plot_own_notitle=0 if s3aq25==. & s3bq25==.
la var plot_own_notitle "HH owns plot but has no title"

gen plot_notown=0
replace plot_notown=1 if s3aq25==. & s3bq25==.
la var plot_notown "HH does not own the plot"

generate plot_rightsell = 0 
replace plot_rightsell = 1 if plot_right_sell == 1
la var plot_rightsell "HH has right to sell plot or use as collateral"


///////HH CONSUMPTION//////

merge m:1 hhid using "$input4\TZY1.HH.Consumption.dta", gen (_merge_HHConsumption_2008)

*Expenditure per adult equivalent in the household
gen consum_per_adult = .
replace consum_per_adult = expmR/adulteq  //total HH consumption, annual, nominal, divided by adult-equivalents in the HH

*Daily expenditure per adult equivalent in the household
gen consum_per_adult_daily = .
replace consum_per_adult_daily = consum_per_adult/365

****2016 implied PPP Conversion Rate is 685.72
****CPI in 2016 was 166.191
****CPI in in 2008 was 83.966
gen inflation=1+((166.191-83.966)/83.966)
gen usd_tzs_exchange=685.72

*Convert the expenditure values from Tanzanian Shillings to US Dollars
gen dailycons=consum_per_adult_daily*inflation/usd_tzs_exchange
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

gen hoh_literate=.
gen wave=1

save "$merge\TZ_W1_Plot_Level_All.dta", replace

//creating categorical variables
gen gender_plot_owner=.
replace gender_plot_owner=1 if male_only_plot_own==1
replace gender_plot_owner=2 if fem_only_plot_own==1
replace gender_plot_owner=3 if mixed_gen_plot_own==1
label var gender_plot_owner "1 is male only, 2 if female only, 3 is mixed"


////PLOT LEVEL EXPORT TO EXCEL FOR TABLEAU
export excel hhid plotnum region plot_title_held hoh_fem hoh_age hoh_literate ///
plot_area plot_area_owned plot_area_notowned  ///
gender_plot_owner fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own ownership_own2 ///
dailycons poverty125 poverty2 wave using "\\evansfiles\files\Project\EPAR\Working Files\357 - Land Reform Review\Tableau\Excel\TZ_W1_Plot.xls", sheetmodify firstrow(varlabel)

keep hhid plotnum region plot_title_held hoh_fem hoh_age hoh_literate ///
plot_area plot_area_owned plot_area_notowned  ///
gender_plot_owner fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own ownership_own2 ///
dailycons poverty125 poverty2 wave

save "$merge\TZ_W1_tableau.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			5. Other land tenure indicator variables at HH Level	         //
/////////////////////////////////////////////////////////////////////////////

//// Collapse plot-level data to HH level//
clear
use "$merge\TZ_W1_Plot_Level_All.dta"

local sum_vars number_plots plot_title_held plot_area plot_area_owned plot_area_notowned plot_area_rentedin plot_area_usedfree plot_area_rentedout ///
ownership_owned ownership_sharedown ownership_usedfree ownership_rentedin ownership_sharedrent ownership_rent2 ownership_own2 /// 
value_owned_plot plot_security plot_right_sell fem_plot_owned rent_in_plot_cost plot_rented_out plot_rental_income_total 
collapse (firstnm) clusterid strataid hh_weight (sum) `sum_vars', by (hhid) 
 

la var number_plots "(sum) Total number of plots for the household"
la var plot_title_held "(sum) Plots for which household held a title"
la var plot_area "(sum) Plot area measure, all plots, ha"
la var plot_area_owned "(sum) Plot area, owned plots, ha"
la var plot_area_notowned "(sum) Plot area, not owned plots, ha"
la var plot_area_rentedin "(sum) Plot area, rented in plots, ha"
la var plot_area_usedfree "(sum) Plot area, used free of charge plots, ha"
la var plot_area_rentedout "(sum) Plot area, rented out, ha"
label var ownership_owned "(sum) Number of plots owned"
label var ownership_usedfree "(sum) Number of plots used free of charge"
label var ownership_rentedin "(sum) Number of plots rented in"
label var ownership_sharedrent "(sum) Number of plots rented in and shared"
label var ownership_sharedown "(sum) Number of plots owned and shared"
label var ownership_rent2 "(sum) Number of plots rented in or rented in and shared"
label var ownership_own2 "(sum) Number of plots owned or owned and shared"
la var value_owned_plot "(sum) Estimated value of owned plots if sold today, TSH"
la var plot_security "(sum) Number of plots the respondent is comfortable leaving uncultivated several months"
la var plot_right_sell "(sum) Number of plots HH has right to sell or use as collateral"
label variable fem_plot_owned "(sum) Number of plots owned or co-owned by females"
la var rent_in_plot_cost "(sum) Cost to rent in plots in last year"
la var plot_rented_out "(sum) Number of plots rented out"
la var plot_rental_income_total "(sum) Income from renting out plots in last year"

save "$collapse\W1_Plot_HH_sum_collapse.dta", replace

////SMALLHOLDER////

gen smallholder2 = .
replace smallholder2 = 1 if plot_area <=2
replace smallholder2 = 0 if plot_area >2 & plot_area!= . 
la var smallholder2 "total area 2ha or less"

gen smallholder2_owned = .
replace smallholder2_owned = 1 if plot_area_owned <=2
replace smallholder2_owned = 0 if plot_area_owned >2 & plot_area_owned!= . 
la var smallholder2 "total area owned 2ha or less"


/////HOH GENDER
clear
use "$input2\SEC_B_C_D_E1_F_G1_U.dta"

gen hoh_sex=.
replace hoh_sex=0 if sbq2==1 & sbmemno==1
replace hoh_sex=1 if sbq2==2 & sbmemno==1

collapse (max) hoh_sex, by (hhid) 

la var hoh_sex "Sex of the head of household"

save "$collapse\w1_HoH_sex_collapse.dta", replace

////////Merge in HHs that did not complete ag section
clear
use "$input2\SEC_A_T.dta"

merge 1:1 hhid using "$collapse\W1_Plot_HH_sum_collapse.dta", gen (_merge_ag_hh) 
**2,429 matched, 836 not matched from master - did not complete ag questionnaire

merge 1:1 hhid using "$collapse\w1_HoH_sex_collapse.dta", gen (_merge_hoh) 
**3265 matched

//Turning the value variables into thousands to help with presentation in table form
replace value_owned_plot = value_owned_plot/1000
la var value_owned_plot "(sum) Estimated value of owned plots if sold today, TSH (1000s)"
replace rent_in_plot_cost=rent_in_plot_cost/1000
la var rent_in_plot_cost "(sum) Cost to rent in plots in last year, TSH (1000s)"
replace plot_rental_income_total = plot_rental_income_total/1000
la var plot_rental_income_total "(sum) Income from renting out plots in last year, TSH (1000s)"

//Replace missings with 0s
foreach var of varlist number_plots plot_title_held plot_area plot_area_owned plot_area_notowned plot_area_rentedin plot_area_usedfree plot_area_rentedout ///
ownership_owned ownership_sharedown ownership_usedfree ownership_rentedin ownership_sharedrent ownership_rent2 ownership_own2 value_owned_plot ///
plot_security plot_right_sell fem_plot_owned rent_in_plot_cost plot_rented_out plot_rental_income_total{
	replace `var'=0 if `var'==.
}

//

//Construct additional variables
**any plot ownership dummy 
gen ownership_any=0
replace ownership_any=1 if ownership_own2>0 & ownership_own2!=.
la var ownership_any "HH owns at least 1 plot"

**proportion of secure plots
gen plot_security_prop=plot_security/number_plots
la var plot_security_prop "Proportion of plots the HH is comfortable leaving uncultivated several months"

**proportion of plots with right to sell or use as collateral
gen plot_right_sell_prop=plot_right_sell/number_plots
la var plot_right_sell_prop "Proportion of plots HH has right to sell or use as collateral"

save "$merge\W1_Plot_HH_sum_collapse.dta", replace


//////////////////////////////////////////////////////////////////////////////
// 			6. Land Tenure Indivator Variables at Community Level          //
/////////////////////////////////////////////////////////////////////////////

clear
use "$input3\SEC_D.dta"

generate cert_village_lands = cd2 
recode cert_village_lands (2=0)
la var cert_village_lands "Village has Certificate of Village Lands, 2008" 

******************* Land appropriation and reallocation ************************

***** Direct Foreign Investment 
gen land_approp_dfi=cd4a 
recode land_approp_dfi (2=0)
gen land_approp_mth_dfi=cd5am 
gen land_approp_yr_dfi=cd5ay 
gen land_approp_hhs_dfi=cd6a 
replace land_approp_hhs_dfi=0 if land_approp_hhs_dfi==.
gen land_approp_comp_dfi=cd7a 

la var land_approp_dfi "Any land appropriated for dfi, 2008"
la var land_approp_mth_dfi "Month of land appropriation for dfi, 2008"
la var land_approp_yr_dfi "Year of land appropriation for dfi, 2008"
la var land_approp_hhs_dfi "# of HHs affected by appropriation for direct foreign investment, 2008"
la var land_approp_comp_dfi "Compensation per HH for appropriated land for dfi, 2008"


***** Land Reserves
gen land_approp_res=cd4b 
recode land_approp_res (2=0)
gen land_approp_mth_res=cd5bm 
gen land_approp_yr_res=cd5by 
gen land_approp_hhs_res=cd6b 
replace land_approp_hhs_res=0 if land_approp_hhs_res==.
gen land_approp_comp_res=cd7b 

la var land_approp_res "Any land appropriated for land reserves, 2008"
la var land_approp_mth_res "Month of land appropriation for land reserves, 2008"
la var land_approp_yr_res "Year of land appropriation for land reserves, 2008"
la var land_approp_hhs_res "# of HHs affected by appropriation for land reserves, 2008"
la var land_approp_comp_res "Compensation per HH for appropriated land for land reserves, 2008"


***** Public Use
gen land_approp_pubuse=cd4c 
recode land_approp_pubuse (2=0)
gen land_approp_mth_pubuse=cd5cm 
gen land_approp_yr_pubuse=cd5cy 
gen land_approp_hhs_pubuse=cd6c 
replace land_approp_hhs_pubuse=0 if land_approp_hhs_pubuse==.
gen land_approp_comp_pubuse=cd7c 

la var land_approp_pubuse "Any land appropriated for public use, 2008"
la var land_approp_mth_pubuse "Month of land appropriation for public use, 2008"
la var land_approp_yr_pubuse "Year of land appropriation for public use, 2008"
la var land_approp_hhs_pubuse "# of HHs affected by appropriation for public use, 2008"
la var land_approp_comp_pubuse "Compensation per HH for appropriated land for public use, 2008"

***** Land Use Variables

generate landuse_cult_ha = cd1a1*0.404685642
generate landuse_cult_pct = cd1a2 
replace landuse_cult_ha=0 if landuse_cult_ha==.
replace landuse_cult_pct=0 if landuse_cult_pct==.
replace landuse_cult_pct=0 if landuse_cult_pct==998
replace landuse_cult_pct=100 if landuse_cult_pct>100
la var landuse_cult_ha "Land use for cultivation, ha, 2008"
la var landuse_cult_pct "Percentage of land used cultivated, 2008"

generate landuse_agrobiz_ha = cd1b1*0.404685642
generate landuse_agrobiz_pct = cd1b2 
replace landuse_agrobiz_ha=0 if landuse_agrobiz_ha==.
replace landuse_agrobiz_pct=0 if landuse_agrobiz_pct==.
replace landuse_agrobiz_pct=0 if landuse_agrobiz_pct==998
replace landuse_agrobiz_pct=100 if landuse_agrobiz_pct>100
la var landuse_agrobiz_ha "Land used for agro-business, ha, 2008"
la var landuse_agrobiz_pct "Percentage of land used for agrobusiness, 2008"

generate landuse_forest_ha = cd1c1*0.404685642
generate landuse_forest_pct = cd1c2 
replace landuse_forest_ha=0 if landuse_forest_ha==.
replace landuse_forest_pct=0 if landuse_forest_pct==.
replace landuse_forest_pct=0 if landuse_forest_pct==998
replace landuse_forest_pct=100 if landuse_forest_pct>100
la var landuse_forest_ha "Land used for forests, ha, 2008"
la var landuse_forest_pct "Percentage of land used for forests, 2008"

generate landuse_grazing_ha = cd1d1*0.404685642 
generate landuse_grazing_pct = cd1d2 
replace landuse_grazing_ha=0 if landuse_grazing_ha==.
replace landuse_grazing_pct=0 if landuse_grazing_pct==.
replace landuse_grazing_pct=0 if landuse_grazing_pct==998
replace landuse_grazing_pct=100 if landuse_grazing_pct>100
la var landuse_grazing_ha "Land used for grazing, ha, 2008"
la var landuse_grazing_pct "Percentage of land used for grazing, 2008"

generate landuse_wetland_ha = cd1e1*0.404685642  
generate landuse_wetland_pct = cd1e2 
replace landuse_wetland_ha=0 if landuse_wetland_ha==.
replace landuse_wetland_pct=0 if landuse_wetland_pct==.
replace landuse_wetland_pct=0 if landuse_wetland_pct==998
replace landuse_wetland_pct=100 if landuse_wetland_pct>100
la var landuse_wetland_ha "Land used for wetlands, ha, 2008"
la var landuse_wetland_pct "Percentage of land used for wetlands, 2008"

generate landuse_resid_ha = cd1f1*0.404685642 
generate landuse_resid_pct = cd1f2 
replace landuse_resid_ha=0 if landuse_resid_ha==.
replace landuse_resid_pct=0 if landuse_resid_pct==.
replace landuse_resid_pct=0 if landuse_resid_pct==998
replace landuse_resid_pct=100 if landuse_resid_pct>100
la var landuse_resid_ha "Land used for residential purposes, ha, 2008"
la var landuse_resid_pct "Percentage of land used for residential purposes, 2008"

generate landuse_biz_ha = cd1g1*0.404685642  
generate landuse_biz_pct = cd1g2 
replace landuse_biz_ha=0 if landuse_biz_ha==.
replace landuse_biz_pct=0 if landuse_biz_pct==.
replace landuse_biz_pct=0 if landuse_biz_pct==998
replace landuse_biz_pct=100 if landuse_biz_pct>100
la var landuse_biz_ha "Land used for businesses, ha, 2008"
la var landuse_biz_pct "Percentage of land used for businesses, 2008"

generate landuse_other_ha = cd1h1*0.404685642 
generate landuse_other_pct = cd1h2 
replace landuse_other_ha=0 if landuse_other_ha==.
replace landuse_other_pct=0 if landuse_other_pct==.
replace landuse_other_pct=0 if landuse_other_pct==998
replace landuse_other_pct=100 if landuse_other_pct>100
la var landuse_other_ha "Land used for other purposes, ha, 2008"
la var landuse_other_pct "Percentage of land used for other purposes, 2008"

save "$collapse/w1_community_collapseprep.dta", replace

