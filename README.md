### README para el Backend (sismologia_api/README.md)

```markdown
# Sismología App - Backend

Este proyecto es la parte del backend de la aplicación web para monitorear y comentar sobre eventos sísmicos. Está desarrollado en Ruby on Rails y utiliza Docker para su gestión y Sidekiq para la cola de tareas en segundo plano.

## Características Principales

- **Backend en Ruby on Rails**: Gestiona las API y la lógica del servidor.
- **Docker**: Facilita la configuración y despliegue del backend.
- **Sidekiq**: Maneja tareas en segundo plano, como la obtención de datos sísmicos.

## Rutas del Backend

El backend expone las siguientes rutas:

```ruby
require 'sidekiq/web'

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  mount Sidekiq::Web => '/sidekiq'
  
  namespace :api do
    resources :features, only: [:index] do
      resources :comments, only: [:index, :create]
    end
  end
end
```

### Controladores

#### FeaturesController

```ruby
module Api
  class FeaturesController < ApplicationController
    def index
      features = Feature.all

      if params[:filters] && params[:filters][:mag_type]
        features = features.where(mag_type: params[:filters][:mag_type])
      end

      features = features.page(params[:page]).per(params[:per_page] || 9)

      render json: FeatureSerializer.new(features, meta: pagination_meta(features)).serializable_hash
    end

    private

    def pagination_meta(features)
      {
        current_page: features.current_page,
        total: features.total_count,
        per_page: features.limit_value
      }
    end
  end
end
```

#### CommentsController

```ruby
module Api
  class CommentsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:create]

    def index
      feature = Feature.find(params[:feature_id])
      comments = feature.comments

      render json: comments.map { |comment| CommentSerializer.new(comment).serializable_hash }
    end

    def create
      feature = Feature.find(params[:feature_id])
      comment = feature.comments.build(comment_params)

      if comment.save
        render json: CommentSerializer.new(comment).serializable_hash, status: :created
      else
        render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def comment_params
      params.require(:comment).permit(:body)
    end
  end
end
```

## Tareas en Segundo Plano

Utilizamos Sidekiq para manejar tareas en segundo plano. A continuación se muestra un ejemplo de una tarea que obtiene datos sísmicos:

```ruby
class FetchEarthquakeDataJob
  include Sidekiq::Job

  def perform(*args)
    require 'faraday'
    require 'json'

    url = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson'
    response = Faraday.get(url)
    data = JSON.parse(response.body)

    data['features'].each do |feature|
      properties = feature['properties']
      geometry = feature['geometry']

      next if properties['title'].nil? || properties['url'].nil? || properties['place'].nil? || properties['magType'].nil? || geometry['coordinates'].nil?

      magnitude = properties['mag']
      latitude = geometry['coordinates'][3]
      longitude = geometry['coordinates'][2]

      next if magnitude < -1.0 || magnitude > 10.0 || latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0

      Feature.find_or_create_by(external_id: feature['id']) do |f|
        f.magnitude = magnitude
        f.place = properties['place']
        f.time = Time.at(properties['time'] / 1000)
        f.tsunami = properties['tsunami'] == 1
        f.mag_type = properties['magType']
        f.title = properties['title']
        f.longitude = longitude
        f.latitude = latitude
        f.url = properties['url']
      end
    end
  end
end
```

## Configuración y Ejecución

1. **Clonar el repositorio**:
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd sismologia_root/sismologia_api
   ```

2. **Construir y ejecutar los contenedores Docker**:
   ```bash
   docker-compose up --build
   ```

3. **Acceder a la aplicación**:
   - API: `http://localhost:3000`
   - Sidekiq: `http://localhost:3000/sidekiq`

### Endpoints de la API

- **Listar comentarios de un feature**:
  - **GET** `http://localhost:3000/api/features/:feature_id/comments`
  - Ejemplo: `http://localhost:3000/api/features/1/comments`

- **Agregar un comentario**:
  - **POST** `http://localhost:3000/api/features/:feature_id/comments`
  - Headers: `Content-Type: application/json`
  - Body:
    ```json
    {
      "comment": {
        "body": "Este es un comentario de prueba"
      }
    }
    ```

## Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o un pull request para cualquier mejora o corrección.

