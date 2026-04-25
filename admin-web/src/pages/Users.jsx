import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot, doc, updateDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { Search, Ban, CheckCircle } from 'lucide-react'
import { compareByDateDesc, displayText, getFirstText, matchesSearch } from '../utils/firestoreDisplay'

const tabs = ['Tat ca', 'Hoat dong', 'Bi khoa', 'Admin']

export default function Users() {
  const [users, setUsers] = useState([])
  const [search, setSearch] = useState('')
  const [activeTab, setActiveTab] = useState('Tat ca')
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
        setError(snapshotError.message || 'Khong the tai danh sach nguoi dung.')
        setLoading(false)
      },
    )

    return unsub
  }, [])

  const banUser = uid => updateDoc(doc(db, 'users', uid), { role: 'banned' })
  const unbanUser = uid => updateDoc(doc(db, 'users', uid), { role: 'user' })

  const filtered = useMemo(() => {
    return users.filter(user => {
      const role = getFirstText(user, ['role']).toLowerCase()
      const matchTab =
        activeTab === 'Tat ca'
          ? true
          : activeTab === 'Hoat dong'
            ? role === 'user'
            : activeTab === 'Bi khoa'
              ? role === 'banned'
              : activeTab === 'Admin'
                ? role === 'admin'
                : true

      const matchQuery =
        matchesSearch(user?.fullName, search) ||
        matchesSearch(user?.displayName, search) ||
        matchesSearch(user?.email, search)

      return matchTab && matchQuery
    })
  }, [activeTab, search, users])

  const counts = {
    'Tat ca': users.length,
    'Hoat dong': users.filter(user => getFirstText(user, ['role']).toLowerCase() === 'user').length,
    'Bi khoa': users.filter(user => getFirstText(user, ['role']).toLowerCase() === 'banned').length,
    Admin: users.filter(user => getFirstText(user, ['role']).toLowerCase() === 'admin').length,
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Quan ly Nguoi dung</h1>
        <p className="text-gray-500 text-sm mt-1">Xem va quan ly tai khoan nguoi dung trong he thong.</p>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {tabs.map(tab => (
          <div key={tab} className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{tab}</p>
            <p className="text-3xl font-bold text-gray-900 mt-1">{counts[tab]}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
          <div className="relative flex-1 max-w-xs">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={event => setSearch(event.target.value)}
              placeholder="Tim ten hoac email..."
              className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm outline-none focus:border-blue-400"
            />
          </div>
          <div className="flex gap-1">
            {tabs.map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-3 py-1.5 text-sm rounded-lg font-medium transition-colors ${
                  activeTab === tab ? 'bg-gray-900 text-white' : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="p-8 text-center text-gray-400">Dang tai...</div>
        ) : error ? (
          <div className="p-8 text-center text-red-500">{error}</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100">
                {['Nguoi dung', 'Email', 'Dien thoai', 'Gioi tinh', 'Trang thai', 'Thao tac'].map(header => (
                  <th key={header} className="text-left text-xs font-semibold text-gray-500 uppercase tracking-wider px-5 py-3">
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-5 py-8 text-center text-gray-400">No data available</td>
                </tr>
              )}
              {filtered.map(user => {
                const fullName = getFirstText(user, ['fullName', 'displayName'])
                const role = getFirstText(user, ['role']).toLowerCase()
                const roleClass = !role
                  ? 'bg-gray-100 text-gray-600'
                  : role === 'banned'
                    ? 'bg-red-100 text-red-600'
                    : role === 'admin'
                      ? 'bg-purple-100 text-purple-600'
                      : 'bg-green-100 text-green-600'
                return (
                  <tr key={user.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-sm flex-shrink-0">
                          {fullName?.[0]?.toUpperCase() || '—'}
                        </div>
                        <p className="text-sm font-semibold text-gray-800">{displayText(fullName)}</p>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-sm text-gray-600">{displayText(user?.email)}</td>
                    <td className="px-5 py-4 text-sm text-gray-600">{displayText(user?.phone)}</td>
                    <td className="px-5 py-4 text-sm text-gray-600">{displayText(user?.gender)}</td>
                    <td className="px-5 py-4">
                      <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${roleClass}`}>
                        {displayText(role)}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex gap-2">
                        {role === 'banned' ? (
                          <button
                            onClick={() => unbanUser(user.id)}
                            title="Mo khoa"
                            className="p-1.5 text-green-500 hover:bg-green-50 rounded"
                          >
                            <CheckCircle size={15} />
                          </button>
                        ) : role !== 'admin' ? (
                          <button
                            onClick={() => banUser(user.id)}
                            title="Khoa tai khoan"
                            className="p-1.5 text-red-400 hover:bg-red-50 rounded"
                          >
                            <Ban size={15} />
                          </button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
        <div className="px-5 py-3 border-t border-gray-100">
          <p className="text-sm text-gray-500">Hien thi {filtered.length} / {users.length} nguoi dung</p>
        </div>
      </div>
    </div>
  )
}
