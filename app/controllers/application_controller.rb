class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: { safari: 16.4, chrome: 108, firefox: 108, opera: 94, ie: false }

  stale_when_importmap_changes

  before_action :resume_session

  helper_method :session_strip

  private
    def session_strip
      return unless Current.session

      @session_strip ||= SessionStrip.new(user: Current.user, since: Current.session.created_at)
    end
end
