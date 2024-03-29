FROM ruby:2.3-alpine

MAINTAINER SLAPI Dev Team

ENV APP_HOME /usr/src/sinatra

RUN mkdir -p $APP_HOME &&\
    mkdir -p $APP_HOME/log

WORKDIR /usr/src/sinatra

COPY supervisord.conf /etc/supervisor.d/supervisord.conf
COPY . $APP_HOME

RUN apk update && apk add \
    bash \
    supervisor \
    git &&\
    gem install json \
    sinatra \
    sinatra-contrib \
    httparty &&\
    gem cleanup &&\
    rm -rf /var/cache/apk/* &&\
    rm -rf /tmp/*

EXPOSE 4567

ONBUILD ADD . $APP_HOME

ONBUILD RUN apk update
    runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" &&\
    if [ -f Gemfile.lock ]; then rm -f Gemfile.lock; fi &&\
    apk add --virtual .ruby-builddeps $runDeps \
    build-base \
    linux-headers &&\
    bundle install
    apk del .ruby-builddeps &&\
    rm -rf /var/cache/apk/* &&\
    rm -rf /tmp/*

ONBUILD CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.conf", "-n"]

