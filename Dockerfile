FROM  ubuntu

RUN   mkdir -p /root/web/frontend/
RUN   apt-get update
RUN   apt-get  install -y  git 
RUN   apt-get  install -y  nodejs
RUN   apt-get  install -y  npm
RUN   apt-get  install -y yarn 
RUN   npm config set registry https://registry.npmmirror.com
RUN   npm install -g hexo-cli --no-optional
# RUN   npm install  hexo-cli -g
# RUN   npm install aplayer  
# RUN   npm install --save hexo-tag-aplayer  
# RUN   npm update  hexo
COPY  ./hexo  /root/web/frontend/hexo
WORKDIR /root/web/frontend/hexo/
CMD   bash ./run-myweb.sh
