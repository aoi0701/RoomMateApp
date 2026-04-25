import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { X, Check, RotateCcw, Info } from 'lucide-react'
import { db } from '../firebase'
import {
  compareByDateDesc,
  displayText,
  formatDateTime,
  getFirstText,
  getImageUrl,
  matchesKeywords,
} from '../utils/firestoreDisplay'

const tabs = ['Tat ca', 'Cho phe duyet', 'Da gan co', 'Da phe duyet']

const statusBadge = {
  pending: 'bg-orange-100 text-orange-600',
  approved: 'bg-green-100 text-green-600',
  flagged: 'bg-red-100 text-red-600',
  default: 'bg-gray-100 text-gray-600',
}

export default function Media() {
  const [posts, setPosts] = useState([])
  const [users, setUsers] = useState([])
  const [activeTab, setActiveTab] = useState('Tat ca')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let readyCount = 0
    const markReady = () => {
      readyCount += 1
      if (readyCount >= 2) setLoading(false)
    }

    const unsubPosts = onSnapshot(
      collection(db, 'posts'),
      snap => {
        setPosts(snap.docs.map(docItem => ({ id: docItem.id, ...docItem.data() })))
        markReady()
      },
      snapshotError => {
        setError(snapshotError.message || 'Khong the tai du lieu media.')
        markReady()
      },
    )

    const unsubUsers = onSnapshot(
      collection(db, 'users'),
      snap => {
        setUsers(snap.docs.map(docItem => ({ id: docItem.id, ...docItem.data() })))
        markReady()
      },
      snapshotError => {
        setError(prev => prev || snapshotError.message || 'Khong the tai du lieu nguoi dung.')
        markReady()
      },
    )

    return () => {
      unsubPosts()
      unsubUsers()
    }
  }, [])

  const usersMap = useMemo(() => {
    return users.reduce((accumulator, user) => {
      accumulator[user.id] = user
      return accumulator
    }, {})
  }, [users])

  const mediaItems = useMemo(() => {
    return posts
      .flatMap(post => {
        const imageUrls = Array.isArray(post?.imageUrls) && post.imageUrls.length > 0
          ? post.imageUrls
            .filter(url => typeof url === 'string')
            .map(url => url.trim())
            .filter(Boolean)
          : getImageUrl(post, ['imageUrl'])
            ? [getImageUrl(post, ['imageUrl'])]
            : []

        return imageUrls.map((url, index) => {
          const owner = usersMap?.[post?.ownerId] ?? {}
          const rawStatus = getFirstText(post, ['mediaStatus', 'moderationStatus'])
          const status =
            matchesKeywords(rawStatus, ['pending', 'cho']) ? 'pending' :
            matchesKeywords(rawStatus, ['flag', 'report', 'vi pham']) ? 'flagged' :
            matchesKeywords(rawStatus, ['approved', 'duyet']) ? 'approved' :
            ''

          return {
            id: `${post.id}-${index}`,
            imageUrl: url,
            type: getFirstText(post, ['mediaType', 'fileType']),
            user: getFirstText(owner, ['fullName', 'displayName']),
            title: getFirstText(post, ['title']),
            time: post?.createdAt || post?.updatedAt,
            status,
            rawStatus,
            note: getFirstText(post, ['moderationNote', 'flagReason']),
          }
        })
      })
      .sort((left, right) => compareByDateDesc(left, right, ['time']))
  }, [posts, usersMap])

  const filtered = useMemo(() => {
    return mediaItems.filter(item => {
      if (activeTab === 'Cho phe duyet') return item.status === 'pending'
      if (activeTab === 'Da gan co') return item.status === 'flagged'
      if (activeTab === 'Da phe duyet') return item.status === 'approved'
      return true
    })
  }, [activeTab, mediaItems])

  const pendingCount = mediaItems.filter(item => item.status === 'pending').length
  const flaggedCount = mediaItems.filter(item => item.status === 'flagged').length
  const approvedCount = mediaItems.filter(item => item.status === 'approved').length

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Quan ly noi dung</h1>
          <p className="text-gray-500 text-sm mt-1">Tong hop hinh anh dang co trong Firestore tu bai dang.</p>
        </div>
        <div className="flex rounded-lg border border-gray-200 overflow-hidden">
          {tabs.map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 text-sm font-medium transition-colors ${
                activeTab === tab ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-50'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center text-gray-400">Dang tai...</div>
      ) : error ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center text-red-500">{error}</div>
      ) : filtered.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center text-gray-400">No data available</div>
      ) : (
        <div className="grid grid-cols-4 gap-4">
          {filtered.map(item => {
            const badgeClass = statusBadge[item.status] || statusBadge.default
            return (
              <div key={item.id} className={`bg-white rounded-xl border shadow-sm overflow-hidden ${item.status === 'flagged' ? 'border-red-200' : 'border-gray-100'}`}>
                <div className="relative">
                  {item.imageUrl ? (
                    <img src={item.imageUrl} alt="" className="w-full h-36 object-cover" />
                  ) : (
                    <div className="w-full h-36 bg-gray-100 flex items-center justify-center text-sm text-gray-400">—</div>
                  )}
                  <span className="absolute top-2 left-2 text-xs font-bold bg-blue-600/90 text-white px-2 py-0.5 rounded">
                    {displayText(item.type)}
                  </span>
                </div>
                <div className="p-3">
                  <div className="flex items-center gap-1.5 mb-1">
                    <div className="w-5 h-5 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 text-xs font-bold">
                      {item.user?.[0]?.toUpperCase() || '—'}
                    </div>
                    <span className="text-xs font-semibold text-gray-700 truncate">{displayText(item.user)}</span>
                  </div>
                  <p className="text-xs text-gray-500 truncate">{displayText(item.title)}</p>
                  <p className="text-xs text-gray-400">Da tai len {formatDateTime(item.time)}</p>
                  {item.note ? <p className="text-xs text-red-500 font-medium mt-1">{item.note}</p> : null}
                  <div className="flex items-center gap-1.5 mt-3">
                    {item.status === 'approved' ? (
                      <button className="p-1.5 text-gray-400 hover:bg-gray-100 rounded"><RotateCcw size={14} /></button>
                    ) : (
                      <>
                        <button className="p-1.5 text-red-500 hover:bg-red-50 rounded border border-red-200"><X size={14} /></button>
                        <button className="p-1.5 text-green-500 hover:bg-green-50 rounded border border-green-200"><Check size={14} /></button>
                      </>
                    )}
                    {item.status === 'flagged' && (
                      <button className="p-1.5 text-gray-500 hover:bg-gray-100 rounded border border-gray-200"><Info size={14} /></button>
                    )}
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ml-auto ${badgeClass}`}>
                      {displayText(item.rawStatus)}
                    </span>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800">Tong quan kiem duyet</h3>
          <p className="text-sm text-gray-500 mt-1">So lieu ben duoi duoc tinh truc tiep tu hinh anh dang co trong Firestore.</p>
          <div className="grid grid-cols-3 gap-4 mt-4">
            {[
              { label: 'HANG DOI', value: pendingCount },
              { label: 'CO BAO', value: flaggedCount, red: true },
              { label: 'TONG CONG', value: mediaItems.length },
            ].map(stat => (
              <div key={stat.label} className="text-center">
                <p className="text-xs text-gray-500 font-semibold">{stat.label}</p>
                <p className={`text-2xl font-bold mt-1 ${stat.red ? 'text-red-500' : 'text-gray-900'}`}>{stat.value}</p>
              </div>
            ))}
          </div>
          <div className="mt-4 bg-blue-600 rounded-lg p-3 text-center">
            <p className="text-xs text-blue-100 font-semibold">DA PHE DUYET</p>
            <p className="text-white font-bold text-sm mt-0.5">{approvedCount}</p>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Lich su moi nhat</p>
          {mediaItems.length === 0 ? (
            <p className="text-sm text-gray-400">No data available</p>
          ) : (
            <div className="space-y-2">
              {mediaItems.slice(0, 5).map(item => (
                <div key={item.id} className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${item.status === 'flagged' ? 'bg-red-500' : item.status === 'approved' ? 'bg-green-500' : 'bg-yellow-500'} flex-shrink-0`} />
                  <span className="text-xs text-gray-700 flex-1 truncate">{displayText(item.title)}</span>
                  <span className="text-xs text-gray-400">{formatDateTime(item.time)}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
