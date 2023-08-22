
# 安装和导入所需的库 Install and load packages and functions---------------------------------------------------------------


if("rgdal" %in% rownames(installed.packages()) == FALSE) { 
  install.packages("rgdal", repos = "http://cran.rstudio.com/")}

if("rgeos" %in% rownames(installed.packages()) == FALSE) { 
  install.packages("rgeos", repos = "http://cran.rstudio.com/")}

if("knitr" %in% rownames(installed.packages()) == FALSE) { 
  packageurl <- "http://cran.r-project.org/src/contrib/Archive/knitr/knitr_1.12.tar.gz"
  install.packages(packageurl, repos=NULL, type="source")}
library(rgdal)
library(rgeos)
library(knitr)
source("runConefor.R")
source("coneforInputs.R")


# 下载并解压样例数据 Downloading ConeforST --------------------------------------------
# 
# url.use<-"http://www.conefor.org/files/usuarios/conefor_directed.zip"
# temp.file<-paste(dest.src, "ConeforST", sep="/")
# download.file(url.use, temp.file, mode="wb")
# 
# unzip(paste(dest.src, "ConeforST", sep="/"))
# file.remove("ConeforST")



# 读取空间数据 Loading and visualizing the spatial data set------------------------------------------------------------------

area<-readOGR(dsn='F:/TQP/lml/data', "yd20585", verbose=FALSE)


# 计算的过程-------------------------------------------------------------------
coneforInputs(area)
#Calculating the metrics
#Setting the global parameters for running
probmin <- 0.001   # This is just set to avoid the complete graph calculation, therefore, saving time, and not changing the final result.
#Set species dispersal distance to 50m for this example
distmean <- 100000

# Run ConeforST
runConefor(distmean, probmin)


# 结果 ----------------------------------------------------------------------

res<-read.table("results_all_overall_indices.txt")

# Selecting the spatio-temporal results

res.st<-res[res$V1=="almost_spatiotemporal_except_for_intra",]

# Splitting by metrics

res.pcnum.st<-res.st[res.st$V4=="PCnum",]
res.pcintra.st<-res.st[res.st$V4=="PCintra(%)",]
res.pcdirect.st<-res.st[res.st$V4=="PCdirect(%)",]
res.pcstep.st<-res.st[res.st$V4=="PCstep(%)",]

# Calculating the amount of PCst for PCdirectst and PCsetpst based on the proportion

values.res.pcdirect.st<-res.pcnum.st$V5*res.pcdirect.st$V5/100
values.res.pcstep.st<-res.pcnum.st$V5*res.pcstep.st$V5/100

#Load the values of the PCnum from the spatio-temporal calculations
tot<-read.table("RESULTS_TOT_1e+05.txt")
tot

# Select the PCnumst and merge as a column

values.res.pcnum.st<-tot[1,4] #PCnum values

values.res.pcintra.st<-values.res.pcnum.st-values.res.pcdirect.st-values.res.pcstep.st
#Proportions
prop.res.pcdirect.st<-values.res.pcdirect.st/values.res.pcnum.st*100
prop.res.pcstep.st<-values.res.pcstep.st/values.res.pcnum.st*100
prop.res.pcintra.st<-values.res.pcintra.st/values.res.pcnum.st*100


# Organizing the results for t1 and t2

res.t1<-res[res$V1=="onlystableT1",]

res.pcnum.t1<-res.t1[res.t1$V4=="PCnum",5]

prop.res.pcintra.t1<-res.t1[res.t1$V4=="PCintra(%)",5]
prop.res.pcdirect.t1<-res.t1[res.t1$V4=="PCdirect(%)",5]
prop.res.pcstep.t1<-res.t1[res.t1$V4=="PCstep(%)",5]

values.res.pcintra.t1<-res.pcnum.t1*prop.res.pcintra.t1/100
values.res.pcdirect.t1<-res.pcnum.t1*prop.res.pcdirect.t1/100
values.res.pcstep.t1<-res.pcnum.t1*prop.res.pcstep.t1/100

res.t2<-res[res$V1=="onlystableT2",]

res.pcnum.t2<-res.t2[res.t2$V4=="PCnum",5]

prop.res.pcintra.t2<-res.t2[res.t2$V4=="PCintra(%)",5]
prop.res.pcdirect.t2<-res.t2[res.t2$V4=="PCdirect(%)",5]
prop.res.pcstep.t2<-res.t2[res.t2$V4=="PCstep(%)",5]

values.res.pcintra.t2<-res.pcnum.t2*prop.res.pcintra.t2/100
values.res.pcdirect.t2<-res.pcnum.t2*prop.res.pcdirect.t2/100
values.res.pcstep.t2<-res.pcnum.t2*prop.res.pcstep.t2/100

# Organize final table
PCnum.values<-rbind(values.res.pcnum.st, res.pcnum.t1, res.pcnum.t2)
PCint.values<-rbind(values.res.pcintra.st, values.res.pcintra.t1, values.res.pcintra.t2)
PCint.propor<-rbind(prop.res.pcintra.st, prop.res.pcintra.t1, prop.res.pcintra.t2)
PCdir.values<-rbind(values.res.pcdirect.st, values.res.pcdirect.t1, values.res.pcdirect.t2)
PCdir.propor<-rbind(prop.res.pcdirect.st, prop.res.pcdirect.t1, prop.res.pcdirect.t2)
PCstp.values<-rbind(values.res.pcstep.st, values.res.pcstep.t1, values.res.pcstep.t2)
PCstp.propor<-rbind(prop.res.pcstep.st, prop.res.pcstep.t1, prop.res.pcstep.t2)

results<-cbind(PCnum.values, PCint.values, PCint.propor, PCdir.values, PCdir.propor, PCstp.values, PCstp.propor)
colnames(results)<-c("PCnum", "PCintra", "PCintra(%)", "PCdirect", "PCdirect(%)", "PCstep", "PCsetp(%)")
rownames(results)<-c("spatio-temporal", "t1", "t2")

write.table(results, "RESULTS_FINAL.txt", sep=";") 
