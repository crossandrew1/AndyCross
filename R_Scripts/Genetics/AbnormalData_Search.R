################# path to single csv sheet. #################
dat<- read.csv("/Users/andycross/Desktop/erins_chromosomes/S001282.csv",header = FALSE)




slides<-unique(as.character(dat$V1))
loc = which(as.character(dat$V1) %in% c(slides[1]))


########################## if re-running to look for non-normal or normal stor_mat must be re-run ####################
stor_mat<-matrix(0,nrow=500,ncol=length(slides))
count<-matrix(0,nrow=500,ncol=1)



for(i in 1:length(slides)){
  print("******************************************")
  print(slides[i])
  chrom_loc = matrix(0,nrow = 10000,ncol=1)
  chrom = matrix(0,nrow = 10000,ncol=1)
  chrom_loc = which(as.character(dat$V1) %in% c(slides[i]))
  for(j in 1:length(chrom_loc)){
    chrom[j] = as.character(dat$V3[chrom_loc[j]])
  }
  chrom_zer<-which(chrom == 0)
  chrom<-chrom[-chrom_zer]
  len_check = unique(chrom)
  count[i]<-length(len_check)
  for(d in 1:length(len_check)){
    ############## To look for less than 10 chromosomes change == 10 to != 10 ###################
    if(length(which(chrom %in% c(len_check[d]))) != 10){
      norm_check<-matrix(0,nrow=100,ncol=1)
      norm_check1<-matrix(0,nrow=100,ncol=1)
      norm_check2<-matrix(0,nrow=100,ncol=1)
      norm_check3<-matrix(0,nrow=100,ncol=1)
      norm_check4<-matrix(0,nrow=100,ncol=1)
      norm_loc<-which(dat$V3 %in% c(slides[i],len_check[d]))
      discarded<-matrix(0,nrow=50,ncol=1)
      for(k in 1:length(norm_loc)){
        if(as.character(dat$V1[norm_loc[k]]) != as.character(slides[i])){
          discarded[k]<-as.numeric(as.character(norm_loc[k]))
        }
      }
      dis_zer<-which(discarded == 0)
      discarded<-discarded[-dis_zer]
      away<-which(norm_loc %in% c(discarded))
      if(length(discarded) != 0 ){
        norm_loc<-norm_loc[-away]
      }
      for(f in 1:length(norm_loc)){
        norm_check[f]<-as.character(dat$V18[norm_loc[f]])
      }
      for(g in 1:length(norm_loc)){
        norm_check1[g]<-as.character(dat$V15[norm_loc[g]])
      }
      for(a in 1:length(norm_loc)){
        norm_check2[a]<-as.character(dat$V12[norm_loc[a]])
      }
      for(p in 1:length(norm_loc)){
        norm_check3[p]<-as.character(dat$V10[norm_loc[p]])
      }
      for(p in 1:length(norm_loc)){
        norm_check4[p]<-as.character(dat$V8[norm_loc[p]])
      }
      norm_zer<-which(norm_check == 0)
      norm_check<-norm_check[-norm_zer]
      norm_zer1<-which(norm_check1 == 0)
      norm_check1<-norm_check1[-norm_zer1]
      norm_zer2<-which(norm_check2 == 0)
      norm_check2<-norm_check2[-norm_zer2]
      norm_zer3<-which(norm_check3 == 0)
      norm_check3<-norm_check3[-norm_zer3]
      norm_zer4<-which(norm_check4 == 0)
      norm_check4<-norm_check4[-norm_zer4]
      normal_mat<-matrix(0,nrow=50,ncol=1)
      if("Abnormal" %in% norm_check == TRUE){
      }
      else{
        normal_mat[1]<-1
      }
      if ("Abnormal" %in% norm_check1 == TRUE){
      }
      else{
        normal_mat[2]<-1
      }
      if ("SSC" %in% norm_check2 == TRUE){
      }
      else{
        normal_mat[3]<-1
      }
      if ("SSC" %in% norm_check3 == TRUE || "Insertion" %in% norm_check3 == TRUE){
      }
      else{
        normal_mat[4]<-1
      }
      Null_check<-which(norm_check4 != "Null")
      if (length(Null_check) != 0 ){
      }
      else{
        normal_mat[5]<-1
      }
  ############### for non-normal cells comment out this if statement ###################
  #   if(sum(normal_mat) == 5 && length(which(chrom %in% c(len_check[d]))) == 10 ){
  #      print(paste("IMAGE:",len_check[d]))
  #      print(paste("Number of Chromosomes:",length(which(chrom %in% c(len_check[d])))))
  #      print("All Columns Normal")
  #      stor_mat[d,i]<-1
  #   }
  ################## for normal cells comment out these following print statements and the stor_mat#####################
      print(paste("IMAGE:",len_check[d]))
      print(paste("Number of Chromosomes:",length(which(chrom %in% c(len_check[d])))))
      stor_mat[d,i]<-1
    
    }
  }
}
print(paste("Total Number of Cells",sum(count)))
############## for clarity, if looking at non normal cells change print statement to read Non-normal#####################
print(paste("Total Number of Normal Cells",sum(stor_mat)))

