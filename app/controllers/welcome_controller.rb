class WelcomeController < ApplicationController
  include HistoryHelper

  def index
    @hashtags = Hashtag.order(:label)
  end
end
