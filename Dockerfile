FROM ruby:3.2.4

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

WORKDIR /sismologia_api

COPY Gemfile /sismologia_api/Gemfile
COPY Gemfile.lock /sismologia_api/Gemfile.lock

RUN bundle install

COPY . /sismologia_api

# Cambiar permisos del script de entrada
RUN chmod +x entrypoint.sh

# Exponer el puerto
EXPOSE 3000

# Usar el script de entrada
ENTRYPOINT ["./entrypoint.sh"]

# Comando de inicio
CMD ["rails", "server", "-b", "0.0.0.0"]
    
    
