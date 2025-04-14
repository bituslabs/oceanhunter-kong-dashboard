local cjson = require "cjson"
local openssl_mac = require "resty.openssl.mac"
local ngx = ngx

local API_SECRET_KEY = "INSERT_SECRET_KEY"

function utf8_encode(str)
    local result = {}
    for i = 1, #str do
        local byte = string.byte(str, i)
        if byte <= 0x7F then
            table.insert(result, string.char(byte))
        elseif byte <= 0x7FF then
            table.insert(result, string.char(0xC0 + math.floor(byte / 64)))
            table.insert(result, string.char(0x80 + (byte % 64)))
        elseif byte <= 0xFFFF then
            table.insert(result, string.char(0xE0 + math.floor(byte / 4096)))
            table.insert(result, string.char(0x80 + math.floor(byte / 64) % 64))
            table.insert(result, string.char(0x80 + (byte % 64)))
        elseif byte <= 0x10FFFF then
            table.insert(result, string.char(0xF0 + math.floor(byte / 262144)))
            table.insert(result, string.char(0x80 + math.floor(byte / 4096) % 64))
            table.insert(result, string.char(0x80 + math.floor(byte / 64) % 64))
            table.insert(result, string.char(0x80 + (byte % 64)))
        else
            error("Invalid Unicode code point: " .. byte)
        end
    end
    return table.concat(result)
end

local function get_api_key_and_signature(auth_header)
    -- format: "WALLET <API-Key>:<Signature>"
    local _, _, api_key, signature = string.find(auth_header, "WALLET%s+([^:]+):(.+)")
    return api_key, signature
end

local AuthPluginHandler = {
  PRIORITY = 1000,
  VERSION = "1.0",
}

function AuthPluginHandler:access(conf)
    local headers = ngx.req.get_headers()
    local auth_header = headers["Authorization"]
    
    if not auth_header then
        ngx.log(ngx.ERR, "No Authorization Header")

        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    local api_key, signature_received = get_api_key_and_signature(auth_header)
    if not api_key or not signature_received then
        ngx.log(ngx.ERR, "Authorization No Parameters")

        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    ngx.log(ngx.DEBUG, "API Key: ", api_key)
    ngx.log(ngx.DEBUG, "Signature: ", signature_received)

    ngx.req.read_body()
    local body_data = ngx.req.get_body_data() or ""

    ngx.log(ngx.DEBUG, "body: ", body_data)

    if body_data == "" then
        ngx.log(ngx.ERR, "No request")

        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    -- format: Signature = Base64(HMAC-SHA256(APISecretKey, UTF-8-Encoding-Of(StringToSign)));
    local string_to_sign = utf8_encode(body_data)

    ngx.log(ngx.DEBUG, "StringToSign utf8: ", string_to_sign)

    local hmac_sha256 = openssl_mac.new(API_SECRET_KEY, "HMAC", nil, "sha256")
    local generated_signature = ngx.encode_base64(hmac_sha256:final(string_to_sign))

    ngx.log(ngx.DEBUG, "generated_signature: ", generated_signature)

    if generated_signature ~= signature_received then
        ngx.log(ngx.ERR, "sign not match signature_received: ", signature_received, " generated_signature: ", generated_signature)
        
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    ngx.log(ngx.DEBUG, string_to_sign, " sign ok")

    ngx.say(cjson.encode({status = "success", message = "auth success!"}))
end

return AuthPluginHandler

