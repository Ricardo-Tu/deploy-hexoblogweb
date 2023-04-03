FROM  ubuntu:latest

RUN   mkdir -p /root/web/frontend/
RUN   apt-get update
RUN   apt-get  install -y  git 
RUN   apt-get  install -y  nodejs
RUN   apt-get  install -y  npm
RUN   apt-get  install -y yarn 
RUN   npm install -g hexo-cli --no-optional
CMD   npm install  hexo-cli -g
CMD   np  mupdate  hexo
COPY  ./hexo  /root/web/frontend/hexo
WORKDIR /root/web/frontend/hexo/
CMD   bash ./run-myweb.sh



