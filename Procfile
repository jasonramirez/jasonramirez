release: rails db:migrate
web: bundle exec puma -p $PORT -C ./config/puma.rb
worker: bundle exec rake jobs:work
