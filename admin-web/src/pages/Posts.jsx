import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot, doc, deleteDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { MapPin, Trash2, Search } from 'lucide-react'
import {
  compareByDateDesc,
  displayText,
  formatCurrency,
  formatNumber,
  getFirstNumber,
  getFirstText,
  getImageUrl,
  matchesSearch,
} from '../utils/firestoreDisplay'

export default function Posts() {
  const [posts, setPosts] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, 'posts'),
      snap => {
        const nextPosts = snap.docs
          .map(docItem => ({ id: docItem.id, ...docItem.data() }))
          .sort((left, right) => compareByDateDesc(left, right))
        setPosts(nextPosts)
        setLoading(false)
        setError('')
      },
      snapshotError => {
        setError(snapshotError.message || 'Khong the tai danh sach bai dang.')
        setLoading(false)
      },
    )
    return unsub
  }, [])

  const deletePost = async id => {
    if (window.confirm('Ban co chac muon xoa bai dang nay?')) {
      await deleteDoc(doc(db, 'posts', id))
    }
  }

  const filtered = useMemo(() => {
    return posts.filter(post => {
      return (
        matchesSearch(post?.title, search) ||
        matchesSearch(post?.location, search) ||
        matchesSearch(post?.province, search) ||
        matchesSearch(post?.district, search)
      )
    })
  }, [posts, search])

  const withImagesCount = posts.filter(post => getImageUrl(post, ['imageUrls', 'imageUrl'])).length
  const withLocationCount = posts.filter(post => getFirstText(post, ['location', 'district', 'province'])).length

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Quan ly Bai dang</h1>
        <p className="text-gray-500 text-sm mt-1">Xem va quan ly cac bai dang tim phong trong he thong.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Tong bai dang', value: posts.length, color: 'text-blue-600' },
          { label: 'Co hinh anh', value: withImagesCount, color: 'text-green-600' },
          { label: 'Co dia diem', value: withLocationCount, color: 'text-purple-600' },
        ].map(stat => (
          <div key={stat.label} className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{stat.label}</p>
            <p className={`text-3xl font-bold mt-1 ${stat.color}`}>{stat.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-4">
          <div className="relative flex-1 max-w-sm">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={event => setSearch(event.target.value)}
              placeholder="Tim tieu de hoac dia chi..."
              className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm outline-none focus:border-blue-400"
            />
          </div>
          <p className="text-sm text-gray-500 ml-auto">{filtered.length} bai dang</p>
        </div>

        {loading ? (
          <div className="p-8 text-center text-gray-400">Dang tai...</div>
        ) : error ? (
          <div className="p-8 text-center text-red-500">{error}</div>
        ) : (
          <div className="divide-y divide-gray-50">
            {filtered.length === 0 && (
              <div className="p-8 text-center text-gray-400">No data available</div>
            )}
            {filtered.map(post => {
              const imageUrl = getImageUrl(post, ['imageUrls', 'imageUrl'])
              const location = [getFirstText(post, ['location']), getFirstText(post, ['district']), getFirstText(post, ['province'])]
                .filter(Boolean)
                .join(', ')
              return (
                <div key={post.id} className="flex items-center gap-4 px-5 py-4 hover:bg-gray-50 transition-colors">
                  {imageUrl ? (
                    <img src={imageUrl} alt="" className="w-16 h-12 object-cover rounded-lg flex-shrink-0" />
                  ) : (
                    <div className="w-16 h-12 bg-gray-100 rounded-lg flex-shrink-0 flex items-center justify-center text-xs text-gray-400">
                      —
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-800 truncate">{displayText(post?.title)}</p>
                    <div className="flex items-center gap-1 mt-0.5">
                      <MapPin size={11} className="text-gray-400" />
                      <p className="text-xs text-gray-400 truncate">{displayText(location)}</p>
                    </div>
                    <div className="flex items-center gap-3 mt-1">
                      <span className="text-xs text-blue-600 font-semibold">{formatCurrency(getFirstNumber(post, ['price']))}/thang</span>
                      <span className="text-xs text-gray-400">{formatNumber(getFirstNumber(post, ['area']))}m2</span>
                      <span className="text-xs text-gray-400">{displayText(getFirstText(post, ['roomType']))}</span>
                    </div>
                  </div>
                  <button
                    onClick={() => deletePost(post.id)}
                    className="p-2 text-red-400 hover:bg-red-50 rounded-lg transition-colors flex-shrink-0"
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
