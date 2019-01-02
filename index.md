---
layout: default
title: Home
pagination:
  enabled: true
---

<div class="posts">
  <div class="post">
    <h1 class="post-title">Posts</h1>
    <ul class="post-list">{% for post in paginator.posts %}
      <li>
        <span class="post-date">{{ post.date | date: "%b %-d, %Y" }}</span>
        <h2>
          <a class="post-link" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
        </h2>
      </li>
    {% endfor %}</ul>
  </div>

  <div class="pagination">
    {% if paginator.total_pages > 1 %}
    <ul class="pager">
      {% if paginator.previous_page %}
        <li class="previous">
          <a href="{{ paginator.previous_page_path | prepend: site.baseurl | replace: '//', '/' }}">&larr; Newer Posts</a>
        </li>
      {% endif %}
      {% if paginator.next_page %}
        <li class="next">
          <a href="{{ paginator.next_page_path | prepend: site.baseurl | replace: '//', '/' }}">Older Posts &rarr;</a>
        </li>
      {% endif %}
    </ul>
    {% endif %}
  </div>
</div>

<p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | prepend: site.baseurl }}">via RSS</a></p>
