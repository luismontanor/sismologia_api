module Api
    class FeaturesController < ApplicationController
        def index
            features = Feature.all
    
            if params[:filters] && params[:filters][:mag_type]
                features = features.where(mag_type: params[:filters][:mag_type])
            end
    
            # features = features.page(params[:page]).per(params[:per_page] || 10)
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
  