## Path where is the 0D configuration

path <- here::here("Compare0Dand2D/0D")

#######################
##   FISH MAPS CREATION
##      IN 0D
#######################

## Create a netcdf file to define the maps of the fish

dimnx   <- ncdf4::ncdim_def(name='nx', longname='nx', vals=1, units='x' )
dimny   <- ncdf4::ncdim_def(name='ny', longname='ny', vals=1, units='y' )

## define variables

varlong <- ncdf4::ncvar_def(name="longitude", dim=list(dimnx), units='float')
varlat  <- ncdf4::ncvar_def(name="latitude", dim=list(dimny), units='float')
varmap  <- ncdf4::ncvar_def(name="map", dim=list(dimnx,dimny), units='8 byte int')

vars    <- list(varlong, varlat, varmap)

## create netcdf

locname = paste("C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/map0D",".nc", sep = "")
ncnew <- ncdf4::nc_create(locname, vars)

ncdf4::ncvar_put(nc = ncnew, varid = varmap, vals = c(1), start = c(1,1), count = c(1,1))
ncdf4::nc_close(ncnew)


#######################
##   LTL MAPS CREATION
##      IN 0D
##   24 TIME STEPS
#######################

## Create an array to fill in the netcdf file

ltl_array_0D <- array(1, dim = c(1,1,6,24))

## Extract the sum of ltlfor each time step and for each species

   ## Path to distribution files ----

   ncpath <- here::here("matricedinteraction/configosmose-med2renewed")
   ncname <- "corrected_eco3m_med.nc"  
   ncfname <- paste(ncpath,"/", ncname, sep="")
   dname <- c("picophyto", "nanophyto", "microphyto", "nanozoo", "microzoo", "mesozoo")  # variable name

   ## open netCDF file

   ncin <- ncdf4::nc_open(ncfname)
   for (i in 1:length(dname)){
     assign(paste("ltl_array", dname[i], sep="_"), ncdf4::ncvar_get(ncin, dname[1]))
   }
   dim(ltl_array_picophyto)
   
   ## loop : copy the data in the array
   
   for (i in 1:6){
     for (j in 1:24){
       ltl_array <- get(paste("ltl_array", dname[i], sep="_"))
       prey <- apply(t(ltl_array[,,j]), 2,rev)
       ltl_array_0D[1,1,i,j] <- sum(prey, na.rm = TRUE)
     }
   } 
   
## Create a netcdf file to define the maps of the fish

dimnx   <- ncdf4::ncdim_def(name='nx', longname='nx', vals=1, units='x' )
dimny   <- ncdf4::ncdim_def(name='ny', longname='ny', vals=1, units='y' )
dimtime <- ncdf4::ncdim_def(name='time', longname='time step', vals=c(1:24), units='half a month')

## define variables

varlong <- ncdf4::ncvar_def(name="longitude", dim=list(dimnx), units='float')
varlat  <- ncdf4::ncvar_def(name="latitude", dim=list(dimny), units='float')
varpico <- ncdf4::ncvar_def(name="pico biomass", dim=list(dimnx,dimny,dimtime), units='biomass')
picophyto <- ncdf4::ncvar_def(name="picophyto biomass", dim=list(dimnx,dimny,dimtime), units='biomass')
nanophyto <- ncdf4::ncvar_def(name="nanophyto biomass", dim=list(dimnx,dimny,dimtime), units='biomass')
microphyto <- ncdf4::ncvar_def(name="microphyto biomass", dim=list(dimnx,dimny,dimtime), units='biomass')
nanozoo <- ncdf4::ncvar_def(name="nanozoo biomass", dim=list(dimnx,dimny,dimtime), units='biomass')
microzoo <- ncdf4::ncvar_def(name="microzoo biomass", dim=list(dimnx,dimny,dimtime), units='biomass')
mesozoo <- ncdf4::ncvar_def(name="mesozoo biomass", dim=list(dimnx,dimny,dimtime), units='biomass')

vars    <- list(varlong, varlat, picophyto,nanophyto, microphyto,  nanozoo, microzoo, mesozoo)

## create netcdf

locname = paste("C:/Users/mbeneat/Documents/osmose/Compare0Dand2D/0D/eco3m_med_0D",".nc", sep = "")
ncnew <- ncdf4::nc_create(locname, vars)

ncdf4::ncvar_put(nc = ncnew, varid = picophyto, vals = ltl_array_0D[,,1,], start = c(1,1,1), count = c(1,1,24))
ncdf4::ncvar_put(nc = ncnew, varid = nanophyto, vals = ltl_array_0D[,,2,], start = c(1,1,1), count = c(1,1,24))
ncdf4::ncvar_put(nc = ncnew, varid = microphyto, vals = ltl_array_0D[,,3,], start = c(1,1,1), count = c(1,1,24))
ncdf4::ncvar_put(nc = ncnew, varid = nanozoo, vals = ltl_array_0D[,,4,], start = c(1,1,1), count = c(1,1,24))
ncdf4::ncvar_put(nc = ncnew, varid = microzoo, vals = ltl_array_0D[,,5,], start = c(1,1,1), count = c(1,1,24))
ncdf4::ncvar_put(nc = ncnew, varid = mesozoo, vals = ltl_array_0D[,,6,], start = c(1,1,1), count = c(1,1,24))
ncdf4::nc_close(ncnew)

ncdf4::nc_open(locname)-> interopen
ncdf4::ncvar_get(interopen, varid=varbiom)-> interopen2
