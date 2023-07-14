class WelcomeController < ApplicationController
  include HistoryHelper

  def index
    @hashtags = Hashtag.all
  end
end
