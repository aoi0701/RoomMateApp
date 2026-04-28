import { useEffect, useState } from 'react'
import { collection, onSnapshot, query, orderBy, limit } from 'firebase/firestore'
import { db } from '../firebase'
import {
  Users, FileText, GitPullRequest, Ban, TrendingUp,
  ShieldAlert, UserCheck, ArrowUpRight, MapPin, Inbox,
} from 'lucide-react'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  CartesianGrid, Cell,
} from 'recharts'

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl shadow-xl px-4 py-3">
        <p className="text-sm font-bold text-gray-700 dark:text-gray-200 mb-1.5">{label}</p>
        {payload.map((p) => (
          <p key={p.name} style={{ color: p.fill }} className="text-sm font-semibold">
            {p.name}: <span className="font-extrabold">{p.value}</span>
          </p>
        ))}
      </div>
    )
  }
  return null
}

const RoleBadge = ({ role }) => {
  const map = {
    banned: { label: 'Bị khóa', cls: 'bg-red-50 dark:bg-red-950 text-red-500 ring-1 ring-red-100 dark:ring-red-900', icon: ShieldAlert },
    admin:  { label: 'Admin',   cls: 'bg-violet-50 dark:bg-violet-950 text-violet-600 dark:text-violet-400 ring-1 ring-violet-100 dark:ring-violet-900', icon: UserCheck },
  }
  const cfg = map[role] ?? { label: 'Người dùng', cls: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-100 dark:ring-emerald-900', icon: UserCheck }
  const Icon = cfg.icon
  return (
    <span className={`inline-flex items-center gap-1 text-xs font-bold px-2.5 py-1 rounded-full flex-shrink-0 ${cfg.cls}`}>
      <Icon size={11} />
      {cfg.label}
    </span>
  )
}

const EmptyState = ({ label }) => (
  <div className="flex flex-col items-center justify-center py-8 text-center">
    <div className="w-10 h-10 rounded-2xl bg-gray-50 dark:bg-gray-800 flex items-center justify-center mb-3">
      <Inbox size={18} className="text-gray-300 dark:text-gray-600" />
    </div>
    <p className="text-sm font-semibold text-gray-400 dark:text-gray-500">{label}</p>
    <p className="text-xs text-gray-300 dark:text-gray-600 mt-0.5">Dữ liệu sẽ xuất hiện ở đây</p>
  </div>
)

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
    {
      label: 'Tổng người dùng',
      value: stats.users,
      icon: Users,
      color: 'text-primary',
      bg: 'bg-primary-light dark:bg-primary/20',
      border: 'border-primary/15',
      ring: 'ring-1 ring-primary/10',
      trend: '+12% tháng này',
      trendColor: 'text-emerald-500',
    },
    {
      label: 'Bài đăng phòng',
      value: stats.posts,
      icon: FileText,
      color: 'text-emerald-600 dark:text-emerald-400',
      bg: 'bg-emerald-50 dark:bg-emerald-950',
      border: 'border-emerald-100 dark:border-emerald-900',
      ring: '',
      trend: '+5% tháng này',
      trendColor: 'text-emerald-500',
    },
    {
      label: 'Yêu cầu ghép phòng',
      value: stats.requests,
      icon: GitPullRequest,
      color: 'text-amber-600 dark:text-amber-400',
      bg: 'bg-amber-50 dark:bg-amber-950',
      border: 'border-amber-100 dark:border-amber-900',
      ring: '',
      trend: 'Đang chờ xử lý',
      trendColor: 'text-amber-500',
    },
    {
      label: 'Tài khoản bị khóa',
      value: stats.banned,
      icon: Ban,
      color: 'text-red-500',
      bg: 'bg-red-50 dark:bg-red-950',
      border: 'border-red-100 dark:border-red-900',
      ring: '',
      trend: 'Cần xem xét',
      trendColor: 'text-red-400',
    },
  ]

  const chartData = [
    { name: 'Người dùng', value: stats.users, fill: '#2F6BFF' },
    { name: 'Bài đăng', value: stats.posts, fill: '#10b981' },
    { name: 'Yêu cầu', value: stats.requests, fill: '#f59e0b' },
    { name: 'Bị khóa', value: stats.banned, fill: '#ef4444' },
  ]

  return (
    <div className="space-y-8">
      {/* Page header */}
      <div className="flex items-end justify-between">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white leading-tight">Bảng điều khiển</h1>
          <p className="text-gray-400 dark:text-gray-500 text-sm font-medium mt-1.5">
            Dữ liệu hệ thống RoomMate cập nhật theo thời gian thực.
          </p>
        </div>
        <div className="flex items-center gap-2 text-sm font-semibold text-gray-500 dark:text-gray-400
          bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 rounded-2xl px-4 py-2.5 shadow-sm">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <TrendingUp size={14} className="text-primary" />
          Cập nhật theo thời gian thực
        </div>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-4 gap-5">
        {statCards.map((s) => (
          <div
            key={s.label}
            className={`group bg-white dark:bg-gray-900 rounded-2xl border ${s.border} ${s.ring} shadow-sm p-6
              hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200 ease-in-out cursor-default`}
          >
            <div className="flex items-start justify-between mb-5">
              <div className={`w-11 h-11 rounded-xl ${s.bg} flex items-center justify-center`}>
                <s.icon size={20} className={s.color} />
              </div>
              <span className={`flex items-center gap-1 text-xs font-bold ${s.trendColor}`}>
                <ArrowUpRight size={12} />
                {s.trend}
              </span>
            </div>
            <p className={`text-5xl font-extrabold ${s.color} leading-none mb-2 tabular-nums`}>{s.value}</p>
            <p className="text-sm font-semibold text-gray-400 dark:text-gray-500">{s.label}</p>
          </div>
        ))}
      </div>

      {/* Chart + Lists */}
      <div className="grid grid-cols-5 gap-5">
        {/* Bar chart */}
        <div className="col-span-3 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-base font-bold text-gray-800 dark:text-gray-100">Thống kê tổng quan</h2>
              <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-0.5">Phân bổ dữ liệu theo danh mục</p>
            </div>
            <span className="text-xs font-semibold text-gray-400 bg-gray-50 dark:bg-gray-800
              border border-gray-100 dark:border-gray-700 rounded-xl px-3 py-1.5">
              Tháng hiện tại
            </span>
          </div>
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={chartData} barSize={40} barGap={8}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
              <XAxis dataKey="name" tick={{ fontSize: 12, fill: '#9ca3af', fontWeight: 600 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 12, fill: '#d1d5db', fontWeight: 600 }} axisLine={false} tickLine={false} width={28} />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: '#f9fafb', rx: 8 }} />
              <Bar dataKey="value" radius={[8, 8, 0, 0]}>
                {chartData.map((entry, index) => (
                  <Cell key={index} fill={entry.fill} fillOpacity={0.9} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="flex items-center gap-5 mt-5 pt-4 border-t border-gray-50 dark:border-gray-800">
            {chartData.map(d => (
              <div key={d.name} className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: d.fill }} />
                <span className="text-xs font-semibold text-gray-400 dark:text-gray-500">{d.name}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Side lists */}
        <div className="col-span-2 space-y-5">
          {/* Recent users */}
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-sm font-bold text-gray-800 dark:text-gray-100">Người dùng mới</h2>
                <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-0.5">5 tài khoản gần nhất</p>
              </div>
              <button className="text-xs font-bold text-primary hover:text-primary-dark transition-colors cursor-pointer flex items-center gap-0.5">
                Xem tất cả <ArrowUpRight size={11} />
              </button>
            </div>
            <div className="space-y-1">
              {recentUsers.length === 0
                ? <EmptyState label="Chưa có người dùng" />
                : recentUsers.map(u => (
                  <div
                    key={u.id}
                    className="flex items-center gap-3 px-2.5 py-2 rounded-xl
                      hover:bg-gray-50 dark:hover:bg-gray-800 hover:scale-[1.01]
                      transition-all duration-150 ease-in-out cursor-pointer group/item"
                  >
                    <div className="w-8 h-8 rounded-full bg-primary-light dark:bg-primary/20 flex items-center justify-center
                      text-primary font-extrabold text-xs flex-shrink-0
                      group-hover/item:ring-2 group-hover/item:ring-primary/20 transition-all">
                      {u.fullName?.[0]?.toUpperCase() ?? '?'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-bold text-gray-800 dark:text-gray-100 truncate leading-tight">
                        {u.fullName ?? 'Không có tên'}
                      </p>
                      <p className="text-xs font-medium text-gray-400 dark:text-gray-500 truncate mt-0.5">{u.email}</p>
                    </div>
                    <RoleBadge role={u.role} />
                  </div>
                ))
              }
            </div>
          </div>

          {/* Recent posts */}
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-sm font-bold text-gray-800 dark:text-gray-100">Bài đăng mới</h2>
                <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-0.5">5 bài đăng gần nhất</p>
              </div>
              <button className="text-xs font-bold text-primary hover:text-primary-dark transition-colors cursor-pointer flex items-center gap-0.5">
                Xem tất cả <ArrowUpRight size={11} />
              </button>
            </div>
            <div className="space-y-1">
              {recentPosts.length === 0
                ? <EmptyState label="Chưa có bài đăng" />
                : recentPosts.map(p => (
                  <div
                    key={p.id}
                    className="flex items-center gap-3 px-2.5 py-2 rounded-xl
                      hover:bg-gray-50 dark:hover:bg-gray-800 hover:scale-[1.01]
                      transition-all duration-150 ease-in-out cursor-pointer"
                  >
                    <div className="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-950 flex items-center justify-center
                      text-emerald-500 dark:text-emerald-400 flex-shrink-0">
                      <FileText size={14} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-bold text-gray-800 dark:text-gray-100 truncate leading-tight">{p.title}</p>
                      <p className="text-xs font-medium text-gray-400 dark:text-gray-500 truncate mt-0.5 flex items-center gap-1">
                        <MapPin size={10} />
                        {p.location ?? p.province ?? 'Chưa cập nhật'}
                      </p>
                    </div>
                    <span className="text-xs font-extrabold text-primary flex-shrink-0
                      bg-primary-light dark:bg-primary/20 px-2.5 py-1 rounded-full whitespace-nowrap">
                      {p.price?.toLocaleString('vi-VN')}đ
                    </span>
                  </div>
                ))
              }
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
