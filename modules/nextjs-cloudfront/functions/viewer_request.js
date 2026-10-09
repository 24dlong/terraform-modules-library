// Viewer-request handler (cloudfront-js-2.0), rendered by templatefile().
// CloudFront replaces the Host header with the origin's domain so the
// Function URL can verify the OAC signature; Next.js reads the public
// hostname from x-forwarded-host instead.

var APEX_DOMAIN = "${apex_domain}";
var REDIRECT_APEX_TO_WWW = ${redirect_apex_to_www};

function toQueryString(querystring) {
  var parts = [];
  for (var key in querystring) {
    var param = querystring[key];
    var values = param.multiValue ? param.multiValue : [param];
    for (var i = 0; i < values.length; i++) {
      parts.push(values[i].value === "" ? key : key + "=" + values[i].value);
    }
  }
  return parts.join("&");
}

function handler(event) {
  var request = event.request;
  var host = request.headers.host ? request.headers.host.value.toLowerCase() : "";

  if (REDIRECT_APEX_TO_WWW && host === APEX_DOMAIN) {
    var query = toQueryString(request.querystring);
    return {
      statusCode: 301,
      statusDescription: "Moved Permanently",
      headers: {
        location: {
          value: "https://www." + APEX_DOMAIN + request.uri + (query ? "?" + query : ""),
        },
      },
    };
  }

  if (host) {
    request.headers["x-forwarded-host"] = { value: host };
  }
  return request;
}
