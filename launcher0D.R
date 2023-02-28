rm(list=ls())

# Laod libraries
library(osmose)
library(stringr)

javaPath   = here::here("osmose-private/target")
configDir  = here::here("Compare0Dand2D/0D")
outputDir = file.path(configDir, "output")

# Mediterranean configuration --------------------------------------------------

configFile  = file.path(configDir, "osm_all-parameters.csv")
jarfile = file.path(javaPath, "osmose_4.3.3.jar")
#parameters = "-Poutput.start.year=0" -> need this argument in run_osmose : parameters = parameters,
# en JAVA : pour forcer la définition d'un paramètre output.start.year
run_osmose(input = configFile,  osmose = jarfile, options = "-Xmx64G", version = "4.3.3", force=TRUE) # only needs reinstall netbeans (java)
#run_osmose(input = configFile, options = "-Xmx64G", force=TRUE)  # needs to reinstall via netbeans (java) + rstudio (package)


med0D = read_osmose(path = outputDir)

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/biomass.png", width = 4000, height =2000)
plot(med0D, what = "biomass")
dev.off()

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/yield.png", width = 4000, height =2000)
plot(med0D, what = "yield")
dev.off()

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/meanTL.png", width = 800, height =500)
plot(med0D, what = "meanTL")
dev.off()

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/meanTLCatch.png", width = 800, height =500)
plot(med0D, what = "meanTLCatch")
dev.off()

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/meanTLDistribByAge.png", width = 800, height =500)
plot(med0D, what = "meanTLByAge")
dev.off()

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/meanTLDistribByAge.png", width = 800, height =500)
plot(med0D, what = "meanTLBySize", species="Anguillanguilla", time=c(1))
dev.off()

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/biomassDistribByTL.png", width = 2000, height =1000)
plot(med0D, what = "biomassByTL")
dev.off()

png(file = "C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/output/Plots/TLbyageAlosaalosa.png", width = 2000, height =1000)
plot(med0D$meanTLByAge[[,,1]])
dev.off()