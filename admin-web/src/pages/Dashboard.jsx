import { useEffect, useState } from 'react'
import { collection, onSnapshot, query, orderBy, limit } from 'firebase/firestore'
import { db } from '../firebase'
import { Users, FileText, GitPullRequest, Ban } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'

export default function Dashboard() {
  const [stats, setStats] = useState({ users: 0, posts: 0, requests: 0, banned: 0 })
  const [recentUsers, setRecentUsers] = useState([])
  const [recentPosts, setRecentPosts] = useState([])

  useEffect(() => {
    const unsubs = []

    unsubs.push(onSnapshot(collection(db, 'users'), s => {
      const banned = s.docs.filter(d => d.data().role === 'banned').length
      setStats(prev => ({ ...prev, users: s.size, banned }))
    }))

    unsubs.push(onSnapshot(collection(db, 'posts'), s =>
      setStats(prev => ({ ...prev, posts: s.size }))
    ))

    unsubs.push(onSnapshot(collection(db, 'roommate_requests'), s =>
      setStats(prev => ({ ...prev, requests: s.size }))
    ))

    const recentUsersQ = query(collection(db, 'users'), orderBy('createdAt', 'desc'), limit(5))
    unsubs.push(onSnapshot(recentUsersQ, s =>
      setRecentUsers(s.docs.map(d => ({ id: d.id, ...d.data() })))
    ))

    const recentPostsQ = query(collection(db, 'posts'), orderBy('createdAt', 'desc'), limit(5))
    unsubs.push(onSnapshot(recentPostsQ, s =>
      setRecentPosts(s.docs.map(d => ({ id: d.id, ...d.data() })))
    ))

    return () => unsubs.forEach(u => u())
  }, [])

  const statCards = [
    { label: 'Tổng người dùng', value: stats.users, icon: Users, color: 'text-blue-600', bg: 'bg-blue-50' },
    { label: 'Bài đăng', value: stats.posts, icon: FileText, color: 'text-green-600', bg: 'bg-green-50' },
    { label: 'Yêu cầu ghép phòng', value: stats.requests, icon: GitPullRequest, color: 'text-purple-600', bg: 'bg-purple-50' },
    { label: 'Tài khoản bị khóa', value: stats.banned, icon: Ban, color: 'text-red-600', bg: 'bg-red-50' },
  ]

  const chartData = [
    { name: 'Users', value: stats.users },
    { name: 'Posts', value: stats.posts },
    { name: 'Requests', value: stats.requests },
    { name: 'Banned', value: stats.banned },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Bảng điều khiển</h1>
        <p className="text-gray-500 text-sm mt-1">Tổng quan hệ thống RoomMate theo thời gian thực.</p>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {statCards.map(s => (
          <div key={s.label} className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{s.label}</p>
              <div className={`w-9 h-9 rounded-lg ${s.bg} flex items-center justify-center`}>
                <s.icon size={18} className={s.color} />
              </div>
            </div>
            <p className={`text-3xl font-bold ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h2 className="font-semibold text-gray-800 mb-4">Thống kê tổng quan</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartData}>
              <XAxis dataKey="name" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Bar dataKey="value" fill="#2563EB" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h2 className="font-semibold text-gray-800 mb-3">Người dùng mới nhất</h2>
            <div className="space-y-2">
              {recentUsers.length === 0 && <p className="text-sm text-gray-400">Chưa có dữ liệu</p>}
              {recentUsers.map(u => (
                <div key={u.id} className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-sm flex-shrink-0">
                    {u.fullName?.[0]?.toUpperCase() ?? '?'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-800 truncate">{u.fullName ?? 'Không có tên'}</p>
                    <p className="text-xs text-gray-400 truncate">{u.email}</p>
                  </div>
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                    u.role === 'banned' ? 'bg-red-100 text-red-600' :
                    u.role === 'admin' ? 'bg-purple-100 text-purple-600' :
                    'bg-green-100 text-green-600'
                  }`}>{u.role ?? 'user'}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h2 className="font-semibold text-gray-800 mb-3">Bài đăng mới nhất</h2>
            <div className="space-y-2">
              {recentPosts.length === 0 && <p className="text-sm text-gray-400">Chưa có dữ liệu</p>}
              {recentPosts.map(p => (
                <div key={p.id} className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center text-gray-500 flex-shrink-0">
                    <FileText size={14} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-800 truncate">{p.title}</p>
                    <p className="text-xs text-gray-400 truncate">{p.location ?? p.province}</p>
                  </div>
                  <span className="text-xs font-semibold text-blue-600 flex-shrink-0">
                    {p.price?.toLocaleString('vi-VN')}đ
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
