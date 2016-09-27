real.data <- rep(c(0,0,0,1,2,0,1,1,9,29,15,9,15,19,6,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)*7.14, each=7)
setwd("/home/andrew")
results<-read.csv("RNetlogozika_parallel.csv")
top.paras<-read.csv("RNetlogozika_parallel_parmatrix.csv")
master.results<-array(rep(0,1680000),c(212,8,1000))
for (k in 1:1000){
  master.results[1:210,1:7,k]<-unlist(results[((k-1)*211+1):(k*211-1),1:7])
  for (j in 2:210){
    master.results[j,8,k]<-(results[((k-1)*211-1+j),2]-results[((k-1)*211+j),2])+(results[((k-1)*211-1+j),1]-results[((k-1)*211+j),1])
  } #compiling results into an array
  diff<-rep(20,42)
  for (i in 1:42){
  diff[i] <- sum(abs(real.data[i:(i+209)] - master.results[1:210,8,k]))
  } #comparing results to real data 
  master.results[212,5,k] <- which(diff==min(diff))[1]
  diff<-min(diff)
  master.results[212,4,k] <- diff
  master.results[211,,k] <- unlist(top.paras[k,1:8])
  master.results[212,1:3,k] <- unlist(top.paras[k,9:11])
}
diff.vector<-master.results[212,4,]
diff.vector<-sort(diff.vector,decreasing=FALSE)
top.ten<-array(,c(212,8,10))
top.ten.vector<-match(diff.vector[1:10],master.results[212,4,])
for (c in 1:10){ 
  top.ten[,,c]<-master.results[,,top.ten.vector[c]]
}#forming array of best 10 runs
