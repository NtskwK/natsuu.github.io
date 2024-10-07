clean:
	hexo clean

deploy:
	hexo clean
	hexo generate
	hexo deploy

generate:
	hexo clean
	hexo generate

server:
	hexo clean
	hexo generate
	hexo server