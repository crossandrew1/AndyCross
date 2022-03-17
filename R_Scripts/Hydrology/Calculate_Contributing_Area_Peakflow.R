
#Updated 04/17/2020 Andy Cross

#The first import function reads in the "conduits" table as taken from SWMM, the second is a two column matrix of basins and associated areas, the third is a 
#list of design points along a river. This code will calculate contributing area to the listed design points and then sum the contributing areas along the river.

#Because of how this calculates the way design points contribute to eachother, this will give inaccurate results if there are design points along tributaries.


#dat is the swmm routing information taken from swmm model
dat<-read.csv("N:/Projects/W0010 - MHFD/W0010.21002-Hydrology Living Model/3_Models/4_Traditions_Pond_Modifications_in_Aurora/ScriptOutput/Traditions_Conduits.csv",header = FALSE,fileEncoding="UTF-8-BOM")
#basins are the basins and associated areas taken from cuhp
basins<-read.csv("N:/Projects/W0010 - MHFD/W0010.21002-Hydrology Living Model/3_Models/4_Traditions_Pond_Modifications_in_Aurora/ScriptOutput/AlternativeOrigBasin.csv",header = FALSE,fileEncoding="UTF-8-BOM")
#dp are the design points of interest along the network
dp<-read.csv("N:/Projects/W0010 - MHFD/W0010.21002-Hydrology Living Model/3_Models/4_Traditions_Pond_Modifications_in_Aurora/ScriptOutput/FCMainDP.csv",header = FALSE,fileEncoding="UTF-8-BOM")

##path to swmm are the rpt files
path_to_swmm<-"C:/Users/andy.cross/Desktop/hlcLiving/4_Traditions_Pond_Modifications_in_Aurora/SWMM/"



names(dat)<-c("name","inlet","outlet")
names(basins)<-c("name",'area')
names(dp)<-c("name")
basins<-basins[,1:2]
dat<-dat[,1:3]


#this can be changed if the outfall isn't the last point of interest, i.e for tributaries joining the main stem. 
last_pt="OUTFALL"



start<-matrix(0,nrow=500,ncol=10)
'%ni%' <- Negate('%in%')

for(i in 1:length(basins$name)){
  print(as.character(basins$name[i]))
  pos<-which(as.character(dat$inlet) %in% c(as.character(basins$name[i])))
  print(pos)
  out<-as.character(dat$outlet[pos])
  start[i,1]<-as.character(basins$name[i])
  start[i,2]<-as.character(out[1])
#  print(out)
  while(as.character(out)%ni% c(as.character(dp$name)) == TRUE){
    inlet_loc<-which(as.character(dat$inlet) %in% c(as.character(out)))
    inlet<-as.character(dat$inlet[inlet_loc])
    out<-as.character(dat$outlet[inlet_loc])
 #   print(out)
    if(length(out)==2){
      start[i,3]<-out[1]
    }
    else{
      start[i,3]<-out
    }
   }
}
if("OUTFALL" != last_pt){
  out_f<-which(start[,3]=="OUTFALL")
  start<-start[-out_f,]
}
zeros<-which(start[,1]==0)
start<-start[-zeros,]
third<-unique(start[,3])
second<-matrix(0,nrow=1,ncol=500)
start<-as.data.frame(start)
pos_second<-which(start$V3==0)
for(i in pos_second){
  second[i]<-as.character(start$V2[i])
}
zer<-which(second==0)
second<-as.data.frame(unique(second[-zer]))
#print(second)
zer<-which(third==0)
third<-as.data.frame(third[-zer])
names(second)<-c("val")
names(third)<-c("val")
design_p<-rbind(second,third)
design_p<-unique(design_p)
a <- character(0)


dp_area<-matrix(0,nrow=length(design_p$val),ncol=2)
for(i in 1:length(design_p$val)){
  datal<-matrix(0,nrow=1,ncol=50)
  datad<-matrix(0,nrow=1,ncol=50)
  data_loc<-matrix(0,nrow=1,ncol=50)
  data_doc<-matrix(0,nrow=1,ncol=50)
  loc<-which(as.character(start$V3)%in%c(as.character(design_p$val[i])))
  doc<-which(as.character(start$V2)%in%c(as.character(design_p$val[i])))
  basin_loc<-as.character(start$V1[loc])
  basin_doc<-as.character(start$V1[doc])
  if(identical(basin_loc, character(0))){
    for(j in 1:length(basin_doc)){
      data_doc[j]<-which(as.character(basins$name)%in% c(as.character(basin_doc[j])))
      
    }
    v=which(data_doc==0)
    data_doc<-data_doc[-v]
    for(f in 1:length(data_doc)){
      datad[f]<-basins$area[data_doc[f]]
    }
  }
  else if(identical(basin_doc,character(0))) {
    for(k in 1:length(basin_loc)){
      data_loc[k]<-which(as.character(basins$name)%in% c(as.character(basin_loc[k])))
    }
    z=which(data_loc==0)
    data_loc<-data_loc[-z]
    for(h in 1:length(data_loc)){
       datal[h]<-basins$area[data_loc[h]]
    }
  }
  else{
    for(g in 1:length(basin_loc)){
      data_loc[g]<-which(as.character(basins$name)%in% c(as.character(basin_loc[g])))
    }
    z=which(data_loc==0)
    data_loc<-data_loc[-z]
    for(l in 1:length(basin_doc)){
      data_doc[l]<-which(as.character(basins$name)%in% c(as.character(basin_doc[l])))
    }
    v=which(data_doc==0)
    data_doc<-data_doc[-v]
    for(a in 1:length(data_loc)){
      datal[a]<-basins$area[data_loc[a]]
    }
    for(d in 1:length(data_doc)){
      datad[d]<-basins$area[data_doc[d]]
    }
  }
  dp_area[i,1]<-as.character(design_p$val[i])
  dp_area[i,2]<-sum(as.numeric(as.character(datal)))+sum(as.numeric(as.character(datad)))
}
design_p_routing<-matrix(0,nrow=length(design_p$val),ncol=300)
for(i in 1:length(design_p$val)){
  pos<-which(as.character(dat$inlet) %in% c(as.character(design_p$val[i])))
  out<-as.character(dat$outlet[pos])
  design_p_routing[i,1]<-as.character(design_p$val[i])
  design_p_routing[i,2]<-as.character(out)
  j=2
  design_p_routing[i,1]<-as.character(design_p$val[i])
  while(as.character(out) != as.character(last_pt)){
    j=j+1
    inlet_loc<-which(as.character(dat$inlet) %in% c(as.character(out)))
    inlet<-as.character(dat$inlet[inlet_loc])
    out<-as.character(dat$outlet[inlet_loc])
 #   print(out)
    if(length(out)>1){
      for( h in 1:length(out)){
        if(as.character(design_p$val) %in% c(as.character(out[h])) == TRUE){
          o=which(as.character(design_p$val) %in% c(as.character(out[h])))
          out=as.character(design_p$val[o])
        }
        else{
          out=as.character(out[1])
        }
      }
    }
    design_p_routing[i,j]<-as.character(out)
  }
}
dp_area<-as.data.frame(dp_area)
#print(design_p_routing[1,1])
sort_dp<-matrix(0,nrow=length(design_p$val),ncol=20)
for(f in 1:length(design_p$val)){
  d<-design_p_routing[f,]
  zeros<-which(d==0)
  d<-d[-zeros]
  d<-length(d)
  sort_dp[f,1]<-as.character(design_p_routing[f,1])
  sort_dp[f,2]<-sprintf(d, fmt = '%#.2f')
  
}
sort_dp<-as.data.frame(sort_dp)
sort<-as.matrix(sort_dp[order(as.numeric(as.character(sort_dp$V2)),decreasing=TRUE),])
for(i in 1:length(sort[,1])){
  loc=which(as.character(dp_area$V1) %in% c(as.character(sort[i,1])))
  #print(as.character(sort_dp$V1[i]))
  #print(as.character(dp_area$V2[loc]))
  sort[i,3]<-as.numeric(as.character(dp_area$V2[loc]))
}
area<-matrix(0,nrow=length(sort[,1]),ncol=1)
for(i in 1:length(sort[,1])){
  area[i]<-as.numeric(as.character(sort[i,3]))
  sort[i,4]<-sum(area)
}
sort<-as.data.frame(sort)
names(sort)<-c("DP","position","area_from_basins","area_contributed_to_DP","areaMinor","areaMajor","2yr_Existing","2yr_Future","5yr_Existing","5yr_Future","10yr_Existing","10yr_Future","25yr_Existing","25yr_Future","50yr_Existing","50yr_Future","100yr_Existing","100yr_Future","500yr_Existing","500yr_Future")
sort$area_contributed_to_DP<-as.numeric(as.character(sort$area_contributed_to_DP))
sort$area_from_basins<-as.numeric(as.character(sort$area_from_basins ))
sort$area_contributed_to_DP<-round(sort$area_contributed_to_DP,digits=2)
sort$area_from_basins<-round(sort$area_from_basins,digits=3)
for(p in 1:length(sort$area_contributed_to_DP)){
  if(sort$area_contributed_to_DP[p] < 15){
    sort$areaMajor[p] = '0m'
  }
  else if(sort$area_contributed_to_DP[p] == 15 || sort$area_contributed_to_DP[p] < 25 ){
    sort$areaMajor[p] = 15
  }
  else if(sort$area_contributed_to_DP[p] == 25 || sort$area_contributed_to_DP[p] < 30 ){
    sort$areaMajor[p] = 25
  }
  else if(sort$area_contributed_to_DP[p] == 30 || sort$area_contributed_to_DP[p] < 35 ){
    sort$areaMajor[p] = 30
  }
  else if(sort$area_contributed_to_DP[p] == 35 || sort$area_contributed_to_DP[p] < 40 ){
    sort$areaMajor[p] = 35
  }
  else if(sort$area_contributed_to_DP[p] == 40 || sort$area_contributed_to_DP[p] < 45 ){
    sort$areaMajor[p] = 40
  }
  else if(sort$area_contributed_to_DP[p] == 45 || sort$area_contributed_to_DP[p] < 50 ){
    sort$areaMajor[p] = 45
  }
  else if(sort$area_contributed_to_DP[p] == 50 || sort$area_contributed_to_DP[p] < 55 ){
    sort$areaMajor[p] = 45
  }
}
for(p in 1:length(sort$area_contributed_to_DP)){
  if(sort$area_contributed_to_DP[p] < 2){
    sort$areaMinor[p] = '0m'
  }
  else if(sort$area_contributed_to_DP[p] == 2 || sort$area_contributed_to_DP[p] < 5 ){
    sort$areaMinor[p] = '2m'
  }
  else if(sort$area_contributed_to_DP[p] == 5 || sort$area_contributed_to_DP[p] < 10 ){
    sort$areaMinor[p] = '5m'
  }
  else if(sort$area_contributed_to_DP[p] == 10 || sort$area_contributed_to_DP[p] < 15 ){
    sort$areaMinor[p] = 10
  }
  else if(sort$area_contributed_to_DP[p] == 15 || sort$area_contributed_to_DP[p] < 25 ){
    sort$areaMinor[p] = 15
  }
  else if(sort$area_contributed_to_DP[p] == 25 || sort$area_contributed_to_DP[p] < 30 ){
    sort$areaMinor[p] = 25
  }
  else if(sort$area_contributed_to_DP[p] == 30 || sort$area_contributed_to_DP[p] < 35 ){
    sort$areaMinor[p] = 30
  }
  else if(sort$area_contributed_to_DP[p] == 35 || sort$area_contributed_to_DP[p] < 40 ){
    sort$areaMinor[p] = 35
  }
  else if(sort$area_contributed_to_DP[p] == 40 || sort$area_contributed_to_DP[p] < 45 ){
    sort$areaMinor[p] = 40
  }
  else if(sort$area_contributed_to_DP[p] == 45 || sort$area_contributed_to_DP[p] < 55 ){
    sort$areaMinor[p] = 45
  }
}


design_points<-sort


files<-list.files(path=path_to_swmm,pattern = ".rpt")


for(i in files){
  file<-paste(path_to_swmm,i,sep="")
  print(file)
  unl_file<-unlist(strsplit(as.character(file),"_"))
  print(length(unl_file))
  for(i in 1:length(unl_file)){
    if(unl_file[i]=="Fut" || unl_file[i]=="Ex"){
      p1=as.numeric(i)
      p2=as.numeric(i+1)
      p3=as.numeric(i+2)
    }
  }
  print(paste("pvalues",p1,p2,p3))
  g<-unlist(strsplit(as.character(file),"_"))[p3]
  f<-unlist(strsplit(g,""))
  f<-f[1:6]
  #print(f)
  f<-paste(f[1],f[2],sep="")
  f<-as.character(f)
  print(paste("f",f))
  print(paste("UNLFILE4",unl_file[p2]))
  if(as.character(unl_file[p2]) == "WQ" || as.character(unl_file[p2]) == "2yr" || as.character(unl_file[p2]) == "5yr" || as.character(unl_file[p2]) == "10yr"){
    pos<-which(as.character(design_points$areaMinor) %in% c(as.character(f)))
  }
  else{
    pos<-which(as.character(design_points$areaMajor) %in% c(as.character(f)))
  }
  #print(paste("pos",pos))
  for(u in 1:length(pos)){
    print(paste("posU",pos[u]))
    junction<-as.character(design_points$DP[pos[u]])
    print(paste("junction",junction))
    df<-read.table(file,sep = '\t' )
    for(d in 1:length(df[,1])){
      nodes_search<-strsplit(as.character(df[d,]),"\\s+")
      nodes_search<-unlist(nodes_search)
      if(isTRUE(nodes_search[4] == "nodes")){
        number_nodes<-as.numeric(as.character(nodes_search[6]))
      }
    }
    for(h in 1:length(df[,1])){
      if(as.character("  Node Inflow Summary") == as.character(df[h,])){
        node_summary=as.numeric(as.character(h))
        print(paste("node sum",node_summary))
      }
    }
    node_matrix<-matrix(0,nrow=number_nodes+15,ncol=10)
    junctions=junction
    for(j in node_summary:(node_summary+number_nodes+8)){
      vals<-t(unlist(strsplit(as.character(df[j,]),"\\s+")))
      
      if(isTRUE(vals[2] == junctions)){
        print(paste("vals 5",vals[5]))
        if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "WQ")){
          design_points$WQ_Existing[pos[u]]<-as.character(vals[5])
          #print(vals[5])
          print(paste("vals 5",vals[5]))
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "WQ")){
          design_points$WQ_Future[pos[u]]<-as.character(vals[5])
          #print(vals[5])
          print(paste("vals 5",vals[5]))
        }
        
        else if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "2yr")){
          design_points$`2yr_Existing`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "2yr")){
          design_points$`2yr_Future`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        
        else if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "5yr")){
          design_points$`5yr_Existing`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "5yr")){
          design_points$`5yr_Future`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "10yr")){
          design_points$`10yr_Existing`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "10yr")){
          design_points$`10yr_Future`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        
        else if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "25yr")){
          design_points$`25yr_Existing`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "25yr")){
          design_points$`25yr_Future`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "50yr")){
          design_points$`50yr_Future`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "50yr")){
          design_points$`50yr_Existing`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "100yr")){
          design_points$`100yr_Future`[pos[u]]<-as.character(vals[5])
          #print(paste("vals 5",vals[5]))
        }
        
        else if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "100yr")){
          design_points$`100yr_Existing`[pos[u]]<-as.character(vals[5])
          #print(vals[5])
        }
        else if(isTRUE(unl_file[p1] == "Fut" && unl_file[p2] == "500yr")){
          design_points$`500yr_Future`[pos[u]]<-as.character(vals[5])
          #print(paste("vals 5",vals[5]))
        }
        
        else if(isTRUE(unl_file[p1] == "Ex" && unl_file[p2] == "500yr")){
          design_points$`500yr_Existing`[pos[u]]<-as.character(vals[5])
         # print(vals[5])
        }
      }
    }
  }
}

write.csv(design_points,"N:/Projects/W0010 - MHFD/W0010.21002-Hydrology Living Model/3_Models/4_Traditions_Pond_Modifications_in_Aurora/ScriptOutput/OutputTables/TraditionsPond_100yr_20220317.csv")

















