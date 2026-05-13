//Figure2
//Immediate Rise in Government Spending

//Consumption taste shock
shocks;
var eps_con;
periods 1:1;
values(-sig_con);
end;


//Government spending shock
//FIRST SIMULATION(Both shocks)
shocks;
var eps_gov;
periods 1:1;
values (sig_gov);
end;
simul(periods=40);
//Save IRFS
irfs_gov1 = oo_.endo_simul;


//SECOND SIMULATION  (Taste shock only)
shocks;
var eps_gov;
periods 1:1;
values (0);
end;
simul(periods=40);
//save IRFS
irfs_gov2 = oo_.endo_simul;


//THIRD SIMULATION   (Government shock only)
shocks;
var eps_con;
periods 1:1;
values (0);
var eps_gov;
periods 1:1;
values (sig_gov);
end;
simul(periods=40);
//save IRFS
irfs_gov3 = oo_.endo_simul;

mkdir('output');
mkdir('output/data');
if xip == 1
	figure_id = 'figure-2-no-inflation-response';
elseif xip == 0.8 && gam_xgap == 0.2 && gam_pi == 1.5
	figure_id = 'figure-2-5-quarter-new-taylor-rule';
elseif xip == 0.8
	figure_id = 'figure-2-5-quarter-price-contract';
else
	figure_id = sprintf('figure-2-xip-%0.2f', xip);
end;

fid = fopen(sprintf('output/data/%s.csv', figure_id), 'w');
fprintf(fid, 'figure_id,xip,quarter,variable,series,value\n');
for t = 2:20
	quarter = t-2;
	fprintf(fid, '%s,%.15g,%d,real_interest_rate,both_shocks,%.15g\n', figure_id, xip, quarter, 400*irfs_gov1(11,t));
	fprintf(fid, '%s,%.15g,%d,real_interest_rate,taste_shock_only,%.15g\n', figure_id, xip, quarter, 400*irfs_gov2(11,t));
	fprintf(fid, '%s,%.15g,%d,real_interest_rate,government_shock_only,%.15g\n', figure_id, xip, quarter, 400*(irfs_gov1(11,t)-irfs_gov2(11,t)));
	fprintf(fid, '%s,%.15g,%d,output_gap,both_shocks,%.15g\n', figure_id, xip, quarter, 100*irfs_gov1(1,t));
	fprintf(fid, '%s,%.15g,%d,output_gap,taste_shock_only,%.15g\n', figure_id, xip, quarter, 100*irfs_gov2(1,t));
	fprintf(fid, '%s,%.15g,%d,output_gap,government_shock_only,%.15g\n', figure_id, xip, quarter, 100*(irfs_gov1(1,t)-irfs_gov2(1,t)));
	fprintf(fid, '%s,%.15g,%d,inflation,both_shocks,%.15g\n', figure_id, xip, quarter, 400*irfs_gov1(2,t));
	fprintf(fid, '%s,%.15g,%d,inflation,taste_shock_only,%.15g\n', figure_id, xip, quarter, 400*irfs_gov2(2,t));
	fprintf(fid, '%s,%.15g,%d,inflation,government_shock_only,%.15g\n', figure_id, xip, quarter, 400*(irfs_gov1(2,t)-irfs_gov2(2,t)));
	fprintf(fid, '%s,%.15g,%d,government_debt_to_gdp,both_shocks,%.15g\n', figure_id, xip, quarter, 25*irfs_gov1(6,t));
	fprintf(fid, '%s,%.15g,%d,government_debt_to_gdp,taste_shock_only,%.15g\n', figure_id, xip, quarter, 25*irfs_gov2(6,t));
	fprintf(fid, '%s,%.15g,%d,government_debt_to_gdp,government_shock_only,%.15g\n', figure_id, xip, quarter, 25*(irfs_gov1(6,t)-irfs_gov2(6,t)));
end;
fclose(fid);

//Some additional calculations
//Calculate positive output of government spending shock on debt
gov_debt_govshk = irfs_gov1(6,1:20) - irfs_gov2(6,1:20)
gov_debt_govshk_duration = gov_debt_govshk < 0
sum (gov_debt_govshk_duration)

//Calculate liquidity trap duration
liqduration =  [sum(irfs_gov1(3,1:end) == -ibar) sum(irfs_gov2(3,1:end) == -ibar)]

//Calculate government spending multiplier
y1 = irfs_gov1(10,2);
g1 = irfs_gov1(8,2);
y2 = irfs_gov2(10,2);
g2 = irfs_gov2(8,2);

mul1 = (y1 - y2)/(g1 - g2) * 1/shrgy

//Calculate output gap response
x = 100*(irfs_gov1(1,2) - irfs_gov2(1,2))

//Calculate potential output response
ypot = 100*(irfs_gov1(4,2) - irfs_gov2(4,2))

mul = x + ypot

//Calculate (negativ) change in government debt after 4 Quartes due to government spending increase
debtgov= irfs_gov1(6,4) - irfs_gov2(6,4)
