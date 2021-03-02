#This scrips requires a .csv file with 3 columns labeled DP areaMinor and areaMajor, these values come from contributing_drainage.R







#install.packages("swmmr")

library(swmmr)
#path_to_swmm is the directory where all of the swmm rpt files are located
path_to_swmm<-"Z:/MHFD/First Creek/20_Baseline Hydrology/SWMM/Current/"
#dp is the csv file created by contributing_drainage.r - as of now the file must be modified to have areaMinow and areaMajor columns that have corresponding 
# area correction factors that are the same as in CUHP. Area contributed to design p can be used as the basis for these values
dp<-read.csv("Z:/MHFD/First Creek/888_SCRIPTS/ContributingDrainageData/8149.csv",header = TRUE,encoding="UTF-16-BOM")


files<-list.files(path=path_to_swmm,pattern=".out")
print(files)
hydro_hyperlink<-as.data.frame(matrix(0,nrow=length(dp$ï..DP),ncol=1))

#hydrohyperlink is appended to the dp data frame to be used for linking design points to the various excel sheets showing plots of hyperlinks.
names(hydro_hyperlink)<-c("hydro_hyperlink")
dp<-cbind(dp,hydro_hyperlink)


for(k in 1:nrow(dp)){
  time<-data.frame(matrix(0, nrow = 6600, ncol = 137))
  headers<-matrix(0,nrow = 1,ncol=137)
  for( i in 1:length(files)){
    unl_file<-unlist(strsplit(as.character(files[i]),"_"))
    #print(paste("unlfile",unl_file))
    area_filter<-unlist(strsplit(as.character(unl_file[4]),""))
    area_filter<-paste(area_filter[1],area_filter[2],sep="")
    ##print(area_filter)
    if(as.character(area_filter) == as.character(dp$areaMinor[k]) || as.character(area_filter) == as.character(dp$areaMajor[k])){
      
      
      # condition where major doesnt equal minor and the storm is a minor storm
      
      if((as.character(dp$areaMajor[k]) != as.character(dp$areaMinor[k])) & (as.character(unl_file[3]) == "WQ" || as.character(unl_file[3]) == "2yr" || as.character(unl_file[3]) == "5yr" || as.character(unl_file[3]) == "10yr")) {
        if(as.character(dp$areaMinor[k]) == "0m" || as.character(dp$areaMinor[k]) == "2m" || as.character(dp$areaMinor[k]) == "5m"){
          print(paste("area minor",dp$areaMinor[k]))
          minor_file = paste(unl_file[1],"_",unl_file[2],"_",unl_file[3],"_",dp$areaMinor[k],"i^2","_",unl_file[5],"_",unl_file[6],sep="")
        }
        else{
          minor_file = paste(unl_file[1],"_",unl_file[2],"_",unl_file[3],"_",dp$areaMinor[k],"mi^2","_",unl_file[5],"_",unl_file[6],sep="")
        }
        print("In Minor")
        print(minor_file)
        #print(as.character(dp$DP[k]))
        short_name<-unlist(strsplit(as.character(files[i]),"_"))
        if(short_name[2]=="Ex"){
          short_name<-paste("Existing",short_name[3],sep=" ")
        }
        else if(short_name[2]=="Fut"){
          short_name<-paste("Future",short_name[3],sep=" ")
        }
        headers[,i]<-as.character(short_name)
        time[,i]<-data.frame(read_out(file = paste(path_to_swmm,minor_file,sep=""), iType = 1, object_name = as.character(dp$ï..DP[k]), vIndex = 4))
        names(time)<-c(headers)
        write.csv(time[1:1000,],paste("D:/PullHydroOut/8149/",as.character(dp$ï..DP[k]),".csv",sep=""))
        
        
       # Condition where major does not equal minor and the storm is a major storm  
        
      }else if((as.character(dp$areaMajor[k]) != as.character(dp$areaMinor[k])) & (as.character(unl_file[3]) == "25yr" || as.character(unl_file[3]) == "50yr" || as.character(unl_file[3]) == "100yr" || as.character(unl_file[3]) == "500yr")){
        if(as.character(dp$areaMajor[k]) == "0m"){
          major_file = paste(unl_file[1],"_",unl_file[2],"_",unl_file[3],"_",dp$areaMajor[k],"i^2","_",unl_file[5],"_",unl_file[6],sep="")
        }
        else{
          major_file = paste(unl_file[1],"_",unl_file[2],"_",unl_file[3],"_",dp$areaMajor[k],"mi^2","_",unl_file[5],"_",unl_file[6],sep="")
        }
        print(major_file)
        print("In Major")
        #print(as.character(dp$DP[k]))
        short_name<-unlist(strsplit(as.character(files[i]),"_"))
        if(short_name[2]=="Ex"){
          short_name<-paste("Existing",short_name[3],sep=" ")
        }
        else if(short_name[2]=="Fut"){
          short_name<-paste("Future",short_name[3],sep=" ")
        }
        headers[,i]<-as.character(short_name)
        time[,i]<-data.frame(read_out(file = paste(path_to_swmm,major_file,sep=""), iType = 1, object_name = as.character(dp$ï..DP[k]), vIndex = 4))
        names(time)<-c(headers)
        write.csv(time[1:1000,],paste("D:/PullHydroOut/8149/",as.character(dp$ï..DP[k]),".csv",sep=""))
        
      }
      
      
      
      # Condition where major storm equals minor storm area correction
      
      else{
      print("In else")
      #print(as.character(dp$DP[k]))
      short_name<-unlist(strsplit(as.character(files[i]),"_"))
      if(short_name[2]=="Ex"){
        short_name<-paste("Existing",short_name[3],sep=" ")
      }
      else if(short_name[2]=="Fut"){
        short_name<-paste("Future",short_name[3],sep=" ")
      }
      
      headers[,i]<-as.character(short_name)
      dp$hydro_hyperlink[k]<-paste(dp$DP[k],".xlsx",sep="")
      time[,i]<-data.frame(read_out(file = paste(path_to_swmm,files[i],sep=""), iType = 1, object_name = as.character(dp$ï..DP[k]), vIndex = 4))
      names(time)<-c(headers)
      write.csv(time[1:1000,],paste("D:/PullHydroOut/8149/",as.character(dp$ï..DP[k]),".csv",sep=""))
      }
    }
  }
}

path_data<-"D:/PullHydroOut/8149/"
path<-"D:/PullHydroOut/XLSX/"
files<-list.files(path=path_data,pattern = ".csv")
for(i in 1:length(files)){
  print(files[i])
  data<-read.csv(paste(path_data,files[i],sep=""),header=TRUE)
  data<-data[,colSums(data != 0) > 0 ]
  data<-data[,colSums(data != 2) > 2 ]
  write.csv(data,paste(path_data,files[i],sep=""))
}
write.csv(dp, paste(path_data,"data.csv",sep=""))

#this is for renaming and moving files that were created twice 

# csv_fil<-list.files(path_data)
# new_mat<-matrix(0,nrow=79,ncol=1)
# for(i in 1:length(csv_fil)){
#  # print(csv_fil[i])
#   fil<-unlist(strsplit(as.character(csv_fil[i]),"csv"))
#   print(paste(fil,"xlsx",sep=""))
#   #print(paste(as.character(fil),".xlsx",sep=""))
#   new_mat[i]<-paste(fil,"xlsx",sep="")
#   
# }
# print(new_mat)
# vals<-as.numeric(which(as.character(new_mat) %in% c(as.character(dp$hydro_hyperlink))))
# print(vals)
# for(i in 1:length(vals)){
#   #print(paste(path_data,dp$hydro_hyperlink[vals[i]],sep=""))
#   file_csv<-dp$hydro_hyperlink[vals[i]]
#   print(file_csv)
#   file_csv<-unlist(strsplit(as.character(file_csv),"xlsx"))
#   file_csv<-paste(file_csv,"csv",sep="")
#   print(file_csv)
#   file.copy(paste(path_data,file_csv,sep=""),path)
# }
print(vals)
matplot(time[1:400,],type = "l")


