import { useEffect, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { Eye, CheckCircle, Ban } from 'lucide-react'
import { db } from '../firebase'
import { compareByDateDesc, displayText, formatDateTime, getFirstText, matchesKeywords } from '../utils/firestoreDisplay'

function severityClass(severity) {
  if (matchesKeywords(severity, ['high', 'cao'])) return 'bg-red-100 text-red-600'
  if (matchesKeywords(severity, ['medium', 'trung'])) return 'bg-yellow-100 text-yellow-600'
  if (matchesKeywords(severity, ['low', 'thap'])) return 'bg-green-100 text-green-600'
  return 'bg-gray-100 text-gray-600'
}

export default function Violations() {
  const [violations, setViolations] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, 'violations'),
      snap => {
        const nextViolations = snap.docs
          .map(docItem => ({ id: docItem.id, ...docItem.data() }))
          .sort((left, right) => compareByDateDesc(left, right))
        setViolations(nextViolations)
        setLoading(false)
        setError('')
      },
      snapshotError => {
        setError(snapshotError.message || 'Khong the tai du lieu vi pham.')
        setLoading(false)
      },
    )

    return unsub
  }, [])

  const pendingCount = violations.filter(item => matchesKeywords(getFirstText(item, ['status']), ['pending', 'cho xu ly', 'cho'])).length
  const reviewingCount = violations.filter(item => {
    const status = getFirstText(item, ['status'])
    return matchesKeywords(status, ['review', 'xem xet'])
  }).length
  const resolvedCount = violations.filter(item => {
    const status = getFirstText(item, ['status'])
    return matchesKeywords(status, ['resolved', 'closed', 'giai quyet'])
  }).length

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Quan ly Vi pham</h1>
        <p className="text-gray-500 text-sm mt-1">Xem xet va xu ly cac bao cao vi pham trong Firestore.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Cho xu ly', value: pendingCount, color: 'text-red-500', bg: 'bg-red-50 border-red-100' },
          { label: 'Dang xem xet', value: reviewingCount, color: 'text-yellow-600', bg: 'bg-yellow-50 border-yellow-100' },
          { label: 'Da giai quyet', value: resolvedCount, color: 'text-green-600', bg: 'bg-green-50 border-green-100' },
        ].map(stat => (
          <div key={stat.label} className={`rounded-xl border p-5 shadow-sm ${stat.bg}`}>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{stat.label}</p>
            <p className={`text-3xl font-bold mt-2 ${stat.color}`}>{stat.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100">
          <h2 className="font-semibold text-gray-800">Danh sach vi pham</h2>
        </div>

        {loading ? (
          <div className="p-8 text-center text-gray-400">Dang tai...</div>
        ) : error ? (
          <div className="p-8 text-center text-red-500">{error}</div>
        ) : violations.length === 0 ? (
          <div className="p-8 text-center text-gray-400">No data available</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100">
                {['ID', 'Nguoi dung', 'Loai vi pham', 'Thoi gian', 'Muc do', 'Trang thai', 'Thao tac'].map(header => (
                  <th key={header} className="text-left text-xs font-semibold text-gray-500 uppercase tracking-wider px-4 py-3">
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {violations.map(item => {
                const violationId = getFirstText(item, ['code', 'violationId']) || item.id
                const userName = getFirstText(item, ['userName', 'reportedUserName'])
                const type = getFirstText(item, ['type', 'reason', 'category'])
                const severity = getFirstText(item, ['severity'])
                const status = getFirstText(item, ['status'])
                return (
                  <tr key={item.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-4 text-xs font-mono">{displayText(violationId)}</td>
                    <td className="px-4 py-4 text-sm font-medium text-gray-800">{displayText(userName)}</td>
                    <td className="px-4 py-4 text-sm text-gray-600">{displayText(type)}</td>
                    <td className="px-4 py-4 text-xs text-gray-400">{formatDateTime(item?.createdAt || item?.updatedAt)}</td>
                    <td className="px-4 py-4">
                      <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${severityClass(severity)}`}>{displayText(severity)}</span>
                    </td>
                    <td className="px-4 py-4 text-sm text-gray-600">{displayText(status)}</td>
                    <td className="px-4 py-4">
                      <div className="flex gap-2">
                        <button className="p-1.5 text-blue-500 hover:bg-blue-50 rounded"><Eye size={15} /></button>
                        <button className="p-1.5 text-green-500 hover:bg-green-50 rounded"><CheckCircle size={15} /></button>
                        <button className="p-1.5 text-red-400 hover:bg-red-50 rounded"><Ban size={15} /></button>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
