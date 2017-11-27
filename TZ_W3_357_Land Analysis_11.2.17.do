*Title/Purpose of Do File: Tanzania LSMS-ISA (2012-13) - Land Tenure Analysis (Project #357)
*Author(s): Maggie Beetstra, Max McDonald, Emily Morton, Pierre Biscaye, Kirby Callaway, Isabella Sun, Emma Weaver

clear

set more off

global input "\\evansfiles\files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2012-13\Raw Data"
global merge "\\evansfiles\files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2012-13\Merged Data"
global collapse "\\evansfiles\files\Project\EPAR\Tanzania LSMS-ISA\Analysis\357 Land Analysis\2012-13\Collapse Data" 
global output "R:\Project\EPAR\Working Files\357 - Land Reform Review\Output" 

//////////////////////////////////////////////////////////////////////////////
// 			1. Merge LRS and SRS Plot Roster and Details 					//
//////////////////////////////////////////////////////////////////////////////


***SECTIONS 2A & 2B (PLOT ROSTER)***
clear
use "$input\Agriculture\AG_SEC_2B"

//Dropping households that did not list unique plots in the SRS so we can merge this with 2A. Since no observations match, we are appending these data onto section 2A.
drop if plotnum=="" //27 unique observations remain

append using "$input\Agriculture\AG_SEC_2A", gen(_merge_SEC_2A_2B)

*merge m:1 y3_hhid plotnum using "$input\Agriculture\AG_SEC_2A", generate (_merge_SEC_2A_2B) 
*0 matched, 27 not matched from master (2B), 9157 not matched from using (2A) 
*Result is 9,184 unique plots

save "$merge\SEC_2A_2B_HH_PLOT.dta", replace

***SECTIONS 3A & 3B (PLOT DETAILS)***

clear 
use "$input\Agriculture\AG_SEC_3B"

// Dropping households that did not list unique plots in the SRS so we can merge this with 3A. Since no observations match, we are appending these data onto section 3A.
drop if plotnum!="V1" & plotnum!="V2" //27 unique observations remain 

append using "$input\Agriculture\AG_SEC_3A", generate (_merge_SEC_3A_3B) 

*merge m:1 y3_hhid plotnum using "$input\Agriculture\AG_SEC_3A", generate (_merge_SEC_3A_3B) 
*0 matched, 27 not matched from master (3B), 9157 not matched from using (3A) 
*Result is 9,184 unique plots

**check HH IDs of plot decision-makers, owners, and users to determine how much individual-level information to retain from AG HH Roster 
//who decided what to plant 
tab ag3a_08_1
tab ag3a_08_2
tab ag3a_08_3
tab ag3b_08_1
tab ag3b_08_2
tab ag3b_08_3
*highest is 22
//who owns the plot
tab ag3a_29_1
tab ag3a_29_2
tab ag3b_29_1
tab ag3b_29_2
*highest is 17
//who has rights to use plot
tab ag3a_37_1
tab ag3a_37_2
tab ag3b_37_1
tab ag3b_37_2
*highest is 7

save "$merge\SEC_3A_3B_HH_PLOT.dta", replace

***SECTION 1 (AG HH ROSTER)***

clear
use "$input\Agriculture\AG_SEC_01"

**Generate variables for gender of each HH member up to 22nd (no HH member beyond #22 listed as a plot decision-maker)
foreach x of numlist 1/22 {
	gen hhmem_fem_`x'=.
	replace hhmem_fem_`x'=0 if indidy3==`x' & ag01_03==1 
	replace hhmem_fem_`x'=1 if indidy3==`x' & ag01_03==2 
} 

**Generate variables for age of each HH member up to 22nd (no HH member beyond #22 listed as a plot owner)
foreach x of numlist 1/22 {
	gen hhmem_age_`x'=.
	replace hhmem_age_`x'=ag01_02 if indidy3==`x'  
} 

gen hoh_fem=0
replace hoh_fem=1 if indidy3==1 & ag01_03==2


gen hoh_age=ag01_02 if indidy3==1

/// HOH education///

merge 1:1 y3_hhid indidy3 using "$input\Household\hh_sec_c.dta", generate (_merge_HH_SEC_C)

*** can hoh read and write?
gen hoh_literate=1 if indidy3==1 & hh_c02!=. 
replace hoh_literate=0 if indidy3==1 & hh_c02==5 
la var hoh_literate "Can the head of household read and write?; YES=1 NO=2" 

local maxvars hhmem_fem_* hhmem_age_* hoh_fem hoh_age hoh_literate 
collapse (max) `maxvars', by (y3_hhid)

save "$collapse/AG_indy_collapse.dta", replace

***MERGING ALL HH-PLOT LEVEL DATA TOGETHER***

clear
use "$merge\SEC_3A_3B_HH_PLOT.dta"

//Merge in sections 2A & 2B
merge 1:1 y3_hhid plotnum using "$merge\SEC_2A_2B_HH_PLOT", generate (_merge_SEC_2A_2B_Final)
*9184 matched, 0 not matched 

//Merge in HH information
merge m:1 y3_hhid using "$input\Household\HH_SEC_A", generate (_merge_HH_SEC_A_HH_PLOT)
*9184 matched, 0 not matched 

//Merge in HH Plot Roster
merge m:1 y3_hhid using "$collapse/AG_indy_collapse.dta", generate (_merge_AG_SEC_1_HH) keep(3)
*7505 matched; not keeping 1679 not matched observations with missing plot information

save "$merge\AG_plot-level_merge.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			2. Generate Land Tenure Variables at Plot Level				//
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge\AG_plot-level_merge.dta"

egen number_plots = count(occ), by(y3_hhid)
la var number_plots "Total number of plots for the household"

gen plot_cultivated =1 if ag3a_40==1
replace plot_cultivated =0 if ag3a_40==2
la var plot_cultivated "plot cultivated during LRS 2012 (ag3a_40)"


////////LAND TITLE

gen plot_title_proportion = ag3a_28
replace plot_title_proportion = ag3b_28 if plot_title_proportion==. & ag3b_28!=.
la var plot_title_proportion "Type of title held for plot, 2012"

**Title Held
gen plot_title_held = .
replace plot_title_held = 1 if  plot_title_proportion >= 1 & plot_title_proportion <= 10
replace plot_title_held = 0 if plot_title_proportion == 11
la var plot_title_held "HH has a title for plot"

////////////Plot size

gen plotsize_acres = ag2a_04
la var plotsize_acres "(ag2a_04) farmer reported plot size in acres"

gen plotsize_ha = plotsize_acres* 0.404685642
la var plotsize_ha "(ag2a_04) farmer reported plot size in hectares"

gen plotsize_acres_gps = ag2a_09
la var plotsize_acres_gps "(ag2a_09) GPS measured plot size in acres"

gen plotsize_ha_gps = plotsize_acres_gps* 0.404685642
la var plotsize_ha_gps "(ag2a_09) GPS measured plot size in hectares"

gen plotsize_acres_SRS = ag2b_15
la var plotsize_acres_SRS "(ag2b_15) farmer reported plot size in acres for SRS"

gen plotsize_ha_SRS = plotsize_acres_SRS* 0.404685642
la var plotsize_ha_SRS "(ag2b_15) farmer reported plot size in hectares"

gen plotsize_acres_gps_SRS = ag2b_20
la var plotsize_acres_gps_SRS "(ag2b_20) GPS measured plot size in acres"

gen plotsize_ha_gps_SRS = plotsize_acres_gps_SRS* 0.404685642
la var plotsize_ha_gps_SRS "(ag2b_20) GPS measured plot size in hectares"

** make the area measure we will use for yield and area calculations: GPS measure for HH that have it, FR if not
gen plot_area = plotsize_ha_gps //1737 missing - 1710 of these are plots with no area measure for both LRS and SRS
replace plot_area = plotsize_ha if plot_area ==. //2051 changes
replace plot_area = plotsize_ha_gps_SRS if plot_area==. //9 changes
replace plot_area = plotsize_ha_SRS if plot_area==. //18 changes
la var plot_area "plot area measure, ha - GPS-based if they have one, farmer-report if not, LRS and SRS"

*make a var identifying whether FR or GPS was used for this hh for this year
gen gps_hh = .
replace gps_hh=0 if plotsize_ha!=. | plotsize_ha_SRS!=.
replace gps_hh =1 if plotsize_ha_gps!=. | plotsize_ha_gps_SRS!=.
la var gps_hh "number of plots with a GPS measure (farmer-reported area not used)"

////////////PLOT OWNERSHIP

gen ownership_owned=.
replace ownership_owned = 1 if ag3a_25==1
replace ownership_owned = 0 if ag3a_25!=1 & ag3a_25!=.
replace ownership_owned = 1 if ag3b_25==1
replace ownership_owned = 0 if ag3b_25!=1 & ag3b_25!=.
label var ownership_owned "Did you own this plot (ag3a_25, ag3b_25)"

gen ownership_usedfree=.
replace ownership_usedfree = 1 if ag3a_25==2
replace ownership_usedfree = 0 if ag3a_25!=2 & ag3a_25!=.
replace ownership_usedfree = 1 if ag3b_25==2
replace ownership_usedfree = 0 if ag3b_25!=2 & ag3b_25!=.
label var ownership_usedfree "Did you use this plot free of charge (ag3a_25, ag3b_25)"

gen ownership_rentedin=.
replace ownership_rentedin = 1 if ag3a_25==3
replace ownership_rentedin = 0 if ag3a_25!=3 & ag3a_25!=.
replace ownership_rentedin = 1 if ag3b_25==3
replace ownership_rentedin = 0 if ag3b_25!=3 & ag3b_25!=.
label var ownership_rentedin "Did you rent in this plot (ag3a_25, ag3b_25)"

gen ownership_sharedrent=.
replace ownership_sharedrent = 1 if ag3a_25==4
replace ownership_sharedrent = 0 if ag3a_25!=4 & ag3a_25!=.
replace ownership_sharedrent = 1 if ag3b_25==4
replace ownership_sharedrent = 0 if ag3b_25!=4 & ag3b_25!=.
label var ownership_sharedrent "Did you share rent on this plot (ag3a_25, ag3b_25)"

gen ownership_sharedown=.
replace ownership_sharedown = 1 if ag3a_25==5
replace ownership_sharedown = 0 if ag3a_25!=5 & ag3a_25!=.
replace ownership_sharedown = 1 if ag3b_25==5
replace ownership_sharedown = 0 if ag3b_25!=5 & ag3b_25!=.
label var ownership_sharedown "Did you share ownership on this plot (ag3a_25, ag3b_25)"

gen ownership_rent2=.
replace ownership_rent2=1 if ownership_sharedrent==1 | ownership_rentedin==1
replace ownership_rent2=0 if ownership_sharedrent==0 & ownership_rentedin==0
label var ownership_rent2 "Plot is rented in or shared rented in (ag3a_25, ag3b_25)"

gen ownership_own2=.
replace ownership_own2=1 if ownership_owned==1 | ownership_sharedown==1
replace ownership_own2=0 if ownership_owned==0 & ownership_sharedown==0
label var ownership_own2 "Plot is owned or shared owned (ag3a_25, ag3b_25)"

//////////////////PLOT OWNERSHIP BY GENDER

gen fem_plot_owner = .
la var fem_plot_owner "First listed plot owner is female"
foreach x of numlist 1/22 {
	replace fem_plot_owner = 0 if ag3a_29_1 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_owner = 1 if ag3a_29_1 == `x' & hhmem_fem_`x' == 1 
	replace fem_plot_owner = 0 if ag3b_29_1 == `x' & hhmem_fem_`x' == 0
	replace fem_plot_owner = 1 if ag3b_29_1 == `x' & hhmem_fem_`x' == 1
} 
// 4,837 male, 1,478 female

gen fem_plot_co_owner = .
la var fem_plot_co_owner "Second listed plot owner is female"

foreach x of numlist 1/22 {
	replace fem_plot_co_owner = 0 if ag3a_29_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_co_owner = 1 if ag3a_29_2 == `x' & hhmem_fem_`x' == 1 
	replace fem_plot_co_owner = 0 if ag3b_29_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_co_owner = 1 if ag3b_29_2 == `x' & hhmem_fem_`x' == 1 
} 
// 114 male, 2,249 female

// Plots with at least one female owner
generate fem_plot_owned = .
replace fem_plot_owned = 0 if fem_plot_owner == 0 | fem_plot_co_owner == 0
replace fem_plot_owned = 1 if fem_plot_owner == 1 | fem_plot_co_owner == 1 // 3,689 instances of female owned or co-owned plots
label variable fem_plot_owned "Plot owned or co-owned by a female"

// Female only owned plots
generate fem_only_plot_own = .
replace fem_only_plot_own = 0 if (fem_plot_owner != 1 | fem_plot_co_owner != 1) 
replace fem_only_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 1) | (fem_plot_owner == 1 & fem_plot_co_owner==.) 
label variable fem_only_plot_own "Female-only owned plot"
// 1,387 plots 

// Male only owned plots
generate male_only_plot_own = .
replace male_only_plot_own = 0 if (fem_plot_owner == 1 | fem_plot_co_owner == 1)
replace male_only_plot_own = 1 if (fem_plot_owner == 0 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == .) // females could be either missing or not listed in either case (owner or co-owner)   
label variable male_only_plot_own "Male-only owned plot"
// 2,627 plots

// Mixed gender ownership plots
generate mixed_gen_plot_own = .
replace mixed_gen_plot_own = 0 if male_only_plot_own == 1 | fem_only_plot_own == 1
replace mixed_gen_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == 1) // requires two owners, of different gender (i.e., specifically one female owner)
label variable mixed_gen_plot_own "Plot with mixed gender ownership"
// 2,301 plots

//create plot weights, household weight (y3_weight) times plot area, as per World Bank practice
gen plot_weight = y3_weight*plot_area	

////////////////////Save plot level variables
save "$merge\W3_AG_Plot_Level_Land_Variables.dta", replace  


//////////////////////////////////////////////////////////////////////////////
// 			3. Summary Statistics at Plot Level						        //
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge\W3_AG_Plot_Level_Land_Variables.dta"

svyset clusterid [pweight=plot_weight], strata(strataid)

//Gender of Plot Owner - sample is owned/shared owned plots, 6314 of 7446 in LRS (85%), 5 of 26 in SRS (19%)
**Summary stats for fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own

eststo plots1: svy: mean fem_plot_owned fem_only_plot_own mixed_gen_plot_own male_only_plot_own 	
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]
eststo plots1a: svy, subpop(if plot_title_held==1): mean fem_plot_owned fem_only_plot_own mixed_gen_plot_own male_only_plot_own
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]
eststo plots1b: svy, subpop(if plot_title_held==0): mean fem_plot_owned fem_only_plot_own mixed_gen_plot_own male_only_plot_own 
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]
esttab plots1 plots1a plots1b using "$output/TZ_w3_plot_table1.rtf", cells(b(fmt(3)) & se(fmt(3) par)) label mlabels("All Owned Plots" "Owned plots with a Title/Certificate" "Owned plots with No Title/Certificate" ) collabels(none) title("Table 1. Proportion of owned plots, by sex of owner and title/certificate type (Tanzania, 2012)")  /// 
note("The sample excludes plots rented in or used free of charge, and four owned plots with missing data on gender of the plot owner. Estimates are plot-level cluster-weighted means, with standard errors in parentheses.") replace stats(subpop_N, label("Observations") fmt(0))



//////////////////////////////////////////////////////////////////////////////
// 			4. Other land tenure indicator variables	                    //
/////////////////////////////////////////////////////////////////////////////

/////////////LAND TITLE//////////
//Posession of title by title type
***Creating dummy variables for each category of land title

gen title_granted_right_occupancy = .
replace title_granted_right_occupancy = 1 if plot_title_proportion==1
replace title_granted_right_occupancy = 0 if plot_title_proportion!=1 & plot_title_proportion!=.
la var title_granted_right_occupancy "HH granted right of occupancy for plot"

gen title_customary_right_occupancy = . 
replace title_customary_right_occupancy = 1 if plot_title_proportion==2
replace title_customary_right_occupancy = 0 if plot_title_proportion!=2 & plot_title_proportion!=.
la var title_customary_right_occupancy "HH has certificate of customary right of occupancy for plot"

gen title_resid_license = .
replace title_resid_license = 1 if plot_title_proportion==3
replace title_resid_license = 0 if plot_title_proportion!=3 & plot_title_proportion!=.
la var title_resid_license "HH has residential license for plot"

gen title_village_gov_agreement = . 
replace title_village_gov_agreement = 1 if plot_title_proportion==4
replace title_village_gov_agreement = 0 if plot_title_proportion!=4 & plot_title_proportion!=.
la var title_village_gov_agreement "HH has village govt-witnessed purchase agreement for plot"

gen title_court_cert_agreement = .
replace title_court_cert_agreement = 1 if plot_title_proportion==5
replace title_court_cert_agreement = 0 if plot_title_proportion!=5 & plot_title_proportion!=.
la var title_court_cert_agreement "HH has local court-certified purchase agreement for plot"

gen title_inheritance_ltr = . 
replace title_inheritance_ltr = 1 if plot_title_proportion==6
replace title_inheritance_ltr = 0 if plot_title_proportion!=6 & plot_title_proportion!=.
la var title_inheritance_ltr "HH has inheritance letter for plot"

gen title_allocation_ltr = . 
replace title_allocation_ltr = 1 if plot_title_proportion==7
replace title_allocation_ltr = 0 if plot_title_proportion!=7 & plot_title_proportion!=.
la var title_allocation_ltr "HH has village govt letter of allocation for plot"

gen title_other_gov_doc = . 
replace title_other_gov_doc = 1 if plot_title_proportion==8
replace title_other_gov_doc = 0 if plot_title_proportion!=8 & plot_title_proportion!=.
la var title_other_gov_doc "HH has other govt document for plot"

gen title_official_corres = . 
replace title_official_corres = 1 if plot_title_proportion==9
replace title_official_corres = 0 if plot_title_proportion!=9 & plot_title_proportion!=.
la var title_official_corres "HH has official correspondence for plot"

gen title_utility_bill = .
replace title_utility_bill = 1 if plot_title_proportion==10
replace title_utility_bill = 0 if plot_title_proportion!=10 & plot_title_proportion!=.
la var title_utility_bill "HH has utility or other bill for plot"

gen no_title = .
replace no_title = 1 if plot_title_proportion==11
replace no_title = 0 if plot_title_proportion!=11 & plot_title_proportion!=.
la var no_title "HH has no title for plot"

/////////////PLOT SIZE/////////

**Plot area by ownership status
gen plot_area_owned = plot_area if ag3a_25 == 1 | ag3a_25 == 5 | ag3b_25 == 1 | ag3b_25 == 5
la var plot_area_owned "Plot area, owned plot, ha"

gen plot_area_notowned = plot_area if ag3a_25 != 1 & ag3a_25 != 5 & ag3b_25 != 1 & ag3b_25 != 5
la var plot_area_notowned "Plot area, not owned plot, ha"

gen plot_area_rentedin = plot_area if ag3a_25 == 3 | ag3a_25 == 4 | ag3b_25 == 3 | ag3b_25 == 4
la var plot_area_rentedin "Plot area, rented in plot, ha"

gen plot_area_usedfree = plot_area if ag3a_25 == 2 | ag3b_25 == 2
la var plot_area_usedfree "Plot area, used free of charge plot, ha"

gen plot_area_rentedout = plot_area if ag3a_03 == 2 | ag3b_03 == 2
la var plot_area_rentedout "Plot area, rented out, ha"

////////////VALUE OF PLOTS//////

// Value of owned plots - Respondent's estimate
// Values should be captured only for plots that are counted as owned or shared
// -owned (i.e., if ag3a_25 == 1 or ag3a_25 == 2). 

generate value_owned_plot= .
replace value_owned_plot= ag3a_24 if ag3a_25 == 1 | ag3a_25 == 5
replace value_owned_plot= ag3b_24 if ag3b_25 == 1 | ag3b_25 == 5
la var value_owned_plot "Estimated value of plot if sold today, LRS and SRS, TSH"

///////////NUMBER OF SECURE PLOTS OWNED
generate plot_security = . 
replace plot_security = 0 if ag3a_39 == 2 | ag3b_39 == 2
replace plot_security = 1 if ag3a_39 == 1 | ag3b_39 == 1
la var plot_security "Respondent comfortable leaving plot uncultivated several months"

//////Number of plots owned where owner has right to sell or use as collateral: LRS and SRS
generate plot_right_sell = . 
replace plot_right_sell = 0 if ag3a_30 == 2 | ag3b_30 == 2
replace plot_right_sell = 1 if ag3a_30 == 1 | ag3b_30 == 1
la var plot_right_sell "HH has right to sell plot or use as collateral"

/////////////PLOT OWNERSHIP BY AGE //////////////////
gen age_plot_owner = .
la var age_plot_owner "Age of first listed plot owner"
foreach x of numlist 1/22 {
	replace age_plot_owner=hhmem_age_`x' if ag3a_29_1 == `x' 
	replace age_plot_owner=hhmem_age_`x' if ag3b_29_1 == `x' 
} 

gen age_plot_co_owner = .
la var age_plot_co_owner "Age of second listed plot owner"
foreach x of numlist 1/22 {
	replace age_plot_co_owner=hhmem_age_`x' if ag3a_29_2 == `x' 
	replace age_plot_co_owner=hhmem_age_`x' if ag3b_29_2 == `x' 
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
label variable age_plot_owner_10_24 "Plot owners between the ages of 10 and 24, 2012"

generate age_plot_owner_25_34 = .
replace age_plot_owner_25_34=0 if (age_plot_owner<25 | age_plot_owner>34) & age_plot_owner!=.
replace age_plot_owner_25_34=1 if age_plot_owner >=25 & age_plot_owner <= 34
label variable age_plot_owner_25_34 "Plot owners between the ages of 25 and 34, 2012"

generate age_plot_owner_35_44 = .
replace age_plot_owner_35_44=0 if (age_plot_owner<35 | age_plot_owner>44) & age_plot_owner!=.
replace age_plot_owner_35_44=1 if age_plot_owner >=35 & age_plot_owner <= 44
label variable age_plot_owner_35_44 "Plot owners between the ages of 35 and 44, 2012"

generate age_plot_owner_45_54 = .
replace age_plot_owner_45_54=0 if (age_plot_owner<45 | age_plot_owner>54) & age_plot_owner!=.
replace age_plot_owner_45_54=1 if age_plot_owner >=45 & age_plot_owner <= 54
label variable age_plot_owner_45_54 "Plot owners between the ages of 45 and 54, 2012"

generate age_plot_owner_55_over = .
replace age_plot_owner_55_over=0 if (age_plot_owner<55)
replace age_plot_owner_55_over=1 if age_plot_owner >=55 & age_plot_owner != .
label variable age_plot_owner_55_over "Plot owners aged 55 and above, 2012"

*Generating dummy variable for either position plot owner age categories
generate age_plot_any_owner_10_24 = .
replace age_plot_any_owner_10_24=0 if ((age_plot_owner <10 | age_plot_owner>24) & age_plot_owner!=.) | ((age_plot_co_owner <10 | age_plot_co_owner>24) & age_plot_owner!=.)
replace age_plot_any_owner_10_24=1 if (age_plot_owner >=10 & age_plot_owner <= 24) | (age_plot_co_owner >=10 & age_plot_co_owner <= 24)
label variable age_plot_any_owner_10_24 "Plot owners between the ages of 10 and 24, 2012"

generate age_plot_any_owner_25_34 = .
replace age_plot_any_owner_25_34=0 if ((age_plot_owner <25 | age_plot_owner>34) & age_plot_owner!=.) | ((age_plot_co_owner <25 | age_plot_co_owner>34) & age_plot_owner!=.)
replace age_plot_any_owner_25_34=1 if (age_plot_owner >=25 & age_plot_owner <= 34) | (age_plot_co_owner >=25 & age_plot_co_owner <= 34) 
label variable age_plot_any_owner_25_34 "Plot owners between the ages of 25 and 34, 2012"

generate age_plot_any_owner_35_44 = .
replace age_plot_any_owner_35_44=0 if ((age_plot_owner <35 | age_plot_owner>44) & age_plot_owner!=.) | ((age_plot_co_owner <35 | age_plot_co_owner>44) & age_plot_owner!=.)
replace age_plot_any_owner_35_44=1 if (age_plot_owner >=35 & age_plot_owner <= 44) | (age_plot_co_owner >=35 & age_plot_co_owner <= 44)
label variable age_plot_any_owner_35_44 "Plot owners between the ages of 35 and 44, 2012"

generate age_plot_any_owner_45_54 = .
replace age_plot_any_owner_45_54=0 if ((age_plot_owner <45 | age_plot_owner>54) & age_plot_owner!=.) | ((age_plot_co_owner <45 | age_plot_co_owner>54) & age_plot_owner!=.)
replace age_plot_any_owner_45_54=1 if (age_plot_owner >=45 & age_plot_owner <= 54) | (age_plot_co_owner >=45 & age_plot_co_owner <= 54)
label variable age_plot_any_owner_45_54 "Plot owners between the ages of 45 and 54, 2012"

generate age_plot_any_owner_55_over = .
replace age_plot_any_owner_55_over=0 if (age_plot_owner <55 & age_plot_owner !=. ) | (age_plot_co_owner <55 & age_plot_co_owner != .)
replace age_plot_any_owner_55_over=1 if (age_plot_owner >=55 & age_plot_owner !=. ) | (age_plot_co_owner >=55 & age_plot_co_owner != .)
label variable age_plot_any_owner_55_over "Plot owners aged 55 and above, 2012"


//////////////PLOT CULTIVATION DECISION MAKER BY GENDER 
gen fem_cult_dec_mkr = .
la var fem_cult_dec_mkr "First cultivation decision-maker is female"
foreach x of numlist 1/22 {
	replace fem_cult_dec_mkr = 0 if ag3a_08_1 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr = 1 if ag3a_08_1 == `x' & hhmem_fem_`x' == 1 
	replace fem_cult_dec_mkr = 0 if ag3b_08_1 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr = 1 if ag3b_08_1 == `x' & hhmem_fem_`x' == 1 
} 

gen fem_cult_dec_mkr2 = .
la var fem_cult_dec_mkr2 "Second cultivation decision-maker is female"

foreach x of numlist 1/22 {
	replace fem_cult_dec_mkr2 = 0 if ag3a_08_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr2 = 1 if ag3a_08_2 == `x' & hhmem_fem_`x' == 1
	replace fem_cult_dec_mkr2 = 0 if ag3b_08_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr2 = 1 if ag3b_08_2 == `x' & hhmem_fem_`x' == 1
} 

gen fem_cult_dec_mkr3 = .
la var fem_cult_dec_mkr3 "Third cultivation decision-maker is female"

foreach x of numlist 1/22 {
	replace fem_cult_dec_mkr3 = 0 if ag3a_08_3 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr3 = 1 if ag3a_08_3 == `x' & hhmem_fem_`x' == 1
	replace fem_cult_dec_mkr3 = 0 if ag3b_08_3 == `x' & hhmem_fem_`x' == 0 
	replace fem_cult_dec_mkr3 = 1 if ag3b_08_3 == `x' & hhmem_fem_`x' == 1
} 

// Generate # of female decision makers for what is planted 
egen fem_cult_dec_mkr_obs = rowtotal(fem_cult_dec_mkr fem_cult_dec_mkr2 fem_cult_dec_mkr3)
replace fem_cult_dec_mkr_obs=. if fem_cult_dec_mkr==. & fem_cult_dec_mkr2==. & fem_cult_dec_mkr3==.
tab fem_cult_dec_mkr_obs // 1,764 no females, 4,195 1 female, 210 2 females, 13 3 females
la var fem_cult_dec_mkr_obs "Number of female cultivation decision-makers on plot"

//////////////LAND USE DECISION MAKER BY GENDER 
generate fem_lduse_dec_mkr1 = . 
la var fem_lduse_dec_mkr1 "First land use decision-maker is female"

foreach x of numlist 1/22 {
	replace fem_lduse_dec_mkr1 = 0 if ag3a_31_1 == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr1 = 1 if ag3a_31_1 == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr1 = 0 if ag3b_31_1 == `x' & hhmem_fem_`x' == 0
	replace fem_lduse_dec_mkr1 = 1 if ag3b_31_1 == `x' & hhmem_fem_`x' == 1 
}

generate fem_lduse_dec_mkr2 = . 
la var fem_lduse_dec_mkr2 "Second land use decision-maker is female"

foreach x of numlist 1/22 {
	replace fem_lduse_dec_mkr2 = 0 if ag3a_31_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_lduse_dec_mkr2 = 1 if ag3a_31_2 == `x' & hhmem_fem_`x' == 1 
	replace fem_lduse_dec_mkr2 = 0 if ag3b_31_2 == `x' & hhmem_fem_`x' == 0 
	replace fem_lduse_dec_mkr2 = 1 if ag3b_31_2 == `x' & hhmem_fem_`x' == 1 
}

gen lduse_dec_mkr_num=.
replace lduse_dec_mkr_num=1 if ag3a_31_1!=. | ag3b_31_1!=. 
replace lduse_dec_mkr_num=2 if ag3a_31_2!=. | ag3b_31_2!=. 
la var lduse_dec_mkr_num "Number of landuse decision-makers on plot"

egen fem_lduse_dec_mkr_obs = rowtotal(fem_lduse_dec_mkr1 fem_lduse_dec_mkr2)
replace fem_lduse_dec_mkr_obs=. if fem_lduse_dec_mkr1==. & fem_lduse_dec_mkr2==.
la var fem_lduse_dec_mkr_obs "Number of female landuse decision-makers on plot"


////////////////COST OF RENTED IN PLOTS 
// We want to use ag3a_33 (How much in t-shillings?), ag3a_34_1 (frequency paid)
// and ag3a_34_2 (period: 1 = months, 2 = years).
// Working assumption here is that missing values means that the household paid zero rent to use a plot. 
generate rent_in_plot_LRS = ag3a_33 
replace rent_in_plot_LRS = 0 if rent_in_plot_LRS == . // 9,184 real changes made; 8,886 to missing
replace rent_in_plot_LRS = (rent_in_plot_LRS/ag3a_34_1) if ag3a_34_2 == 2 //replace with annual average if payment covered more than 1 year; leave payment total as is if reported period covered is in months

generate rent_in_plot_SRS = ag3b_33
replace rent_in_plot_SRS = 0 if rent_in_plot_SRS == .
replace rent_in_plot_SRS = (ag3b_33/(ag3b_34_1)) if ag3b_34_2 == 2 //replace with annual average if payment covered more than 1 year; leave payment total as is if reported period covered is in months

gen rent_in_plot_cost=rent_in_plot_SRS+rent_in_plot_LRS
la var rent_in_plot_cost "Cost to rent in plot in last year"

////////////////////income from renting out plots

// Working assumption here is that missing values means that the household received zero income from plot rentals. 
gen plot_rented_out=.
replace plot_rented_out=1 if ag3a_03==2 
replace plot_rented_out=1 if ag3b_03==2
replace plot_rented_out=0 if (ag3a_03!=2 & ag3a_03!=.) | (ag3b_03!=2 & ag3b_03!=.)
la var plot_rented_out "Plot was rented out during LRS or SRS"

generate plot_rental_income_LRS = 0
replace plot_rental_income_LRS = ag3a_04 if ag3a_04 != .

generate plot_rental_income_SRS = 0
replace plot_rental_income_SRS = ag3b_04 if ag3b_04 != .

gen plot_rental_income_total=plot_rental_income_SRS+plot_rental_income_LRS
la var plot_rental_income_total "Income from renting out plot in last year"

////////OTHER PLOT CLASSIFICATION VARIABLES
gen plot_own_title=0
replace plot_own_title=1 if plot_title_held==1
replace plot_own_title=0 if ag3a_28==.
la var plot_own_title "HH owns plot and has a title"

gen plot_own_notitle=0
replace plot_own_notitle=1 if no_title==1
replace plot_own_notitle=0 if ag3a_28==.
la var plot_own_notitle "HH owns plot but has no title"

gen plot_notown=0
replace plot_notown=1 if ag3a_28==.
la var plot_notown "HH does not own the plot"

generate plot_rightsell = 0 
replace plot_rightsell = 1 if plot_right_sell == 1
la var plot_rightsell "HH has right to sell plot or use as collateral"


///////HH CONSUMPTION//////

merge m:1 y3_hhid using "$input\ConsumptionNPS3.dta", gen (_merge_HHConsumption_2012)

*Expenditure per adult equivalent in the household
gen consum_per_adult = .
replace consum_per_adult = expm/adulteq  //total HH consumption, annual, nominal, divided by adult-equivalents in the HH

*Daily expenditure per adult equivalent in the household
gen consum_per_adult_daily = .
replace consum_per_adult_daily = consum_per_adult/365


****2016 implied PPP Conversion Rate is 685.72
****CPI in 2016 was 166.191
****CPI in in 2012 was 130.725
gen inflation=1+((166.191-130.725)/130.725)
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


////Geo variables///

gen district_name=hh_a02_2
la var district_name "district name"

gen wave=3

save "$merge\TZ_W3_Plot_Level_All.dta", replace

gen hhid=y3_hhid 

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
dailycons poverty125 poverty2 wave using "\\evansfiles\files\Project\EPAR\Working Files\357 - Land Reform Review\Tableau\Excel\TZ_W3_Plot.xls", sheetmodify firstrow(varlabel)

keep hhid plotnum region plot_title_held hoh_fem hoh_age hoh_literate ///
plot_area plot_area_owned plot_area_notowned  ///
gender_plot_owner fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own ownership_own2 ///
dailycons poverty125 poverty2 wave

save "$merge\TZ_W3_tableau.dta", replace 

//////////////////////////////////////////////////////////////////////////////
// 			5. Other land tenure indicator variables at HH Level	         //
/////////////////////////////////////////////////////////////////////////////

//// Collapse plot-level data to HH level//
clear
use "$merge\TZ_W3_Plot_Level_All.dta"

local sum_vars plot_title_held plot_area plot_area_owned plot_area_notowned plot_area_rentedin plot_area_usedfree plot_area_rentedout ///
ownership_owned ownership_sharedown ownership_usedfree ownership_rentedin ownership_sharedrent ownership_rent2 ownership_own2 /// 
value_owned_plot plot_security plot_right_sell fem_plot_owned rent_in_plot_cost plot_rented_out plot_rental_income_total 
collapse (max) number_plots (firstnm) clusterid strataid (sum) `sum_vars', by (y3_hhid) 

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
la var plot_security "(sum) Number of all plots the HH is comfortable leaving uncultivated"
la var plot_right_sell "(sum) Number of owned plots the HH has right to sell or use as collateral"
label variable fem_plot_owned "(sum) Number of plots owned or co-owned by females"
la var rent_in_plot_cost "(sum) Cost to rent in plots in last year"
la var plot_rented_out "(sum) Number of plots rented out"
la var plot_rental_income_total "(sum) Income from renting out plots in last year"

save "$collapse\w3_Plot_HH_sum_collapse.dta", replace

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
use "$input/Household/HH_SEC_B.dta

gen hoh_sex=.
replace hoh_sex=0 if hh_b02==1 & indidy3==1
replace hoh_sex=1 if hh_b02==2 & indidy3==1

collapse (max) hoh_sex, by (y3_hhid) 

la var hoh_sex "Sex of the head of household"

save "$collapse\w3_HoH_sex_collapse.dta", replace

////////Merge in HHs that did not complete ag section
clear
use "$input/Household/HH_SEC_A.dta"

merge 1:1 y3_hhid using "$collapse\w3_Plot_HH_sum_collapse.dta", gen (_merge_ag_hh) 
**3331 matched, 1679 not matched from master - did not complete ag questionnaire

merge 1:1 y3_hhid using "$collapse\w3_HoH_sex_collapse.dta", gen (_merge_hoh) 
**5010 matched

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

//Construct additional variables
**any plot ownership dummy 
gen ownership_any=0
replace ownership_any=1 if ownership_own2>0 & ownership_own2!=.
la var ownership_any "HH owns at least 1 plot"

**proportion of secure plots
gen plot_security_prop=plot_security/number_plots
la var plot_security_prop "Proportion of plots the HH is comfortable leaving uncultivated several months"

**proportion of plots with right to sell or use as collateral
gen plot_right_sell_prop=plot_right_sell/ownership_own2
la var plot_right_sell_prop "Proportion of owned plots HH has right to sell or use as collateral"

save "$merge\w3_Plot_HH_sum_collapse.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			6. Land Tenure Indivator Variables at Community Level          //
/////////////////////////////////////////////////////////////////////////////
clear
use "$input\Community\COM_SEC_CD.dta"

generate cert_village_lands = cm_d02 
recode cert_village_lands (2=0)
la var cert_village_lands "Village has Certificate of Village Lands, 2012" 

******************* Land appropriation and reallocation ************************

***** Direct Foreign Investment 
gen land_approp_dfi=cm_d04a 
recode land_approp_dfi (2=0)
gen land_approp_mth_dfi=cm_d05am 
gen land_approp_yr_dfi=cm_d05ay 
gen land_approp_hhs_dfi=cm_d06a 
replace land_approp_hhs_dfi=0 if land_approp_hhs_dfi==.
gen land_approp_comp_dfi=cm_d07a 

la var land_approp_dfi "Any land appropriated for dfi, 2012"
la var land_approp_mth_dfi "Month of land appropriation for dfi, 2012"
la var land_approp_yr_dfi "Year of land appropriation for dfi, 2012"
la var land_approp_hhs_dfi "# of HHs affected by appropriation for direct foreign investment, 2012"
la var land_approp_comp_dfi "Compensation per HH for appropriated land for dfi, 2012"


***** Land Reserves
gen land_approp_res=cm_d04b 
recode land_approp_res (2=0)
gen land_approp_mth_res=cm_d05bm 
gen land_approp_yr_res=cm_d05by 
gen land_approp_hhs_res=cm_d06b 
replace land_approp_hhs_res=0 if land_approp_hhs_res==.
gen land_approp_comp_res=cm_d07b 

la var land_approp_res "Any land appropriated for land reserves, 2012"
la var land_approp_mth_res "Month of land appropriation for land reserves, 2012"
la var land_approp_yr_res "Year of land appropriation for land reserves, 2012"
la var land_approp_hhs_res "# of HHs affected by appropriation for land reserves, 2012"
la var land_approp_comp_res "Compensation per HH for appropriated land for land reserves, 2012"


***** Public Use
gen land_approp_pubuse=cm_d04c 
recode land_approp_pubuse (2=0)
gen land_approp_mth_pubuse=cm_d05cm 
gen land_approp_yr_pubuse=cm_d05cy 
gen land_approp_hhs_pubuse=cm_d06c 
replace land_approp_hhs_pubuse=0 if land_approp_hhs_pubuse==.
gen land_approp_comp_pubuse=cm_d07c 

la var land_approp_pubuse "Any land appropriated for public use, 2012"
la var land_approp_mth_pubuse "Month of land appropriation for public use, 2012"
la var land_approp_yr_pubuse "Year of land appropriation for public use, 2012"
la var land_approp_hhs_pubuse "# of HHs affected by appropriation for public use, 2012"
la var land_approp_comp_pubuse "Compensation per HH for appropriated land for public use, 2012"

***** Land Use Variables

generate landuse_cult_ha = cm_d01a1*0.404685642
generate landuse_cult_pct = cm_d01a2 
replace landuse_cult_ha=0 if landuse_cult_ha==.
replace landuse_cult_pct=0 if landuse_cult_pct==.
la var landuse_cult_ha "Land use for cultivation, ha, 2012"
la var landuse_cult_pct "Percentage of land used cultivated, 2012"

generate landuse_agrobiz_ha = cm_d01b1*0.404685642
generate landuse_agrobiz_pct = cm_d01b2 
replace landuse_agrobiz_ha=0 if landuse_agrobiz_ha==.
replace landuse_agrobiz_pct=0 if landuse_agrobiz_pct==.
la var landuse_agrobiz_ha "Land used for agro-business, ha, 2012"
la var landuse_agrobiz_pct "Percentage of land used for agro-business, 2012"

generate landuse_forest_ha = cm_d01c1*0.404685642
generate landuse_forest_pct = cm_d01c2 
replace landuse_forest_ha=0 if landuse_forest_ha==.
replace landuse_forest_pct=0 if landuse_forest_pct==.
la var landuse_forest_ha "Land used for forests, ha, 2012"
la var landuse_forest_pct "Percentage of land used for forests, 2012"

generate landuse_grazing_ha = cm_d01d1*0.404685642 
generate landuse_grazing_pct = cm_d01d2 
replace landuse_grazing_ha=0 if landuse_grazing_ha==.
replace landuse_grazing_pct=0 if landuse_grazing_pct==.
la var landuse_grazing_ha "Land used for grazing, ha, 2012"
la var landuse_grazing_pct "Percentage of land used for grazing, 2012"

generate landuse_wetland_ha = cm_d01e1*0.404685642  
generate landuse_wetland_pct = cm_d01e2 
replace landuse_wetland_ha=0 if landuse_wetland_ha==.
replace landuse_wetland_pct=0 if landuse_wetland_pct==.
la var landuse_wetland_ha "Land used for wetlands, ha, 2012"
la var landuse_wetland_pct "Percentage of land used for wetlands, 2012"

generate landuse_resid_ha = cm_d01f1*0.404685642 
generate landuse_resid_pct = cm_d01f2 
replace landuse_resid_ha=0 if landuse_resid_ha==.
replace landuse_resid_pct=0 if landuse_resid_pct==.
la var landuse_resid_ha "Land used for residential purposes, ha, 2012"
la var landuse_resid_pct "Percentage of land used for residential purposes, 2012"

generate landuse_biz_ha = cm_d01g1*0.404685642  
generate landuse_biz_pct = cm_d01g2 
replace landuse_biz_ha=0 if landuse_biz_ha==.
replace landuse_biz_pct=0 if landuse_biz_pct==.
la var landuse_biz_ha "Land used for businesses, ha, 2012"
la var landuse_biz_pct "Percentage of land used for businesses, 2012"

generate landuse_other_ha = cm_d01h1*0.404685642 
generate landuse_other_pct = cm_d01h2 
replace landuse_other_ha=0 if landuse_other_ha==.
replace landuse_other_pct=0 if landuse_other_pct==.
la var landuse_other_ha "Land used for other purposes, ha, 2012"
la var landuse_other_pct "Percentage of land used for other purposes, 2012"

save "$collapse/w3_community_collapseprep.dta", replace
