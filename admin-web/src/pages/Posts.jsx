import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query, doc, deleteDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { MapPin, Trash2, Search } from 'lucide-react'

export default function Posts() {
  const [posts, setPosts] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, snap => {
      setPosts(snap.docs.map(d => ({ id: d.id, ...d.data() })))
      setLoading(false)
    })
    return unsub
  }, [])

  const deletePost = async (id) => {
    if (confirm('Bạn có chắc muốn xóa bài đăng này?')) {
      await deleteDoc(doc(db, 'posts', id))
    }
  }

  const filtered = posts.filter(p =>
    (p.title ?? '').toLowerCase().includes(search.toLowerCase()) ||
    (p.location ?? '').toLowerCase().includes(search.toLowerCase()) ||
    (p.province ?? '').toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Quản lý Bài đăng</h1>
        <p className="text-gray-500 text-sm mt-1">Xem và quản lý các bài đăng tìm phòng trong hệ thống.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Tổng bài đăng', value: posts.length, color: 'text-blue-600' },
          { label: 'Hà Nội', value: posts.filter(p => (p.province ?? '').toLowerCase().includes('hà nội')).length, color: 'text-green-600' },
          { label: 'TP. HCM', value: posts.filter(p => (p.province ?? '').toLowerCase().includes('hồ chí minh')).length, color: 'text-purple-600' },
        ].map(s => (
          <div key={s.label} className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{s.label}</p>
            <p className={`text-3xl font-bold mt-1 ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-4">
          <div className="relative flex-1 max-w-sm">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Tìm tiêu đề hoặc địa chỉ..."
              className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm outline-none focus:border-blue-400"
            />
          </div>
          <p className="text-sm text-gray-500 ml-auto">{filtered.length} bài đăng</p>
        </div>

        {loading ? (
          <div className="p-8 text-center text-gray-400">Đang tải...</div>
        ) : (
          <div className="divide-y divide-gray-50">
            {filtered.length === 0 && (
              <div className="p-8 text-center text-gray-400">Không có bài đăng nào</div>
            )}
            {filtered.map(p => (
              <div key={p.id} className="flex items-center gap-4 px-5 py-4 hover:bg-gray-50 transition-colors">
                {p.imageUrls?.[0] || p.imageUrl ? (
                  <img src={p.imageUrls?.[0] ?? p.imageUrl} alt="" className="w-16 h-12 object-cover rounded-lg flex-shrink-0" />
                ) : (
                  <div className="w-16 h-12 bg-gray-100 rounded-lg flex-shrink-0" />
                )}
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-800 truncate">{p.title}</p>
                  <div className="flex items-center gap-1 mt-0.5">
                    <MapPin size={11} className="text-gray-400" />
                    <p className="text-xs text-gray-400 truncate">{p.location ?? `${p.district}, ${p.province}`}</p>
                  </div>
                  <div className="flex items-center gap-3 mt-1">
                    <span className="text-xs text-blue-600 font-semibold">{p.price?.toLocaleString('vi-VN')}đ/tháng</span>
                    <span className="text-xs text-gray-400">{p.area}m²</span>
                    <span className="text-xs text-gray-400">{p.roomType}</span>
                  </div>
                </div>
                <button onClick={() => deletePost(p.id)}
                  className="p-2 text-red-400 hover:bg-red-50 rounded-lg transition-colors flex-shrink-0">
                  <Trash2 size={15} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
