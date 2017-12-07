/*-----------------------------------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				  for the construction of a set of land tenure indicators 
				  using the Ethiopia Socioeconomic Survey (ESS) LSMS-ISA Wave 3 (2015-16)
				  
*Author(s)		: Maggie Beetstra, Max McDonald, Emily Morton, Pierre Biscaye, Kirby Callaway, Isabella Sun, Emma Weaver

*Acknowledgments: We acknowledge the helpful contributions of members of the World Bank's LSMS-ISA team. 
				  All coding errors remain ours alone.
				  
*Date			: 30 November 2017

----------------------------------------------------------------------------------------------------------------------------------------------------*/


*Data source
*-----------
*The Ethiopia Socioeconomic Survey (ESS) was collected by the Ethiopia Central Statistical Agency (CSA) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture (LSMS-ISA)
*The data were collected over the period September to December 2015, and February to April 2016. 
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*http://microdata.worldbank.org/index.php/catalog/2783



*Summary of Executing the Master do.file
*-----------
*This Master do.file constructs selected indicators using the Ethiopia LSMS-ISA (ETH LSMS) data set.
*First: Save the raw unzipped data files from the World bank in a new "Raw DTA files" folder.
*The do.file constructs common and intermediate variables, saving dta files when appropriate 
*in a "Merged Data" folder or "Collapse Data" folder.
*These folders will need to be created and the filepaths updated in the global macros at the beginning of the do.file. 

*The processed files include all households, individuals, and plots in the sample.
*In the middle of the do.file, a block of code estimates summary statistics of total plot ownership and plot title, 
*restricted to the rural households only and disaggregated by gender of the plot owner.
*Those summary statistics are created in the excel file "ETH_W3_plot_table1.rtf" in the "\Ethiopia ESS LSMS-ISA - Wave 3 (2015-16)\Final files" folder.
*The do.file also generates other related indicators that are not used in the summary statistics. 


*Outline of the do.file
*-----------
*Below is the list of the main files created by running this Master do.file:

////////PLOT LEVEL////////
*sect_cover_pp_w3_collapse.dta
*AG_indy_collapse.dta
*AG_field_roster_collapse.dta
*AG_parcel_roster_collapseprep.dta
*ETH_W3_plot_table1.rtf
*HOH_educ_collapse.dta
*ETH_W3_Parcel_All.dta


////////HOUSEHOLD LEVEL////////
*ETH_W3_HoH_Literate_collapse.dta
*ETH_w3_HoH_sex_collapse.dta 
*ETH_W3_HH_Level.dta

////////COMMUNITY LEVEL////////
*ETH_W3_Community_Level.dta

*/


clear
set more off 

//set directories ****specify the filepaths****
*These paths correspond to the folders where the raw data files are located and where the created data and final data will be stored.

global input "filepath to folder where you have saved Raw DTA files"
global merge "filepath to folder you created to save Merged Data"
global collapse "filepath to folder you created to save Collapse Data" 
global output "filepath to folder you created to save Final files" 


//////////////////////////////////////////////////////////////////////////////
// 			1. Prepare Raw Data from Ag Sections 							//
//////////////////////////////////////////////////////////////////////////////

***********************************************
//Post-planting Ag Questionnaire Cover (front page)//

clear
use "$input/Post-Planting/sect_cover_pp_w3.dta"
**This dataset is at the holder level

rename pp_saq10 household_size
rename pp_saq13 farm_type
rename pp_saq13a holder_education

//generate strata and cluster variables for analysis with survey weights

gen clusterid=ea_id //first stage sampling unit

/*The BID suggests that the strata are based on the regions:  "The wave 1 sample design is a stratified, two-stage design where the regions of Ethiopia serve as the strata. 
Quotas were set for the number of EAs in each region to ensure a minimum number of EAs are drawn from each EA. The data is representative at the regional level for the most populous regions: 
Amhara, Oromiya, SNNP, and Tigray." However, this only applies to rural areas. 
The BID notes that for urban areas "Specifically, the 6 strata are: Addis Ababa, Amhara, Oromiya, SNNP, Tigray, and “other regions” (including Dire Dawa)." 
Further, "In an effort to improve efficiency, the frame was further stratified based on town size. 
While we did not have empirical evidence of important types of heterogeneity across big and medium cities, the assumption held was that big cities look quite different from medium 
cities and therefore stratification by size ensures coverage across these two types of urban areas. To this end, all strata except for the city state of Addis Ababa were stratified 
in medium-sized (population between 10,000 and 100,000) and big-sized (greater than 100,000) towns." 
This would suggest that there are 11 strata for urban areas.
*/
gen strataid=saq01 if rural==1 //assign region as strataid to rural respondents; regions from from 1 to 7 and then 12 to 15
gen stratum_id=.
replace stratum_id=16 if rural==2 & saq01==1 //Tigray, small town
replace stratum_id=17 if rural==2 & saq01==3 //Amhara, small town
replace stratum_id=18 if rural==2 & saq01==4 //Oromiya, small town
replace stratum_id=19 if rural==2 & saq01==7 //SNNP, small town
replace stratum_id=20 if rural==2 & (saq01==2 | saq01==5 | saq01==6 | saq01==12 | saq01==13 | saq01==15) //Other regions, small town
replace stratum_id=21 if rural==3 & saq01==1 //Tigray, large town
replace stratum_id=22 if rural==3 & saq01==3 //Amhara, large town
replace stratum_id=23 if rural==3 & saq01==4 //Oromiya, large town
replace stratum_id=24 if rural==3 & saq01==7 //SNNP, large town
replace stratum_id=25 if rural==3 & saq01==14 //Addis Ababa, large town
replace stratum_id=26 if rural==3 & (saq01==2 | saq01==5 | saq01==6 | saq01==12 | saq01==13 | saq01==15) //Other regions, large town

replace strataid=stratum_id if rural!=1 //assign new strata IDs to urban respondents, stratified by region and small or large towns



save "$collapse/sect_cover_pp_w3_collapse.dta", replace

***********************************************
//Post-planting Ag Questionnaire Household Roster

clear
use "$input/Post-Planting/sect1_pp_w3.dta"
**This dataset is at the individual level

**Generate variables for gender of each HH member up to 24th (only 24 HH members listed in largest HH)

//pp_s1q03 is just a dummy with 1=Male and 2=Female, but the data include alternate entries: 0 (n=1), 3 (n=1), 4 (n=1), and 6 (n=2). We set these to missing
replace pp_s1q03 = . if !inlist(pp_s1q03,1,2)

foreach x of numlist 1/24 {
	gen hhmem_fem_`x'=.
	replace hhmem_fem_`x'=0 if pp_s1q00==`x' & pp_s1q03==1 
	replace hhmem_fem_`x'=1 if pp_s1q00==`x' & pp_s1q03==2 
} 

**Generate variables for age of each HH member up to 24th (no HH member beyond #22 listed as a plot owner) 


foreach x of numlist 1/24 {
	gen hhmem_age_`x'=.
	replace hhmem_age_`x'=pp_s1q02 if pp_s1q00==`x'  
} 

gen hoh_fem=0
replace hoh_fem=1 if pp_s1q00==1 & pp_s1q03==2


gen hoh_age=pp_s1q02 if pp_s1q00==1

local maxvars hhmem_fem_* hhmem_age_* hoh_fem hoh_age
collapse (max) `maxvars', by (holder_id)

save "$collapse/AG_indy_collapse.dta", replace

***********************************************
//Post-planting Ag Questionnaire Field Roster

clear
use "$input/Post-Planting/sect3_pp_w3.dta"

*Renaming to merge conversion files
ren saq01 region
ren saq02 zone
ren saq03 woreda


**Field area
//GPS-calculated field area in square meters is available for ~97% of fields
gen field_area_gps_ha=.
replace field_area_gps_ha=pp_s3q05_a*.0001			// from square meters into hectares
replace field_area_gps_ha=. if field_area_gps_ha==0 //replace 0 area observations with missings (321 observations)
la var field_area_gps_ha "Area of field, measured by GPS, in hectares pp_s3q05_a"

//Farmer-reported field area is measured in several units for which conversion factors are not available, so we cannot calculate field area in ha for ~1/3 of observations

gen local_unit = pp_s3q02_c
merge m:1 region zone woreda local_unit using "$input/Land Area Conversion Factor/ET_local_area_unit_conversion.dta", generate (_merge_units_pp3) keep(1 3)
// 12,479 matched; dropping unmatched from using

*For those missing conversion:
*Counts
bys region zone local_unit: egen count_conv_zone = count(conversion)
bys region local_unit: egen count_conv_region = count(conversion)
*Mean
bys region zone local_unit: egen mean_conv_zone = mean(conversion)
bys region local_unit: egen mean_conv_region = mean(conversion)
bys local_unit: egen mean_conv_eth = mean(conversion)

gen field_area_fr_ha=.
replace field_area_fr_ha=pp_s3q02_a/0.0001 if pp_s3q02_c==1				// First putting in m^2 (since this is the unit for the conversion factors)
replace field_area_fr_ha=pp_s3q02_a if pp_s3q02_c==2
replace field_area_fr_ha=pp_s3q02_a*conversion if field_area_fr_ha==.	// conversion factors are to sq meters
*Imputed values:
replace field_area_fr_ha=pp_s3q02_a*mean_conv_zone if field_area_fr_ha==. & count_conv_zone>=5 & count_conv_zone!=.
replace field_area_fr_ha=pp_s3q02_a*mean_conv_region if field_area_fr_ha==. & count_conv_region>=5 & count_conv_region!=.
replace field_area_fr_ha=pp_s3q02_a*mean_conv_eth if field_area_fr_ha==.
replace field_area_fr_ha = field_area_fr_ha*0.0001
la var field_area_fr_ha "Area of field, farmer reported, in hectares pp_s3q02"

//Generating a single area variable
gen field_area_ha=.
replace field_area_ha=field_area_gps_ha
replace field_area_ha=field_area_fr_ha if field_area_ha==. & field_area_fr_ha!=.	// Replace missing GPS area with farmer-reported, if available -- 442 changes
la var field_area_ha "field area measure, ha - GPS-based if they have one, farmer-report if not"

**Field rented out
gen field_rented_out=.
replace field_rented_out=1 if pp_s3q03==6
replace field_rented_out=0 if pp_s3q03!=6 & pp_s3q03!=.
la var field_rented_out "Field is rented out"

gen field_rented_out_ha=.
replace field_rented_out_ha=field_area_ha if field_rented_out==1
replace field_rented_out_ha=0 if field_rented_out==0
la var field_rented_out_ha "Area of rented out field"

//collapse to parcel level
collapse (sum) field_area_ha field_rented_out_ha field_rented_out, by (holder_id parcel_id)

la var field_area_ha "(sum) area of fields on parcel, ha"
la var field_rented_out "(sum) number of rented out fields on parcel"
la var field_rented_out_ha "(sum) area of rented out fields on parcel, ha"

save "$collapse/AG_field_roster_collapse.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			2. Prepare Parcel-Level Variables 								//
//////////////////////////////////////////////////////////////////////////////

***********************************************
//Merge data to holder-parcel level

clear
use "$collapse/sect_cover_pp_w3_collapse.dta"

//Merge in Household Roster data
merge 1:1 holder_id using "$collapse/AG_indy_collapse.dta", generate (_merge_AG_HH_Roster)
*3830 matched, 0 not matched 

//Merge in Parcel Roster data
merge 1:m holder_id using "$input/Post-Planting/sect2_pp_w3.dta", generate (_merge_AG_Parcel_Roster)
*15293 matched, 98 not matched
//tab farm_type if _merge_AG_Parcel_Roster==1, 86 are either livestock only or none for farm type, 12 are both 

//Merge in Collapsed Field Roster data at parcel level
merge 1:1 holder_id parcel_id using "$collapse/AG_field_roster_collapse.dta", generate (_merge_AG_Field_Roster)
*12144 matched, 3422 not matched, 3247 from master, 175 from using

drop if pp_s2q00==. //drop observations with no parcels, 273 obs
drop if pp_s2q01b==2 //drop parcels from previous wave that are no longer owned or rented by the holder, 2391 obs; leaves 12,902, 889 of which are not matched

***********************************************
//Create Variables

//Number of fields
gen number_plots=1
la var number_plots "Number of fields in this plot"

//Plot acquisition 
*asked of all but 1 plot (12902)

gen plot_acquisition=pp_s2q03
la var plot_acquisition "How did the HH acquire this plot?"

gen plot_granted=.
replace plot_granted=1 if pp_s2q03==1
replace plot_granted=0 if pp_s2q03!=1 & pp_s2q03!=.
la var plot_granted "HH was granted the plot by local leaders"

gen plot_inherited=.
replace plot_inherited=1 if pp_s2q03==2
replace plot_inherited=0 if pp_s2q03!=2 & pp_s2q03!=.
la var plot_inherited "HH inherited the plot"

gen plot_rentedin=.
replace plot_rentedin=1 if pp_s2q03==3
replace plot_rentedin=0 if pp_s2q03!=3 & pp_s2q03!=.
la var plot_rentedin "HH rented in the plot"

gen plot_usedfree=.
replace plot_usedfree=1 if pp_s2q03==4
replace plot_usedfree=0 if pp_s2q03!=4 & pp_s2q03!=.
la var plot_usedfree "HH used the plot for free"

gen plot_used_nopermission=.
replace plot_used_nopermission=1 if pp_s2q03==5
replace plot_used_nopermission=0 if pp_s2q03!=5 & pp_s2q03!=.
la var plot_used_nopermission "HH moved into the plot without permission"

gen plot_shared_crop=.
replace plot_shared_crop=1 if pp_s2q03==6
replace plot_shared_crop=0 if pp_s2q03!=6 & pp_s2q03!=.
la var plot_shared_crop "HH shared crop in parcel"

gen plot_purchased=.
replace plot_purchased=1 if pp_s2q03==7
replace plot_purchased=0 if pp_s2q03!=7 & pp_s2q03!=.
la var plot_purchased "HH purchased parcel"

gen plot_used_other=.
replace plot_used_other=1 if pp_s2q03==8
replace plot_used_other=0 if pp_s2q03!=8 & pp_s2q03!=.
la var plot_used_other "HH acquired the plot in other unspecified way"

gen plot_owned=.
replace plot_owned=1 if plot_granted==1 | plot_inherited==1 | plot_purchased==1	
replace plot_owned=0 if plot_granted==0 & plot_inherited==0 & plot_purchased==0
la var plot_owned "HH owns the plot, purchased, inherited, granted by local leaders"

//Ability to sell plot
*asked for 11,154 plots that aren't rented or borrowed for free

gen plot_right_sell=.
replace plot_right_sell=0 if pp_s2q03b==2
replace plot_right_sell=1 if pp_s2q03b==1
la var plot_right_sell "HH has right to sell plot or use as collateral"

//Gender of Plot Owner

**10219 respondents for this decision, will consider them the owners
gen fem_plot_owner = .
la var fem_plot_owner "First listed plot owner is female"
foreach x of numlist 1/14 {
	replace fem_plot_owner = 0 if pp_s2q03c_a == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_owner = 1 if pp_s2q03c_a == `x' & hhmem_fem_`x' == 1 
} 

gen fem_plot_co_owner = .
la var fem_plot_co_owner "Second listed plot owner is female"
foreach x of numlist 1/11 {
	replace fem_plot_co_owner = 0 if pp_s2q03c_b == `x' & hhmem_fem_`x' == 0 
	replace fem_plot_co_owner = 1 if pp_s2q03c_b == `x' & hhmem_fem_`x' == 1 
} 

gen fem_plot_owned = .
replace fem_plot_owned = 0 if fem_plot_owner == 0 | fem_plot_co_owner == 0
replace fem_plot_owned = 1 if fem_plot_owner == 1 | fem_plot_co_owner == 1
label variable fem_plot_owned "Plot owned or co-owned by female"

*Female only owned plots
generate fem_only_plot_own = .
replace fem_only_plot_own = 0 if (fem_plot_owner == 0 | fem_plot_co_owner == 0) 
replace fem_only_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 1) | (fem_plot_owner == 1 & fem_plot_co_owner==.) 
label variable fem_only_plot_own "Female-only owned plot"

*Male only owned plots
generate male_only_plot_own = .
replace male_only_plot_own = 0 if (fem_plot_owner == 1 | fem_plot_co_owner == 1)
replace male_only_plot_own = 1 if (fem_plot_owner == 0 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == .)    
label variable male_only_plot_own "Male-only owned plot"

*Mixed gender ownership plots
generate mixed_gen_plot_own = .
replace mixed_gen_plot_own = 0 if male_only_plot_own == 1 | fem_only_plot_own == 1
replace mixed_gen_plot_own = 1 if (fem_plot_owner == 1 & fem_plot_co_owner == 0) | (fem_plot_owner == 0 & fem_plot_co_owner == 1)
label variable mixed_gen_plot_own "Plot with mixed gender ownership"

//Age of Plot Owner

gen age_plot_owner = .
la var age_plot_owner "Age of first listed plot owner"

foreach x of numlist 1/14 {
	replace age_plot_owner=hhmem_age_`x' if pp_s2q03c_a == `x' 
} 

gen age_plot_co_owner = .
la var age_plot_co_owner "Age of second listed plot owner"

foreach x of numlist 1/11 {
	replace age_plot_co_owner=hhmem_age_`x' if pp_s2q03c_b == `x' 
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

//Parcel certificate
*asked for 11,175 plots that aren't rented or borrowed for free

gen plot_certificate=.
replace plot_certificate=0 if pp_s2q04==2
replace plot_certificate=1 if pp_s2q04==1
la var plot_certificate "HH has a certificate for this plot"

**6243 respondents for certificate holding
gen plot_certificate_fem = .
la var plot_certificate_fem "First listed plot certificate holder is female"
foreach x of numlist 1/9 {
	replace plot_certificate_fem = 0 if pp_s2q06_a == `x' & hhmem_fem_`x' == 0 
	replace plot_certificate_fem = 1 if pp_s2q06_a == `x' & hhmem_fem_`x' == 1 
} 

gen plot_certificate_fem2 = .
la var plot_certificate_fem2 "Second listed plot certificate holder is female"
foreach x of numlist 1/9 {
	replace plot_certificate_fem2 = 0 if pp_s2q06_b == `x' & hhmem_fem_`x' == 0 
	replace plot_certificate_fem2 = 1 if pp_s2q06_b == `x' & hhmem_fem_`x' == 1 
}

//Land rental cost and income (birr)
egen land_rentin_cost = rowtotal(pp_s2q07_a pp_s2q07_b)		
la var land_rentin_cost "How much did you pay for use of this plot, cash and in-kind value"

gen land_rental_any=pp_s2q10 
recode land_rental_any pp_s2q10 (3=.)
la var land_rental_any "Were any fields on this plot rented out?"

gen plot_rentedout = land_rental_any
la var plot_rentedout "Plot had fields rented out"

egen land_rental_income = rowtotal(pp_s2q13_a pp_s2q13_b)
la var land_rental_income "How much did you receive for renting out this plot, cash and in-kind value"

//Value of renting out parcel

gen plot_rent_value=pp_s2q11
la var plot_rent_value "Estimated value of renting out plot for 12 months"

//Area

gen plot_area=field_area_ha
la var plot_area "Plot area, ha"

gen plot_area_rentedout=field_rented_out_ha
la var plot_area_rentedout "Plot area, rented out, ha"

gen plot_area_owned=field_area_ha if plot_owned==1
replace plot_area_owned=0 if plot_owned==0
la var plot_area_owned "Plot area, owned plot, ha"

gen plot_area_notowned=field_area_ha if plot_owned==0
replace plot_area_notowned=0 if plot_owned==1
la var plot_area_notowned "Plot area, not owned plot, ha"

gen plot_area_rentedin=field_area_ha if plot_rentedin==1
replace plot_area_rentedin=0 if plot_rentedin==0
la var plot_area_rentedin "Plot area, rented in plot, ha"

gen plot_area_usedfree=field_area_ha if plot_usedfree==1
replace plot_area_usedfree=0 if plot_usedfree==0
la var plot_area_usedfree "Plot area, used free plot, ha"

gen plot_area_shared_crop=field_area_ha if plot_shared_crop==1
replace plot_area_shared_crop=0 if plot_shared_crop==0
la var plot_area_usedfree "Plot area, shared crop in plot, ha"

gen plot_area_plot_purchased=field_area_ha if plot_purchased==1
replace plot_area_plot_purchased=0 if plot_purchased==0
la var plot_area_plot_purchased "Plot area, purchased plot, ha"

gen plot_area_used_nopermission=field_area_ha if plot_used_nopermission==1
replace plot_area_used_nopermission=0 if plot_used_nopermission==0
la var plot_area_used_nopermission "Plot area, used without permission plot, ha"

gen plot_area_used_other=field_area_ha if plot_used_other==1
replace plot_area_used_other=0 if plot_used_other==0
la var plot_area_used_other "Plot area, plot acquired in other unspecified way, ha"

//other plot classification variables
gen plot_notown=0
replace plot_notown=1 if plot_owned==0
la var plot_notown "HH does not own the plot"

generate plot_rightsell = 0 
replace plot_rightsell = 1 if plot_right_sell == 1
la var plot_rightsell "HH has right to sell plot or use as collateral"

gen plot_cert=0
replace plot_cert=1 if plot_certificate==1
la var plot_cert "HH has a certificate for this plot"

//create plot weights, household weight (pw_w3) times plot area, as per World Bank practice
gen plot_weight = pw_w3*plot_area	
replace plot_weight = pw_w3 if plot_weight==.

save "$merge/AG_parcel_roster_collapseprep.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			3. Summary Statistics at Plot Level						        //
//////////////////////////////////////////////////////////////////////////////

clear
use "$merge/AG_parcel_roster_collapseprep.dta"

svyset clusterid [pweight=plot_weight], strata(strataid) singleunit(centered)

//Gender of Plot Owner - sample is plots with land use decision-maker information, 9777 of 12545
**Summary stats Via Marghera, 43, 00185 Romafor fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own

eststo plots1: svy, subpop(if fem_plot_owned!=.): mean fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]		
eststo plots1a: svy, subpop(if plot_certificate==1): mean fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own 	
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]	
eststo plots1b: svy, subpop(if plot_certificate==0): mean fem_plot_owned fem_only_plot_own male_only_plot_own mixed_gen_plot_own
matrix N = e(_N)
estadd scalar subpop_N = N[1,1]	
esttab plots1 plots1a plots1b using "$output/ETH_W3_plot_table1.rtf", cells(b(fmt(3)) & se(fmt(3) par)) label mlabels("Owned Plots HH Has Right to Sell or Use as Collateral" "Owned plots with a Certificate" "Owned plots with No Certificate" ) collabels(none) title("Table 1. Proportion of owned plots by gender and title")  /// 
note("Respondents were asked to specify up to two household members as deciding whether to sell or use the plot as collateral, typically with the head of household listed first, and we designate these as plot owners. Plots with a female owner had a female listed as either the first or second plot owner, and may also have a male owner. The sample is plots the HH has the right to sell or use as collateral, which we use as a proxy for 'owned' plots. Estimates are plot-level cluster-weighted means, with standard errors in parentheses.") replace stats(subpop_N, label("Observations") fmt(0))



///// HOH Education///
clear 
use "$input\Household\sect2_hh_w3.dta"

*** can hoh read and write?
gen hoh_literate=1 if hh_s2q00==1 & hh_s2q02!=. 
replace hoh_literate=0 if hh_s2q00==1 & hh_s2q02==2 
la var hoh_literate "Can the head of household read and write?; YES=1 NO=2" 

collapse (max) hoh_literate, by (household_id household_id2)

save "$collapse/HOH_educ_collapse.dta", replace

////////////HH CONSUMPTION///////////
use "$merge/AG_parcel_roster_collapseprep.dta"
merge m:1 household_id household_id2 using "$collapse/HOH_educ_collapse.dta", gen (_merge_HHEDUC_2015)

merge m:1 household_id household_id2 using "$input\Consumption Aggregate\cons_agg_w3.dta", gen (_merge_HHConsumption_2015)

*Expenditure per adult equivalent in the household
gen consum_per_adult = nom_totcons_aeq
la var consum_per_adult "nominal annual consumption per adult equivalent"

*Daily expenditure per adult equivalent in the household
gen consum_per_adult_daily = .
replace consum_per_adult_daily = consum_per_adult/365

****2016 implied PPP Conversion Rate is 8.61
****CPI in 2016 was 224.27
****CPI in in 2013 was 209.078
gen inflation=1+((224.27-209.078)/209.078)
gen usd_bir_exchange=8.61


*Convert the expenditure values from Tanzanian Shillings to US Dollars
gen dailycons=consum_per_adult_daily*inflation/usd_bir_exchange
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


//create categorical variables 
gen plot_own_gender=.
replace plot_own_gender=1 if male_only_plot_own==1
replace plot_own_gender=2 if fem_only_plot_own==1
replace plot_own_gender=3 if mixed_gen_plot_own==1
la var plot_own_gender "1 if male only, 2 if female only, 3 if mixed"

save "$merge\ETH_W3_Parcel_All.dta", replace 


//////////////////////////////////////////////////////////////////////////////
// 			4. Generate Land Tenure Variables at HH Level					//
//////////////////////////////////////////////////////////////////////////////

////////Collapse plot-level data to HH level
clear
use "$merge/ETH_W3_Parcel_All.dta"

gen plot_rent_value_owned = plot_rent_value if plot_owned

local sum_vars number_plot plot_certificate plot_area plot_area_owned plot_area_notowned plot_area_rentedin plot_area_usedfree plot_area_rentedout plot_area_shared_crop plot_area_plot_purchased ///
plot_area_used_nopermission plot_area_used_other plot_granted plot_inherited plot_rentedin plot_usedfree plot_shared_crop plot_purchased plot_used_nopermission plot_used_other plot_owned plot_rentedout  /// 
plot_rent_value plot_right_sell fem_plot_owned land_rentin_cost land_rental_income plot_rent_value_owned
collapse (max) dailycons poverty125 poverty2 hoh_literate (sum) `sum_vars', by (household_id2) 

la var number_plot "(sum) Total number of plots for the household"
la var plot_certificate "(sum) Plots for which HH has a certificate"
la var plot_area "(sum) Plot area measure, all plots, ha"
la var plot_area_owned "(sum) Plot area, owned plots (granted/inherited), ha"
la var plot_area_notowned "(sum) Plot area, not owned plots, ha"
la var plot_area_rentedin "(sum) Plot area, rented in plots, ha"
la var plot_area_usedfree "(sum) Plot area, used free of charge plots, ha"
la var plot_area_rentedout "(sum) Plot area, rented out, ha"
la var plot_area_shared_crop "(sum) Plot area, shared crop plots, ha"
la var plot_area_plot_purchased "(sum) Plot area, purchased plots, ha"
la var plot_area_used_nopermission "(sum) Plot area, used without permission plot, ha"
la var plot_area_used_other "(sum) Plot area, plot acquired in other unspecified way, ha"
la var plot_granted "(sum) Number of plots granted by local leaders"
la var plot_inherited "(sum) Number of plots inherited"
la var plot_rentedin "(sum) Number of plots rented in"
la var plot_usedfree "(sum) Number of plots used for free"
la var plot_shared_crop "(sum) Number of plots shared crop"
la var plot_purchased "(sum) Number of plots purchased"
la var plot_usedfree "(sum) Number of plots used for free"
la var plot_used_nopermission "(sum) Number of plots used without permission"
la var plot_used_other "(sum) Number of plots acquired in other unspecified way"
la var plot_owned "(sum) Number of plots owned (inherited or granted by local leaders)"
la var plot_rentedout "(sum) Number of plots with fields rented out"
la var plot_rent_value "(sum) Estimated value of renting out plots for 12 months, birr"
la var plot_right_sell "(sum) Number of plots the HH has right to sell or use as collateral"
la var fem_plot_owned "(sum) Number of plots owned or co-owned by females"
la var land_rentin_cost "(sum) Payment for use of plots, cash and in-kind value, birr"
la var land_rental_income "(sum) Income for renting out plots, cash and in-kind value, birr"


////SMALLHOLDER////

gen smallholder2 = .
replace smallholder2 = 1 if plot_area <=2
replace smallholder2 = 0 if plot_area >2 & plot_area!= . 
la var smallholder2 "total area 2ha or less"

gen smallholder2_owned = .
replace smallholder2_owned = 1 if plot_area_owned <=2
replace smallholder2_owned = 0 if plot_area_owned >2 & plot_area_owned!= . 
la var smallholder2 "total area owned 2ha or less"


save "$collapse/ETH_W3_Plot_HH_sum_collapse.dta", replace

////////Get data on gender of Head of HH
clear
use "$input/Household/sect1_hh_w3.dta"

gen hoh_sex=.	
replace hoh_sex=0 if hh_s1q03==1 & hh_s1q02==1
replace hoh_sex=1 if hh_s1q03==2 & hh_s1q02==1
replace hoh_sex=0 if hh_s1q04e==1 & hh_s1q02==1
replace hoh_sex=1 if hh_s1q04e==2 & hh_s1q02==1

collapse (max) hoh_sex, by (household_id2) 

replace hoh_sex=1 if hoh_sex==. 
la var hoh_sex "Sex of the head of household"	

save "$collapse/ETH_W3_HoH_sex_collapse.dta", replace


////////Merge in HHs that did not complete ag section
clear
use "$input/Household/sect_cover_hh_w3.dta"

merge 1:1 household_id2 using "$collapse/ETH_W3_Plot_HH_sum_collapse.dta", gen (_merge_ag_hh) 
**3619 matched, 1335 not matched from master - did not complete ag questionnaire, 27 not matched from using
drop if _merge_ag_hh==2

merge 1:1 household_id2 using "$collapse/ETH_W3_HoH_sex_collapse.dta", gen (_merge_hoh_sex) 
**4954 matched

//generate strata and cluster variables for analysis with survey weights
gen clusterid=ea_id2 //first stage sampling unit

gen strataid=saq01 if rural==1 //assign region as strataid to rural respondents; regions from from 1 to 7 and then 12 to 15
gen stratum_id=.
replace stratum_id=16 if rural==2 & saq01==1 //Tigray, small town
replace stratum_id=17 if rural==2 & saq01==3 //Amhara, small town
replace stratum_id=18 if rural==2 & saq01==4 //Oromiya, small town
replace stratum_id=19 if rural==2 & saq01==7 //SNNP, small town
replace stratum_id=20 if rural==2 & (saq01==2 | saq01==5 | saq01==6 | saq01==12 | saq01==13 | saq01==15) //Other regions, small town
replace stratum_id=21 if rural==3 & saq01==1 //Tigray, large town
replace stratum_id=22 if rural==3 & saq01==3 //Amhara, large town
replace stratum_id=23 if rural==3 & saq01==4 //Oromiya, large town
replace stratum_id=24 if rural==3 & saq01==7 //SNNP, large town
replace stratum_id=25 if rural==3 & saq01==14 //Addis Ababa, large town
replace stratum_id=26 if rural==3 & (saq01==2 | saq01==5 | saq01==6 | saq01==12 | saq01==13 | saq01==15) //Other regions, large town

replace strataid=stratum_id if rural!=1 //assign new strata IDs to urban respondents, stratified by region and small or large towns


//Replace missings with 0s
foreach var of varlist number_plot plot_certificate plot_area plot_area_owned plot_area_notowned plot_area_rentedin plot_area_usedfree plot_area_rentedout plot_shared_crop plot_purchased ///
plot_area_used_nopermission plot_area_used_other plot_granted plot_inherited plot_rentedin plot_usedfree plot_used_nopermission plot_used_other plot_owned plot_rentedout plot_area_shared_crop plot_area_plot_purchased  /// 
plot_rent_value plot_right_sell fem_plot_owned land_rentin_cost land_rental_income plot_rent_value_owned{
	replace `var'=0 if `var'==.
}


//Winsorize top 1% of continuous variables (replace with 99th percentile)
local trimming plot_area plot_area_owned plot_area_notowned plot_area_rentedin plot_area_usedfree plot_area_rentedout plot_area_used_nopermission plot_area_used_other plot_rent_value land_rentin_cost land_rental_income
winsor2 `trimming', suffix(_w) cuts(0 99)
//not using these

//Construct additional variables
**any plot ownership dummy 
gen ownership_any=0
replace ownership_any=1 if plot_owned>0 & plot_owned!=.
la var ownership_any "HH owns at least 1 plot (granted or inherited)"

**proportion of plots with right to sell or use as collateral
gen plot_right_sell_prop=plot_right_sell/number_plot
la var plot_right_sell_prop "Proportion of plots HH has right to sell or use as collateral"

save "$merge/ETH_W3_HH_Level.dta", replace

//////////////////////////////////////////////////////////////////////////////
// 			5. Generate Land Tenure Variables at Community Level			//
//////////////////////////////////////////////////////////////////////////////

clear 
use "$input/Community/sect03_com_w3.dta"

**share of community land to different uses
gen land_pct_bush=cs3q09
gen land_pct_largescalefarms=cs3q10
gen land_pct_forest=scsq11
replace land_pct_bush=0 if land_pct_bush==. | land_pct_bush>100
replace land_pct_largescalefarms=0 if land_pct_largescalefarms==. | land_pct_largescalefarms>100
replace land_pct_forest=0 if land_pct_forest==. | land_pct_forest>100
la var land_pct_bush "Share of land in the community that is in bush"
la var land_pct_largescalefarms "Share of land in the community that is in large scale farms"
la var land_pct_forest "Share of land in the community that is in forest"

save "$collapse/ETH_W3_Community_Level.dta", replace
