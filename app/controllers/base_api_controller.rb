class BaseApiController < ApplicationController
  skip_before_action :verify_authenticity_token
	before_filter :parse_request

  private
    def parse_request
      @json = JSON.parse(request.body.read)
    end
end
