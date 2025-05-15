local typedefs = require "kong.db.schema.typedefs"

return {
  name = "authenticate",
  fields = {
    { config = {
        type = "record",
        fields = {
          { api_secret_key = { type = "string" } },  -- 用于存储API的密钥
        },
      },
    },
  },
}