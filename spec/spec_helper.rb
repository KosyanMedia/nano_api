# encoding: UTF-8
# Configure Rails Envinronment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'rails/test_help'
require 'rspec/rails'
require 'fabrication'
require 'forgery'

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = 'test.com'

Rails.backtrace_cleaner.remove_silencers!

require 'capybara/rspec'

# Setup FakeWeb
require 'fakeweb'
FakeWeb.allow_net_connect = false

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path('../dummy/db/migrate/', __FILE__)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/fabricators/**/*.rb"].each { |f| require f }

I18n.backend.store_translations :en, :date => {
  :abbr_month_names => %w[ ~ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ],
  :month_names => %w[ ~ January February March April May June July August September October November December ]
}
I18n.backend.store_translations :ru, :date => {
  :abbr_month_names => %w[ ~ Янв Фев Мар Апр Май Июн Июл Авн Сен Окт Ноя Дек ],
  :month_names => %w[ ~ января февраля марта апреля мая июня июля августа сентября октября ноября декабря ]
}
I18n.backend.store_translations :de, :date => {
  :abbr_month_names => %w[ ~ Jan Feb Mär Apr Mai Jun Jul Aug Sep Okt Nov Dez ],
  :month_names => %w[ ~ Januar Februar März April Mai Juni Juli August September Oktober November Dezember ]
}

RSpec.configure do |config|
  # Remove this line if you don't want RSpec's should and should_not
  # methods or matchers
  require 'rspec/expectations'
  config.include RSpec::Matchers

  # == Mock Framework
  config.mock_with :rspec
end
