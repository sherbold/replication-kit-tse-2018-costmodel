########################################################################
# Functions used for the simulation of results and plotting of results #
########################################################################

# executes a single simulation run
simulationRun = function(numInstances, numDefects, expectedArtifactsPerDefect, expectedAccuracy, p.qf) {
  simdata_list = generateData(numInstances, numDefects, expectedArtifactsPerDefect)
  
  simdata = simdata_list$data
  colBugsStart = simdata_list$colBugsStart
  colBugsEnd = simdata_list$colBugsEnd
  
  simdata = simulatePrediction(simdata, numInstances, expectedAccuracy)
  confusionMatrix = getConfusionMatrix(predictions=simdata$pred, actual=simdata$hasBug)
  
  metrics = getPerformanceMetrics(confusionMatrix)
  constNM = boundariesConstNM(predictions=simdata$pred, defects=simdata[,colBugsStart:colBugsEnd], p.qf=p.qf)
  const1M = boundariesConst1M(predictions=simdata$pred, numDefects=simdata$numBugs, p.qf=p.qf)
  const11 = boundariesConst11(confusionMatrix = confusionMatrix, p.qf=p.qf)
  
  return(data.frame(instances=numInstances,defects=numDefects,artifactsPerDefect=expectedArtifactsPerDefect,
                    expectedAccuracy=expectedAccuracy,pqf=p.qf,
                    accuracy=metrics$accuracy,
                    recall=metrics$recall,
                    precision=metrics$precision,
                    constNM.lower=constNM$lower,
                    constNM.upper=constNM$upper,
                    const1M.lower=const1M$lower,
                    const1M.upper=const1M$upper,
                    const11.lower=const11$lower,
                    const11.upper=const11$upper))
}

# calculates boundaries for the const,n/m cost model
boundariesConstNM = function(predictions, defects, p.qf) {
  lowerNominator = sum(predictions)
  upperNominator = length(predictions)-sum(predictions)
  lowerDenominator = 0
  upperDenominator = 0
  for( j in 1:ncol(defects) ) {
    defect.numArtifacts = sum(defects[,j])
    defect.numArtifactsPredicted = sum(predictions[defects[,j]==1])
    if( defect.numArtifacts==defect.numArtifactsPredicted ) {
      # defect predicted
      lowerDenominator = lowerDenominator+(1-p.qf)^defect.numArtifacts
    } else {
      # defect not predicted
      upperDenominator = upperDenominator+(1-p.qf)^defect.numArtifacts
    }
  }
  return(list(lower=lowerNominator/lowerDenominator, upper=upperNominator/upperDenominator))
}

# calculates boundaries for the const,1/m cost model
boundariesConst1M = function(predictions, numDefects, p.qf) {
  lowerNominator = sum(predictions)
  upperNominator = length(predictions)-sum(predictions)
  lowerDenominator = sum(numDefects[predictions])*(1-p.qf)
  upperDenominator = sum(numDefects[!predictions])*(1-p.qf)
  return(list(lower=lowerNominator/lowerDenominator, upper=upperNominator/upperDenominator))
}

# calculates boundaries for the const,1/1 cost model
boundariesConst11 = function(confusionMatrix, p.qf) {
  lowerNominator = confusionMatrix$tp+confusionMatrix$fp
  upperNominator = confusionMatrix$tn+confusionMatrix$fn
  lowerDenominator = confusionMatrix$tp*(1-p.qf)
  upperDenominator = confusionMatrix$fp*(1-p.qf)
  return(list(lower=lowerNominator/lowerDenominator, upper=upperNominator/upperDenominator))
}

# calculates the confusion matrix
getConfusionMatrix = function(predictions, actual) {
  tp = sum(predictions[actual==1])
  fp = sum(predictions[actual==0])
  fn = sum(actual)-tp
  tn = length(actual)-tp-fp-fn
  return(list(tp=tp,fp=fp,fn=fn,tn=tn))
}

# calculates the performance metrics accuracy, recall, and precision based on a confusion matrix
getPerformanceMetrics = function(confusionMatrix) {
  accuracy = (confusionMatrix$tp+confusionMatrix$tn)/
    (confusionMatrix$tp+confusionMatrix$tn+confusionMatrix$fp+confusionMatrix$fn)
  recall = confusionMatrix$tp/(confusionMatrix$tp+confusionMatrix$fn)
  precision = confusionMatrix$tp/(confusionMatrix$tp+confusionMatrix$fp)
  return(list(accuracy=accuracy, recall=recall, precision=precision))
}

# generates the data for a simulation run
generateData = function(numInstances, numDefects, expectedArtifactsPerDefect) {
  dat = data.frame(instances=paste("instance_", c(1:numInstances), sep=""))
  colBugsStart = ncol(dat)+1
  for( i in 1:numDefects ) {
    dat = cbind(dat, rbern(numInstances, expectedArtifactsPerDefect/numInstances))
    colnames(dat)[ncol(dat)] = paste("defect_", i, sep="")
  }
  colBugsEnd = ncol(dat)
  
  for( j in 1:nrow(dat) ) {
    curNumBugs = sum(dat[j,colBugsStart:colBugsEnd])
    dat$hasBug[j] = curNumBugs>0
    dat$numBugs[j] = curNumBugs
  }
  return(list(data=dat,colBugsStart=colBugsStart,colBugsEnd=colBugsEnd))
}

# simulates a defect prediction model with an expected accuracy
simulatePrediction = function(dat, numInstances, expectedAccuracy) {
  dat$correct = rbern(numInstances, expectedAccuracy)
  for( j in 1:nrow(dat) ) {
    if( dat$correct[j]==1 ) {
      dat$pred[j] = dat$hasBug[j]
    } else {
      dat$pred[j] = !dat$hasBug[j]
    }
  }
  return(dat)
}

# generates a result plot
plotResults = function(results,
                       ndefects,
                       pqf,
                       aes_lower=aes(accuracy, constNM.lower),
                       aes_upper=aes(accuracy, constNM.upper),
                       withScatterplot = FALSE,
                       withLegend = TRUE,
                       withTitle = TRUE,
                       metric="accuracy",
                       costmodel="constnm",
                       path="~/") {
  col1 = 1
  col2 = 2
  col3 = 3
  col4 = 4
  points.alpha = 0.05
  points.shape.lower = "\u25BC"
  points.shape.upper = "\u25B2"
  points.shape.size = 3
  
  leg = data.frame(x1=rep(-10,4), y1=rep(-10,4), col = c(col1,col2, col3, col4), text = c("1 expected artifact per defect","2 expected artifact per defect", "3 expected artifact per defect", "4 expected artifact per defect"))
  
  data1 = results[results$defects==ndefects & results$pqf==pqf & results$artifacstPerDefect==1,]
  data2 = results[results$defects==ndefects & results$pqf==pqf & results$artifacstPerDefect==2,]
  data3 = results[results$defects==ndefects & results$pqf==pqf & results$artifacstPerDefect==3,]
  data4 = results[results$defects==ndefects & results$pqf==pqf & results$artifacstPerDefect==4,]
  
  if( pqf==0.0 ) {
    plottitle = paste("Results for ", ndefects, " defects and perfect quality assurance (p.qf=0)", sep="")
  } else {
    plottitle = paste("Results for ", ndefects, " defects and imperfect quality assurance (p.qf=",pqf,")", sep="")
  }
  
  if( withLegend ) {
    plot = ggplot(leg, aes(x1,y1))
  } else {
    plot = ggplot()
  }
  
  # Add trend lines
  plot = plot + 
    geom_smooth(aes_lower, data=data1, col=col1, linetype="dotted", fill=NA) + 
    geom_smooth(aes_lower, data=data2, col=col2, linetype="dotted", fill=NA) +
    geom_smooth(aes_lower, data=data3, col=col3, linetype="dotted", fill=NA) +
    geom_smooth(aes_lower, data=data4, col=col4, linetype="dotted", fill=NA) +
    geom_smooth(aes_upper, data=data1, col=col1, linetype="dashed", fill=NA) +
    geom_smooth(aes_upper, data=data2, col=col2, linetype="dashed", fill=NA) +
    geom_smooth(aes_upper, data=data3, col=col3, linetype="dashed", fill=NA) +
    geom_smooth(aes_upper, data=data4, col=col4, linetype="dashed", fill=NA)
  
  # Add scatterplot
  if( withScatterplot ) {
    plot = plot +
      geom_point(aes_lower, data=data1, col=col1, alpha=points.alpha, shape=points.shape.lower, size=points.shape.size) +
      geom_point(aes_lower, data=data2, col=col2, alpha=points.alpha, shape=points.shape.lower, size=points.shape.size) +
      geom_point(aes_lower, data=data3, col=col3, alpha=points.alpha, shape=points.shape.lower, size=points.shape.size) +
      geom_point(aes_lower, data=data4, col=col4, alpha=points.alpha, shape=points.shape.lower, size=points.shape.size) +
      geom_point(aes_upper, data=data1, col=col1, alpha=points.alpha, shape=points.shape.upper, size=points.shape.size) +
      geom_point(aes_upper, data=data2, col=col2, alpha=points.alpha, shape=points.shape.upper, size=points.shape.size) +
      geom_point(aes_upper, data=data3, col=col3, alpha=points.alpha, shape=points.shape.upper, size=points.shape.size) +
      geom_point(aes_upper, data=data4, col=col4, alpha=points.alpha, shape=points.shape.upper, size=points.shape.size)
  }
  
  # Format plot
  textsize = 15
  plot = plot +
    ylab("C") + xlab(metric) + ylim(0,100) + xlim(0,1) +
    theme_classic() + 
    theme(axis.title = element_text(size=textsize), axis.text = element_text(size=textsize), plot.title = element_text(size=textsize))
  
  if( withTitle ) {
    plot = plot + ggtitle(plottitle)
  }
  
  if( withLegend ) {
    plot = plot + geom_point(aes(x1,y1, col=text), shape=15, size=2)
    plot = plot + scale_color_manual(name="Expected Artifacts per Defect\ndotted = lower bound\ndashed = upper bound", values = c(col1,col2, col3, col4))
  }
  
  # save to file
  if( pqf==0.0 ) {
    pqf = "0.0"
  }
  scatterString = 
    if( withScatterplot) {
      scatterString = "scatter"
      
    } else {
      scatterString = "noscatter"
    }
  filename = paste(path,costmodel,"_",scatterString,"_",metric,"_",ndefects,"_",pqf,".png", sep="")
  print(paste("Saving file", filename))
  ggsave(filename=filename, plot=plot)
}
