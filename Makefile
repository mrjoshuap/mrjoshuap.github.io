SITE= site
RM= rm -rf

all : site

site:
	bundle exec jekyll build --source . --destination $(SITE)

server:
	bundle exec jekyll server --source . --destination $(SITE) --watch

publish: site gh-pages

gh-pages:
	shell/publish gh-pages

clean :
		$(RM) $(SITE)
