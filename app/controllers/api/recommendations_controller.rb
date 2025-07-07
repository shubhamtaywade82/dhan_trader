module Api
  class RecommendationsController < ApplicationController
    def index
      style = params[:style] || 'intraday'
      recs = Recommendation.where(style: style).order(generated_at: :desc)
      render json: recs.as_json(only: %i[style signals explanation generated_at],
                                include: { instrument: { only: :symbol } })
    end
  end
end
