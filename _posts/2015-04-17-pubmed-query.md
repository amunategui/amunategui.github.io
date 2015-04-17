---
layout: post
title: 'Getting PubMed Medical Text with R and Package { RISmed }'
category: Exploring Data
tags: exploring
year: 2015
month: 4
day: 17
published: true
summary: "PubMed is a great source of medical literature. If you are working on a Natural Language Processing (NLP) project and need topic-based medical text, the RISmed package can simplify and automate that process."
image: pubmed-query/pubmed.png
---
![plot of pubmed logo](../img/posts/pubmed-query/pubmed.png) 
<BR><BR>
**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/user/mamunate/videos" target='_blank'>YouTube Companion Video</a></li>
<li type="square"><a href="#sourcecode">Full Source Code</a></li>
</ul>
<BR>
**Packages Used in this Walkthrough**

<ul>
        <li type="square"><a href="http://cran.r-project.org/web/packages/RISmed/index.html" target="_blank">{RISmed}</a> - Download Content from NCBI Databases</li>
</ul>

<BR><BR>
<a href="http://www.ncbi.nlm.nih.gov/pubmed" target="_blank">PubMed</a> is a phenomenal source of medical literature. For anybody working in **Natural Language Processing (NLP)** project and are looking for topic-based medical text, PubMed is a great resource.

<blockquote>"PubMed comprises more than 24 million citations for biomedical literature from MEDLINE, life science journals, and online books. Citations may include links to full-text content from PubMed Central and publisher web sites. (Wikipedia.com)"</blockquote>

There are lots of stand-alone tools and many programming library extensions to help query and extract PubMed data. The information available ranges from topics, titles, citations, abstracts, articles, etc. Researchers use them to see what is trending in the medical community, what subjects are covered, who’s writing what and when, and so on.

On my end, I needed a large swath of unstructured medical data for very specific topics and the package <a href="http://cran.r-project.org/web/packages/RISmed/index.html" target="_blank">RISmed</a> allowed me to get to that data in a straightforward way. 

**Let’s Code!**

If you haven't done so, install the **RISmed** package. We call the library and assign a variable for our search topic: **Chronic obstructive pulmonary disease (COPD)**.


```r
#install.packages("RISmed")
library(RISmed)
search_topic <- 'copd'
```

The ``EUtilsSummary`` function helps narrow a search query and will indicate how much datais available under the q uerying criteria. This is an important steps as it allows your to do some exploratory work with downloading the actual data. Here we ask for 100 articles regarding our search topic published in 2012


```r
search_query <- EUtilsSummary(search_topic, retmax=100, mindate=2012, maxdate=2012)
```

We can call the ``summary`` function and see what the ``search_query`` holds:

```r
summary(search_query)
```

```
## Query:
## ("pulmonary disease, chronic obstructive"[MeSH Terms] OR ("pulmonary"[All Fields] AND "disease"[All Fields] AND "chronic"[All Fields] AND "obstructive"[All Fields]) OR "chronic obstructive pulmonary disease"[All Fields] OR "copd"[All Fields]) AND 2012[EDAT] : 2012[EDAT] 

## Result count:  3550
```

We read from the summary that PubMed contains 3550 documents on **COPD** published in 2012. It also displays how it queried our search term and confirming that it correctly understood the **COPD** acronym. Checking this is an important step as it is hard to manually check the theme of thousands of articles.

We can also see the 100 document IDs we asked for:

```r
# see the ids of our returned query
QueryId(search_query)
```

```
##   [1] "23272298" "23271905" "23271904" "23271829" "23271821" "23271819"
##   [7] "23271818" "23271817" "23271741" "23271621" "23271620" "23270668"
##  [13] "23270360" "23270062" "23270045" "23249528" "23269884" "23269866"
##  [19] "23268483" "23268465" "23267696" "23266884" "23266537" "23266127"
##  [25] "23265910" "23265333" "23265285" "23265268" "23265228" "23264836"
##  [31] "23264660" "23264538" "23263935" "23263604" "23262518" "23262512"
##  [37] "23261311" "23261310" "23260455" "23259787" "23259710" "23259655"
##  [43] "23258927" "23258787" "23258786" "23258785" "23258783" "23258777"
##  [49] "23258776" "23258731" "23258580" "23258576" "23258471" "23258468"
##  [55] "23258247" "23258244" "23257773" "23257650" "23257530" "23257347"
##  [61] "23256918" "23256845" "23256723" "23256722" "23256721" "23256720"
##  [67] "23256719" "23256718" "23256717" "23256716" "23256715" "23256714"
##  [73] "23256713" "23256346" "23256175" "23256174" "23256173" "23256172"
##  [79] "23256171" "23256170" "23256169" "23256168" "23256167" "23256166"
##  [85] "23256165" "23256164" "23256163" "23256162" "23256161" "23255854"
##  [91] "23255616" "23255540" "23254770" "23253873" "23253549" "23253321"
##  [97] "23252578" "23252355" "23252287" "23251993"
```

Once happy with the search terms, we fetch for the actual data by calling function ``EUtilsGet``:

```r
records<- EUtilsGet(search_query)
class(records)
```

```
## [1] "Medline"
## attr(,"package")
## [1] "RISmed"
```

```r
# str(records)
```
To see the contents of records you can call function ``str`` but it returns so much information that I won't do it here. The best way to extract your data out of the returned ``EUtilsGet`` object is to only use the tags of interest. You can get a full list of the available tags off the <a href="http://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html" target="_blank">PubMed Help</a> document.

Here we will use the tags ``ArticleTitle`` and ``AbstractText`` on the ``records`` object and stuff it into a data frame:


```r
pubmed_data <- data.frame('Title'=ArticleTitle(records),'Abstract'=AbstractText(records))
head(pubmed_data,1)
```

```
##                                                                     Title
## 1 Burning HOT: revisiting guidelines associated with home oxygen therapy.
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          Abstract
## 1 Burn injuries secondary to home oxygen therapy (HOT) have become increasingly common in recent years, yet several guidelines for HOT and chronic obstructive pulmonary disease (COPD) neglect to stress the dangers of open flames. This retrospective review of burn injury admissions secondary to HOT to our burn centre from 2007 to 2012 aimed to establish the extent of this problem and to discuss the current literature and a selection of national guidelines. Out of six patients (five female, one male) with a median age of 72 (range 58-79), four were related to smoking, and two due to lighting candles. The mean total body surface area (TBSA) affected was 17% (range 2-60%). Five patients sustained facial burns, two suffered from inhalation injury (33.3%), and five required surgery (83.3%). Mean total length of stay was 20 days (range 8 to 33), and one patient died. Although mentioned in the majority, some guidelines fail to address the issue of smoking in light of the associated risk for injury, which in turn might have future implications in litigation related to iatrogenic injuries. Improved HOT guidelines will empower physicians to discourage smoking, and fully consider the risks versus benefits of home oxygen before prescription. With a view on impeding a rising trend of burns secondary to HOT, we suggest revision to national guidelines, where appropriate.
```

There are two more important steps to make our data fully usable in ``R``. I tend to save my data sets in comma delimited data sets (CSV) so I need to make sure the data is comma-free. If commas are important to you, then I'd recommend saving the data set with a ``write.table`` instead of ``write.csv`` and come up with your own delimiter. 

```r
pubmed_data$Abstract <- as.character(pubmed_data$Abstract)
pubmed_data$Abstract <- gsub(",", " ", pubmed_data$Abstract, fixed = TRUE)
```

See what we have:
```r
str(pubmed_data)
## 'data.frame':	100 obs. of  2 variables:
##  $ Title   : Factor w/ 100 levels "[Advances in pulmonology in year 2012].",..: 24 47 63 69 76 18 92 98 37 1 ...
##  $ Abstract: chr  "Burn injuries secondary to home oxygen therapy (HOT) have become increasingly common in recent years  yet several guidelines fo"| __truncated__ "BACKGROUND: High-intensity (high-pressure and high backup rate) noninvasive ventilation has recently been advocated for the man"| __truncated__ "" "Oxygen is necessary for all aerobic life  and nothing is more important in respiratory care than its proper understanding  asse"| __truncated__ ...
```

<b>Note:</b> There are many other packages to pull PubMed data in R - google them if this one doesn't satisfy all your needs.

<BR><BR>        
<a id="sourcecode">Full source code (<a href='https://github.com/amunategui/feature-hashing-walkthrough/blob/master/feature-hasher-walkthrough.r' target='_blank'>also on GitHub</a>)</a>:

```r
#install.packages("RISmed")
library(RISmed)

search_topic <- 'copd'
search_query <- EUtilsSummary(search_topic, retmax=100, mindate=2012,maxdate=2012)
summary(search_query)

# see the ids of our returned query
QueryId(search_query)

# get actual data from PubMed
records<- EUtilsGet(search_query)
class(records)

# store it
pubmed_data <- data.frame('Title'=ArticleTitle(records),'Abstract'=AbstractText(records))
head(pubmed_data,1)

pubmed_data$Abstract <- as.character(pubmed_data$Abstract)
pubmed_data$Abstract <- gsub(",", " ", pubmed_data$Abstract, fixed = TRUE)

# see what we have
str(pubmed_data)

```
 
