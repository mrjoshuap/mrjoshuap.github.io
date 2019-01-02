---
layout: default
title: Home
pagination:
  enabled: true
---

<!-- Just some nice to have styles for the pager buttons -->
<style>
  ul.pager { text-align: center; list-style: none; }
  ul.pager li {display: inline;border: 1px solid black; padding: 10px; margin: 5px;}
</style>

<div class="posts">
  <div class="post">
    <h1 class="post-title">Posts</h1>
    <ul class="post-list">{% for post in paginator.posts %}
      <li>
        <span class="post-date">{{ post.date | date: "%b %-d, %Y" }}</span>
        <h2>
          <a class="post-link" href="{{ post.url | prepend: site.baseurl | replace: '//', '/' }}">{{ post.title | escape }}</a>
        </h2>
      </li>
    {% endfor %}</ul>
  </div>

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

<p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | prepend: site.baseurl }}">via RSS</a></p>
