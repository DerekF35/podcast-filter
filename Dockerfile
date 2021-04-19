FROM ruby:3.0

COPY Gemfile /app/Gemfile

WORKDIR /app

RUN bundle install

COPY filter-pod.rb /app/filter-pod.rb

ENTRYPOINT [ "ruby" , "filter-pod.rb" ]
