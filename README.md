# Yap-Island-Zika-virus-model

The model is a spatial version of a SEIR (susceptible, exposed, infectious, recovered) model modified to better match the vector-borne nature of Zika virus. Humans are classed as S, E, I or R and mosquitoes as S, E or I (mosquitoes rarely clear the virus so remain infectious). In a given “tick” (a day in the outbreak’s course), I humans have a probability of “infecting” S mosquitoes and vice versa, E humans or mosquitoes have a probability to convert to I humans or mosquitoes and I humans into R humans.

This process is repeated in every patch of a patch map of the study area (Yap island in Micronesia or San Andreas island in Columbia), each patch representing a 100x100m area. Every tick, nearby patches exchange people and mosquitoes simulating geographical movement, allowing the outbreak to spread between patches. A network of nodes and links was used to allow distant patches to exchange humans, simulating faster transmission between populated areas.

Patch maps were created in QGIS from USAD landcover data (Yap) and forest/not-forest satellite data from ALOS2 (San Andreas). Land type data combined with census estimates and mosquito ecology papers were used to estimate human and mosquito populations for each patch. 

The base model (Yap geographical sir (R).nlogo) was constructed using the Netlogo extension NetlogoGIS. Using RNetlogo, scripts were written to repeatedly run the model with randomised model peramiters within plausable ranges.

When tested on the San Andreas outbreak, the Yap outbreak model turned out to be unhelpful, because of the higher maximum population density, the model, which depended on density-dependent transmission within patches (chance of infection proportional to the number of infectious agents in the patch), either resulted in a very quick, almost total infection of the population or quick elimination of the outbreak with very low rates of infection, both of which were unlike the real outbreak. To remedy this issue the model of transmission was changed so each mosquito has a fixed number of potentially transmissive encounters in each tick, resulting in a human-to-mosquito transmission dependent on the ratio of infectious humans to uninfectious humans and mosquito-to-human transmission dependent on ratio of humans to infected mosquitoes. This results in a more frequency-dependent transmission model (San Andreas geographical sir (R).nlogo) and reduced transmission in urban areas resulting in runs which better fit the data.

The new transmission model was also applied to Yap (Yap geographical sir (R) mosbite.nlogo

