---
layout: post
title:  "Satellite MongoDB Storage Filled Up!"
categories: satellite troubleshooting
---

So, after letting my automated release script cut new releases daily and weekly
promoting from the Library to Production for about 30 days or so, I found my
32GB ```/var/lib/mongodb``` partition full -- presumably because there was no
purging of older, unused content view versions.  I had worked up the theory in
my first post, but didn't actually test it or really give it any thought to
speeding up it's delivery.

However, it seems I must accelerate that mechanism...  after I repair my crippled
Satellite server...

Also, I would highly recommend you take a look at the
[How to manage paused tasks on Red Hat Satellite 6](https://access.redhat.com/solutions/2089951)
solution first.

Symptoms
--------

* Publish or promotion tasks of the
[cut-release.sh](/assets/satellite-6-release-automation/cut-release.sh)
never end, and instead spin apparently doing nothing
* A number of tasks in Foreman/Satellite that are running for long periods of
time without change in completion percentage.
* Pulp has a number of tasks seemingly stuck in _Waiting_ state
* Repository synchronizations fail or never complete

Cleanup and Restoration
-----------------------

* First, we need to stop Satellite 6, as gracefully as possible:

{% highlight none %}
# katello-service stop
{% endhighlight %}

* Now, we need to increase the size of the ```/var/lib/mongodb``` partition, I
just *KNOW* you made it a separate volume you can grow!  If not, you'll need to
create a new one and perform the appropriate data migration steps to move the
data to a new, more spacious location.

* After ensuring ```/var/lib/mongodb``` is remounted, permissions, ownership
and selinux labels are applied properly, we need to repair it (this might take
a while):

{% highlight none %}
# sudo -u mongodb mongod --repair --dbpath /var/lib/mongodb
{% endhighlight %}

* Let's start up PostgreSQL:

{% highlight none %}
# systemctl start postgresql
{% endhighlight %}

* Now, let's clean up the Foreman tasks directly in the PostgreSQL database
(WARNING: you could do this more selectively, following this will purge ALL tasks.
if you are concerned about audit trails of tasks, this is not your solution!):

{% highlight none %}
# su -s /bin/bash - postgres

-bash-4.2$ psql
psql (9.2.15)
Type "help" for help.

postgres=# \c foreman;
You are now connected to database "foreman" as user "postgres".
foreman=# delete from foreman_tasks_tasks;
DELETE 329
foreman=# delete from foreman_tasks_locks;
DELETE 6268
foreman=# \q
-bash-4.2$ exit
{% endhighlight %}

* Go ahead and stop PostgreSQL:

{% highlight none %}
# systemctl stop postgresql
{% endhighlight %}

* Bring Satellite 6 back up:

{% highlight none %}
# katello-service start
{% endhighlight %}

* If you haven't installed ```pulp-admin-client```, do so now:

{% highlight none %}
# yum -y install pulp-admin-client
{% endhighlight %}

* Configure auto-logins for pulp-admin:

{% highlight none %}
# cd ~
# mkdir .pulp
# cat \
  /etc/pki/katello/certs/pulp-client.crt \
  /etc/pki/katello/private/pulp-client.key \
  > ~/.pulp/user-cert.pem
{% endhighlight %}

* Get the status of Pulp:

{% highlight none %}
# pulp-admin status
+----------------------------------------------------------------------+
                          Status of the server
+----------------------------------------------------------------------+

Api Version:           2
Database Connection:
  Connected: True
Known Workers:
  _id:            scheduler@satellite.example.com
  _ns:            workers
  Last Heartbeat: 2016-11-15T20:53:10Z
  _id:            reserved_resource_worker-2@satellite.example.com
  _ns:            workers
  Last Heartbeat: 2016-11-15T20:54:15Z
  _id:            reserved_resource_worker-0@satellite.example.com
  _ns:            workers
  Last Heartbeat: 2016-11-15T20:54:16Z
  _id:            reserved_resource_worker-1@satellite.example.com
  _ns:            workers
  Last Heartbeat: 2016-11-15T20:54:16Z
  _id:            resource_manager@satellite.example.com
  _ns:            workers
  Last Heartbeat: 2016-11-15T20:54:16Z
  _id:            reserved_resource_worker-3@satellite.example.com
  _ns:            workers
  Last Heartbeat: 2016-11-15T20:54:16Z
Messaging Connection:
  Connected: True
Versions:
  Platform Version: 2.8.3.4
{% endhighlight %}

* Check if there are any pulp tasks stuck in _Waiting_ state:

{% highlight none %}
# pulp-admin tasks list
+----------------------------------------------------------------------+
                                 Tasks
+----------------------------------------------------------------------+

Operations:  sync
Resources:   Default_Organization-JBoss_Enterprise_Application_Platform-JBoss_Enterpr
             ise_Application_Platform_7_RHEL_7_Server_RPMs_x86_64_7Server
             (repository)
State:       Waiting
Start Time:  Unstarted
Finish Time: Incomplete
Task Id:     3274bbba-47f8-4ec4-a9bd-19ad55686411

Operations:  sync
Resources:   Default_Organization-Red_Hat_Enterprise_Linux_Server-Red_Hat_Satellite_T
             ools_6_2_for_RHEL_7_Server_RPMs_x86_64 (repository)
State:       Waiting
Start Time:  Unstarted
Finish Time: Incomplete
Task Id:     93495b75-9bcb-45e2-952d-267c253589de

Operations:  sync
Resources:   Default_Organization-Ansible_Tower-PostgreSQL_9_4_7Server_-_x86_64
             (repository)
State:       Waiting
Start Time:  Unstarted
Finish Time: Incomplete
Task Id:     a1104e9c-336b-437b-a66f-2ff492d62f5e

... <output trimmed>
{% endhighlight %}

* If there are tasks in _Waiting_ state, download and run the ```cancel-pulp-tasks.sh``` script:

{% highlight none %}
# wget https://gist.githubusercontent.com/snobear/16c42b19455ffe3ab83e/raw/d7fb397191da31006ca3475b5cbfd79d6c9cce10/cancel-pulp-tasks.sh
# chmod +x cancel-pulp-tasks.sh
# ./cancel-pulp-tasks.sh
Enter task state to kill, e.g. Waiting: Waiting

-- Dumping the full list of pulp server tasks to /tmp/tasks...
Task cancel is successfully initiated.

Task cancel is successfully initiated.

... <output trimmed>
{% endhighlight %}

* Now check to see if any pulp tasks remain:

{% highlight none %}
[root@satellite ~]# pulp-admin tasks list
+----------------------------------------------------------------------+
                                 Tasks
+----------------------------------------------------------------------+

No tasks found
{% endhighlight %}

At this point, you should have cleaned up / repaired your Satellite installation
and should probably go ahead and restart all Satellite services:

{% highlight none %}
# katello-service stop
# sleep 10
# katello-service start
{% endhighlight %}

You should now be back in business!  Now might be a good time to start cleaning
up old and unneeded content view versions...

References
----------
* [cut-release.sh script](/assets/satellite-6-release-automation/cut-release.sh)

* [How to manage paused tasks on Red Hat Satellite 6](https://access.redhat.com/solutions/2089951)
* [Foreman-dev thread: how to clear locked dynflow tasks?](https://groups.google.com/d/msg/foreman-dev/vkM3VhaXEOI/FGR8Pu1viwkJ)
* [Pulp-list thread: Unstarted tasks?](https://www.redhat.com/archives/pulp-list/2015-May/msg00074.html)
* [Cancel Pulp tasks script](https://gist.github.com/snobear/16c42b19455ffe3ab83e)

* [Red Hat Satellite 6](https://access.redhat.com/products/red-hat-satellite)
* [The Foreman](https://theforeman.org/)
* [Katello](http://www.katello.org/)
* [Pulp](http://pulpproject.org/)
