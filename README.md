# lcd - Locate Change Dir

Program that uses the "locate" command and some cleverness, to find the directory the user wants to "cd" to. Simply search by running the command with one or more (ordered) string arguments to look for in the path.

Examples
--------

Chdir to Downloads inside users home dir

    $ lcd hom Down

Or if we just specify "Do" we hit Documents 

    $ lcd Do
    /home/dan/Documents

Everytime you re-run the command, it'll pick the next likely candidate, based on current-dir:

    $ lcd Do
    /home/dan/Downloads




Prerequisites
-------------

You need perl, which is usually on most Linux's & Unix's by default.

You need to have locate. This is also somewhat default. "updatedb" must have been run at least once. Check your "locate" installation by running "locate home/|head". Either you get path names or you get an error. If missing, then you must install it. For debian/ubuntu you would do:

    $ sudo apt-get install mlocate
    $ sudo updatedb

Let updatedb run to completion (can take a minute or two).

Installation
------------


Place the program somewhere. Eg. /opt/LocateChdir/. Then add this to your shells environment.

    lcd () { eval "`/opt/LocateChdir/lcd.pl $*`";}


This can be put in eg. ~/.bashrc. On Ubuntu it makes sense to put it in ~/.bash_aliases, if you like. Then restart your shell start lcd'ing.


Troubleshooting
----------------

### lcd to a newly created directory, doesnt work.
 lcd uses `locate` - remember to run `updatedb`, or locate wont know about your new directory.


Notes about the search algorithm
------------------

 * Lowercase search string = case-insensitive search. 
 * Dirs inaccessable to user, is filtered out. (otherwise she would just get an access denied error)
 * Shortest paths are visisted first, unless a "boosted" result supersedes it.
 * Boosts includes:
     * Users home directory. "lcd Documents" will go to users own /home/user/Documents, before it will go to /home/another_user/Documents.
     * Hidden directories (dirs starting with a dot) gets downvoted slightly.
     * Last directory. "lcd apache2" will rather go to "/etc/apache2/ than to "/apache2/etc" because LAST dir matches searchstring best.
     * If last directory perfectly matches search string, it will massively boost this result. Eg. "lcd Go" will rather go to "/home/user/development/Go/" than
       "/home/user/GoLang_docs/"


TODO / Ideas
------------

lcd could be sped up by exporting the "locate" data into a our own database, keeping only directories. This should massively reduce the size of the data to search
each time. Then we could check the timestamp of the locatedb and see if it was time to repopulate our own.

Another option could be to simply cache results, since users likely jump between a fixed set of dirs, most of the time. Again we could check timestamp of locatedb to expire cache.

License
-------

GPL 3.0 or any later version of GPL.

Copyright 2016 - Dan Faerch

