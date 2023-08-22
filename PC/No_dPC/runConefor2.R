##########################################################################
##########################################################################
###
###     Funtion to run ConeforST based on nodes_input.txt, nodes_type.txt.
###
### Martensen, A.C.; Saura, S. and Fortin, M.J.
###
##########################################################################
##########################################################################

runConefor<-function(distmean, probmin){
  
  nodefilename <- "nodes_input.txt"
  nodes_input <- read.table(nodefilename, sep=";")
  nodes <- nodes_input
  
  nodetypefilename <- "nodes_type.txt"
  nodes_type <- read.table(nodetypefilename, sep=";")
  
  files<-dir()
  distances<-grep("distance", files)
  distancefilename <- files[distances]
  distances <- read.table(distancefilename, sep=";")
  
  newline <- data.frame(matrix(0,nrow=1,ncol=2))
  colnames(newline) <- c("V1","V2")
  ii <- 1
  cont_non_6 <-0
  
  while (ii<=nrow(nodes_input)) {
    
    if (nodes_type[ii,2]<6) {
      cont_non_6 <- cont_non_6+1
      nodes[cont_non_6+nrow(nodes_input),1]=nodes[ii,1]+max(nodes_input$V1)
      nodes[cont_non_6+nrow(nodes_input),2]=0
      newline[1,1]=ii+max(nodes_input$V1)
      newline[1,2]=nodes_type[ii,2]
      nodes_type=rbind(nodes_type,newline)
    }
    
    #print(paste(round(100*ii/nrow(nodes_input)),"%","of duplicating gain and loss nodes"))
    ii <- ii+1 
  }
  
  distances_reversed <- distances[c("V2","V1","V3")]
  
  colnames(distances_reversed)[1] <- "V1"
  colnames(distances_reversed)[2] <- "V2"
  
  distances_dir <- data.frame(matrix(-1,nrow=nrow(distances)*2,ncol=3))
  
  distances_dir<- rbind(distances,distances_reversed)
  
  connection_spatial <- data.frame(matrix(0,nrow=nrow(distances_dir),ncol=3))
  
  connection_spatial <- distances_dir
  
  connection_spatial$V3<-exp(-distances_dir$V3/distmean)
  
  connection_spatial <- subset(connection_spatial,V3>=probmin)
  
  absolute_probmin<-1e-100
  
  if (absolute_probmin>probmin) {
    
    connection_spatial <- subset(connection_spatial,V3>=absolute_probmin)
    
  }
  
  node_line<-data.frame(matrix(-1,nrow=max(nodes$V1),ncol=1))
  
  nn<-1
  while (nn<=nrow(nodes)) {
    node_line[nodes[nn,1],1]<-nn
    nn<-nn+1
    #print(paste(round(100*nn/nrow(nodes)),"%","of storing line for each nodeID"))  
  }
  
  ## and now we implement the temporal constraints and possibilities, filtering out those cases (links) that are not possible in the temporal dimension, adding temporal connections where needed, etc.
  ## this part of the code ('qq' loop) is the one that will consume most of the processing time in R
  
  connection_temp <- connection_spatial
  
  newrow <- data.frame(matrix(0,nrow=1,ncol=3))
  colnames(newrow)[1] <- "V1"
  colnames(newrow)[2] <- "V2"
  colnames(newrow)[3] <- "V3"
  
  qq<-1
  
  while (qq<=nrow(connection_spatial)) {
    
    ## as before, all these print statements are not needed for the calculations but just to keep track of the processing. They may be removed with no impact in the calculations.
    # print(paste(round(100*qq/nrow(connection_spatial)),"%","of accounting for time in the connection file"))
    
    ## if movement starts in a gain
    if (nodes_type[node_line[connection_temp[qq,1],1],2]==1) {
      ## and ends in a gain
      if (nodes_type[node_line[connection_temp[qq,2],1],2]==1) {
        connection_temp[qq,3] <- connection_temp[qq,3]
        connection_temp[qq,1] <- connection_temp[qq,1]+max(nodes_input$V1)
        connection_temp[qq,2] <- connection_temp[qq,2]+max(nodes_input$V1)
        ##print("starts in gain and ends in gain")
      }
      ## and ends in a loss
      else {
        if (nodes_type[node_line[connection_temp[qq,2],1],2]==0) {
          connection_temp[qq,3] <- 0.5*connection_temp[qq,3]
          connection_temp[qq,1] <- connection_temp[qq,1]+max(nodes_input$V1)
          connection_temp[qq,2] <- connection_temp[qq,2]+max(nodes_input$V1)
          newrow[1,3]<-connection_temp[qq,3]
          newrow[1,2]<-connection_temp[qq,1]
          newrow[1,1]<-connection_temp[qq,2]
          connection_temp=rbind(connection_temp,newrow)
          ##print("starts in gain and ends in loss")
        }
        ## and ends in stable
        else {
          if (nodes_type[node_line[connection_temp[qq,2],1],2]==6) {
            connection_temp[qq,3] <- connection_temp[qq,3]
            connection_temp[qq,1] <- connection_temp[qq,1]+max(nodes_input$V1)
            newrow[1,3]<-connection_temp[qq,3]
            newrow[1,2]<-connection_temp[qq,1]
            newrow[1,1]<-connection_temp[qq,2]
            connection_temp=rbind(connection_temp,newrow)
            ##print("starts in a gain and ends in stable")
          }
        } ## else end
      } ## else end
    }
    
    #### if movement goes to a loss
    if (nodes_type[node_line[connection_temp[qq,2],1],2]==0) {
      ## and starts in a loss
      if (nodes_type[node_line[connection_temp[qq,1],1],2]==0) {
        connection_temp[qq,3] <- connection_temp[qq,3]
        connection_temp[qq,1] <- connection_temp[qq,1]+max(nodes_input$V1)
        connection_temp[qq,2] <- connection_temp[qq,2]+max(nodes_input$V1)
        ##print("goes to a loss and starts in a loss")
      }
      else {
        ## and starts in stable
        if (nodes_type[node_line[connection_temp[qq,1],1],2]==6) {
          connection_temp[qq,3] <- connection_temp[qq,3]
          connection_temp[qq,2] <- connection_temp[qq,2]+max(nodes_input$V1)
          newrow[1,3]<-connection_temp[qq,3]
          newrow[1,2]<-connection_temp[qq,1]
          newrow[1,1]<-connection_temp[qq,2]
          connection_temp=rbind(connection_temp,newrow)
          ##print("starts in stable and ends in a loss")
        }
      }  ## end else
    }
    
    ## if starts in loss and ends in gain
    if (nodes_type[node_line[connection_temp[qq,1],1],2]==0 & nodes_type[node_line[connection_temp[qq,2],1],2]==1) {
      connection_temp[qq,3] <- 0.5*connection_temp[qq,3]
      ##print("starts in a loss and ends in a gain")
    }
    
    qq <- qq+1
    
  }
  
  tt<-1
  
  while (tt<=nrow(nodes_input)) {
    
    if (nodes_type[tt,2]==0) {
      
      newrow[1,1]<-nodes_input[tt,1]
      newrow[1,2]<-nodes_input[tt,1]+max(nodes_input$V1)
      newrow[1,3]<-1
      connection_temp=rbind(connection_temp,newrow)
      
      
    }
    else {
      
      if (nodes_type[tt,2]==1) {
        
        newrow[1,1]<-nodes_input[tt,1]+max(nodes_input$V1)
        newrow[1,2]<-nodes_input[tt,1]
        newrow[1,3]<-1
        connection_temp=rbind(connection_temp,newrow)
        
      }
    }
    
    #print(paste(round(100*tt/nrow(nodes_input)),"%","of creating the links between duplicated nodes for gains and losses"))
    tt <- tt+1 
  }
  
  write.table(nodes,"nodes.txt",row.names=FALSE, col.names=FALSE)
  write.table(connection_temp,"probs.txt",row.names=FALSE, col.names=FALSE)
  
  shell("conefor.exe -nodeFile nodes.txt -conFile probs.txt -t prob notall -PC onlyoverall -wprobmax -wprobdir -prefix almost_spatiotemporal_except_for_intra")
  #shell("conefor.exe -nodeFile nodes.txt -conFile probs.txt -t prob notall -PC -BCPC -wprobmax -wprobdir -prefix almost_spatiotemporal_except_for_intra")
  
  coneforresultsfilename <- "overall_indices.txt"
  Conefor_results <- read.table(coneforresultsfilename)
  
  PCnum_prov<-Conefor_results[1,2]
  
  ee <- 1
  resta_PCnum<-0
  
  while (ee<=nrow(nodes_input)) {
    
    if (nodes_type[ee,2]<6) {
      resta_PCnum <- resta_PCnum+nodes_input[ee,2]*nodes_input[ee,2]
    }
    ee <- ee+1 
  }
  
  PCnum_spatiotemp<-PCnum_prov-resta_PCnum
  
  ECA_spatiotemp<-sqrt(PCnum_spatiotemp)
  
  print("test1")
  print("PCnum_st (spatiotemporal)")
  print(PCnum_spatiotemp)
  
  print("ECAst (spatiotemporal)")
  print(ECA_spatiotemp)
  
  write.table(connection_spatial,"probs_all.txt",row.names=FALSE, col.names=FALSE)
  
  write.table(nodes,"nodes_input2.txt",row.names=FALSE, col.names=FALSE)
  
  #shell("conefor.exe -nodeFile nodes_input2.txt -conFile probs_all.txt -t prob notall -PC onlyoverall -prefix all3patchtypes")
  shell("conefor.exe -nodeFile nodes_input2.txt -conFile probs_all.txt -t prob notall -PC -BCPC -prefix all3patchtypes")
  
  Conefor_results <- read.table(coneforresultsfilename)
  PCnum_all3types<-Conefor_results[1,2]
  ECA_all3types<-sqrt(PCnum_all3types)
  
  nodes_stable <- subset(nodes_input,nodes_type[V1,2]==6)
  
  connection_stable<- subset(connection_spatial,nodes_type[node_line[V1,1],2]==6)
  connection_stable<- subset(connection_stable,nodes_type[node_line[V2,1],2]==6)
  
  write.table(nodes_stable,"nodes_stable.txt",row.names=FALSE, col.names=FALSE)
  write.table(connection_stable,"probs_stable.txt",row.names=FALSE, col.names=FALSE)
  
  #shell("conefor.exe -nodeFile nodes_stable.txt -conFile probs_stable.txt -t prob -PC onlyoverall -prefix onlystable")
  shell("conefor.exe -nodeFile nodes_stable.txt -conFile probs_stable.txt -t prob -PC -BCPC  -prefix onlystable")
  
  Conefor_results <- read.table(coneforresultsfilename)
  PCnum_stable<-Conefor_results[1,2]
  ECA_stable<-sqrt(PCnum_stable)
  
  
  
  nodes_t1 <- subset(nodes_input,nodes_type[V1,2]!=1)
  
  connection_t1 <- subset(connection_spatial,nodes_type[node_line[V1,1],2]!=1)
  connection_t1 <- subset(connection_t1,nodes_type[node_line[V2,1],2]!=1)
  
  write.table(nodes_t1,"nodes_t1.txt",row.names=FALSE, col.names=FALSE)
  write.table(connection_t1,"probs_t1.txt",row.names=FALSE, col.names=FALSE)
  
  #shell("conefor.exe -nodeFile nodes_t1.txt -conFile probs_t1.txt -t prob -PC onlyoverall -prefix onlystableT1")
  shell("conefor.exe -nodeFile nodes_t1.txt -conFile probs_t1.txt -t prob -PC -BCPC  -prefix onlystableT1")
  Conefor_results <- read.table(coneforresultsfilename)
  PCnum_t1<-Conefor_results[1,2]
  ECA_t1<-sqrt(PCnum_t1)
  
  ## now we do the same thing for the spatial only ECA at time 2 (stable+gains), called ECA_t2
  
  nodes_t2 <- subset(nodes_input,nodes_type[V1,2]!=0)
  
  connection_t2 <- subset(connection_spatial,nodes_type[node_line[V1,1],2]!=0)
  connection_t2 <- subset(connection_t2,nodes_type[node_line[V2,1],2]!=0)
  
  write.table(nodes_t2,"nodes_t2.txt",row.names=FALSE, col.names=FALSE)
  write.table(connection_t2,"probs_t2.txt",row.names=FALSE, col.names=FALSE)
  
  #shell("conefor.exe -nodeFile nodes_t2.txt -conFile probs_t2.txt -t prob -PC onlyoverall -prefix onlystableT2")
  shell("conefor.exe -nodeFile nodes_t2.txt -conFile probs_t2.txt -t prob -PC -PC -BCPC   -prefix onlystableT2")
  Conefor_results <- read.table(coneforresultsfilename)
  PCnum_t2<-Conefor_results[1,2]
  ECA_t2<-sqrt(PCnum_t2)
  
  
  ## now we print the results for the purely spatial versions of ECA
  
  print("PCnum stable")
  print(PCnum_stable)
  print("ECA stable")
  print(ECA_stable)
  
  print("PCnum all 3 types")
  print(PCnum_all3types)
  print("ECA all 3 types")
  print(ECA_all3types)
  
  print("PCnum t1 (losses+stable)")
  print(PCnum_t1)
  print("ECA t1 (losses+stable)")
  print(ECA_t1)
  
  print("PCnum t2 (gains+stable)")
  print(PCnum_t2)
  print("ECA t2 (gains+stable)")
  print(ECA_t2)
  
  ## now we just print again the spatiotemporal values to have them back at the end of all the runs.
  
  print("PCnum_st (spatiotemporal)")
  print(PCnum_spatiotemp)
  print("ECAst (spatiotemporal)")
  print(ECA_spatiotemp)
  
  res.stable<-rbind(PCnum_stable, ECA_stable)
  res.all3  <-rbind(PCnum_all3types, ECA_all3types)
  res.T1    <-rbind(PCnum_t1, ECA_t1)
  res.T2    <-rbind(PCnum_t2, ECA_t2)
  res.ST    <-rbind(PCnum_spatiotemp, ECA_spatiotemp)
  
  a.t1<-sum(nodes_t1$V2)
  a.t2<-sum(nodes_t2$V2)
  a.sb<-sum(nodes_stable$V2)
  t1_sb<-a.sb/a.t1
  t2_sb<-a.sb/a.t2
  dif<-a.t1-a.t2
  ls<-a.t1-a.sb
  gn<-a.t2-a.sb
  AREAS<-data.frame(cbind(a.t1, a.t2, a.sb, t1_sb, t2_sb, dif, ls, gn))
  
  write.table(AREAS, "AREAS.txt", row.names=TRUE, col.names=TRUE)
  
  res.tot<-cbind(res.stable, res.T1, res.T2, res.ST, res.all3)
  colnames(res.tot)<-c("stable", "T1", "T2", "ST", "all")
  
  name<-paste("RESULTS_TOT", "_", distmean, ".txt", sep="")
  
  write.table(res.tot, name, row.names=TRUE, col.names=TRUE)
  
}
## END