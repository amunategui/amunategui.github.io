---
layout: post
title: Mapping The US with { ggmap }
category: Visualization
tags: visualizing
year: 2014
month: 9
day: 29
published: true
summary: GGMAP will enable you to easily plot data onto maps from around the world as long as you give it geographical coordinates.
image: MappingTheUSWithGGMAP/figure/unnamed-chunk-10.png
---

If you haven't played with the [ggmap](http://cran.r-project.org/web/packages/ggmap/index.html) package then you are in for a treat!

This will enable you to easily plot your data onto maps from around the world as long as it contains geographical coordinates.

Eventhough **ggmap** supports different map providers, I have only used it with Google Maps and that is what I'll walk you through in this article. We're going to download the median household income for the United States from the 2006 to 2010 census. Normally you would need to download a shape file from the [Census.gov](https://www.census.gov/geo/maps-data/data/tiger-line.html) site but the **University of Michigan's Institute for Social Research** graciously provides an Excel file for the national numbers. 

The file is limited to the mean and median household numbers by zip codes (but this is still a lot simpler than dealing with shape files).
 
We're going to load two packages in order to downlaod the data: [RCurl](http://cran.r-project.org/web/packages/RCurl/index.html) which allows us to download files directly from the Internet and [xlsx](http://cran.r-project.org/web/packages/xlsx/index.html) to read the Excel file and load the sheet named 'Median' into a data.frame:




```r
# NOTE if you can't download the file automatically, download it manually at:
# 'http://www.psc.isr.umich.edu/dis/census/Features/tract2zip/'
urlfile <-'http://www.psc.isr.umich.edu/dis/census/Features/tract2zip/MedianZIP-3.xlsx'
destfile <- "census20062010.xlsx"
download.file(urlfile, destfile, mode="wb")
census <- read.xlsx2(destfile, sheetName = "Median")
```

We clean the file up by keeping only the zip codes and median household incomes and removing the decorative commas in the dollar figures:

```r
census <- census[c('Zip','Median..')]
names(census) <- c('Zip','Median')
census$Median <- as.character(census$Median)
census$Median <- as.numeric(gsub(',','',census$Median))
print(head(census,5))
```

```
##    Zip Median
## 1 1001  56663
## 2 1002  49853
## 3 1003  28462
## 4 1005  75423
## 5 1007  79076
```

We leverage another package [zipcode](http://cran.r-project.org/web/packages/zipcode/index.html) that will not only clean our zip codes by removing any '+4' data and padding with zeros when needed, it will also give us the centroid latitude and longitude coordinate for that zip code (this requires downloading the zipcode data file):



```r
data(zipcode)
census$Zip <- clean.zipcodes(census$Zip)
```

We merge our census data with the zipcode data on zip codes:

```r
census <- merge(census, zipcode, by.x='Zip', by.y='zip')
```

Finally we get to heart of our mapping goals. We retrieve a map of the United States using **ggmap**. We opt for the zoom level 4 which works well to cover the US, terrain type and request a colored map (verus a black and white one):


```r
map<-get_map(location='united states', zoom=4, maptype = "terrain",
             source='google',color='color')
```

```
## Map from URL : http://maps.googleapis.com/maps/api/staticmap?center=united+states&zoom=4&size=%20640x640&scale=%202&maptype=terrain&sensor=false
## Google Maps API Terms of Service : http://developers.google.com/maps/terms
## Information from URL : http://maps.googleapis.com/maps/api/geocode/json?address=united+states&sensor=false
## Google Maps API Terms of Service : http://developers.google.com/maps/terms
```

And [ggplot2](http://cran.r-project.org/web/packages/ggplot2/index.html) that will handle the graphics where we pass our census data with the geograpical coordinates:


```r
ggmap(map) + geom_point(
        aes(x=longitude, y=latitude, show_guide = TRUE, colour=Median), 
        data=census, alpha=.5, na.rm = T)  + 
        scale_color_gradient(low="beige", high="blue")
```

![plot of chunk unnamed-chunk-10](figure/unnamed-chunk-10.png) 
<BR>
And there you have it, the median household income from 2006 to 2010 mapped on Google Maps in just a few lines of code! You can play around with the alpha setting to increase or decrease the transparency of the census data on the map.        
        
[Full source](https://github.com/amunategui/Mapping-The-US-With-GGMAP/blob/master/ggmap-example.R):

```r
require(RCurl)
require(xlsx)

# NOTE if you can't download the file automatically, download it manually at:
# 'http://www.psc.isr.umich.edu/dis/census/Features/tract2zip/'
urlfile <-'http://www.psc.isr.umich.edu/dis/census/Features/tract2zip/MedianZIP-3.xlsx'
destfile <- "census20062010.xlsx"
download.file(urlfile, destfile, mode="wb")
census <- read.xlsx2(destfile, sheetName = "Median")

# clean up data
census <- census[c('Zip','Median..')]
names(census) <- c('Zip','Median')
census$Median <- as.character(census$Median)
census$Median <- as.numeric(gsub(',','',census$Median))
print(head(census,5))

# get geographical coordinates from zipcode
require(zipcode)
data(zipcode)
census$Zip <- clean.zipcodes(census$Zip)
census <- merge(census, zipcode, by.x='Zip', by.y='zip')

# get a Google map
require(ggmap)
map<-get_map(location='united states', zoom=4, maptype = "terrain",
             source='google',color='color')

# plot it with ggplot2
require("ggplot2")
require("RColorBrewer")
ggmap(map) + geom_point(
        aes(x=longitude, y=latitude, show_guide = TRUE, colour=Median), 
        data=census, alpha=.8, na.rm = T)  + 
        scale_color_gradient(low="beige", high="blue")
```
