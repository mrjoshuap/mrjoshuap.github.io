---
layout: post
title:  "Satellite 6 Release Automation: Part 1"
categories: satellite
---

After a heated discussion regarding the use of Red Hat Satellite 5 (aka the
upstream project [Spacewalk](https://fedorahosted.org/spacewalk/)) versus Red
Hat Satellite 6 (aka the plethora of upstream projects, namely
[Foreman](https://theforeman.org/), [Katello](http://www.katello.org/),
[Pulp](http://pulpproject.org/)), I decided it was time to record my thoughts
for posterities sake.  For brevity, I will base this on a few simple truths:

1. they are two different products.
1. they are two TOTALLY different products.
1. different tools do things, wait for it, ... differently.

So you might be asking yourself, where did this conversation start?  Well, the
short answer is that with time running out on Satellite 5, now might be the time
to start planning a [transition to Satellite 6](https://access.redhat.com/articles/1187643).

Like many heated conversations (for example, do a quick
[Google Search of systemd hate](https://www.google.com/#q=systemd+hate)), this
one was full of passion and a whole selection of three to five letter words.
However, at the end of the day, technology moves forward, and many of the
arguments made actually smelled of the "fear of change".

My environment is fairly simple and I have the following content views:

* RHEL6_Base
* RHEL7_Ansible_Tower
* RHEL7_Base
* RHEL7_CloudForms
* RHEL7_OpenShift_Server
* RHEL7_Satellite
* RHEL7_Virtualization_Host
* RHEL7_Virtualization_Manager

They must traverse the following lifecycle environments:

* Library
* Production

I keep my lifecycle environments simple, and assign development systems to the
Library and production systems to the Production lifecycles.  Knowing this, I
run a script that will publish the sync'd content to a new version in the
Library lifecycle environment.  After that completes, I then publish the new
versions from the Library to the Production lifecycle.

cut-release.sh
--------------

Obviously, there is not a direct replacement of the channel cloning methods,
such as clone-by-date, that were present in Satellite 5. Since my process is
fairly simple and I wanted to automate it, I decided to work on a small script
that would utilize the Hammer CLI to promote content views through lifecycles.

You can download the [cut-release.sh script here](/assets/satellite-6-release-automation/cut-release.sh).

You will need to install hammer before running the script and then login or
configure hammer through the use of the
[cli_config.yml](https://theforeman.org/2013/11/hammer-cli-for-foreman-part-i-setup.html) for any of this to work.

I did manage to slap in a usage page for some help:

{% highlight none %}
cut-release.sh -- simple content view management for Satellite 6

Usage:

  cut-release.sh [options]

Options:
        -d                  Enable debugging to see WTF is happening
        -f [lifecycle]      When promoting content views, this is the FROM lifecycle
        -h, --help          Show this message
        -o [organization]   (required) Specify the Satellite 6 organization
        -p                  Publish new content views to the Library
        -P                  Promote content view versions to a lifecycle
                            You must specify the -f and -t options to promote
        -t [lifecycle]      When promoting content views, this is the TO lifecycle
        -x [number]         Keep num of versions older than the PURGE lifecycle
        -X [lifecycle]      Purge versions older than the one assigned to PURGE lifecycle

Environment Variables:

Options can also be specified as environment variables instead, making
integration with CI/CD tools such as Jenkins easier.

        DEBUG              true/false
        ORG                "Default_Organization"
        PUBLISH_VERSION    true/false
        PROMOTE_VERSION    true/false
          FROM_LIFECYCLE   "From_Lifecycle"
          TO_LIFECYCLE     "To_Lifecycle"
        PURGE_VERSIONS     true/false
          PURGE_LIFECYCLE  "Purge_Lifecycle"
          PURGE_KEEP_EXTRA 0

Examples:

  To publish a new version of all content views to the "Library" lifecycle
  environment:

    # cut-release.sh -o "Default_Organization" -p

  To promote the version of all content views in the "Library" lifecyle to
  the "Development" lifecycle environment:

    # cut-release.sh -o "Default_Organization" -P -f "Library" -t "Development"

  To publish a new version of all content views to the "Library" lifecycle and
  immediately promote to the "Development" lifecycle environment:

    # cut-release.sh -o "Default_Organization" -p -P -f "Library" -t "Development"

  To purge all versions of all content views older than the "Production" lifecycle:

    # cut-release.sh -o "Default_Organization" -X "Development"

  To purge all but the latest 3 versions of all content views older than
  the "Production" lifecycle:

    # cut-release.sh -o "Default_Organization" -X "Development" -x 3
{% endhighlight %}

Stay Tuned
----------

For my next trick, we'll look at taking the above and automating it with
Jenkins -- and the teaser below shows what I'm thinking.

![Satellite 6 Release Automation with Jenkins](/assets/satellite-6-release-automation/satellite-6-release-automation.png)

References
----------
* [cut-release.sh script](/assets/satellite-6-release-automation/cut-release.sh)

* [Red Hat Satellite 5](https://access.redhat.com/documentation/en/red-hat-satellite/5.7/?version=5.7)
* [Spacewalk](https://fedorahosted.org/spacewalk/)

* [Red Hat Satellite 6](https://access.redhat.com/products/red-hat-satellite)
* [The Foreman](https://theforeman.org/)
* [Katello](http://www.katello.org/)
* [Pulp](http://pulpproject.org/)
