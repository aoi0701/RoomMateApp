import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { db } from '../firebase'
import { Users, FileText, GitPullRequest, Ban } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import {
  EMPTY_VALUE,
  compareByDateDesc,
  displayText,
  formatCurrency,
  getFirstNumber,
  getFirstText,
} from '../utils/firestoreDisplay'

export default function Dashboard() {
  const [users, setUsers] = useState([])
  const [posts, setPosts] = useState([])
  const [requests, setRequests] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let readyCount = 0

    const markReady = () => {
      readyCount += 1
      if (readyCount >= 3) setLoading(false)
    }

    const unsubUsers = onSnapshot(
      collection(db, 'users'),
      snap => {
        setUsers(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })))
        markReady()
      },
      snapshotError => {
        setError(snapshotError.message || 'Khong the tai du lieu nguoi dung.')
        markReady()
      },
    )

    const unsubPosts = onSnapshot(
      collection(db, 'posts'),
      snap => {
        setPosts(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })))
        markReady()
      },
      snapshotError => {
        setError(prev => prev || snapshotError.message || 'Khong the tai du lieu bai dang.')
        markReady()
      },
    )

    const unsubRequests = onSnapshot(
      collection(db, 'roommate_requests'),
      snap => {
        setRequests(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })))
        markReady()
      },
      snapshotError => {
        setError(prev => prev || snapshotError.message || 'Khong the tai du lieu yeu cau.')
        markReady()
      },
    )

    return () => {
      unsubUsers()
      unsubPosts()
      unsubRequests()
    }
  }, [])

  const stats = useMemo(() => {
    const banned = users.filter(user => getFirstText(user, ['role']).toLowerCase() === 'banned').length
    return {
      users: users.length,
      posts: posts.length,
      requests: requests.length,
      banned,
    }
  }, [posts, requests, users])

  const recentUsers = useMemo(
    () => [...users].sort((left, right) => compareByDateDesc(left, right)).slice(0, 5),
    [users],
  )
  const recentPosts = useMemo(
    () => [...posts].sort((left, right) => compareByDateDesc(left, right)).slice(0, 5),
    [posts],
  )

  const statCards = [
    { label: 'Tong nguoi dung', value: stats.users, icon: Users, color: 'text-blue-600', bg: 'bg-blue-50' },
    { label: 'Bai dang', value: stats.posts, icon: FileText, color: 'text-green-600', bg: 'bg-green-50' },
    { label: 'Yeu cau ghep phong', value: stats.requests, icon: GitPullRequest, color: 'text-purple-600', bg: 'bg-purple-50' },
    { label: 'Tai khoan bi khoa', value: stats.banned, icon: Ban, color: 'text-red-600', bg: 'bg-red-50' },
  ]

  const chartData = statCards
    .map(card => ({ name: card.label, value: card.value }))
    .filter(item => item.value > 0)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Bang dieu khien</h1>
        <p className="text-gray-500 text-sm mt-1">Tong quan he thong RoomMate theo du lieu Firestore hien tai.</p>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {statCards.map(card => (
          <div key={card.label} className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{card.label}</p>
              <div className={`w-9 h-9 rounded-lg ${card.bg} flex items-center justify-center`}>
                <card.icon size={18} className={card.color} />
              </div>
            </div>
            <p className={`text-3xl font-bold ${card.color}`}>{card.value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h2 className="font-semibold text-gray-800 mb-4">Thong ke tong quan</h2>
          {loading ? (
            <div className="h-[200px] flex items-center justify-center text-sm text-gray-400">Dang tai...</div>
          ) : error ? (
            <div className="h-[200px] flex items-center justify-center text-sm text-red-500">{error}</div>
          ) : chartData.length === 0 ? (
            <div className="h-[200px] flex items-center justify-center text-sm text-gray-400">No data available</div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={chartData}>
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} allowDecimals={false} />
                <Tooltip />
                <Bar dataKey="value" fill="#2563EB" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h2 className="font-semibold text-gray-800 mb-3">Nguoi dung moi nhat</h2>
            {loading ? (
              <p className="text-sm text-gray-400">Dang tai...</p>
            ) : error ? (
              <p className="text-sm text-red-500">{error}</p>
            ) : recentUsers.length === 0 ? (
              <p className="text-sm text-gray-400">No data available</p>
            ) : (
              <div className="space-y-2">
                {recentUsers.map(user => {
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
                    <div key={user.id} className="flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-sm flex-shrink-0">
                        {fullName?.[0]?.toUpperCase() || EMPTY_VALUE}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-800 truncate">{displayText(fullName)}</p>
                        <p className="text-xs text-gray-400 truncate">{displayText(user?.email)}</p>
                      </div>
                      <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${roleClass}`}>
                        {displayText(role)}
                      </span>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h2 className="font-semibold text-gray-800 mb-3">Bai dang moi nhat</h2>
            {loading ? (
              <p className="text-sm text-gray-400">Dang tai...</p>
            ) : error ? (
              <p className="text-sm text-red-500">{error}</p>
            ) : recentPosts.length === 0 ? (
              <p className="text-sm text-gray-400">No data available</p>
            ) : (
              <div className="space-y-2">
                {recentPosts.map(post => (
                  <div key={post.id} className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center text-gray-500 flex-shrink-0">
                      <FileText size={14} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-800 truncate">
                        {displayText(getFirstText(post, ['title']))}
                      </p>
                      <p className="text-xs text-gray-400 truncate">
                        {displayText(getFirstText(post, ['location', 'province', 'district']))}
                      </p>
                    </div>
                    <span className="text-xs font-semibold text-blue-600 flex-shrink-0">
                      {formatCurrency(getFirstNumber(post, ['price']))}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
