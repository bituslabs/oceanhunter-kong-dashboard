export type GatewayEdition = 'enterprise' | 'community'

const getConfig = <T>(key: string, defaultValue: T): T => {
  if (typeof window !== 'object' || !window.K_CONFIG) {
    return defaultValue
  }

  const value = window.K_CONFIG[key]
  if (value === '' || value == null) {
    return defaultValue
  }

  try {
    // Properly handle booleans, numbers, arrays, and objects
    return JSON.parse(value)
  } catch (_) {
    // Value must have be a string or empty
    return value as T
  }
}

export const config = {

  get ADMIN_GUI_PATH() {
    return getConfig<string>('ADMIN_GUI_PATH', '/')
  },

  get ADMIN_API_PORT() {
    return getConfig<number>('ADMIN_API_PORT', 8001)
  },

  get ADMIN_API_SSL_PORT() {
    return getConfig<number>('ADMIN_API_SSL_PORT', 8444)
  },

  get ADMIN_API_URL() {
    return 'INSERT_KONG_API_ENDPOINT'
  },

  get ANONYMOUS_REPORTS() {
    return getConfig('ANONYMOUS_REPORTS', false)
  },
}
