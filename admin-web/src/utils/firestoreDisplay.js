export const EMPTY_VALUE = '—'

export function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim() !== ''
}

export function asText(value) {
  if (typeof value === 'string') return value.trim()
  if (typeof value === 'number' || typeof value === 'boolean') return String(value)
  return ''
}

export function displayText(value, fallback = EMPTY_VALUE) {
  const text = asText(value)
  return text || fallback
}

export function asNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (typeof value === 'string') {
    const normalized = value.replace(/[^\d.-]/g, '')
    const parsed = Number(normalized)
    return Number.isFinite(parsed) ? parsed : null
  }
  return null
}

export function formatNumber(value, fallback = EMPTY_VALUE) {
  const parsed = asNumber(value)
  return parsed === null ? fallback : parsed.toLocaleString('vi-VN')
}

export function formatCurrency(value, fallback = EMPTY_VALUE) {
  const parsed = asNumber(value)
  return parsed === null ? fallback : `${parsed.toLocaleString('vi-VN')}đ`
}

export function asDate(value) {
  if (!value) return null
  if (value instanceof Date && !Number.isNaN(value.getTime())) return value
  if (typeof value?.toDate === 'function') {
    const date = value.toDate()
    return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null
  }
  if (typeof value === 'number') {
    const date = new Date(value)
    return Number.isNaN(date.getTime()) ? null : date
  }
  if (typeof value === 'string') {
    const date = new Date(value)
    return Number.isNaN(date.getTime()) ? null : date
  }
  return null
}

export function formatDateTime(value, fallback = EMPTY_VALUE) {
  const date = asDate(value)
  return date
    ? new Intl.DateTimeFormat('vi-VN', {
        dateStyle: 'short',
        timeStyle: 'short',
      }).format(date)
    : fallback
}

export function formatRelativeTime(value, fallback = EMPTY_VALUE) {
  const date = asDate(value)
  if (!date) return fallback

  const diffMs = date.getTime() - Date.now()
  const rtf = new Intl.RelativeTimeFormat('vi', { numeric: 'auto' })
  const minute = 60 * 1000
  const hour = 60 * minute
  const day = 24 * hour

  if (Math.abs(diffMs) < hour) return rtf.format(Math.round(diffMs / minute), 'minute')
  if (Math.abs(diffMs) < day) return rtf.format(Math.round(diffMs / hour), 'hour')
  return rtf.format(Math.round(diffMs / day), 'day')
}

export function compareByDateDesc(left, right, fieldNames = ['createdAt', 'updatedAt']) {
  const leftDate = getFirstDate(left, fieldNames)
  const rightDate = getFirstDate(right, fieldNames)
  return (rightDate?.getTime() ?? 0) - (leftDate?.getTime() ?? 0)
}

export function getFirstDate(source, fieldNames) {
  for (const fieldName of fieldNames) {
    const date = asDate(source?.[fieldName])
    if (date) return date
  }
  return null
}

export function getFirstText(source, fieldNames) {
  for (const fieldName of fieldNames) {
    const text = asText(source?.[fieldName])
    if (text) return text
  }
  return ''
}

export function getFirstNumber(source, fieldNames) {
  for (const fieldName of fieldNames) {
    const value = asNumber(source?.[fieldName])
    if (value !== null) return value
  }
  return null
}

export function getList(value) {
  if (!Array.isArray(value)) return []
  return value
    .map(item => asText(item))
    .filter(Boolean)
}

export function getImageUrl(source, fieldNames = ['imageUrl', 'avatarUrl', 'photoURL']) {
  for (const fieldName of fieldNames) {
    const value = source?.[fieldName]
    if (Array.isArray(value)) {
      const first = value.find(item => isNonEmptyString(item))
      if (first) return first.trim()
    }
    if (isNonEmptyString(value)) return value.trim()
  }
  return ''
}

export function matchesSearch(value, search) {
  if (!search) return true
  return asText(value).toLowerCase().includes(search.trim().toLowerCase())
}

export function matchesKeywords(value, keywords = []) {
  const text = asText(value).toLowerCase()
  if (!text) return false
  return keywords.some(keyword => text.includes(asText(keyword).toLowerCase()))
}
