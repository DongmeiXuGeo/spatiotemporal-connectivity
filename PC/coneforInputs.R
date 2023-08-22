##############################################################################
##############################################################################
###
###       Generate coneforInputs: nodes_input, nodes_type and distance_matrix
###
### Martensen, A.C.; Saura, S. and Fortin, M.J.
##############################################################################
##############################################################################

coneforInputs<-function(gis){
  
  row.names(gis@data)<-gis@data$NodeID
    
  nodes_input<-data.frame(cbind(gis@data$NodeID, gis@data$area_ha))
  colnames(nodes_input)<-c("V1", "V2")
  write.table(nodes_input, "nodes_input.txt", sep=";", row.names=FALSE, col.names=FALSE)
    
  nodes_type<-data.frame(cbind(gis@data$NodeID, data.frame(gis@data$Type_all)))
  colnames(nodes_type)<-c("V1", "V2")
  write.table(nodes_type, "nodes_type.txt", sep=";", row.names=FALSE, col.names=FALSE)

  dist.mat<-gDistance(gis, byid=TRUE, hausdorff=FALSE)
  n.tot<-NA
  for (i in 1:(dim(dist.mat)[1]-1)){
    n<-data.frame(dist.mat[i, (i+1):(dim(dist.mat)[1])])
    n.tot<-rbind(n.tot, n)
  }
  n.tot<-data.frame(n.tot[-1,])

tot<-as.numeric(dim(nodes_input)[1])
col.1.df.f<-NULL
for (i in 2:tot-1){
col.1<-rep(i, tot-i)
col.1.df<-data.frame(col.1)
col.1.df.f<-rbind(col.1.df.f, col.1.df)
i<-i+1
}

tot<-dim(nodes_input)[1]
col.2.df.f<-NULL
for (i in 2:tot-1){
  col.2<-seq(i+1, tot)
  col.2.df<-data.frame(col.2)
  col.2.df.f<-rbind(col.2.df.f, col.2.df)
  i<-i+1
}

cols<-cbind(col.1.df.f, col.2.df.f) # cbind the two first columns
dist.final<-cbind(cols, n.tot) # Generate the final distance file
colnames(dist.final)<-c("V1", "V2", "V3")

write.table(dist.final, "distance_final.txt", sep=";", row.names=FALSE, col.names=FALSE) 
}
