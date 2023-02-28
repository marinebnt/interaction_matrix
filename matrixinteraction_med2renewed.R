###############################################
#                                             #
#          Interaction Matrix                 #
#                                             #
###############################################
#
# GOAL : convert the 2 dimensions spatial fish distribution into a 0 dimension fish interaction matrix
# First : extract the fish maps 
# Second : create the interaction matrix which converts the presence/absence matrix of all the fish species into an
#          interaction factor depending on their distribution overlapp.
# Third : estimate the interaction factor of fish with the low trophic levels (LTL) and merge this matrix with the fish interaction matrix : step-time dependent. 
# Fourth : multiplicate the interaction factor with the accessible one : this way it will be easier to integrate the interaction factor into the model. 
# Fifth : convert all of it into a great netcdf document to store the data.  
#
#
#
#
#***************Data initialization*****************************************************************
#
#
####################################################################################################
### Packages needed : raster, readr, here, stringr, tibble, tidyr, ggplot2, grDevices, gtools

### FISH

## Name of the output file

outputname <- c("matrixinteraction.csv")

## Path to distribution files ----

path <- here::here("matricedinteraction/configosmose-med2renewed/maps")

## Files names ----

filelist <- list.files(path, pattern = ".csv")
filelist <- gtools::mixedsort(sort(filelist))
filenames <- filelist[filelist != outputname[1]]


## Loop on files ----

for (filename in filenames) {
  
  ## Check if file exists ----
  
  if (!file.exists(file=paste(path, filename, sep="/"))) {
    stop("The file '", filename, "' does not exist", call. = FALSE)
  }
  
  ## Loads files on R
  
  suppressMessages(assign(strsplit(filename, split="\\.")[[1]][1], readr::read_csv(col_names=FALSE, file=paste(path, filename, sep="/"))))
  
}
####################################################################################################
### LTL (* netCDF file -> https://pjbartlein.github.io/REarthSysSci/netCDF.html *)


## Path to distribution files ----

 ncpath <- here::here("matricedinteraction/configosmose-med2renewed")
 ncname <- "corrected_eco3m_med.nc"  
 ncfname <- paste(ncpath,"/", ncname, sep="")
 dname <- c("picophyto", "nanophyto", "microphyto", "nanozoo", "microzoo", "mesozoo")  # variable name

 ## open netCDF file

 ncin <- ncdf4::nc_open(ncfname)
 print(ncin)

 # get longitude and latitude

 nx <- ncdf4::ncvar_get(ncin,"nx")
 dimnx <- dim(nx)
 head(nx)

 ny <- ncdf4::ncvar_get(ncin,"ny")
 dimny <- dim(ny)
 head(ny)

 print(c(dimnx, dimny))

 # get the time variable

 time <- ncdf4::ncvar_get(ncin,"Time")
 time

 # get a variable

 for (i in 1:length(dname)){
   assign(paste("ltl_array", dname[i], sep="_"), ncdf4::ncvar_get(ncin, dname[1]))
 }
 dim(ltl_array_picophyto)

###################################################################################################
### Accessibility matrix 
 
 apath <- here::here("matricedinteraction/configosmose-med2renewed")
 afilename <- c("predation-accessibility.csv")
 
 if (!file.exists(file=paste(apath, afilename, sep="/"))) {
   stop("The file '", afilename, "' does not exist", call. = FALSE)
 }
 
 suppressMessages(assign(strsplit(afilename, split="\\.")[[1]][1], data.matrix(readr::read_csv(col_names=TRUE, file=paste(apath, afilename, sep="/")))))
 `predation-accessibility` <- `predation-accessibility`[, 2:109]
 
#
#
#
#*****************Interaction matrix - Fish only- ******************************************************

creatematrixinteraction <- function(path, matrixaccessibility) {
  
  ## Call all the data frames extracted from the csv map files. ---
  ## Remove the .csv extension ---
  
  filelist <- list.files(path, pattern = ".csv")
  filelist <- gtools::mixedsort(sort(filelist))
  names <- filelist[filelist != outputname[1]]
  
  names <- sub(".csv$", "", names)
  colnames <- sub("map", "", names)
  
  dimmatrix <- (length(colnames(matrixaccessibility))) # because there is name for the rownames and the colnames : needs to be removed 
  
  matrixinteraction<-matrix(-99, dimmatrix, dimmatrix)
  
 ## The colnames are the names of the predators, rownames are the names of the preys : extracted from the accessibility matrix (because size-dependent in the accessibility matrix)---  
  
  colnames(matrixinteraction) <- colnames(matrixaccessibility) # to consider only the real colnames and rownames and to exclude the colnames/rownames name
  rownames(matrixinteraction) <- colnames(matrixaccessibility)
  
  ## determine which rows and columns are to be repeated in the integraton matrix to fit with the accessibility matrix
  
  vectordoublevalue <- grep(pattern="(<)",colnames(matrixaccessibility)[1:length(colnames(matrixaccessibility))])
  
  i=1;
  j=1;
  
 ## Fill in the matrix ---
  
  for (namepred in names) {
    
    predator <- as.matrix(get(namepred))
    predsurface <- sum(predator==1)
    
    for (nameprey in names) {
      
      prey <- as.matrix(get(nameprey))
      preysurface <-sum(prey==1)
      
      overlappmatrix <- predator+prey
    
      matrixinteraction[j,i] <- sum(overlappmatrix==2)/predsurface
      
      j=j+1
      
    }
    
    i=i+1
    j=1
  }
  
  matrixinteraction[is.nan(matrixinteraction)] = 0
  
  for (k in vectordoublevalue){
    
    matrixinteraction[,(k+1):dimmatrix] <- matrixinteraction[,k:(dimmatrix-1)]
    matrixinteraction[(k+1):dimmatrix,] <- matrixinteraction[k:(dimmatrix-1),]
    
  }
  
  return(matrixinteraction)
}

## Call function to create interaction matrix

 creatematrixinteraction(path, `predation-accessibility`)->matrixinteraction
 
#
#
#
#**********************Interaction matrix - add LTL to the fish interaction matrix *******************************
 
 addltl_interactionmatrix <- function(path, ncpath, matrixinteraction, matrixaccessibility, ltl_array_mesozoo, ltl_array_microphyto, ltl_array_microzoo, ltl_array_nanophyto, ltl_array_nanozoo, ltl_array_picophyto) {
   
   
   ## Call all the data frames extracted from the csv map files. ---
   ## Remove the .csv extension to extract its name ---
   
   filelist <- list.files(path, pattern = ".csv")
   names <- filelist[filelist != outputname[1]]
   names <- gtools::mixedsort(sort(names))
   names <- sub(".csv$", "", names)
   
   ## Get the names of the LTL
   
   ltlnames <- c("picophyto", "nanophyto", "microphyto", "nanozoo", "microzoo", "mesozoo")  # variable name
   
   ## Define which columns and rows should be duplicated to fit the accessibility matrix dimensions
   
   vectordoublevalue <- grep(pattern="(<)",colnames(matrixaccessibility)[1:length(colnames(matrixaccessibility))])

   ## Loop the data extraction 
   
   k=1
   listinteraction=list()
     
      for (time in 1:dim(ltl_array_picophyto)[3]){
        
        matrixltl <- matrix(0,  length(ltlnames), dim(matrixinteraction)[1])
        row.names(matrixltl)<-ltlnames[1:6]
        i=1
        
          
          for (ltl in 1:length(ltlnames)) {
            
            ## LTL matrix for a LTL, and a time step : sum all of the preys into _totprey_
            
            j=1
            
            ltl_array <- get(paste("ltl_array", dname[ltl], sep="_"))
            prey <- apply(t(ltl_array[,,time]), 2,rev)
            totprey <- sum(prey, na.rm = TRUE)
            
            for (namepred in names) {
              
              ## Fish predators are extracted one by one
              
              predator <- as.matrix(get(namepred))
              predator <- replace(predator, predator==-99, 0)
              
              sumoverlap <- sum(prey[which(predator!= 0 & predator!= -99,  arr.ind = TRUE)])
              
              ## Create a fraction of interaction for the predators and preys
              
              matrixltl[i,j] <- sumoverlap/totprey
            
              j=j+1
        
            }
          
            i=i+1
          }
        
        for (r in vectordoublevalue){

          matrixltl[,(r+1):dim(matrixltl)[2]] <- matrixltl[,r:(dim(matrixltl)[2]-1)]

        }
        
        
        matrixltl[is.nan(matrixltl)] = 1
        matrixltl <- rbind(matrixltl, matrix(0,1, dim(matrixltl)[2]))
        row.names(matrixltl)[7] <- c("benthos")
        listinteraction[[k]] <- rbind(matrixinteraction,matrixltl) #assign(paste("interaction", time, sep="."), 
        k=k+1

      }
   
      return(listinteraction)
 }
   
 ## Call function to fill-in interaction matrix
 
 interaction <- addltl_interactionmatrix(path, ncpath, matrixinteraction, `predation-accessibility`, ltl_array_mesozoo, ltl_array_microphyto, ltl_array_microzoo, ltl_array_nanophyto, ltl_array_nanozoo, ltl_array_picophyto)
 
 ## Add the accessibility term to the interaction factor
 ## we can do so because we made sure that the dimensions coincidate
 
 for (i in 1:24){
   
   interaction[[i]] <- interaction[[i]]*`predation-accessibility`
   
 }
 
 ## Convert the interaction list into an array (because easier to deal with to create a NetCDF)
 
 inter <- array(rep(0, 24*108*115), dim = c(115,108,24))
 
 for (i in 1:24){
   
   inter[,,i] <- interaction[[i]] 
   
 }

#***************************Store matrix in NetCDF file***************

 ## NetCDF creation to welcome the temporal fish interaction matrix -> https://publicwiki.deltares.nl/display/OET/Creating+a+netCDF+file+with+R
  
 ## define dimensions
 
 data.namesPrey <- 1:dim(inter)[1]
 data.namesPred <- 1:dim(inter)[2]
 data.time      <- 1:dim(inter)[3]
 
 dimPreyNames   <- ncdf4::ncdim_def(name='prey names', longname='species names', vals=data.namesPrey, units='name' )
 dimPredNames   <- ncdf4::ncdim_def(name='pred names', longname='species names', vals=data.namesPred, units='name' )
 dimTime        <- ncdf4::ncdim_def(name='time steps', units='time step', vals=data.time)

 ## define variables

  varInteraction <- ncdf4::ncvar_def(name="interaction", dim=list(dimPreyNames,dimPredNames, dimTime), units='factor')

 vars           <- list(varInteraction)
 
 ## create netcdf
 
 locname = paste("C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/predation-interactionrenewed",".nc", sep = "")
 ncnew <- ncdf4::nc_create(locname, vars)
 
 ## set the prey and pred names as the variables values of the pred and prey names
 
 names(ncnew$dim$`prey names`$vals)<-rownames(interaction[[1]])
 names(ncnew$dim$`pred names`$vals)<-colnames(interaction[[1]])   
 
 ## close the creation of the netcdf
 
 ncdf4::ncvar_put(nc = ncnew, varid = varInteraction, vals = inter, start = c(1,1,1), count = c(115,108,24))
 ncdf4::nc_close(ncnew)
 
 ## open netcdf
 
 ncdf4::nc_open(locname)-> interopen
 ncdf4::ncvar_get(interopen, varid=varInteraction)-> interopen2
   
# #
# #
# #
# #**********************Extract data *******************************
# 
# ## Represent the interaction matrix
#  
#  library(dplyr)
#  
#  matrixinteraction %>% 
#    as.data.frame() %>%
#    tibble::rownames_to_column("f_id") %>%
#    tidyr::pivot_longer(-c(f_id), names_to = "samples", values_to = "counts") %>%
#    ggplot2::ggplot(ggplot2::aes(x=samples, y=f_id, fill=counts)) + 
#    ggplot2::geom_raster() +
#    ggplot2::scale_fill_viridis_c()+
#    ggplot2::ylab("Preys") + 
#    ggplot2::xlab("Predators")+
#    ggplot2::theme(axis.text.x = ggplot2::element_text(angle=90, hjust=0.9, vjust=0.8))
#  
# ## Load the interaction matrix figure on your computer
#  
#  grDevices::dev.print(device = png, file = "matrixinteraction.png", width = 2000)
#  
#  
# ## Load the interaction matrix on the computer
#  
#  file.remove(paste(path, outputname[1], sep="/"))
#  write.csv(file=paste(path, outputname[1], sep="/"), x=matrixinteraction)
