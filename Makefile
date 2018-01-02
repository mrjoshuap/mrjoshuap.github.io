SITE= _site
SOURCE= ./
RM= rm -rf

all : site

clean :
	bundle exec jekyll clean
	$(RM) $(SITE)

doctor:
	bundle exec jekyll doctor

gh-pages:
	shell/publish gh-pages

publish: site gh-pages

server:
	bundle exec jekyll server --source $(SOURCE) --destination $(SITE) --watch

site:
	bundle exec jekyll build --source $(SOURCE) --destination $(SITE)
