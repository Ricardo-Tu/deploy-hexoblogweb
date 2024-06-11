FROM  ubuntu

RUN    mkdir  -p /root/web/frontend/
RUN  sed  -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN  sed  -i s@/deb.debian.org/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN  apt  clean
RUN  apt  update
RUN  apt  install -y  git
RUN  apt  install -y  nodejs
RUN  apt  install -y  npm
RUN  apt  install -y yarn
RUN  npm  config set registry https://registry.npmmirror.com
RUN  npm  install -g hexo-cli --no-optional
# RUN  npm  cache clean --force
# RUN  npm  install
# RUN  npm  install  hexo-cli -g
# RUN  npm  install --save hexo-tag-aplayer
# RUN  npm  update  hexo
COPY  ./hexo  /root/web/frontend/hexo
WORKDIR  /root/web/frontend/hexo/
RUN  npm  install
RUN  npm  install aplayer --save
CMD  bash  ./run-myweb.sh
