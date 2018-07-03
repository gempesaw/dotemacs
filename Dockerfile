# via https://github.com/iquiw/docker-alpine-emacs
FROM alpine:3.7

WORKDIR /root
RUN  apk --no-cache --update \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    add ca-certificates emacs-x11 git

COPY . .emacs.d/

ENV EMACS_DIR=/root/.emacs.d/
ENV EMACS_ELPA_DIR=$EMACS_DIR/elpa/
ENV EMACS_INIT_FILE=$EMACS_DIR/init.el

ENTRYPOINT [ "emacs" ]
CMD [ "-nw" ]
