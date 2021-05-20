weir=read.csv("C:/Users/Andy.Cross/Desktop/1020.csv",header=TRUE)
error=read.csv("C:/Users/Andy.Cross/Desktop/1020_error.csv",header=TRUE)
error=na.omit(error)
for(i in 1:length(weir$elevation)){
  loc=which(as.character(error$ï..Weir.Sta)  %in% c(as.character(weir$ï..station[i])))
  print(paste("weir station orig",weir$ï..station[i]))
  print(loc)
  if(length(loc)>1){
    stor<-matrix(nrow=50,ncol=1)
    for(j in 1:length(loc)){
      stor[j]<-error$Cell.Elv[loc[j]]
    }
    loc2<-which.max(stor)
    loc<-loc[as.numeric(loc2)]
  }
  if(length(loc)== 0){
    print("path")
  }else{
    new_ele<-error$Cell.Elv[loc] + 0.2
    print(paste("error station",error$ï..Weir.Sta[loc]))
    print(paste("weir station",weir$ï..station[i]))
    print(paste("error height",error$Cell.Elv[loc]))
    print(paste("new elevation",new_ele))
    
    weir$elevation[i]<-new_ele
    
  }

}
weir<-na.omit(weir)
write.csv(weir,"C:/Users/Andy.Cross/Desktop/1020_updated.csv")
