proc import 
	out = mhdata
	datafile = '/path/to/excel/file'
	dbms = xlsx replace;
run;
proc contents data = mhdata;
run;
/*Recode variables as numeric;*/
data mh_data(keep = record_id response_1 -- response_7 covid_incident disease);
	set mhdata;
	array old{7} t1_response_1 -- t1_response_7;
	array new{7} t1_1-t1_7;
	do i = 1 to 7;
	new{i} = input(old{i}, ??comma9.);
end;
rename /*rename variables for clarity;*/
t1_1=response_1
t1_2=response_2
t1_3=response_3
t1_4=response_4
t1_5=response_5
t1_6=response_6
t1_7=response_7;
run;
proc contents data = mh_data;
run;
/*create correlation matrix;*/
proc corr data = mh_data spearman;
run;
/*Principal Component Analysis;*/
proc princomp data = mh_data
	cov
	outstat=pca;
	var response_1 -- response_7;
run;
proc print data=pca noobs;
    var _character_ _numeric_;
    format _numeric_ 8.3; /* Rounds numeric values to three decimal places */
run;
/*Export PCA results;*/
/* Create datasets for the results */
ods output Eigenvalues=Eigenvalues
           Eigenvectors=Eigenvectors;

proc princomp data=mh_data cov;
    var response_1 -- response_7;
run; quit;
/*export PCA results;*/
ods close;
options nocenter nodate nonumber;
title 'Principal Component Analysis';
title2 'PCA on Latent Variables Relating to disease';
ods rtf file = '/home/u64004483/eigenvalues.rtf' bodytitle_aux style = journal;
/* Round the Eigenvalues */
data Eigenvalues;
    set Eigenvalues;
    array num_vars _numeric_;
    do over num_vars;
        num_vars = round(num_vars, 0.001);
    end;
run;
/* Round the Eigenvectors */
data Eigenvectors;
    set Eigenvectors;
    array num_vars _numeric_;
    do over num_vars;
        num_vars = round(num_vars, 0.001);
    end;
run;

/* Print the rounded results */
proc print data=Eigenvalues noobs; 
    title 'Eigenvalues';
    format _numeric_ 8.3; 
run;
ods rtf close;
ods close;
options nocenter nodate nonumber;
title 'Figure 2';
ods rtf file = '/home/u64004483/thesis/eigenvectors.rtf' bodytitle_aux style = journal;
/* Print the rounded results */
proc print data=Eigenvectors noobs; 
    title 'Eigenvectors';
    format _numeric_ 8.3; 
run;
ods rtf close;
/*Factor Analysis;*/
proc factor data = mh_data(keep = response_1 -- response_7) 
	n = 3 
	covariance 
	method = principal 
	ev;
run;
/*Export Graphics;*/
ods _all_ close;
options nocenter nodate nonumber;
title 'Figure 1';
ods  file = '/home/u64004483/thesis/Corr_matrix.rtf' bodytitle_aux style = journal;
proc corr data = mh_data spearman;
run; quit;
ods rtf close;
ods _all_ close;
options nocenter nodate nonumber;
title 'Principal Component Analysis';
title2 'PCA on Latent Variables Relating to disease';
ods rtf file = '/home/u64004483/thesis/PCA_results.rtf' bodytitle_aux style = journal;
proc princomp data = mh_data cov plots=scree ;
	var response_1 -- response_7;
run; quit;
ods rtf close;
options nocenter nodate nonumber;
ods rtf file = '/home/u64004483/thesis/FA_results.rtf' bodytitle_aux style = journal;
proc factor data = mh_data(keep = response_1 -- response_7) 
	n = 3 
	covariance 
	method = principal 
	ev
	rotate=varimax
	plot=scree;
run;
ods rtf close;
/*logistric regression (continued in R);*/
/*Merge data for observing disease outcome;*/
proc import 
datafile='/path/to/csv' 
dbms=csv
out=confounders;
run;
data confounders;
	set confounders;
	drop response_1 response_2 response_3 response_4 response_5 response_6 response_7;
	if age.at.consent >= 20;
run;
data mh_data_pc;
	set mh_data;
	if disease = "NA" then longcovid = .;
	else longcovid = input(disease, ?? best32.);
	pc1=(pc1(1,1)*response_1+(pc1(2,1))*response_2+(pc1(3,1))*response_3+(pc1(4,1))*response_4+(pc1(5,1))*response_5+(pc1(6,1))*response_6+(pc1(7,1))*response_7;
	pc2=pc2(1,1)*response_1+pc2(2,1)*response_2+pc2(3,1)*response_3+pc2(4,1)*response_5+pc2(5,1)*response_6;
	pc3=pc3(1,1)*response_1+pc3(2,1)*response_4+pc3(3,1)*response_5+pc3(4,1)*response_6;
run;
proc sort data=mh_data_pc;
by record_id;
run;
proc sort data = confounders;
by record_id;
run;
data mh_pc_adjusted;
	merge mh_data_pc confounders;
	by record_id;
run;
data mh_data_pc_factor;
	set mh_data_pc;
	fac1=0.876*response_1+0.804*response_2+0.787*response_3+0.667*response_7;
	fac2=0.693*response_4+0.81*response_5;
	fac3=0.895*response_6;
run;
data mh_adjusted;
	merge mh_data_pc_factor confounders;
run;
*ensure all variables were included correctly;
proc contents data=mh_pc_adjusted;
run;
*export dataset for use in R;
proc export data=mh_pc_adjusted
	outfile='/desired/path/to/new/PCAdata'
	dbms=csv
	replace;
run;
proc export data=mh_adjusted
	outfile='/desired/path/to/new/FAdata'
	dbms=csv
	replace;
run;
ods _all_ close;
options nocenter nodate nonumber;
title 'Figure 3';
ods rtf file = '/path/to/EFA_results.rtf' bodytitle_aux style = journal;
proc factor data = mh_data(keep = response_1 -- response_7) n = 3 method=prinit cov;
pathdiagram fuzz = 0.2;
run; quit;
ods rtf close;
