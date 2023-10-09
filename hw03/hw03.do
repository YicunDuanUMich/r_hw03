clear
// Load VIX_D.
import sasxport5 "L:\umich\stat506\r_hw03\hw03\data\VIX_D.XPT", clear
// Save VIX_D into a dta file `vid_d.dta`.
save "L:\umich\stat506\r_hw03\hw03\data\vid_d.dta", replace

// Load DEMO_D.
import sasxport5 "L:\umich\stat506\r_hw03\hw03\data\DEMO_D.XPT", clear
// Save DEMO_D into a dta file `demo_d.dta`.
save "L:\umich\stat506\r_hw03\hw03\data\demo_d.dta", replace

// Open the `vid_dta`.
use "L:\umich\stat506\r_hw03\hw03\data\vid_d.dta", clear
// Merge data on the key SEQN and only keep the records which matched.
merge 1:1 seqn using "L:\umich\stat506\r_hw03\hw03\data\demo_d.dta",  keep(match)

// Show the total number.
display _N

// Rename the columns for easy understanding.
rename viq220 glass_wear
rename ridageyr age_year
rename riagendr gender
rename ridreth1 race
rename indfmpir pir


preserve

// Keep the records of respondents who wear glasses/contact lenses for distance vision.
keep if (glass_wear == 1 & !missing(glass_wear)) /// 
		& (age_year >= 0 & !missing(age_year))
// Generate a new variable to show the age categories.
generate age_categories=recode(age_year, 9, 19, 29, 39, 49, 59, 69, 79, 89)
label define rename_age_cat 9 "[0, 9]" 19 "[10, 19]" 29 "[20, 29]" 39 "[30, 39]" ///
							49 "[40, 49]" 59 "[50, 59]" 69 "[60, 69]" 79 "[70, 79]" ///
							89 "[80, 89]"
// Rename the labels for clear display.
label values age_categories rename_age_cat
label variable age_categories "Age Categories"
tabulate age_categories

restore


// Data clean.
// Remove the missing data and invalid data from glass_wear and age_year.
keep if (glass_wear == 1 | glass_wear == 2) & !missing(glass_wear) ///
		& age_year >= 0 & !missing(age_year)
// Remove the missing data from race and gender.
keep if !missing(race) & !missing(gender)
// Remove the missing data from pir.
keep if !missing(pir)

// Build model `gw_a`.

// Originally, 1 means the respondent wears glasses,
// and 2 means the repondent doesn't wear glasses.
// We replace glass_wear == 2 with 1.
replace glass_wear = 0 if glass_wear == 2
// Fit logistic regression model with glass_wear as response and age as predictor.
logistic glass_wear c.age_year
// Estimate AIC.
estat ic
// Store the estimation results. 
// `e(b)` is coefficients.
// `e(N)` is sample size.
// `r2_p` is the pseudo R^2.
// `r(S)[1, 5]` is the AIC value.
matrix gw_a_coef = e(b)
local gw_a_N e(N)
local gw_a_r2_p e(r2_p)
local gw_a_aic r(S)[1, 5]
matrix gw_a_nra_matrix = (`gw_a_N', `gw_a_r2_p', `gw_a_aic')
// Save the model.
estimates store gw_a


// Build model `gw_arg`

// Fit logistic regression model with glass_wear as response, 
// age, race, gender as predictors.
logistic glass_wear c.age i.race i.gender
// Estimate AIC.
estat ic
// Store the estimation results.
matrix gw_arg_coef = e(b)
local gw_arg_N e(N)
local gw_arg_r2_p e(r2_p)
local gw_arg_aic r(S)[1, 5]
matrix gw_arg_nra_matrix = (`gw_a_N', `gw_a_r2_p', `gw_a_aic')
// Save the model.
estimates store gw_arg


// Build model `gw_argp`

// Fit a logistic regression model with glass_wear as reponse,
// age, race, gender and pir as predictors.
logistic glass_wear c.age i.race i.gender c.pir
// Estimate AIC.
estat ic
// Store the estimation results.
matrix gw_argp_coef = e(b)
local gw_argp_N e(N)
local gw_argp_r2_p e(r2_p)
local gw_argp_aic r(S)[1, 5]
matrix gw_argp_nra_matrix = (`gw_a_N', `gw_a_r2_p', `gw_a_aic')
// Save the model.
estimates store gw_argp

// Use MATA to build a table (i.e., a matrix) summarizing the estimation results of three models.
mata:
// Load matrix from STATA.
gw_a_coef = st_matrix("gw_a_coef")
gw_a_nra_matrix = st_matrix("gw_a_nra_matrix")
gw_arg_coef = st_matrix("gw_arg_coef")
gw_arg_nra_matrix = st_matrix("gw_arg_nra_matrix")
gw_argp_coef = st_matrix("gw_argp_coef")
gw_argp_nra_matrix = st_matrix("gw_argp_nra_matrix")

// Combine the matrices to formulate a succinct matrix.
gw_a = (exp(gw_a_coef[1, 1]), J(1, 8, 0), exp(gw_a_coef[1, 2]), gw_a_nra_matrix)
gw_arg = (exp(gw_arg_coef[1, 1..8]), 0, exp(gw_arg_coef[1, 9]), gw_arg_nra_matrix)
gw_argp = (exp(gw_argp_coef), gw_argp_nra_matrix)
report_matrix = (gw_a \ gw_arg \ gw_argp)

// Put the matrix back to STATA.
st_matrix("report_matrix", report_matrix)
end

// Rename the columns and rows of the report matrix for clear display.
matrix colnames report_matrix = "age_year" ///
								"1b.race" "2.race" "3.race" "4.race" "5.race" ///
								"1b.gender" "2.gender" ///
								"pir" "_cons" ///
								"N" "R2" "AIC"
matrix rownames report_matrix = "gw_a" "gw_arg" "gw_argp"

matrix list report_matrix



// Reload the third model.
estimates restore gw_argp
// Replay the regression.
logistic

// Show the the proportion of wearers of glasses/contact lenses for distance vision
// with respect to men and women
label define rename_gender 1 "Male" 2 "Female", replace
label values gender rename_gender
label define rename_glass_wear 0 "No" 1 "Yes", replace
label values glass_wear rename_glass_wear
tabulate gender glass_wear, row

