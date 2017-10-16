# You'll need to set the host to 0.0.0.0 in _config.yml first!
# Note that Jekyll defaults to port 4000 (in container)

# To build image: "docker build -t drastic ." (in the root of this directory)
# To run container from image: "docker run -p 4000:4000 drastic"

FROM starefossen/ruby-node

WORKDIR /website

ADD . /website

RUN gem install jekyll bundler

# Get a JS runtime because Jekyll supports CoffeeScript
RUN gem install therubyrhino

RUN bundle install

EXPOSE 4000

CMD ["bundle", "exec","jekyll","serve"]


