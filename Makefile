BLOG='blog.yuuk.io'

.PHONY: pull
pull:
	blogsync pull $(BLOG)
