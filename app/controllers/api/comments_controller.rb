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
  