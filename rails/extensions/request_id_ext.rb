##
# Handles X-Request-Id functionality patching `ActionDispatch::RequestId`
# to allows the header value to include more characters than alphanumereric
# and `-`.  Extends it to also allow: `\`, `+`, `=`.
#
# See
# ActionDispatch::RequestId
module Daylight::RequestIdExt
  def call(env)
    req = ActionDispatch::Request.new env
    if env["HTTP_X_REQUEST_ID"].presence
      req.request_id = x_make_request_id(req.x_request_id)
    else
      req.request_id = make_request_id(req.x_request_id)
    end
    @app.call(env).tap { |_status, headers, _body| headers[ActionDispatch::RequestId::X_REQUEST_ID] = req.request_id }
  end
  private
    def x_make_request_id(request_id)
      request_id.gsub(/[^\w\/\-+=]/, "").first(255)
    end
end

class ActionDispatch::RequestId
  prepend Daylight::RequestIdExt
end
