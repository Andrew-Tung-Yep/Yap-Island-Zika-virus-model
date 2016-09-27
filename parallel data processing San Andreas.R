real.data <- c(rep(0,12),1,1,1,0,0,0,0,1,0,4,0,0,0,1,1,0,0,1,1,0,1,0,2,1,2,6,5,3,3,6,9,7,10,5,19,10,17,15,17,21,14,12,14,20,10,4,7,5,5,14,8,10,21,3,13,5,28,29,17,13,28,19,37,20,31,25,21,26,29,24,26,12,14,9,3,12,5,10,18,14,11,15,3,6,5,13,1,3,7,1,6,8,3,4,4,6,4,6,4,1,4,2,1,1,1,3,0,0,1,0,0,2,0,0,1,rep(0,125))
setwd("/home/andrew")
results<-read.csv("RNetlogozika_san_andreas_parallel.csv")
top.paras<-read.csv("RNetlogozika_san_andreas_parallel_parmatrix.csv")
master.results<-array(rep(0,1680000),c(212,8,1000))
for (k in 1:1000){
  master.results[1:210,1:7,k]<-unlist(results[((k-1)*211+1):(k*211-1),1:7])
  for (j in 2:210){
    master.results[j,8,k]<-(results[((k-1)*211-1+j),2]-results[((k-1)*211+j),2])+(results[((k-1)*211-1+j),1]-results[((k-1)*211+j),1])
  } #compiling results into an array
  if (master.results[210,4,k]>933){ #ensures unsuccesful outbreaks are not favored 
    diff<-rep(0,42)
    for (i in 1:42){
      diff[i] <- sum(abs(real.data[i:(i+209)]*master.results[210,4,k]/933 - master.results[1:210,8,k]))*10000/master.results[210,4,k]
    } #comparing results to real data (scaled)
    master.results[212,6,k] <- which(diff==min(diff))[1]
    diff<-min(diff)
  }else{
    diff<-100000
  }
  master.results[212,5,k] <- diff
  master.results[211,,k] <- unlist(top.paras[k,1:8])
  master.results[212,1:4,k] <- unlist(top.paras[k,9:12]) 
}
diff.vector<-master.results[212,5,] 
diff.vector<-sort(diff.vector,decreasing=FALSE)
top.ten<-array(,c(212,8,10))
top.ten.vector<-match(diff.vector[1:10],master.results[212,5,])
for (c in 1:10){ 
  top.ten[,,c]<-master.results[,,top.ten.vector[c]]
}#forming array of best 10 runs
