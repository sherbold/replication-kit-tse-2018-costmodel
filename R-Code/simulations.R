##############################
# !REQUIRES MANUAL ADOPTION! #
##############################

# Set working directory to location of the R code
# Should be the same as in plots.R
setwd("~/replication-kit-tse-2018-costmodel/R-Code/")

#######################
# SETUP R Environment #
#######################
if (!require("Rlab")) install.packages("Rlab")
library(Rlab)

source("functions.R")

#########################
# Simulation Parameters #
#########################

parameters.numInstances = c(1000)
parameters.numDefects = c(50,100,150,200)
parameters.expectedArtifactsPerDefect = c(1,2,3,4)
parameters.expectedAccuracy = c(0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95)
parameters.pqf = c(0.0,0.1,0.2,0.3,0.4,0.5)
parameters.iterations = 100

#######################
# Code for simulation #
#######################

# Initialize empty results data frame
results = data.frame(instances=numeric(0),
                     defects=numeric(0),
                     artifactsPerDefect=numeric(0),
                     expectedAccuracy=numeric(0),
                     accuracy=numeric(0),
                     pqf=numeric(0),
                     recall=numeric(0),
                     precision=numeric(0),
                     constNM.lower=numeric(0),
                     constNM.upper=numeric(0),
                     const1M.lower=numeric(0),
                     const1M.upper=numeric(0),
                     const11.lower=numeric(0),
                     const11.upper=numeric(0))

# Run simulation for all parameter combinations
for( iter.instances in 1:length(parameters.numInstances) ) {
  for( iter.defects in 1:length(parameters.numDefects) ) {
    for( iter.expectedArtifacts in 1:length(parameters.expectedArtifactsPerDefect) ) {
      for( iter.accuracy in 1:length(parameters.expectedAccuracy) ) {
        for( iter.pqf in 1:length(parameters.pqf) ) {
          for( iter.iterations in 1:parameters.iterations ) {
            print(paste("instances=",parameters.numInstances[iter.instances],
                      ",defects=",parameters.numDefects[iter.defects],
                      ",artifactsPerDefect=",parameters.expectedArtifactsPerDefect[iter.expectedArtifacts],
                      ",accuracy=",parameters.expectedAccuracy[iter.accuracy],
                      ",pqf=",parameters.pqf[iter.pqf],
                      ",iter=",iter.iterations,
                      sep=""))
            results = rbind(results,
                            simulationRun(numInstances = parameters.numInstances[iter.instances],
                                          numDefects = parameters.numDefects[iter.defects],
                                          expectedArtifactsPerDefect = parameters.expectedArtifactsPerDefect[iter.expectedArtifacts],
                                          expectedAccuracy = parameters.expectedAccuracy[iter.accuracy],
                                          p.qf = parameters.pqf[iter.pqf]))
          }
        }
      }
    }
  }
}

save(results, file="simulation-results.RData")
