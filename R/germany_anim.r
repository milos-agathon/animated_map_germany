# REPLICATION FILE - MILOS POPOVIC 4/26/2021
# MAKE A COOL ANIMATED MAP OF GERMANY USING <150 LINES OF CODE!
# install packages if needed
install.packages(ggplot2, dependencies = T)
install.packages(dplyr, dependencies = T)
install.packages(reshape2, dependencies = T)
install.packages(rgeos, dependencies = T)
install.packages(tweenr, dependencies = T)
install.packages(grid, dependencies = T)
install.packages(rgeos, dependencies = T)
install.packages(dplyr, dependencies = T)
install.packages(plyr, dependencies = T)
install.packages(rgdal, dependencies = T)
install.packages(animation, dependencies = T)
install.packages(scales, dependencies = T)
install.packages(rmapshaper, dependencies = T)

# load packages
library(rgeos, quietly = T)
library(tweenr, quietly = T)
library(ggplot2, quietly=T) 
library(reshape2, quietly=T) 
library(grid, quietly=T) 
library(rgeos, quietly=T)
library(plyr, quietly=T)
library(dplyr, quietly=T)
library(rgdal, quietly=T)
library(animation, quietly=T)
library(scales, quietly=T)
library(rmapshaper, quietly=T)

set.seed(20210428)
# load the shapefile using rgdal package
ger <- readOGR(getwd(),
  "germany_lau", 
  verbose = TRUE, 
  stringsAsFactors = FALSE) %>% 
ms_simplify(keep=.015) # simplify the polygons to make the gif faster

# turn the shapefile into dataframe
a <- as.data.frame(ger)
names(a) 
b <- a[,c(3, 7:16)] # we only need LAU_CODE and nlight columns

# we need a long format for animation
b1 <- melt(data = b, id.vars = "LAU_CODE")

# turn variable string into numeric years
b1$year <- b1$variable %>%
           gsub("nlight", "", .) %>%
           paste0("20", .) %>%
           as.numeric(as.character())

# we need to split the data.frame into list of years for tweenr
# in order to split the data, every unit must have every year
# otherwise the function returns an error
x <- split(b1, b1$year)

# use the list of years to set up transition features, number of frames etc.
tw <- tween_states(x, tweenlength= 4, statelength=5, 
                   ease="linear",
                   nframes=50)
head(tw) #you'll see new columns, phase of transition, id and frame number
#prepare the shapefile in data.frame format
g <- fortify(ger, region = "LAU_CODE") %>% 
  mutate(LAU_CODE = as.numeric(id))

# we'll use a continuous scale this time
# so, we have to set the min/max values
vmax <- max(tw$value, na.rm=T)
vmin <- min(tw$value, na.rm=T)

# we'll assign dark blue for absence and yellow for presence
# of nighlight above a threshold
cols =c("#f6d746", "#140b34")
newcol <- colorRampPalette(cols)
ncols <- 4 # 4 values should be fine
cols2 <- newcol(ncols) # cut the palette into 4 values

# i like to freeze the last frame for some time
# this code assigns 0.2 secs to each frame while
# extending the last to 4 secs
times <- c(rep(0.2, max(tw$.frame)-1), 4)
tw$year <- round(tw$year, 0) # remember to round years

# it's time to make our time-lapse map
oopt = ani.options(interval = .2)
saveGIF({for (i in 1:max(tw$.frame)) { # we need to define a loop to iterate through every frame
grm <- ger[,c(3)] # we don't want to duplicate columns to LAU_CODE is sufficient
grm@data <- join(grm@data, tw, by = "LAU_CODE") %>% # merge into new shapefile...
  filter(.frame==i) # ...and filter by frame
  map <- # map file to be created for every frame
    ggplot() +
  geom_map(data = g, map = g, # this is the base layer without colors
             aes(
              map_id = id),
             color = NA, 
             size = 0, 
             fill = NA) +
    geom_map(data = grm@data, # this is the layer to be filled with values
             map = g,
             aes(fill = value, 
            map_id = LAU_CODE),
             color = NA, 
             size=0)  +
  scale_fill_gradientn(colors=rev(cols2), 
            limits = c(vmin,vmax), 
            breaks=pretty_breaks(n=6), # use pretty breaks
            name="", 
            na.value = "grey80")+
coord_map() +
expand_limits(x=g$long,y=g$lat)+
  labs(y="", 
        subtitle=paste0(as.character(as.factor(tail(tw %>% filter(.frame==i),1)$year))),
        title="Nighttime light in Germany (2009-2018)",
         caption="")+
theme_minimal() +
theme(plot.background = element_rect(fill = "#140b34", color = NA), 
panel.background = element_rect(fill = "#140b34", color = NA), 
legend.background = element_rect(fill = "#140b34", color = NA),
legend.position = "none",
panel.border = element_blank(),
panel.grid.minor = element_blank(),
panel.grid.major = element_line(color = "#140b34", size = 0),
plot.title = element_text(size=24, color="white", hjust=0.5, vjust=-20),
plot.subtitle = element_text(size=60, color="#f6d746", hjust=0.1, vjust=-10, face="bold"),
plot.caption = element_text(size=14, color="grey60", hjust=0.5, vjust=-1),
legend.text = element_text(size=16, color="grey20"),
legend.title = element_text(size=22, color="grey20"),
strip.text = element_text(size=12),
plot.margin=unit(c(t=0, r=0, b=0, l=0), "cm"), # use this to cut extra blank space
axis.title.x = element_blank(),
axis.title.y = element_blank(),
axis.ticks = element_blank(),
axis.text.x = element_blank(),
axis.text.y = element_blank())
print(map)
  print(paste(i,"out of",max(tw$.frame))) # print progress
  ani.pause()}
},movie.name="germany_nightlight.gif", 
dpi=600, 
ani.height=1144, 
ani.width=768,
interval = times,
other.opts = "-framerate 10  -i image%03d.png -s:v 768x1144 -c:v libx264 -profile:v high -crf 20  -pix_fmt yuv420p")