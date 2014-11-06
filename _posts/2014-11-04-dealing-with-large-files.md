---
layout: post
title: How to work with files that are too large for a computer’s RAM – Using R to process data in chunks.
category: Machine Learning
tags: exploring
year: 2014
month: 11
day: 4
published: true
summary: Using the function <b>read.table()</b>, we break file into chunks in order to process them. This allows processing files of any size beyond what the machine's RAM can handle.
image: dealing-with-large-files/memory.png
---
**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/watch?v=Z5rMrI1e4kM" target='_blank'>YouTube Companion Video</a></li>
<li type="square"><a href="#sourcecode">Full Source Code</a></li>
</ul>

<BR><BR>
There are times when files are just too large to fit in a computer’s live memory. 
 
If you’re brand-new to <b>R</b> you may not have encountered this yet but we all do eventually. The problem happens when calling functions such as ``read.csv()`` or ```read.table()`` on large data files and your computer ends up freezing or choking. I usually end up losing patience and killing the process.
 
In <b>R</b> you cannot open a 20 GB file on a computer with 8 GBs of RAM - it just won't work. By default, <b>R</b> will load all the data into RAM. Even files that are smaller than your RAM may not be opened depending on what you have running, on your OS, 32/64 bit, etc.
 
To get an estimate on how much memory a data frame needs remember that an integer uses 4 bytes and a float about 8. So if you have 100 columns and 100,000 rows, you would multiply <b>8 by 100 by 100000</b> (NOTE: 2^20 will convert bytes to megabytes):


```r
options(scipen=999) # block scientific notation
print(paste((8*100*100000) / 2^20, 'megabytes'))
```
```
## [1] "76.2939453125 megabytes"
```
<BR><BR>
<b>76 megabytes</b> isn’t a problem for most computers, but what to do when it is? There are various ways of dealing with such issues such as using command line tools to break the files into smaller ones or rent a larger computer from a cloud service. But an easy <b>R</b> solution is to iteratively read the data in smaller-sized chunks that your computer can handle.
 
Let's download a large <b>CSV</b> file from the <a href='http://archive.ics.uci.edu/ml/datasets.html' target='_blank'>University of California, Irvine's Machine Learning Repository</a>. Download the compressed 
HIGGS Data Set and unzip it (NOTE: this is a huge file that unzips at over 8 GB): 

```r
setwd('Enter Your Folder Path Here...')
download.file('http://archive.ics.uci.edu/ml/machine-learning-databases/00280/HIGGS.csv.gz', 'HIGGS.csv.gz')
```
<BR><BR>
If the above code doesn't work, you can download it directly <a href='http://archive.ics.uci.edu/ml/machine-learning-databases/00280/HIGGS.csv.gz' target='_blank'>here</a>.

Once you unzipped it, we can run the ``file.info`` to get some details about it without loading it in memory(NOTE: 2^30 will convert bytes to gigabytes):


```r
print(paste(file.info('HIGGS.csv')$size  / 2^30, 'gigabytes'))
```
```
## [1] "7.48364066705108 gigabytes"
```
<BR><BR>
This is a big one, coming in at around <b>7.5 GB</b>, a lot of machines won't be able to read it directly into memory with a typical ``read.csv()`` call.

The ``readLines()`` function is a workhorse when it comes to peeking into a very large file without loading the whole thing. I often use it to get the column headers and a handful of rows:
 

```r
transactFile <- 'HIGGS.csv'
readLines(transactFile, n=1)
```

```
## [1] "1.000000000000000000e+00,8.692932128906250000e-01,-6.350818276405334473e-01,2.256902605295181274e-01,3.274700641632080078e-01,-6.899932026863098145e-01,7.542022466659545898e-01,-2.485731393098831177e-01,-1.092063903808593750e+00,0.000000000000000000e+00,1.374992132186889648e+00,-6.536741852760314941e-01,9.303491115570068359e-01,1.107436060905456543e+00,1.138904333114624023e+00,-1.578198313713073730e+00,-1.046985387802124023e+00,0.000000000000000000e+00,6.579295396804809570e-01,-1.045456994324922562e-02,-4.576716944575309753e-02,3.101961374282836914e+00,1.353760004043579102e+00,9.795631170272827148e-01,9.780761599540710449e-01,9.200048446655273438e-01,7.216574549674987793e-01,9.887509346008300781e-01,8.766783475875854492e-01"
```
<BR><BR>

You could easily use readLines to loop through smaller chunks in memory one at a time.  But I prefer ``read.table()`` and that is what I use.
<BR><BR>
I copied from the UCI repository the column names:


```r
higgs_colnames <- c('label','lepton_pT','lepton_eta','lepton_phi','missing_energy_magnitude','missing_energy_phi','jet_1_pt','jet_1_eta','jet_1_phi','jet_1_b_tag','jet_2_pt','jet_2_eta','jet_2_phi','jet_2_b_tag','jet_3_pt','jet_3_eta','jet_3_phi','jet_3_b-tag','jet_4_pt','jet_4_eta','jet_4_phi','jet_4_b_tag','m_jj','m_jjj','m_lv','m_jlv','m_bb','m_wbb','m_wwbb')
```
<BR><BR>

```r
transactFile <- 'HIGGS.csv'
chunkSize <- 100000
con <- file(description= transactFile, open="r")   
data <- read.table(con, nrows=chunkSize, header=T, fill=TRUE, sep=",")
close(con)
names(data) <- higgs_colnames
print(head(data))
```

```
##   label lepton_pT lepton_eta lepton_phi missing_energy_magnitude
## 1     1    0.9075     0.3291   0.359412                   1.4980
## 2     1    0.7988     1.4706  -1.635975                   0.4538
## 3     0    1.3444    -0.8766   0.935913                   1.9921
## 4     1    1.1050     0.3214   1.522401                   0.8828
## 5     0    1.5958    -0.6078   0.007075                   1.8184
## 6     1    0.4094    -1.8847  -1.027292                   1.6725
##   missing_energy_phi jet_1_pt jet_1_eta jet_1_phi jet_1_b_tag jet_2_pt
## 1            -0.3130   1.0955  -0.55752  -1.58823       2.173   0.8126
## 2             0.4256   1.1049   1.28232   1.38166       0.000   0.8517
## 3             0.8825   1.7861  -1.64678  -0.94238       0.000   2.4233
## 4            -1.2053   0.6815  -1.07046  -0.92187       0.000   0.8009
## 5            -0.1119   0.8475  -0.56644   1.58124       2.173   0.7554
## 6            -1.6046   1.3380   0.05543   0.01347       2.173   0.5098
##   jet_2_eta jet_2_phi jet_2_b_tag jet_3_pt jet_3_eta jet_3_phi jet_3_b-tag
## 1   -0.2136    1.2710       2.215   0.5000   -1.2614    0.7322       0.000
## 2    1.5407   -0.8197       2.215   0.9935    0.3561   -0.2088       2.548
## 3   -0.6760    0.7362       2.215   1.2987   -1.4307   -0.3647       0.000
## 4    1.0210    0.9714       2.215   0.5968   -0.3503    0.6312       0.000
## 5    0.6431    1.4264       0.000   0.9217   -1.1904   -1.6156       0.000
## 6   -1.0383    0.7079       0.000   0.7469   -0.3585   -1.6467       0.000
##   jet_4_pt jet_4_eta  jet_4_phi jet_4_b_tag   m_jj  m_jjj   m_lv  m_jlv
## 1   0.3987   -1.1389 -0.0008191       0.000 0.3022 0.8330 0.9857 0.9781
## 2   1.2570    1.1288  0.9004608       0.000 0.9098 1.1083 0.9857 0.9513
## 3   0.7453   -0.6784 -1.3603563       0.000 0.9467 1.0287 0.9987 0.7283
## 4   0.4800   -0.3736  0.1130406       0.000 0.7559 1.3611 0.9866 0.8381
## 5   0.6511   -0.6542 -1.2743449       3.102 0.8238 0.9382 0.9718 0.7892
## 6   0.3671    0.0695  1.3771303       3.102 0.8694 1.2221 1.0006 0.5450
##     m_bb  m_wbb m_wwbb
## 1 0.7797 0.9924 0.7983
## 2 0.8033 0.8659 0.7801
## 3 0.8692 1.0267 0.9579
## 4 1.1333 0.8722 0.8085
## 5 0.4306 0.9614 0.9578
## 6 0.6987 0.9773 0.8288
```
<BR><BR>
The next step is to build the looping mechanism to repeat this for each subsequent chunk and keep track of each chunk:
 

```r
index <- 0
chunkSize <- 100000
con <- file(description=transactFile,open="r")   
dataChunk <- read.table(con, nrows=chunkSize, header=T, fill=TRUE, sep=",")
         
repeat {
        index <- index + 1
        print(paste('Processing rows:', index * chunkSize))
 
        if (nrow(dataChunk) != chunkSize){
                print('Processed all files!')
                break}
       
        dataChunk <- read.table(con, nrows=chunkSize, skip=0, header=FALSE, fill = TRUE, sep=",")
        print(head(dataChunk))
        break
}
close(con)
```

```
## [1] "Processing rows: 100000"
##   V1     V2      V3      V4     V5       V6     V7      V8      V9   V10
## 1  1 0.7238 -0.9146  0.9109 1.1948 -0.44829 0.8395 -0.8714  0.5878 0.000
## 2  0 0.2822 -0.4130  0.1064 0.5119 -1.33140 1.1591 -1.0576  1.5801 1.087
## 3  0 1.6288  0.9291  0.2052 2.0936  0.07923 1.4937 -0.3219 -1.6858 2.173
## 4  1 1.9741  0.6603 -1.3624 1.2341  1.67772 1.4788  0.4089 -0.1053 0.000
## 5  0 0.4209 -0.4529  0.3383 0.4856 -0.51379 0.5136 -0.5189 -0.2322 2.173
## 6  1 0.9469  0.1694  1.2100 0.3433 -1.57955 0.9994  1.0308 -0.4750 0.000
##      V11      V12      V13   V14    V15      V16     V17   V18    V19
## 1 0.6544  1.15988 -0.72592 0.000 0.4220  1.63680 -0.8806 0.000 1.0340
## 2 1.0966 -1.61631 -0.34808 0.000 1.0557 -1.45258  0.2002 0.000 1.0082
## 3 1.0244  0.61105  1.57284 0.000 1.7970  0.61550 -0.4662 1.274 0.6991
## 4 1.0170 -0.12719  0.36331 2.215 0.9187  0.07208  1.1626 0.000 0.9615
## 5 0.8919  0.01852  1.65662 2.215 0.5904 -0.78992 -1.4586 0.000 0.6996
## 6 0.4354  0.05446 -0.08398 0.000 1.4650  0.61368  1.4927 2.548 1.1927
##       V20     V21   V22    V23    V24    V25    V26    V27    V28    V29
## 1 -0.7042 -0.9170 3.102 0.8671 1.1272 1.2117 0.6959 0.6941 0.7558 0.7617
## 2 -1.0215  1.0814 3.102 0.9061 0.7504 0.9942 1.6251 0.5069 1.1208 1.2031
## 3 -0.7059  1.3311 0.000 0.9216 0.9004 0.9633 0.9176 2.1077 1.5558 1.3126
## 4  0.6292  1.6041 3.102 1.9387 1.2339 0.9901 0.5249 0.9006 0.9176 1.0834
## 5 -1.8235  0.7967 0.000 0.8101 0.9102 0.9831 0.7197 1.0245 0.8279 0.7211
## 6  0.1903  0.5586 3.102 0.8816 0.8454 0.9974 0.6951 0.7871 0.6577 0.7211
```
<BR><BR>

If you need the column names, then you will have to reapply them after each loop.


```r
dataChunk <- read.table(con, nrows=chunkSize, skip=0, header=FALSE, fill = TRUE, col.names=higgs_colnames)
```

```
## Error: invalid connection
```
<BR><BR>
 
Now that you understand this chunking mechanism, lets see if we can get a total mean for a row from multiple chunks.


```r
index <- 0
chunkSize <- 100000
con <- file(description=transactFile,open="r")   
dataChunk <- read.table(con, nrows=chunkSize, header=T, fill=TRUE, sep=",", col.names=higgs_colnames)

counter <- 0
total_lepton_pT <- 0
repeat {
        index <- index + 1
        print(paste('Processing rows:', index * chunkSize))
        
        total_lepton_pT <- total_lepton_pT + sum(dataChunk$lepton_pT)
        counter <- counter + nrow(dataChunk)
 
        if (nrow(dataChunk) != chunkSize){
                print('Processed all files!')
                break}
        
        dataChunk <- read.table(con, nrows=chunkSize, skip=0, header=FALSE, fill = TRUE, sep=",", col.names=higgs_colnames)
        
        if (index > 3) break

}
close(con)
```
```
## [1] "Processing rows: 100000"
## [1] "Processing rows: 200000"
## [1] "Processing rows: 300000"
## [1] "Processing rows: 400000"
```

```r
print(paste0('lepton_pT mean: ',  total_lepton_pT / counter))
```
```
## [1] "lepton_pT mean: 0.992386268476397"
```
  
  
We broke out of the loop a little early but you get the point. This type of approach may not work for a real median, unless your live memory can hold the entire column of data at the very least. But anything that can be worked in chunks, like the above mean, can easily be extended into parallel or distributed systems.
 
I hope this helps.

<BR><BR>        
<a id="sourcecode">Full source code (<a href='https://github.com/amunategui/Read-and-Process-Files-Larger-Than-RAM' target='_blank'>also on GitHub</a>)</a>:

```r

options(scipen=999) # block scientific notation
print(paste((8*100*100000) / 2^20, 'megabytes'))

setwd('Enter Your Folder Path Here...')
download.file('http://archive.ics.uci.edu/ml/machine-learning-databases/00280/HIGGS.csv.gz', 'HIGGS.csv.gz')

print(paste(file.info('HIGGS.csv')$size  / 2^30, 'gigabytes'))

transactFile <- 'HIGGS.csv'
readLines(transactFile, n=1)

higgs_colnames <- c('label','lepton_pT','lepton_eta','lepton_phi','missing_energy_magnitude','missing_energy_phi','jet_1_pt','jet_1_eta','jet_1_phi','jet_1_b_tag','jet_2_pt','jet_2_eta','jet_2_phi','jet_2_b_tag','jet_3_pt','jet_3_eta','jet_3_phi','jet_3_b-tag','jet_4_pt','jet_4_eta','jet_4_phi','jet_4_b_tag','m_jj','m_jjj','m_lv','m_jlv','m_bb','m_wbb','m_wwbb')

transactFile <- 'HIGGS.csv'
chunkSize <- 100000
con <- file(description= transactFile, open="r")   
data <- read.table(con, nrows=chunkSize, header=T, fill=TRUE, sep=",")
close(con)
names(data) <- higgs_colnames
print(head(data))

index <- 0
chunkSize <- 100000
con <- file(description=transactFile,open="r")   
dataChunk <- read.table(con, nrows=chunkSize, header=T, fill=TRUE, sep=",")
         
repeat {
        index <- index + 1
        print(paste('Processing rows:', index * chunkSize))
 
        if (nrow(dataChunk) != chunkSize){
                print('Processed all files!')
                break}
       
        dataChunk <- read.table(con, nrows=chunkSize, skip=0, header=FALSE, fill = TRUE, sep=",")
        print(head(dataChunk))
        break
}
close(con)

dataChunk <- read.table(con, nrows=chunkSize, skip=0, header=FALSE, fill = TRUE, col.names=higgs_colnames)

index <- 0
chunkSize <- 100000
con <- file(description=transactFile,open="r")   
dataChunk <- read.table(con, nrows=chunkSize, header=T, fill=TRUE, sep=",", col.names=higgs_colnames)

counter <- 0
total_lepton_pT <- 0
repeat {
        index <- index + 1
        print(paste('Processing rows:', index * chunkSize))
        
        total_lepton_pT <- total_lepton_pT + sum(dataChunk$lepton_pT)
        counter <- counter + nrow(dataChunk)
 
        if (nrow(dataChunk) != chunkSize){
                print('Processed all files!')
                break}
        
        dataChunk <- read.table(con, nrows=chunkSize, skip=0, header=FALSE, fill = TRUE, sep=",", col.names=higgs_colnames)
        
        if (index > 3) break

}
close(con)

print(paste0('lepton_pT mean: ',  total_lepton_pT / counter))

```
<div class="row">   
    <div class="span9 column">
            <p class="pull-right">{% if page.previous.url %} <a href="{{page.previous.url}}" title="Previous Post: {{page.previous.title}}"><i class="icon-chevron-left"></i></a>   {% endif %}   {% if page.next.url %}    <a href="{{page.next.url}}" title="Next Post: {{page.next.title}}"><i class="icon-chevron-right"></i></a>   {% endif %} </p>  
    </div>
</div>
