import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { ChevronDown } from 'lucide-react'
import { db } from '../firebase'
import { asDate, compareByDateDesc, displayText, formatDateTime, getList, getFirstText } from '../utils/firestoreDisplay'

export default function Criteria() {
  const [users, setUsers] = useState([])
  const [selectedId, setSelectedId] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, 'users'),
      snap => {
        const nextUsers = snap.docs
          .map(docItem => ({ id: docItem.id, ...docItem.data() }))
          .sort((left, right) => compareByDateDesc(left, right))
        setUsers(nextUsers)
        setLoading(false)
        setError('')
      },
      snapshotError => {
        setError(snapshotError.message || 'Khong the tai du lieu tieu chi.')
        setLoading(false)
      },
    )

    return unsub
  }, [])

  const criteria = useMemo(() => {
    const criteriaMap = new Map()

    users.forEach(user => {
      const labels = getList(user?.roommateCriteria)
      labels.forEach(label => {
        const existing = criteriaMap.get(label) ?? {
          id: label,
          label,
          count: 0,
          users: [],
          latestAt: null,
        }

        const userName = getFirstText(user, ['fullName', 'displayName'])
        const nextLatest = asDate(user?.updatedAt) || asDate(user?.createdAt)
        criteriaMap.set(label, {
          ...existing,
          count: existing.count + 1,
          users: [...existing.users, userName].filter(Boolean).slice(0, 3),
          latestAt: !existing.latestAt || (nextLatest && nextLatest > existing.latestAt) ? nextLatest : existing.latestAt,
        })
      })
    })

    return [...criteriaMap.values()].sort((left, right) => {
      if (right.count !== left.count) return right.count - left.count
      return left.label.localeCompare(right.label)
    })
  }, [users])

  useEffect(() => {
    if (!criteria.length) {
      setSelectedId('')
      return
    }
    if (!criteria.some(item => item.id === selectedId)) {
      setSelectedId(criteria[0].id)
    }
  }, [criteria, selectedId])

  const selectedCriteria = criteria.find(item => item.id === selectedId) ?? null
  const usersWithCriteria = users.filter(user => getList(user?.roommateCriteria).length > 0).length

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Tieu chi Phu hop</h1>
        <p className="text-gray-500 text-sm mt-1">Tong hop roommate criteria dang ton tai trong Firestore.</p>
      </div>

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-gray-800">Thong so hoat dong</h2>
            <span className="text-xs bg-green-100 text-green-700 font-semibold px-3 py-1 rounded-full">
              {criteria.length} TIEU CHI
            </span>
          </div>

          {loading ? (
            <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center text-gray-400">Dang tai...</div>
          ) : error ? (
            <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center text-red-500">{error}</div>
          ) : criteria.length === 0 ? (
            <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center text-gray-400">No data available</div>
          ) : (
            <div className="space-y-3">
              {criteria.map(item => (
                <button
                  key={item.id}
                  onClick={() => setSelectedId(item.id)}
                  className={`w-full text-left bg-white rounded-xl border shadow-sm p-4 flex items-center gap-4 transition-colors ${
                    selectedId === item.id ? 'border-blue-200' : 'border-gray-100 hover:border-blue-200'
                  }`}
                >
                  <div className="w-11 h-11 rounded-xl bg-blue-50 flex items-center justify-center text-blue-600 text-sm font-semibold flex-shrink-0">
                    {item.label?.[0]?.toUpperCase() || '—'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-800">{displayText(item.label)}</p>
                    <p className="text-xs text-gray-500">
                      {item.count} nguoi dung · {item.users.join(', ') || '—'}
                    </p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="text-2xl font-bold text-blue-600">{item.count}</p>
                    <p className="text-xs text-gray-400">NGUOI DUNG</p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h3 className="font-semibold text-gray-800 mb-4">Chi tiet tieu chi</h3>

            <div className="space-y-4">
              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Nhan hien thi</label>
                <input
                  type="text"
                  readOnly
                  value={selectedCriteria?.label ?? ''}
                  className="w-full mt-1.5 px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm outline-none"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">So nguoi dung co tieu chi nay</label>
                <div className="mt-1.5 px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm">
                  {selectedCriteria?.count ?? '—'}
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Cap nhat gan nhat</label>
                <div className="mt-1.5 relative">
                  <div className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm appearance-none outline-none">
                    {selectedCriteria ? formatDateTime(selectedCriteria.latestAt) : '—'}
                  </div>
                  <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-2">Nguoi dung mau</label>
                <div className="space-y-2">
                  {(selectedCriteria?.users?.length ? selectedCriteria.users : ['—']).map(name => (
                    <div key={name} className="flex items-center gap-2.5">
                      <div className="w-2 h-2 rounded-full bg-blue-500" />
                      <span className="text-sm text-gray-700">{displayText(name)}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 mt-5">
              <div className="rounded-lg border border-gray-200 p-3">
                <p className="text-xs text-gray-500 uppercase tracking-wider">Users co criteria</p>
                <p className="text-lg font-bold text-gray-900 mt-1">{usersWithCriteria}</p>
              </div>
              <div className="rounded-lg border border-gray-200 p-3">
                <p className="text-xs text-gray-500 uppercase tracking-wider">Tong users</p>
                <p className="text-lg font-bold text-gray-900 mt-1">{users.length}</p>
              </div>
            </div>
          </div>

          <div className="bg-blue-50 rounded-xl border border-blue-100 p-4">
            <div className="flex items-center gap-1.5 mb-2">
              <span className="text-blue-600 text-xs">i</span>
              <span className="text-xs font-semibold text-blue-600 uppercase tracking-wider">Tom tat du lieu</span>
            </div>
            <p className="text-xs text-gray-600">
              Trang nay tong hop tu truong <code>users.roommateCriteria</code>. Neu nguoi dung khong co mang nay, giao dien se de trong thay vi tao du lieu gia.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
