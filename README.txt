         How th remove the spatialization from a spatialized configuration on osmose. 


OBJ : 
This document aims to explain how I did convert the 2 dimensions configuration into a 0 dimension configuration.
It explains how does the => matrixinteraction_med2renewed.R <= file work. 

Definitions :
2D configuration : the configuration which takes into account the distribution maps of the species, according to the longitude and latitude in the Mediterranean sea (in this case). 
0D configuration : in the 2D configuration : get rid on the spatial representation, and represent the Mediterranean sea with as if it was a square in space. To do so, we faced a few issues. 
A cell           : the spatial unity of the model. The Mediterranean is devided by a regular grid into cells. Each cell represent a land square (0) or a square of sea (1). 

Process : 
1- Convert the distribution of the species into a parameter managing the encounter probability between two species of fish : the interaction parameter. 
   The calculation of the interaction parameter for prey i and predator j is as follows : 
   The parameter represents the number of cells where both prey i and predator j are present together divided by the number of cells where is the predator j.
   This parameter is necessarily <1.  
2- Include the new parameter created into the configuration : find a way to include the interaction parameter into the code in a simple way. 
   The interaction parameters are stored in an interaction matrix. Each row represent a prey and each column represents a predator. The interaction matrix isn't symmetrical. 
   To include this matrix in the model : 
   We decided to convert the accessibility parameter (which reprensents the vertical dimension) into a parameter which represents both the former accessibility parameter AND the interaction parameter.
   That way, the interaction parameter will be included in the model, without having to change the whole equation expressions. 
   The accessibility matrix is prey-size-dependant. 
   Thus, to adjust to the the size-dependency, we have had to adjust the size of the interaction matrix to the size of the accessibilty matrix by duplicating columns of the interaction matrix.  
3- Ultimately, we need to explain to osmose that the spatial dimension has been removed. 
   To do so, we are changing its grid call, and replacing the former grid-map by a one cell-grid map.
   This part is done in the file : => eco3m-med_and_map_with0d.R <= 

=>  These are the big lines of the process. However, the method is a bit different according to the organism we are focusing on. 
    We need to split the organisms into two categories : a- the fish and b- the low trophic levels (ltl).
    These organisms groups differe in the way they integrate the spatial dimension. 

a- for fish : 
   Their spatial dimention is only considered as a spatial presence absence accordind to the cell we are focusing on. 
   Their biomass is built over the course of time. 
   Therefore, the only non-spatialised dimension we have to create for the fish organisms is their now-matrix of accessibility-interaction.
   That is to say, we are converting the distribution map of the fish into an interaction parameter and integrating it into the model as explained earlier.
b- for low trophic levels (ltl) : 
   The ltl organisms are exclusively preys in our model.
   Instead of a presence/absence distribution map, they have a biomass distribution over the mediterranean sea. 
   Their biomass is reinitialized at the begining of each time step. Their distribution is time-dependant and there are 24 time steps each year. 
   Thus, we need a way to represent both their time-dependant biomass AND to represent their probability of interaction with their predators, according to their biomass distribution extracted from the Eco3MS-med data. 
   To do so : 
   (i)  the interaction matrix construction has a process really close to the one that was described earlier. 
        The main idea is that we are considering the proportion of ltl biomass encountered by the fish predators over their distribution map with respect to the whole ltl biomass in the Mediterranean sea. 
        Again, the interaction parameter of the ltl is <1. 
        The ltl biomass distribution is time-dependent, it means that the now-matrix of accesssibility-interaction includes this temporal dimension. 
   (ii) the ltl biomass needs to be stored without the spatial dimension and time-dependant in some way. 
        We have converted the biomass distribution map into a time_dependant single-cell ltl biomass map. 
        This is done by suming up the ltl biomass over every cell of the mediterranean distribution map.  
        This part is done in the file : => eco3m-med_and_map_with0d.R <= 
