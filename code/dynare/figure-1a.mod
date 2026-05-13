//Figure1a
//Negative Taste Shock and Fiscal Response

//Consumption taste shock
shocks;
var eps_con;
periods 1:1;
values(-sig_con);
end;


//Government spending shock
//FIRST SIMULATION  (Taste shock only)
shocks;
var eps_gov;
periods 1:1;
values (0);
end;
simul(periods=150);
//save irfs
irfs_gov0 = oo_.endo_simul;

//SECOND SIMULATION  (Government spending increase of 1%)
shocks;
var eps_gov;
periods 1:1;
values (sig_gov);
end;
simul(periods=150);
//save irfs
irfs_gov1 = oo_.endo_simul;

//THIRD SIMULATION   (Government spending increase of 2%)
shocks;
var eps_gov;
periods 1:1;
values (0.1);
end;
simul(periods=150);
//save irfs
irfs_gov2 = oo_.endo_simul;


mkdir('output');
mkdir('output/data');
fid = fopen('output/data/figure-1a.csv', 'w');
fprintf(fid, 'quarter,series,value\n');
for t = 2:16
	fprintf(fid, '%d,potential_real_rate_taste_shock_only,%.15g\n', t-2, 400*irfs_gov0(5,t));
	fprintf(fid, '%d,nominal_interest_rate_taste_shock_only,%.15g\n', t-2, 400*irfs_gov0(3,t));
	fprintf(fid, '%d,potential_real_rate_1_percent_g_increase,%.15g\n', t-2, 400*irfs_gov1(5,t));
	fprintf(fid, '%d,potential_real_rate_2_percent_g_increase,%.15g\n', t-2, 400*irfs_gov2(5,t));
end;
fclose(fid);

//Calculate liquidity trap duration
liqduration =  [sum(irfs_gov1(3,1:end) == -ibar) sum(irfs_gov2(3,1:end) == -ibar)]
