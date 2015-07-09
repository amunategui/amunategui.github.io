---
layout: post
title: "R and Excel: Making Your Data Dumps Pretty with library XLConnect" 
category: Machine Learning
tags: exploring r
year: 2015
month: 07
day: 07
published: true
summary: "When it comes to exporting data, one has many formats to choose from \. But if you wantyou're looking for something a little more sophisticated than a comma-delimited file but not quite a content-management system or web server, the Excel format can go a long way into making exports more digestible."
image: excel-data-dumps/RandExcel.png
---
 
**Resources**
<ul>
<li type="square"><a href="" target='_blank'>YouTube Companion Video</a></li>
<li type="square"><a href="#sourcecode">Source Code</a></li>
</ul>
<BR>
**Packages Used in this Walkthrough**
<ul>
        <li type="square"><a href='http://cran.r-project.org/web/packages/XLConnect/index.html' targer='_blank'>{XLConnect}</a>Excel Connector for R</li>
</ul>
<BR>
<BR>
When it comes to sharing data, results, probabilities, one has many choices in terms of delivering tool. On one end of the spectrum you have raw text files, and on the other, you have reporting engines and content management systems.  

As a data scientist, I get away with working and sharing comma delimited files (.csv) everyday, but there are times when customers need more. Excel is a great tool as everybody in analytics is familiar with it and it can do some pretty cool things inexpensively. 

Instead of saving your data as a ``.csv`` or ``.tab`` file, you can leverage the ``.xlsx`` (native Excel format) just as easily and make a huge leap towards fantastic looking reports. 

Here I’ll show how to get a good looking data sheet exported into Excel.

***Case 1: Conditional formatting***
The key here is to prepare the Excel file in advance and use it as a base from R. So go to your Excel application and open a new document. Make the top bar frozen. Go to Layout tab —> Window —> Freeze Top Row (may be different depending on your application version and operating system):
<BR><BR>
<p style="text-align:center"><img src="../img/posts/excel-data-dumps/freeze-top-row.png" alt="free-top-row" style='padding:1px; border:1px solid #021a40;'></p>
To emphasis the difference between a straight ``.csv`` write, in the Home tab, and Font box, bold all the top row, select a dark background color and white font.
<BR><BR>
<p style="text-align:center"><img src="../img/posts/excel-data-dumps/font.png" alt="free-top-row" style='padding:1px; border:1px solid #021a40;'></p>

Now, let’s add some conditional formatting. Go to Home tab —> Format —> Conditional Formatting and select New Rule:
<p style="text-align:center"><img src="../img/posts/excel-data-dumps/free-top-row.png" alt="free-top-row" style='padding:1px; border:1px solid #021a40;'></p>

Select ‘Classic’ and the following options on the Mac, or ‘Use a formula to determine which cells to format’ on Windows:

mac-format-rule.png

In Windows:

windows-format-rule.png

Finally, make the rule apply to the entire row by adding in the Applies to section Sheet1!$2:$200

manage-rule.png

Don’t sweat the details as this isn’t a walkthrough about Excel, we’re just setting up our base file.

Save the file as ‘sample.xlsx’ and close the file.
 
**Jump into R**

Let’s create some data:
```r
income_data <- data.frame('FirstName'=c('Joe','Mike','Liv'), 'LastName'=c('Smith','Steel','Storm'), 'Income'=c(100000,20000,80000))
```

Here is the Excel part:

```r
library(XLConnect)
wb <- loadWorkbook('sample2.xlsx')
lst = readWorksheet(wb, sheet = getSheets(wb)[1])
for (id in 1:nrow(income_data)) {
	colcount <- 1
	for (nm in names(lst)[1:3]){
		lst[id,nm] <- income_data[id,colcount]
		colcount <- colcount + 1
	}
}

sheet_name <- "Salaries"
renameSheet(wb, sheet = getSheets(wb)[1], newName = sheet_name)
writeWorksheet(wb,lst,sheet=getSheets(wb)[1],startRow=2,header=F)
saveWorkbook(wb,'income_data.xlsx')
```
***Case 2: Hidden fields and drop down cells***





<BR><BR>        
<a id="sourcecode">Full source code (<a href='https://github.com/amunategui/SMOTE-Oversample-Rare-Events' target='_blank'>also on GitHub</a>)</a>:



```r
 
```

 