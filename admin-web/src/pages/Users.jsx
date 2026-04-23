import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query, doc, updateDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { Search, Ban, CheckCircle } from 'lucide-react'

const tabs = ['Tất cả', 'Hoạt động', 'Bị khóa', 'Admin']

export default function Users() {
  const [users, setUsers] = useState([])
  const [search, setSearch] = useState('')
  const [activeTab, setActiveTab] = useState('Tất cả')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, snap => {
      setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() })))
      setLoading(false)
    })
    return unsub
  }, [])

  const banUser = (uid) => updateDoc(doc(db, 'users', uid), { role: 'banned' })
  const unbanUser = (uid) => updateDoc(doc(db, 'users', uid), { role: 'user' })

  const filtered = users.filter(u => {
    const matchTab =
      activeTab === 'Tất cả' ? true :
      activeTab === 'Hoạt động' ? u.role === 'user' :
      activeTab === 'Bị khóa' ? u.role === 'banned' :
      activeTab === 'Admin' ? u.role === 'admin' : true

    const matchSearch =
      (u.fullName ?? '').toLowerCase().includes(search.toLowerCase()) ||
      (u.email ?? '').toLowerCase().includes(search.toLowerCase())

    return matchTab && matchSearch
  })

  const counts = {
    'Tất cả': users.length,
    'Hoạt động': users.filter(u => u.role === 'user').length,
    'Bị khóa': users.filter(u => u.role === 'banned').length,
    'Admin': users.filter(u => u.role === 'admin').length,
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Quản lý Người dùng</h1>
        <p className="text-gray-500 text-sm mt-1">Xem và quản lý tài khoản người dùng trong hệ thống.</p>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {tabs.map(t => (
          <div key={t} className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{t}</p>
            <p className="text-3xl font-bold text-gray-900 mt-1">{counts[t]}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
          <div className="relative flex-1 max-w-xs">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Tìm tên hoặc email..."
              className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm outline-none focus:border-blue-400"
            />
          </div>
          <div className="flex gap-1">
            {tabs.map(t => (
              <button key={t} onClick={() => setActiveTab(t)}
                className={`px-3 py-1.5 text-sm rounded-lg font-medium transition-colors ${activeTab === t ? 'bg-gray-900 text-white' : 'text-gray-600 hover:bg-gray-100'}`}>
                {t}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="p-8 text-center text-gray-400">Đang tải...</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100">
                {['Người dùng', 'Email', 'Điện thoại', 'Giới tính', 'Trạng thái', 'Thao tác'].map(h => (
                  <th key={h} className="text-left text-xs font-semibold text-gray-500 uppercase tracking-wider px-5 py-3">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr><td colSpan={6} className="px-5 py-8 text-center text-gray-400">Không có người dùng nào</td></tr>
              )}
              {filtered.map(u => (
                <tr key={u.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-sm flex-shrink-0">
                        {u.fullName?.[0]?.toUpperCase() ?? '?'}
                      </div>
                      <p className="text-sm font-semibold text-gray-800">{u.fullName ?? 'Không có tên'}</p>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-sm text-gray-600">{u.email}</td>
                  <td className="px-5 py-4 text-sm text-gray-600">{u.phone ?? '—'}</td>
                  <td className="px-5 py-4 text-sm text-gray-600">{u.gender ?? '—'}</td>
                  <td className="px-5 py-4">
                    <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${
                      u.role === 'banned' ? 'bg-red-100 text-red-600' :
                      u.role === 'admin' ? 'bg-purple-100 text-purple-600' :
                      'bg-green-100 text-green-600'
                    }`}>
                      {u.role === 'banned' ? 'Bị khóa' : u.role === 'admin' ? 'Admin' : 'Hoạt động'}
                    </span>
                  </td>
                  <td className="px-5 py-4">
                    <div className="flex gap-2">
                      {u.role === 'banned' ? (
                        <button onClick={() => unbanUser(u.id)} title="Mở khóa"
                          className="p-1.5 text-green-500 hover:bg-green-50 rounded">
                          <CheckCircle size={15} />
                        </button>
                      ) : u.role !== 'admin' ? (
                        <button onClick={() => banUser(u.id)} title="Khóa tài khoản"
                          className="p-1.5 text-red-400 hover:bg-red-50 rounded">
                          <Ban size={15} />
                        </button>
                      ) : null}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <div className="px-5 py-3 border-t border-gray-100">
          <p className="text-sm text-gray-500">Hiển thị {filtered.length} / {users.length} người dùng</p>
        </div>
      </div>
    </div>
  )
}
