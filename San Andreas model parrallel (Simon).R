#---
#title: "RNetLogo"
#author: "Simon D.W. Frost"
#date: "12 August 2016"
#output: html_document
---

#Disable Java windowing.

#```{r}
Sys.setenv(NOAWT=1)
#```

#Define folders

#```{r}
nl.path <- "/usr/local/netlogo-5.3.1-64/app" #This one just needs to point at the overall Netlogo FOLDER
setwd(nl.path)
drop.path <- "/home/andrew/San Andreas geographical sir (R).nlogo" # The model
folderdir <- "/home/andrew/RNetlogo" # Where you want to save the results file
tabname <- "zika_san_andreas_parallel.csv" # Name of results file to be written
#```

#Load libraries.

#```{r}
library(foreach)
library(doMC)
registerDoMC(12) # 12 cores
library(RNetLogo)
#```



#Parameter setup.

#```{r}
set.seed(1234) # needed for consistent runs
nsims <- 1000 # Set this to something bigger after testing
#```

#Set parameters (only a few that were in the interface for testing right now). I just chose the upper and lower bounds based on 0.5 and 2 times the default values.

#```{r}
parnames <- c("Bm","Bh","mospop","mosspread","popspread","Ah","Ch","distm","disth","Am","mosdeath","mosbite")
npar <- length(parnames)
lwr <- c(0,0,12,2,5,0.132,0.174,0.26,0.5,0.083,0.09,2)
upr <- c(0.5,0.5,107,9,20,0.227,0.908,0.86,1,0.25,0.341,15)
data.frame(parnames,lwr,upr)
nparams <- length(lwr)
parmatrix <- as.data.frame(matrix(0.0,nsims,nparams))
for(i in c(1,2,4,6:12)){
  parmatrix[,i] <- runif(nsims,lwr[i],upr[i])
}
for(i in c(3,5)){
  parmatrix[,i] <- sample(lwr[i]:upr[i],nsims,replace=TRUE)
}
colnames(parmatrix) <- parnames
head(parmatrix)
nticks <- 210 # Set number of ticks
#```

#```{r,cache=TRUE}
mynlobj <- as.character(seq(1,nsims)) # Makes a list of NetLogo references nsims long (just 1...nsims)  print(paste(k, "/",nsims,"started")) # Do some reporting
mylist <- foreach(k=1:nsims)  %dopar% {
  print(paste(k, "/",nsims,"started")) # Do some reporting
  NLStart(nl.path,gui=FALSE,nl.obj=mynlobj[k],is3d=FALSE) #gui=FALSE means dont visibly open netlogo
  NLLoadModel(drop.path,nl.obj=mynlobj[k])
  curr <- parmatrix[k,] # Get current parameter values
  
  # Loop through the parameter values
  NLCommand("setup", nl.obj=mynlobj[k])
for(p in 1:npar){
   NLCommand(paste("set",parnames[p]),unlist(curr[p]),nl.obj=mynlobj[k])
}
  NLCommand("rerun", nl.obj=mynlobj[k])
  
   #Get initial conditions 
  Shg <- NLReport("Shg", nl.obj=mynlobj[k])
  Ehg <- NLReport("Ehg", nl.obj=mynlobj[k])
  Ihg <- NLReport("Ihg", nl.obj=mynlobj[k])
  Rhg <- NLReport("Rhg", nl.obj=mynlobj[k])
  Smg <- NLReport("Smg", nl.obj=mynlobj[k])
  Emg <- NLReport("Emg", nl.obj=mynlobj[k])
  Img <- NLReport("Img", nl.obj=mynlobj[k])
  nIh <- NLReport("nIh", nl.obj=mynlobj[k])
  
  ticks <- 0
  while (ticks<nticks & Ehg+Ihg+Emg+Img>0){
    NLCommand("Go", nl.obj=mynlobj[k])
    Shg <- c(Shg,NLReport("Shg", nl.obj=mynlobj[k]))
    Ehg <- c(Ehg,NLReport("Ehg", nl.obj=mynlobj[k]))
    Ihg <- c(Ihg,NLReport("Ihg", nl.obj=mynlobj[k]))
    Rhg <- c(Rhg,NLReport("Rhg", nl.obj=mynlobj[k]))
    Smg <- c(Smg,NLReport("Smg", nl.obj=mynlobj[k]))
    Emg <- c(Emg,NLReport("Emg", nl.obj=mynlobj[k]))
    Img <- c(Img,NLReport("Img", nl.obj=mynlobj[k]))
    nIh <- c(nIh,NLReport("nIh", nl.obj=mynlobj[k]))
    ticks <- ticks + 1
  }
  
  NLQuit(nl.obj=mynlobj[k])
  print(paste(k, "/",nsims,"finished"))
  output = data.frame(Shg,Ehg,Ihg,Rhg,Smg,Emg,Img,nIh)
  output
}
#````

#Now convert the list to a data frame and save.

#```[r]
output <- do.call("rbind",mylist)
# output$run <-  rep(seq(1,nsims),each=dim(output)[[2]])
run <- c()
for(i in 1:nsims){
  run <- c(run,rep(i,dim(mylist[[i]])[1]))
}
output$run <- run
write.csv(output,paste(folderdir,tabname,sep=""),row.names=F)
write.csv(parmatrix,paste(folderdir,"zika_san_andreas_parallel_parmatrix_test.csv",sep=""),row.names=F)
#````