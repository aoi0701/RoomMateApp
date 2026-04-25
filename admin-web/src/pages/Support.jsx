import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { Filter, ArrowUpDown, ChevronLeft, ChevronRight } from 'lucide-react'
import { db } from '../firebase'
import {
  compareByDateDesc,
  displayText,
  formatDateTime,
  formatNumber,
  getFirstNumber,
  getFirstText,
  matchesKeywords,
} from '../utils/firestoreDisplay'

function statusBadge(status) {
  if (matchesKeywords(status, ['resolved', 'closed', 'giai quyet', 'da dong'])) return 'bg-green-100 text-green-600'
  if (matchesKeywords(status, ['pending', 'wait', 'cho'])) return 'bg-orange-100 text-orange-600'
  if (matchesKeywords(status, ['open', 'mo'])) return 'bg-blue-100 text-blue-600'
  return 'bg-gray-100 text-gray-600'
}

function priorityBadge(priority) {
  if (matchesKeywords(priority, ['high', 'cao'])) return 'bg-red-100 text-red-600'
  if (matchesKeywords(priority, ['medium', 'trung'])) return 'bg-yellow-100 text-yellow-600'
  if (matchesKeywords(priority, ['low', 'thap'])) return 'bg-green-100 text-green-600'
  return 'bg-gray-100 text-gray-600'
}

export default function Support() {
  const [tickets, setTickets] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, 'support'),
      snap => {
        const nextTickets = snap.docs
          .map(docItem => ({ id: docItem.id, ...docItem.data() }))
          .sort((left, right) => compareByDateDesc(left, right))
        setTickets(nextTickets)
        setLoading(false)
        setError('')
      },
      snapshotError => {
        setError(snapshotError.message || 'Khong the tai du lieu ho tro.')
        setLoading(false)
      },
    )

    return unsub
  }, [])

  const openCount = tickets.filter(ticket => matchesKeywords(getFirstText(ticket, ['status']), ['open', 'mo'])).length
  const unassignedCount = tickets.filter(ticket => !getFirstText(ticket, ['assigneeName', 'assignedToName', 'assignedTo', 'agentName'])).length
  const averageResponseTime = useMemo(() => {
    const values = tickets
      .map(ticket => getFirstNumber(ticket, ['responseTimeMinutes', 'avgResponseMinutes']))
      .filter(value => value !== null)
    if (!values.length) return null
    return Math.round(values.reduce((sum, value) => sum + value, 0) / values.length)
  }, [tickets])

  const leaderboard = useMemo(() => {
    const grouped = tickets.reduce((accumulator, ticket) => {
      const assigneeName = getFirstText(ticket, ['assigneeName', 'assignedToName', 'assignedTo', 'agentName'])
      if (!assigneeName) return accumulator
      const status = getFirstText(ticket, ['status'])
      accumulator[assigneeName] = (accumulator[assigneeName] ?? 0) + (matchesKeywords(status, ['resolved', 'closed', 'giai quyet', 'da dong']) ? 1 : 0)
      return accumulator
    }, {})

    return Object.entries(grouped)
      .map(([name, count]) => ({ name, count }))
      .sort((left, right) => right.count - left.count)
      .slice(0, 5)
  }, [tickets])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Trung tam Ho tro</h1>
        <p className="text-gray-500 text-sm mt-1">Quan ly cac yeu cau ho tro luu trong Firestore.</p>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Ve dang mo', value: openCount },
          { label: 'Phan hoi TB', value: averageResponseTime === null ? '—' : `${formatNumber(averageResponseTime)} phut` },
          { label: 'Chua phan cong', value: unassignedCount, red: true },
          { label: 'Tong ve', value: tickets.length, blue: true },
        ].map(stat => (
          <div key={stat.label} className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{stat.label}</p>
            <p className={`text-3xl font-bold mt-2 ${stat.red ? 'text-red-500' : stat.blue ? 'text-blue-600' : 'text-gray-900'}`}>{stat.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 className="font-semibold text-gray-800">Yeu cau ho tro gan day</h2>
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">
              <Filter size={14} /> Loc
            </button>
            <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">
              <ArrowUpDown size={14} /> Sap xep
            </button>
          </div>
        </div>

        {loading ? (
          <div className="p-8 text-center text-gray-400">Dang tai...</div>
        ) : error ? (
          <div className="p-8 text-center text-red-500">{error}</div>
        ) : tickets.length === 0 ? (
          <div className="p-8 text-center text-gray-400">No data available</div>
        ) : (
          <div className="divide-y divide-gray-50">
            {tickets.map(ticket => {
              const category = getFirstText(ticket, ['category', 'type'])
              const ticketCode = getFirstText(ticket, ['ticketId', 'code'])
              const title = getFirstText(ticket, ['title', 'subject'])
              const description = getFirstText(ticket, ['description', 'content'])
              const priority = getFirstText(ticket, ['priority'])
              const status = getFirstText(ticket, ['status'])
              return (
                <div key={ticket.id} className="px-5 py-4 hover:bg-gray-50 transition-colors cursor-pointer">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex gap-3 flex-1 min-w-0">
                      <div className="w-9 h-9 rounded-lg bg-blue-50 flex items-center justify-center flex-shrink-0 text-blue-600 text-xs font-bold">
                        {category?.[0]?.toUpperCase() || '—'}
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 mb-0.5">
                          <span className="text-xs font-semibold text-blue-600">{displayText(category)}</span>
                          <span className="text-xs text-gray-400">{displayText(ticketCode)}</span>
                        </div>
                        <p className="text-sm font-semibold text-gray-800 truncate">{displayText(title)}</p>
                        <p className="text-xs text-gray-500 mt-0.5 truncate">{displayText(description)}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <div className="text-right">
                        <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${priorityBadge(priority)}`}>{displayText(priority)}</span>
                        <p className="text-xs text-gray-400 mt-1">{formatDateTime(ticket?.createdAt || ticket?.updatedAt)}</p>
                      </div>
                      <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${statusBadge(status)}`}>{displayText(status)}</span>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}

        <div className="px-5 py-3 border-t border-gray-100 flex items-center justify-between">
          <p className="text-sm text-gray-500">Hien thi {tickets.length} ve</p>
          <div className="flex gap-1">
            <button className="p-1.5 border border-gray-200 rounded-lg text-gray-500 hover:bg-gray-50"><ChevronLeft size={16} /></button>
            <button className="p-1.5 border border-gray-200 rounded-lg text-gray-500 hover:bg-gray-50"><ChevronRight size={16} /></button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800">Phan bo trang thai</h3>
          <p className="text-sm text-gray-500 mt-1">Khong co thong ke gia lap. Moi chi so o day duoc dem tu trang thai ticket hien co.</p>
          <div className="grid grid-cols-2 gap-3 mt-4">
            {['open', 'pending', 'resolved', 'closed'].map(statusKey => {
              const keywordsByStatus = {
                open: ['open', 'mo'],
                pending: ['pending', 'wait', 'cho'],
                resolved: ['resolved', 'giai quyet'],
                closed: ['closed', 'da dong'],
              }
              const count = tickets.filter(ticket => matchesKeywords(getFirstText(ticket, ['status']), keywordsByStatus[statusKey])).length
              return (
                <div key={statusKey} className="rounded-lg border border-gray-200 p-3">
                  <p className="text-xs text-gray-500 uppercase tracking-wider">{statusKey}</p>
                  <p className="text-xl font-bold text-gray-900 mt-1">{count}</p>
                </div>
              )
            })}
          </div>
        </div>

        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Bang xep hang ho tro</p>
          {leaderboard.length === 0 ? (
            <p className="text-sm text-gray-400">No data available</p>
          ) : (
            <div className="space-y-3">
              {leaderboard.map(item => (
                <div key={item.name} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white text-xs font-bold">
                      {item.name?.[0]?.toUpperCase() || '—'}
                    </div>
                    <span className="text-sm font-medium text-gray-800">{displayText(item.name)}</span>
                  </div>
                  <span className="text-sm text-gray-500">{item.count}</span>
                </div>
              ))}
            </div>
          )}
          <button className="w-full mt-4 py-2 bg-gray-900 text-white text-sm font-semibold rounded-lg hover:bg-gray-800">Bao cao day du</button>
        </div>
      </div>
    </div>
  )
}
