import matplotlib

x=randn(10000)
hist(x,100)
sql_s='select count(*) from grid_quarters_public where quarter="2010_q2"';
