---
layout: post
title: Brief Guide On Running RStudio Server On Amazon Web Services
category: Machine Learning
tags: rstudioserver
year: 2014
month: 5
day: 15
published: true
summary: Steps you through installing pre-configured AMIs with RStudio Server on AWS EC2, interacting with the web interface, and uploading and downloading files to/from the instance.
image: rstudioserver/runninginstance.png
---

<i><B>YouTube Companion Video:</B> <a href="https://www.youtube.com/watch?v=NQu3ugUkYTk&list=UUq4pm1i_VZqxKVVOz5qRBIA" target="_blank">Brief guide on running RStudio Server's web interface on Amazon Web Services</a></i>
<BR><BR><BR>
**Getting There**

There are a lot of great resources on the web, but I didn't find one that covered my needs from end to end, and figured others could benefit from a walkthrough.  Here, I'll show how to select, install and run RStudio Server, customize security settings to use the RStudio's web interface, and upload and download data between your local machine and the server.

If you like Kaggle competitions, like I do, then this is a great way of quickly adding all sorts of computing configurations to satiate your needs. Our first stop is at <a href="http://www.louisaslett.com/RStudio_AMI/" target="_blank">Louis Aslet's web page</a>. Louis curates a series of Amazon Machine Images (referred as AMIs):

<p align="center"><img src='../img/posts/rstudioserver/amilist.png'></p>
<BR><BR>
These are pre-configured images that will install RStudio and common R packages onto a computing instance. This is a huge time and money saver as it automatically installs a whole slew of software under two minutes - and when you're charged by the minute, every minute counts.    

Louis also has a video, albeit short, on how to setup RStudio and lots of additional resources. So explore them if you have unanswered questions. 
We're interested in the upper right-hand box where you need to select the AMI closest to your location and click on it. This will take you to the Amazon Web Services page. If you do not have an AWS account, it will prompt you to set one up:

<p align="center"><img src='../img/posts/rstudioserver/amzlogin.png'></p> 
<BR><BR>
Otherwise it will take you to **Step 2**. This is the fun part. Its like going to the store and picking up a brand new computer. Here you get to choose how much computing muscle you want. The AMI image you selected earlier will get applied to whatever setup you choose. You can go for more GPU, memory, storage, etc. Unfortunately, throwing more memory at a problem is not a guarantee to make it go away - and I'm talking from personal experience here.

<p align="center"><img src='../img/posts/rstudioserver/instance.png'></p> 
<BR><BR>
I recommend starting small as it is easy to upgrade an existing instance to something bigger.

**Security**

You need to have two open ports and a key-pair to communicate with your instance. 
``Port 22`` should be opened by default and you'll need to add ``port 80``.

``Port 22`` is used to connect a command line terminal tool using SSH. I will not be showing that today. Instead, we'll be using ``port 80`` which allows access to the web interface of RStudio. So add another rule, choose ``HTTP``, enter the value **80**, and leave the rest as is:

<p align="center"><img src='../img/posts/rstudioserver/security.png'/></p> 
<BR><BR>
After you hit <B>Launch</B>, a key-pair pop-up box will appear. This is what authenticates your computer's identity and allows you to communicate securely to your AWS instance. If this is your first time using EC2 you'll want to create and download a new key pair:

<p align="center"><img src='../img/posts/rstudioserver/key.png'/></p> 
<BR><BR>
**View Instance**

After launching your instance, once the <B>instance state</B> goes from ``initializing`` to ``running``, the public DNS string is the official link to your instance's RStudio web interface:

<p align="center"><img src='../img/posts/rstudioserver/runninginstance.png'/></p>

<li>Remember where you save this key-pair as you cannot communicate to your instance without it.</li>
<li>If security is a big concern, there are plenty of additional settings and customizations available, please refer to the online RStudio server and Amazon EC2 help files regarding your options.</li>

Once your instance is running (green light), click on it, copy the Public DNS URL and paste it in your browser:

<p align="center"><img src='../img/posts/rstudioserver/url.png'/></p>
<BR><BR>
**Using RStudio Server**

You will be prompted for your credentials. By default, the initial **account** and **password** for these AMIs is ``rstudio``, ``rstudio``, all lower case:

<p align="center"><img src='../img/posts/rstudioserver/rstudiologin.png'/></p>
<BR><BR>
Once in RStudio, the first thing you should do is run the present script to change the password (minimum length required is 8 characters).  Replace the **mypassword** with your new password and hit the ``run`` script button. Then log out and back in with the new password:

<p align="center"><img src='../img/posts/rstudioserver/changepassword.png'/></p>
<BR><BR>
**Uploading and Downloading Files**

The last part that I want to cover is how to upload and download files to your server instance.

**Uploading Files (i.e. bringing file from your local machine to EC2 Instance):**

<ul><li>Switch to the <B>Files</B> pane</li>
<li>Navigate to the directory you wish to upload files into</li>
<li>Click the <B>Upload</B> toolbar button. A menu box will open and select the file you want to upload</li>
<li>Choose the file you wish to upload and press <B>OK</B></li></ul>
<B>Note:</B> that if you wish to upload several files or even an entire folder, you should first compress your files or folder into a zip file and then upload the zip file (when RStudio receives an uploaded zip file it automatically uncompresses it).

<p align="center"><img src='../img/posts/rstudioserver/upload.png'/></p>
<BR><BR>
**Downloading Files (i.e. exporting files from EC2 to your local server):**

<ul><li>Switch to directory you want to download files from within the <B>Files</B> pane</li>
<li>Select the file(s) and/or folder(s) you want to download</li>
<li>Click <B>More</B> and <B>Export</B> on the toolbar</li>
<li>You'll then be prompted with a default file name for the download. Either accept the default or specify a custom name then press <B>OK</B></li></ul>

<p align="center"><img src='../img/posts/rstudioserver/download.png'/></p>
<BR><BR>
**Important**
Don't forget to shut down the server or terminate it to remove it completely - otherwise the meter will keep running and you will keep being charged!

**Additional Resources (PDFs)**

<a href="https://s3.amazonaws.com/rstudio-server/rstudio-server-pro-0.98.501-admin-guide.pdf" target="_blank">RStudio Server Administrator's Guide</a>

<a href="http://www-personal.umich.edu/~agong/docs/Using%20RStudio%20on%20Amazon%20EC2%20under%20the%20Free%20Usage%20Tier.pdf" target="_blank">Using RStudio on Amazon EC2 under the Free Usage Tier</a>


<div class="row">   
    <div class="span9 column">
            <p class="pull-right">{% if page.previous.url %} <a href="{{page.previous.url}}" title="Previous Post: {{page.previous.title}}"><i class="icon-chevron-left"></i></a>   {% endif %}   {% if page.next.url %}    <a href="{{page.next.url}}" title="Next Post: {{page.next.title}}"><i class="icon-chevron-right"></i></a>   {% endif %} </p>  
    </div>
</div>

<div class="row">   
    <div class="span9 columns">    
        <h2>Comments Section</h2>
        <p>Feel free to comment on the post but keep it clean and on topic.</p> 
        <div id="disqus_thread"></div>
        <script type="text/javascript">
            /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
            var disqus_shortname = 'amunategui'; // required: replace example with your forum shortname
            var disqus_identifier = '{{ page.url }}';
            var disqus_url = 'http://amunategui.github.com{{ page.url }}';
            
            /* * * DON'T EDIT BELOW THIS LINE * * */
            (function() {
                var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
                (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
            })();
        </script>
        <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
        <a href="http://disqus.com" class="dsq-brlink">blog comments powered by <span class="logo-disqus">Disqus</span></a>
    </div>
</div>

