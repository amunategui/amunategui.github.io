<p style="text-align:center">
<img src="../img/posts/all-hacker-news/big-data-surveillance.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 75%; height: 75%'>
</p>
<br><br>

Hacker News is a fascinating site with a constant flow of news, current
events, general-interest articles vetted and posted by users and
commented on, liberally, by users as well. Hacker News is transparent
about its data and offers different ways of accessing it without
complicated hoops to go through or authentication schemes. Here we will
look at two ways of doing it. The first is to download all of it to a
PostgreSQL database using scripts from
<a href='https://github.com/minimaxir/get-all-hacker-news-submissions-comments' target='_blank'>Max
Woolf Github's repository</a> and the second is through the official
Hacker News
<a href='https://github.com/HackerNews/API' target='_blank'>web-service
API</a>. <BR><BR> ***Downloading Everything to PostgreSQL on EC2***

The first way offers a relatively easy way of getting all of it in one
call.
<a href='https://github.com/minimaxir/get-all-hacker-news-submissions-comments' target='_blank'>Max
Woolf Github's repository</a> offers two scripts, one for comments and
the other for news stories that calls the
<a href=' https://hn.algolia.com/api' target='_blank'>Algolia API</a>
and stores them in PostgreSQL. We’ll only look at comments but the same
concept applies with his news stories script. He also offers basic SQL
queries for aggregate analysis of the data.

The twist is that we’ll use an Amazon EC2 instance to do the downloading
and PostgreSQL storing. There is a good reason we’re doing it that way,
just the comments take over 10 hours to download and process. I only
have a notebook computer and I don’t want to wait that long nor is my
internet connection as good as an EC2’s. We can get away with a small
EC2. We need to install PostgreSQL, a few python libraries and we’re
ready to go.

We'll call the python script on a background process so we can close the
EC2 terminal/Putty. <BR><BR> ***Getting Our EC2 Instance
Up-and-Running***

Log into <a href='https://aws.amazon.com/' target='_blank'>Amazon Web
Serivces</a>, click the orange cube in the upper left corner:

<BR>
<p style="text-align:center">
<img src="../img/posts/all-hacker-news/E0A7CD38-D472-49D3-826F-C2502583A887.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<br><br>

**VPC** Click `VPC`:
<p style="text-align:center">
<img src="../img/posts/all-hacker-news/86DFA8C3-C9DC-4689-A267-65A2B439EEA9.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<br><br>

Click `Start VPC Wizard`:
<p style="text-align:center">
<img src="../img/posts/all-hacker-news/B352BF31-D152-42D5-8354-AE43DD094270.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> The defaults are fine so click `Select`:
<p style="text-align:center">
<img src="../img/posts/all-hacker-news/8F3F6B8B-9A4A-448A-93B6-5F76E0F3ABF6.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> Enter a `VPC` name and choose an availability zone. Finally, in
the bottom right, click `Create VPC`:
<p style="text-align:center">
<img src="../img/posts/all-hacker-news/AF9B540F-85C5-4233-BD3B-BFED1DC55C60.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> **EC2**

Now let's set up our EC2 instance. Click the orange cube in the upper
left corner and select `EC2`:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/590CF6BC-DE31-4592-8BB2-C9E7DBE3CBE2.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> Choose `Launch Instance`:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/04201D14-7614-4AD4-AD91-B302830C68F9.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> In `Step 1: Choose an Amazon Machine Image (AMI)` choose the
default instance:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/4D040E08-DEBD-4136-8431-80E74A70F45D.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> In `Step 3: Configure Instance Details` select the correct
`VPC` Network we just created, and enable `Auto-assign Public IP`:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/B1E1172B-AC08-4DB3-A5EB-37397764CB69.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> Click the `Review and Lauch` button then the `Launch` button.
It will ask you to create a new key pair. It is a security file that
will live on your machine and is required to SSH into the instance. I
tend to create them and leave them in my downloads. Whatever you decided
to do, make sure you know where it is as you’ll need to pass a path to
it every time you want to connect to your instance. Create a new one,
check the acknowledgment box and download it to your local machine.
<p style="text-align:center">
<img src="../img/posts/all-hacker-news/4C01F64F-6F80-4CFC-8453-3CC1D10BB566.png" alt="AWS" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> ***Connect to your EC2 Instance***

Click the `View Instance` button or click the upper-left orange cube and
then `EC2`. There you should see your instance either running or
initializing.

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/ec2_instance.png" alt="EC2" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
**Window Users**

If you're using windows, download
<a href='http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html' target='_blank'>PuTTYgen
and PuTTY</a>.

Run `PuTTYgen`. Select load and choose your .pem file that you just
downloaded.

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/59547025-1BEB-43DE-9223-BF1F019556EA.png" alt="PuTTY" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
Save private key, in my case: `hknews.ppk` and remember its path.

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/6A26E032-CED7-4806-9E23-EEF4FCA2C1D2.png" alt="PuTTY" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
Now run `PuTTY`, and enter your instance public DNS in Host Name (in my
case: <ec2-user@ec2-54-246-27-243.eu-west-1.compute.amazonaws.com>) and
name you session hknews and hit save:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/39E08BA4-B25D-49C9-8C85-C5167456B49F.png" alt="PuTTY" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> Finally enter the .ppk file and path we created using PuTTYgen
under `SSH-Auth`:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/EFFA743F-59EB-450A-BA3F-EA3758DBBAEF.png" alt="PuTTY" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> Click `Open` and you will connect to your instance. <BR><BR>
**Mac/Linux Users**

In the AWS web console window, select your instance (checkbox on left of
description) and click the ‘Connect’ button and copy the example line.
Copy the example line:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/7204F62A-1F85-4FC5-AD88-C2FC2710B0FE.png" alt="Terminal" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> Open a terminal window, navigate to the same folder where you
have your saved .pem file and paste the example ssh connection line:

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/91E7B625-B0E4-479F-B431-DE1FE373A915.png" alt="Terminal" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<BR><BR> That's it, you're now connected to your instance! <BR><BR>
***Loading Software on our Instance***

Whether you're connected using PuTTY or the terminal window, the rest of
the steps should be indentical.

Install PostgreSQL:

    sudo yum install postgresql postgresql-server postgresql-devel postgresql-contrib postgresql-docs

Initialize and start PostgreSQL database:

    sudo service postgresql initdb
    sudo service postgresql start

Set the `postgres` user password. Remember what you choose as you'll
need it through out this project.

    sudo passwd postgres 

Log into the database:

    sudo su - postgres
    psql -U postgres

Create our `hacker-news` database:

    CREATE DATABASE hacker_news WITH OWNER postgres;

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/7A27A2AF-3A29-473F-9A8C-BF4F27C0DD1C.png" alt="PostgreSQL" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
Connect to the `hacker_news` database:

    \c hacker_news

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/F720860E-F538-40A9-8D57-83ED7C27FD5C.png" alt="PostgreSQL" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
Run a test `INSERT` statement to verify that things are working. We'll
create a simple table named `ListOfNames`

    CREATE TABLE ListOfNames (first_name varchar(40), last_name varchar(40),  age int );

Now let's run the `\dt` command to list all avaiable tables in our
`hacker_news` database:

    \dt

One final test, let's insert a few names... myself and Bill Gates:

    INSERT INTO ListOfNames (first_name, last_name, age) VALUES ('Manuel', 'Amunategui', 48), ('Bill', 'Gates', 60);
    SELECT * FROM ListOfNames;

The `\q` command will get us out of PostgreSQL and `exit` will log us
back to the default `ec2-user` account:

    \q
    exit

We need to change the database access permissions in order to write to
it from our Python script. Edit the `pg_hba.conf` file:

    sudo vim /var/lib/pgsql9/data/pg_hba.conf

Around the end of the file (line 80), edit the following line so it says
`trust` instead of `peer`:

    local   all             all                                     trust

Restart the PostgreSQL database:

    sudo service postgresql restart

In order to 'edit' in `vim` you need to hit the `i` key to get in insert
mode. Make the edit then hit the escape key followed by colon and wq.
The colon gets you out of insert mode and `w` calls for saving your
changes and `q` to quit out of vim.

ESC : wq

Now let's add the needed Python libraries:

    sudo pip install pytz
    sudo yum -y install python-devel
    sudo yum -y install python-psycopg2
    sudo yum -y install libevent-devel
    sudo yum -y install gcc-c++
    sudo pip install psycopg2

<BR><BR> **Python Script**

We're going to make a few changes to Max Woolf's script
<a href='https://github.com/minimaxir/get-all-hacker-news-submissions-comments/blob/master/hacker_news_comments_all.py' target='_blank'>hacker\_news\_comments\_all.py</a>.
Because the script takes over 10 hours to collect all of Hacker News
comments, we need to remove all `print` statemetns so that it can run in
an unattended, background fashion.

So, open a vim window with the following command:

    sudo vim get-all-hacker-news-comments-background.py

Enter `insert` mode by hitting the escape key followed by `i` and paste
the following code in vim:

    ###
    import urllib2
    import json
    import datetime
    import time
    import pytz
    import psycopg2
    import re
    import HTMLParser

    ###
    ### Define database parameters here
    ###

    dbname = "hacker_news"
    user = "postgres"
    password = "testing" # swap with whatever password you used 

    # Set up database connection settings and other parameters

    ts = str(int(time.time()))
    hitsPerPage = 1000
    tag = re.compile(r'<[^>]+>')
    h = HTMLParser.HTMLParser()
    conn_string = "dbname=%s user=%s password=%s" % (dbname, user, password)
    db = psycopg2.connect(conn_string)
    cur = db.cursor()

    # Set up HN comment database table schema
    cur.execute("DROP TABLE IF EXISTS hn_comments;")
    cur.execute("CREATE TABLE hn_comments (objectID int PRIMARY KEY, story_id int, parent_id int, comment_text varchar, num_points int, author varchar, created_at timestamp);")

    num_processed = 0

    while True:
        try:
            # Retrieve HN comments from the Algolia API; finds all comments before timestamp of last known submission time
            url = 'https://hn.algolia.com/api/v1/search_by_date?tags=comment&hitsPerPage=%s&numericFilters=created_at_i<%s' % (hitsPerPage, ts)
            req = urllib2.Request(url)
            response = urllib2.urlopen(req)

            data = json.loads(response.read())
            comments = data['hits']
            ts = comments[-1 + len(comments)]['created_at_i']

            for comment in comments:

                # if a comment does *not* have a parent_id key, it's definitely [dead] and should not be recorded
                if 'parent_id' in comment.keys():

                    # make sure we remove smartquotes/HTML tags/other unicode from comment text
                    comment_text = tag.sub(' ', h.unescape(comment['comment_text'])).translate(dict.fromkeys([0x201c, 0x201d, 0x2011, 0x2013, 0x2014, 0x2018, 0x2019, 0x2026, 0x2032])).encode('utf-8')

                    # EST timestamp since USA activity reflects majority of HN activity
                    created_at = datetime.datetime.fromtimestamp(int(comment['created_at_i']), tz=pytz.timezone('America/New_York')).strftime('%Y-%m-%d %H:%M:%S')

                    parent_id = None if comment['parent_id'] is None else int(comment['parent_id'])
                    story_id = None if comment['story_id'] is None else int(comment['story_id'])

                    SQL = "INSERT INTO hn_comments (objectID, story_id, parent_id, comment_text, num_points, author, created_at) VALUES (%s,%s,%s,%s,%s,%s,%s)"
                    insert_data = (int(comment['objectID']), story_id, parent_id, comment_text, comment['points'], comment['author'], created_at,)

                    try:
                        cur.execute(SQL, insert_data)
                        db.commit()

                    except Exception, e:
                        # print insert_data
                        # print e
                        continue

            # If there are no more HN comments, we're done!
            if (data["nbHits"] < hitsPerPage):
                break

            num_processed += hitsPerPage

            # make sure we stay within API limits
            time.sleep(3600/10000)

        except Exception, e:
            # print e
            continue

    # Create sensible indices and vacuum the inserted data
    cur.execute('CREATE UNIQUE INDEX objectID_commentx ON hn_comments (objectID);')
    cur.execute('CREATE INDEX created_at_commentx ON hn_comments (created_at);')
    cur.execute('CREATE INDEX story_id_commentx ON hn_comments (story_id);')
    db.commit()

    db.set_isolation_level(0)
    cur.execute('VACUUM ANALYZE hn_comments;')
    db.close()

Save your script by hitting the escape key, followed by `:wq`:

You can also check that your script is working:

    python get-all-hacker-news-comments-background.py

Let it run for a short while and hit `ctrl-c` to break out of it. Then
go to PostgreSQL to verify that your table and some data did indeed get
written to the `hn_comments` table:

    sudo su - postgres
    psql -U postgres
    \c hacker_news
    \dt

<p style="text-align:center">
<img src="../img/posts/all-hacker-news/DC4E633C-14A3-4B3B-8C39-B31A554E4806.png" alt="hacker_news" style='padding:1px; border:1px solid #021a40; width: 50%; height: 50%'>
</p>
<br><br>

If you see both tables, then things are looking good. Let's take a peek
at some of the comments:

    SELECT count(*) FROM hn_comments;
    SELECT comment_text FROM hn_comments limit 1;
    \q
    exit

**Running the Script in Background Mode** Now that we confirmed
everything is working, let's fire up the script on a background process
so that we can safely close the PuTTY/Terminal window:

    nohup python get-all-hacker-news-comments-background.py &

Before closing the terminal window (you can leave it open if you want),
let's make sure we're getting collecting data:

    sudo su - postgres
    psql -U postgres
    \c hacker_news
    SELECT count(*) FROM hn_comments;

<BR><BR> <BR><BR> <BR><BR>
