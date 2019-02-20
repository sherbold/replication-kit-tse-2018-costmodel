##############################
# !REQUIRES MANUAL ADOPTION! #
##############################

# must be updated to the location of the replication kit
parameters.filepath = "~/replication-kit-tse-2018-costmodel/data/"
parameters.plotpath = "~/replication-kit-tse-2018-costmodel/result-plots/"

#########################
# Simulation Parameters #
#########################

parameters.expectedAccuracy = 1:19*5/100
parameters.pqf = 0:5/10
parameters.iterations = 100


# Define if the actual values are shown as scatterplot or if only trend lines should be shown
parameters.scatterplot = TRUE
# Define if the legend is added to the plots
parameters.legend = TRUE
# Define if the title is added to the plots
parameters.title = FALSE

# files with defect data that are used for the simulation
parameters.filenames = c(paste(parameters.filepath,"archiva.csv", sep=""),
                         paste(parameters.filepath,"cayenne.csv", sep=""),
                         paste(parameters.filepath,"commons-math.csv", sep=""),
                         paste(parameters.filepath,"deltaspike.csv", sep=""),
                         paste(parameters.filepath,"falcon.csv", sep=""),
                         paste(parameters.filepath,"kafka.csv", sep=""),
                         paste(parameters.filepath,"kylin.csv", sep=""),
                         paste(parameters.filepath,"nutch.csv", sep=""),
                         paste(parameters.filepath,"storm.csv", sep=""),
                         paste(parameters.filepath,"struts.csv", sep=""),
                         paste(parameters.filepath,"tez.csv", sep=""),
                         paste(parameters.filepath,"tika.csv", sep=""),
                         paste(parameters.filepath,"wss4j.csv", sep=""),
                         paste(parameters.filepath,"zeppelin.csv", sep=""),
                         paste(parameters.filepath,"zookeeper.csv", sep="")
)

#######################################
# Install and load required libraries #
#######################################

if (!require(Rlab)) install.packages("Rlab")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(data.table)) install.packages("data.table")
if( !require(ggpubr)) install.packages("ggpubr")
if (!require(xtable)) install.packages("xtable")
library(Rlab)
library(ggplot2)
library(data.table)
library(ggpubr)
library(xtable)

########################################################################
# Functions used for the simulation of results and plotting of results #
########################################################################

# simulates a defect prediction model with an expected accuracy
simulatePrediction = function(dat, expectedAccuracy) {
  dat$correct = rbern(nrow(dat), expectedAccuracy)
  for( j in 1:nrow(dat) ) {
    if( dat$correct[j]==1 ) {
      dat$pred[j] = dat$hasBug[j]
    } else {
      dat$pred[j] = !dat$hasBug[j]
    }
  }
  return(dat)
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

# calculates boundaries for the size aware, n/m cost model
boundariesSizeNM = function(predictions, defects, p.qf, sizes) {
  lowerNominator = sum(sizes[predictions])
  upperNominator = sum(sizes[!predictions])
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

# calculates boundaries for the size aware,1/m cost model
boundariesSize1M = function(predictions, numDefects, p.qf, sizes) {
  lowerNominator = sum(sizes[predictions])
  upperNominator = sum(sizes[!predictions])
  lowerDenominator = sum(numDefects[predictions])*(1-p.qf)
  upperDenominator = sum(numDefects[!predictions])*(1-p.qf)
  return(list(lower=lowerNominator/lowerDenominator, upper=upperNominator/upperDenominator))
}

# calculates boundaries for the size aware,1/1 cost model
boundariesSize11 = function(confusionMatrix, predictions, p.qf, sizes) {
  lowerNominator = sum(sizes[predictions])
  upperNominator = sum(sizes[!predictions])
  lowerDenominator = confusionMatrix$tp*(1-p.qf)
  upperDenominator = confusionMatrix$fp*(1-p.qf)
  return(list(lower=lowerNominator/lowerDenominator, upper=upperNominator/upperDenominator))
}

# plots the results
plotResults = function(results,
                       filename,
                       pqf,
                       aes_lower11=aes(accuracy, const11.lower),
                       aes_upper11=aes(accuracy, const11.upper),
                       aes_lower1M=aes(accuracy, const1M.lower),
                       aes_upper1M=aes(accuracy, const1M.upper),
                       aes_lowerNM=aes(accuracy, constNM.lower),
                       aes_upperNM=aes(accuracy, constNM.upper),
                       withScatterplot = FALSE,
                       withLegend = TRUE,
                       withTitle = TRUE,
                       metric="accuracy",
                       suffix="") {
  col1 = 1
  col2 = 2
  col3 = 3
  col4 = 4
  points.alpha = 0.05
  points.shape.lower = "\u25BC"
  points.shape.upper = "\u25B2"
  points.shape.size = 3
  
  leg = data.frame(x1=rep(-10,3), y1=rep(-10,3), col = c(col1,col2, col3), text = c("1-to-1","1-to-m", "n-to-m"))
  
  data1 = results[results$filename==filename & results$pqf==pqf,]
  
  if( pqf==0.0 ) {
    plottitle = paste("Results for ", filename, " and perfect quality assurance (p.qf=0)", sep="")
  } else {
    plottitle = paste("Results for ", filename, " and imperfect quality assurance (p.qf=",pqf,")", sep="")
  }
  
  if( withLegend ) {
    plot = ggplot(leg, aes(x1,y1))
  } else {
    plot = ggplot()
  }
  
  # Add trend lines
  plot = plot + 
    geom_smooth(aes_lower11, data=data1, col=col1, linetype="dotted", fill=NA) + 
    geom_smooth(aes_upper11, data=data1, col=col1, linetype="dashed", fill=NA) +
    geom_smooth(aes_lower1M, data=data1, col=col2, linetype="dotted", fill=NA) + 
    geom_smooth(aes_upper1M, data=data1, col=col2, linetype="dashed", fill=NA) +
    geom_smooth(aes_lowerNM, data=data1, col=col3, linetype="dotted", fill=NA) +
    geom_smooth(aes_upperNM, data=data1, col=col3, linetype="dashed", fill=NA)
  
  # Add scatterplot
  if( withScatterplot ) {
    plot = plot +
      geom_point(aes_lower11, data=data1, col=col1, alpha=points.alpha, shape=points.shape.lower, size=points.shape.size) +
      geom_point(aes_upper11, data=data1, col=col1, alpha=points.alpha, shape=points.shape.upper, size=points.shape.size) +
      geom_point(aes_lower1M, data=data1, col=col2, alpha=points.alpha, shape=points.shape.lower, size=points.shape.size) +
      geom_point(aes_upper1M, data=data1, col=col2, alpha=points.alpha, shape=points.shape.upper, size=points.shape.size) +
      geom_point(aes_lowerNM, data=data1, col=col3, alpha=points.alpha, shape=points.shape.lower, size=points.shape.size) +
      geom_point(aes_upperNM, data=data1, col=col3, alpha=points.alpha, shape=points.shape.upper, size=points.shape.size)
  }
  
  # Format plot
  textsize = 15
  plot = plot +
    ylab("C") + xlab(metric) + xlim(0,1) + #ylim(0,100) +
    scale_y_continuous(trans ="log10") +
    theme_classic() + 
    theme(axis.title = element_text(size=textsize), axis.text = element_text(size=textsize), plot.title = element_text(size=textsize))
  
  if( withTitle ) {
    plot = plot + ggtitle(plottitle)
  }
  
  if( withLegend ) {
    plot = plot + geom_point(aes(x1,y1, col=text), shape=15, size=2)
    plot = plot + scale_color_manual(name="Expected Artifacts per Defect\ndotted = lower bound\ndashed = upper bound", values = c(col1,col2, col3))
  }
  
  return(plot)
}

###################################
# Code for running the simulation #
###################################

# Initialize empty results data frame
results = data.frame(filename=character(0),
                     expectedAccuracy=numeric(0),
                     accuracy=numeric(0),
                     pqf=numeric(0),
                     recall=numeric(0),
                     precision=numeric(0),
                     sizeNM.lower=numeric(0),
                     sizeNM.upper=numeric(0),
                     size1M.lower=numeric(0),
                     size1M.upper=numeric(0),
                     size11.lower=numeric(0),
                     size11.upper=numeric(0),
                     constNM.lower=numeric(0),
                     constNM.upper=numeric(0),
                     const1M.lower=numeric(0),
                     const1M.upper=numeric(0),
                     const11.lower=numeric(0),
                     const11.upper=numeric(0))

for( iter.filenames in 1:length(parameters.filenames)) {
  for( iter.accuracy in 1:length(parameters.expectedAccuracy) ) {
    for( iter.iterations in 1:parameters.iterations ) {
      print(paste("filename=",parameters.filenames[iter.filenames],
                  ",accuracy=",parameters.expectedAccuracy[iter.accuracy],
                  ",iter=",iter.iterations,
                  sep=""))
      alldata = read.csv(parameters.filenames[iter.filenames], header=TRUE, row.names=1)
      simdata = alldata
      simdata$LLOC = NULL
      colBugsStart = 1
      colBugsEnd = ncol(simdata)
      simdata$hasBug = rowSums(simdata)>0
      simdata$numBugs = rowSums(simdata)
      simdata = simulatePrediction(simdata, parameters.expectedAccuracy[iter.accuracy])
      lloc = alldata$LLOC
      confusionMatrix = getConfusionMatrix(predictions=simdata$pred, actual=simdata$hasBug)
      metrics = getPerformanceMetrics(confusionMatrix)
      for( iter.pqf in 1:length(parameters.pqf) ) {
        sizeNM = boundariesSizeNM(predictions=simdata$pred, defects=simdata[,colBugsStart:colBugsEnd], p.qf=parameters.pqf[iter.pqf], lloc)
        size1M = boundariesSize1M(predictions=simdata$pred, numDefects=simdata$numBugs, p.qf=parameters.pqf[iter.pqf], lloc)
        size11 = boundariesSize11(confusionMatrix=confusionMatrix, predictions=simdata$pred, p.qf=parameters.pqf[iter.pqf], lloc)
        constNM = boundariesConstNM(predictions=simdata$pred, defects=simdata[,colBugsStart:colBugsEnd], p.qf=parameters.pqf[iter.pqf])
        const1M = boundariesConst1M(predictions=simdata$pred, numDefects=simdata$numBugs, p.qf=parameters.pqf[iter.pqf])
        const11 = boundariesConst11(confusionMatrix = confusionMatrix, p.qf=parameters.pqf[iter.pqf])
        
        curResults = data.frame(filename=parameters.filenames[iter.filenames],
                          expectedAccuracy=parameters.expectedAccuracy[iter.accuracy],
                          pqf=parameters.pqf[iter.pqf],
                          accuracy=metrics$accuracy,
                          recall=metrics$recall,
                          precision=metrics$precision,
                          sizeNM.lower=sizeNM$lower,
                          sizeNM.upper=sizeNM$upper,
                          size1M.lower=size1M$lower,
                          size1M.upper=size1M$upper,
                          size11.lower=size11$lower,
                          size11.upper=size11$upper,
                          constNM.lower=constNM$lower,
                          constNM.upper=constNM$upper,
                          const1M.lower=const1M$lower,
                          const1M.upper=const1M$upper,
                          const11.lower=const11$lower,
                          const11.upper=const11$upper)
        results = rbind(results,curResults)
      }
    }
  }
}

#################################
# Code for generating the plots #
#################################

for( i in 1:length(parameters.filenames)) {
  for( p.qf in parameters.pqf) {
  lastDotIndex = regexpr("\\.[^\\.]*$", parameters.filenames[i])
  lastSlashIndex = regexpr("/[^/]*$", parameters.filenames[i])
  projectName = substr(parameters.filenames[i], lastSlashIndex+1, lastDotIndex-1)
  
  plotRecall = plotResults(results,
                           parameters.filenames[i],
                           p.qf,
                           aes(recall, const11.lower),
                           aes(recall, const11.upper),
                           aes(recall, const1M.lower),
                           aes(recall, const1M.upper),
                           aes(recall, constNM.lower),
                           aes(recall, constNM.upper),
                           withScatterplot = parameters.scatterplot,
                           withLegend = parameters.legend,
                           withTitle = parameters.title,
                           metric="recall")
  plotPrecision = plotResults(results,
                           parameters.filenames[i],
                           p.qf,
                           aes(precision, const11.lower),
                           aes(precision, const11.upper),
                           aes(precision, const1M.lower),
                           aes(precision, const1M.upper),
                           aes(precision, constNM.lower),
                           aes(precision, constNM.upper),
                           withScatterplot = parameters.scatterplot,
                           withLegend = parameters.legend,
                           withTitle = parameters.title,
                           metric="precision")
  plotAll = ggarrange(plotRecall, plotPrecision, ncol=2, nrow=1, legend="none")
  plotAll = annotate_figure(plotAll, top=text_grob("constant quality assurance costs", size=14))
  
  ggsave(filename=paste(parameters.plotpath, projectName,"_", p.qf, "_const.png", sep=""), plot=plotAll,
         width = 10, height = 3.5, dpi = 150, units = "in")
  
  plotRecall = plotResults(results,
                           parameters.filenames[i],
                           p.qf,
                           aes(recall, size11.lower),
                           aes(recall, size11.upper),
                           aes(recall, size1M.lower),
                           aes(recall, size1M.upper),
                           aes(recall, sizeNM.lower),
                           aes(recall, sizeNM.upper),
                           withScatterplot = parameters.scatterplot,
                           withLegend = parameters.legend,
                           withTitle = parameters.title,
                           metric="recall")
  plotPrecision = plotResults(results,
                              parameters.filenames[i],
                              p.qf,
                              aes(precision, size11.lower),
                              aes(precision, size11.upper),
                              aes(precision, size1M.lower),
                              aes(precision, size1M.upper),
                              aes(precision, sizeNM.lower),
                              aes(precision, sizeNM.upper),
                              withScatterplot = parameters.scatterplot,
                              withLegend = parameters.legend,
                              withTitle = parameters.title,
                              metric="precision")
  plotAll = ggarrange(plotRecall, plotPrecision, ncol=2, nrow=1, legend="none")
  plotAll = annotate_figure(plotAll, top=text_grob("size-aware quality assurance costs", size=14))
  
  ggsave(filename=paste(parameters.plotpath, projectName,"_", p.qf, "_size.png", sep=""), plot=plotAll,
         width = 10, height = 3.5, dpi = 150, units = "in")
  }
}
