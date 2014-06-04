dbname='boston_cars';
username='tgebru';
password='';
driver='com.mysql.jdbc.Driver';
dburl = ['jdbc:mysql://localhost:3306/' dbname];
javaclasspath('mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar');

table_names= {'rae_public','grid_quarters_public',};
cities={'boston','springfield','worcester'};
muni_ids=[35,281,348];
place_ids=[07000,67000,82000];

%% Independent variables?
variables={'pop10','pop5_17_10','pop1864_10','pop65p_10','hhpop_10','hh10','fam10','nfam10','hu10','occhu10','ownhu10','rnthu10','vachu10','n11_biz','n11_emp','n21_biz','n21_emp','n22_biz','n22_emp','n23_biz','n23_emp','n31_33_biz','n31_33_emp','n42_biz','n42_emp','n44_45_biz','n44_45_emp','n48_49_biz','n48_49_emp','n51_biz','n51_emp','n52_biz','n52_emp','n53_biz','n53_emp','n54_biz','n54_emp','n55_biz','n55_emp','n56_biz','n56_emp','n61_biz','n61_emp','n62_biz','n62_emp','n71_biz','n71_emp','n72_biz','n72_emp','n81_biz','n81_emp','n92_biz','n92_emp','na_biz','na_emp','total_biz','total_emp','pbld_sqm','prow_sqm','pttlasval','ppaved_sqm','far_agg','mu_psqm','ag_psqm','comlo_psqm','comhi_psqm','inst_psqm','indus_psqm','pub_psqm','res_psqm','oth_psqm','tot_psqm','intsctnden','sidewlksqm','schwlkindx','exit_dist'}
variable_description=cell(length(variables),1);
dependent={'veh_tot'}
dependent_description={'Total number of vehicles in grid cell'}

correlation_type='spearman';

results_dir=sprintf('./results/zipcode_ground/%s/%s',correlation_type,dependent{1});
if ~exist(results_dir)
  mkdir(results_dir)
end

legend_str='';
for i=1:1 %length(cities)
  conn = database(dbname, username, password, driver, dburl);
  veh_zip_query=sprintf('select distinct(zip_code), sum(veh_tot) from grid250m_attributes join grid_quarters_public using(g250m_id) where muni_id=%d group by zip_code',muni_ids(i))
  veh_zip_data=get(fetch(exec(conn,veh_zip_query)),'Data');
  zip=[veh_zip_data{:,1}];
  zero_zip=find(zip==0);
  zip(zero_zip)=[]
  veh_tot=[veh_zip_data{:,2}];
  veh_tot(zero_zip)=[]
  bar(veh_tot);
  set(gca,'XTick', 1:length(zip),'xticklabel',zip)
  ylabel(dependent{1})
  title(sprintf('Total Vehicle in Grid Cell %s'))
  xticklabel_rotate([],75,[], 'Fontsize', 12)
  grid on
  legend_str=sprintf('%s''%s'',',legend_str,cities{i}) 
  hold on

  %% Do same thing with our detections 
  detected_bboxes_file='scail/scratch/u/jkrause/gsv_classify/dpm_test/results_boston/131045_1_0_0.mat'
  detected_ims_file='/imagenetdb/jkrause/geocar_amt/scripts/city_files/boston_massachusetts.mat'
  
  num_zipcodes=length(zip)
  det_tot_1=zeros(num_zipcodes,1)
  det_tot_2=zeros(num_zipcodes,1)
  for z=1:num_zipcodes
    pred_zip_query=sprintf('select p1,p2 from ma_detections m,latlong_fpis l where m.lat=l.lat and m.long=l.long and zipcode=%d',zip(z))
    pred_zip_data=get(fetch(exec(conn,pred_zip_query)),'Data');
    p1=[pred_zip_data{:,1}]; 
    p2=[pred_zip_data{:,2}]; 
     
    det_tot_1(z)=sum(p1)
    det_tot_2(z)=sum(p1)
  end

  bar(det_tot_1,'g');
  bar(det_tot_2,'r');
  set(gca,'XTick', 1:length(zip),'xticklabel',zip)
  close(conn)
  %% see if the ground truth boston data correlates with our data

  % Also get the same data from the census and see correlation
end
