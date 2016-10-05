---
layout: post
title:  "Satellite 6 Release Automation"
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
[Google Search of systemd hate](https://www.google.com/#q=systemd+hate)), this one
was full of passion and a while selection of three to five letter words.  However,
at the end of the day, technology moves forward, and many of the arguments made
were actually the "fear of change".

{% highlight bash %}
#!/bin/bash

ORG=${ORG:?Organization is required!}

###
### You should not have to modify anything below here
###

TODAY=$(date +%Y-%m-%d)

CONTENT_VIEWS=$(hammer --output=csv content-view list \
                --organization="${ORG}" | tail -n +2)

O_IFS=$IFS
IFS=$'\n'

for CV in ${CONTENT_VIEWS}; do
  CV_ID=$(echo ${CV} | cut -d , -f 1)
  CV_NAME=$(echo ${CV} | cut -d , -f 2)

  if [ ${CV_ID} -eq 1 ]; then
    echo "Skipping [${CV_NAME}] with id ${CV_ID}"
    continue
  fi

  if [ "${PUBLISH_VERSION}" = "true" ]; then
    echo "Publishing a new version of content view \
      [${CV_NAME}] with id ${CV_ID}"
    hammer content-view publish \
      --organization="${ORG}" \
      --id=${CV_ID} \
      --description="Publishing new version on ${TODAY} - see ${BUILD_URL}"
  fi

  # If we specified the to/from lifecycle environments
  if [ "${PROMOTE_VERSION}" = "true" ]; then
    FROM_LIFECYCLE=${FROM_LIFECYCLE:?FROM_LIFECYCLE is required!}
    TO_LIFECYCLE=${TO_LIFECYCLE:?TO_LIFECYCLE is required!}

    CV_VERSION=$(hammer --output=csv content-view version list \
                --organization="${ORG}" \
                --environment="${FROM_LIFECYCLE}" \
                --content-view-id=${CV_ID} \
                | tail -n +2 | head -n 1)

    CV_VERSION_ID=$(echo ${CV_VERSION} | cut -d , -f 1)
    CV_VERSION_NAME=$(echo ${CV_VERSION} | cut -d , -f 2)

    echo "Promoting [${CV_VERSION_NAME}] with id ${CV_VERSION_ID} from [${FROM_LIFECYCLE}] to [${TO_LIFECYCLE}]"
    hammer content-view version promote \
      --organization="${ORG}" \
      --content-view-id=${CV_ID} \
      --from-lifecycle-environment="${FROM_LIFECYCLE}" \
      --to-lifecycle-environment="${TO_LIFECYCLE}" \
      --id=${CV_VERSION_ID}

    echo "Installable erratum for [${CV_VERSION_NAME}] content hosts"
    hammer erratum list \
      --organization="${ORG}" \
      --content-view-id=${CV_ID} \
      --content-view-version-id=${CV_VERSION_ID} \
      --errata-restrict-installable=true
  fi

done

IFS=$O_IFS
{% endhighlight %}

References
----------
* [Red Hat Satellite 5]()
* [Spacewalk](https://fedorahosted.org/spacewalk/)

* [Red Hat Satellite 6](https://access.redhat.com/products/red-hat-satellite)
* [The Foreman](https://theforeman.org/)
* [Katello](http://www.katello.org/)
* [Pulp](http://pulpproject.org/)
