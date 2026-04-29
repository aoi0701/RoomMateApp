import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query, doc, updateDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { Search, Ban, CheckCircle, Users as UsersIcon, UserCheck, ShieldOff, Shield } from 'lucide-react'

const TABS = ['Tất cả', 'Hoạt động', 'Bị khóa', 'Admin']

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

  const tabMeta = {
    'Tất cả':    { icon: UsersIcon,  color: 'text-primary' },
    'Hoạt động': { icon: UserCheck,  color: 'text-emerald-600 dark:text-emerald-400' },
    'Bị khóa':   { icon: ShieldOff,  color: 'text-red-500' },
    'Admin':     { icon: Shield,     color: 'text-violet-600 dark:text-violet-400' },
  }

  return (
    <div className="space-y-6">
      <div className="pb-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Quản lý Người dùng</h1>
        <p className="text-gray-400 dark:text-gray-500 text-sm font-medium mt-2">Xem và quản lý tài khoản người dùng trong hệ thống.</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-4 gap-4">
        {TABS.map(t => {
          const { icon: Icon, color } = tabMeta[t]
          return (
            <div key={t} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-5
              hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 cursor-default">
              <div className="flex items-center justify-between mb-3">
                <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">{t}</p>
                <Icon size={15} className={color} />
              </div>
              <p className={`text-4xl font-extrabold ${color} tabular-nums`}>{counts[t]}</p>
            </div>
          )
        })}
      </div>

      {/* Table card */}
      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-700 flex items-center justify-between gap-4">
          <div className="relative flex-1 max-w-xs">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Tìm tên hoặc email..."
              className="w-full pl-9 pr-3 py-2 text-sm font-medium
                bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700
                text-gray-800 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500
                rounded-xl outline-none focus:border-primary focus:ring-2 focus:ring-primary/10 transition-all duration-150"
            />
          </div>
          <div className="flex gap-1 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl p-1">
            {TABS.map(t => (
              <button key={t} onClick={() => setActiveTab(t)}
                className={`px-3 py-1.5 text-sm rounded-lg font-semibold transition-all duration-150 cursor-pointer ${
                  activeTab === t
                    ? 'bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm'
                    : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
                }`}>
                {t}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="p-10 text-center text-gray-400 dark:text-gray-500 font-semibold">Đang tải...</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100 dark:border-gray-700">
                {['Người dùng', 'Email', 'Điện thoại', 'Giới tính', 'Trạng thái', 'Thao tác'].map(h => (
                  <th key={h} className="text-left text-xs font-extrabold text-gray-400 dark:text-gray-500
                    uppercase tracking-widest px-5 py-3.5">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-700">
              {filtered.length === 0 && (
                <tr><td colSpan={6} className="px-5 py-10 text-center text-sm font-semibold text-gray-400 dark:text-gray-500">
                  Không có người dùng nào
                </td></tr>
              )}
              {filtered.map(u => (
                <tr key={u.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/60 transition-colors duration-100">
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-primary-light dark:bg-primary/20
                        flex items-center justify-center text-primary font-extrabold text-sm flex-shrink-0">
                        {u.fullName?.[0]?.toUpperCase() ?? '?'}
                      </div>
                      <p className="text-sm font-bold text-gray-800 dark:text-gray-100">{u.fullName ?? 'Không có tên'}</p>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-sm font-semibold text-gray-500 dark:text-gray-400">{u.email}</td>
                  <td className="px-5 py-4 text-sm font-semibold text-gray-500 dark:text-gray-400">{u.phone ?? '—'}</td>
                  <td className="px-5 py-4 text-sm font-semibold text-gray-500 dark:text-gray-400">{u.gender ?? '—'}</td>
                  <td className="px-5 py-4">
                    <span className={`text-xs font-bold px-2.5 py-1 rounded-full ring-1 ${
                      u.role === 'banned'
                        ? 'bg-red-50 dark:bg-red-950 text-red-500 ring-red-100 dark:ring-red-900'
                        : u.role === 'admin'
                        ? 'bg-violet-50 dark:bg-violet-950 text-violet-600 dark:text-violet-400 ring-violet-100 dark:ring-violet-900'
                        : 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-emerald-100 dark:ring-emerald-900'
                    }`}>
                      {u.role === 'banned' ? 'Bị khóa' : u.role === 'admin' ? 'Admin' : 'Hoạt động'}
                    </span>
                  </td>
                  <td className="px-5 py-4">
                    {u.role === 'banned' ? (
                      <button onClick={() => unbanUser(u.id)} title="Mở khóa"
                        className="p-2 text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-950
                          rounded-lg transition-all duration-150 active:scale-95 cursor-pointer">
                        <CheckCircle size={16} />
                      </button>
                    ) : u.role !== 'admin' ? (
                      <button onClick={() => banUser(u.id)} title="Khóa tài khoản"
                        className="p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-950
                          rounded-lg transition-all duration-150 active:scale-95 cursor-pointer">
                        <Ban size={16} />
                      </button>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-700">
          <p className="text-sm font-semibold text-gray-400 dark:text-gray-500">
            Hiển thị <span className="text-gray-700 dark:text-gray-300 font-bold">{filtered.length}</span> / {users.length} người dùng
          </p>
        </div>
      </div>
    </div>
  )
}
