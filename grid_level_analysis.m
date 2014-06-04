dbname='boston_cars';
username='tgebru';
password='';
driver='com.mysql.jdbc.Driver';
dburl = ['jdbc:mysql://localhost:3306/' dbname];
javaclasspath('mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar');
table_name= 'grid_quarters_public'
attr_table_names= {'grid251m_attributes','b25044_tenure_by_vehicles_available_acs_ct_meta'};
meta_table_names= {'grid251m_attributes_meta','b25044_tenure_by_vehicles_available_acs_ct_meta'};
cities={'all_ma','boston','springfield','worcester'};

%% Independent variables?
variables={'pop10','pop5_17_10','pop1864_10','pop65p_10','hhpop_10','hh10','fam10','nfam10','hu10','occhu10','ownhu10','rnthu10','vachu10','n11_biz','n11_emp','n21_biz','n21_emp','n22_biz','n22_emp','n23_biz','n23_emp','n31_33_biz','n31_33_emp','n42_biz','n42_emp','n44_45_biz','n44_45_emp','n48_49_biz','n48_49_emp','n51_biz','n51_emp','n52_biz','n52_emp','n53_biz','n53_emp','n54_biz','n54_emp','n55_biz','n55_emp','n56_biz','n56_emp','n61_biz','n61_emp','n62_biz','n62_emp','n71_biz','n71_emp','n72_biz','n72_emp','n81_biz','n81_emp','n92_biz','n92_emp','na_biz','na_emp','total_biz','total_emp','pbld_sqm','prow_sqm','pttlasval','ppaved_sqm','far_agg','mu_psqm','ag_psqm','comlo_psqm','comhi_psqm','inst_psqm','indus_psqm','pub_psqm','res_psqm','oth_psqm','tot_psqm','intsctnden','sidewlksqm','schwlkindx','exit_dist'}

variable_description=cell(length(variables),1);
correlation_type='spearman';
dependent={'veh_tot'}
dependent_description={'Total number of vehicles in grid cell'}

results_dir=sprintf('./results/%s/%s',correlation_type,dependent{1});
if ~exist(results_dir)
  mkdir(results_dir)
end

muni_ids=[35,281,348];
colors={'k*','b*','g*','r*'};
rall=zeros(3,length(variables));
pall=zeros(3,length(variables));

meta_name=meta_table_names{1};
attr_name=attr_table_names{1};


for i=1: length(cities)
 for j=1:length(variables)
   save_file=sprintf('%s/%s_%s.mat',results_dir,cities{i},variables{j})
   variable_file=sprintf('./results/%s/%s_%s.mat',dependent{1},cities{i},variables{j})
   if ~exist(save_file)
     if(i~=1)
       hh_tot_veh=sprintf('select a.%s,g.%s from %s g join %s a using (g250m_id)  where quarter="2010_q2" and muni_id=%d',variables{j},dependent{1},table_name,attr_name,muni_ids(i-1))
     else
       hh_tot_veh=sprintf('select a.%s,g.%s from %s g join %s a using (g250m_id)  where quarter="2010_q2"',variables{j},dependent{1},table_name,attr_name)
     end
     description=sprintf('select Field_Name from %s where field_id="%s"',meta_name,variables{j})

    %% total households vs total vehicles 
    if ~exist(variable_file)
      conn = database(dbname, username, password, driver, dburl);
      hh_tot_veh_data=get(fetch(exec(conn,hh_tot_veh)),'Data');
      variable_description{j}=get(fetch(exec(conn,description)),'Data');
      hh=[hh_tot_veh_data{:,1}]; 
      tot_veh=[hh_tot_veh_data{:,2}]; 
      close(conn)
    else
      load(variable_file)
    end
    [r,p]=corr(hh',tot_veh','type',correlation_type) 
    rall(i,j)=r;
    pall(i,j)=p;
    plot(hh,tot_veh,colors{i});
    ylabel(dependent_description{1})
    xlabel(variable_description{j})
    title(sprintf('%s total number of vehicles in grid cell vs. number of households in grid cell',cities{i}))
    save(save_file,'r','p','hh','tot_veh');
  else 
    load(save_file)
    rall(i,j)=r;
    pall(i,j)=p;
  end
 end
 all_corr_file= sprintf('%s/%s_all_correlations_%s.mat',results_dir,cities{i},correlation_type)
 [rsort,rind_sort]=sort(rall(i,:),'descend') 
 psort=pall(i,rind_sort)
 sorted_variables=variables(rind_sort)
 sorted_descriptions=variable_description(rind_sort);
 save(all_corr_file,'rsort','psort','rind_sort','sorted_variables','sorted_descriptions')
 
   %% Bar graph of correlations
   h=figure,
   bar(rsort)
   set(gca,'XTick', 1:length(sorted_variables),'xticklabel',sorted_variables)
   ylabel(dependent{1})
   title(sprintf('Total Vehicle in Grid Cell %s',cities{i}))
   xticklabel_rotate([],75,[], 'Fontsize', 12)
   grid on
   print(h,all_corr_file)
end

%% A bar graph of correlations for all cities
colors={'y','b','g','r'};
legend_str='';
for i=1:length(cities)
  all_corr_fle= sprintf('%s/%s_all_correlations_%s.mat',results_dir,cities{i},correlation_type)
  load(all_corr_file)
  if(i==1)
    width1=1;
    rc=load(all_corr_file)
    h=figure,
    bar(rc.rsort,width1,colors{i})
    set(gca,'XTick', 1:length(sorted_variables),'xticklabel',sorted_variables)
    ylabel(dependent{1})
    title(sprintf('Total Vehicle in Grid Cell %s'))
    xticklabel_rotate([],75,[], 'Fontsize', 12)
    grid on
    legend_str=sprintf('%s''%s'',',legend_str,cities{i}) 
  else
    r=load(all_corr_file)
    [rcs,rcind]=sort(r.rind_sort)
    rcn=r.rsort(rcind)  
    width2=width1/(0.5+(i-1));
    hold on
    bar(rcn(rind_sort),width2,colors{i})
    legend_str=sprintf('%s''%s'',',legend_str,cities{i}) 
 end
end
 hold off
 legend(legend_str(1:end-1))

%print(h,all_corr_file)
  
