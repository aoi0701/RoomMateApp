import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query, doc, updateDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { AlertTriangle, Eye, CheckCircle, Ban, Clock, X } from 'lucide-react'

const STATUS = {
  pending:   { label: 'Chờ xử lý',    color: 'text-amber-600 dark:text-amber-400' },
  reviewing: { label: 'Đang xem xét', color: 'text-primary' },
  resolved:  { label: 'Đã giải quyết', color: 'text-emerald-600 dark:text-emerald-400' },
}

const SEVERITY_MAP = {
  'Nội dung không phù hợp': { label: 'Cao',      cls: 'bg-red-50 dark:bg-red-950 text-red-600 dark:text-red-400 ring-1 ring-red-100 dark:ring-red-900' },
  'Spam bài đăng':           { label: 'Trung bình', cls: 'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900' },
  'Thông tin sai lệch':      { label: 'Thấp',     cls: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-100 dark:ring-emerald-900' },
}

function getSeverity(type) {
  return SEVERITY_MAP[type] ?? { label: 'Trung bình', cls: 'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900' }
}

function timeAgo(ts) {
  if (!ts) return ''
  const diff = Math.floor((Date.now() - ts.toDate().getTime()) / 1000)
  if (diff < 60) return `${diff} giây trước`
  if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`
  if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`
  return `${Math.floor(diff / 86400)} ngày trước`
}

export default function Violations() {
  const [reports, setReports] = useState([])
  const [detail, setDetail] = useState(null)

  useEffect(() => {
    const q = query(collection(db, 'reports'), orderBy('createdAt', 'desc'))
    return onSnapshot(q, snap => {
      setReports(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    })
  }, [])

  const pending   = reports.filter(r => r.status === 'pending').length
  const reviewing = reports.filter(r => r.status === 'reviewing').length
  const resolved  = reports.filter(r => r.status === 'resolved').length

  async function setStatus(id, status) {
    await updateDoc(doc(db, 'reports', id), { status })
  }

  async function banUser(report) {
    if (!report.reportedUserId) return
    await updateDoc(doc(db, 'users', report.reportedUserId), { role: 'banned' })
    await setStatus(report.id, 'resolved')
    setDetail(null)
  }

  return (
    <div className="space-y-6">
      <div className="pb-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Quản lý Vi phạm</h1>
        <p className="text-sm text-gray-400 dark:text-gray-500 mt-1">Xem xét và xử lý các báo cáo vi phạm trong hệ thống.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Chờ xử lý',     value: pending,   color: 'text-red-500',                          icon: AlertTriangle },
          { label: 'Đang xem xét',  value: reviewing, color: 'text-amber-600 dark:text-amber-400',    icon: Clock },
          { label: 'Đã giải quyết', value: resolved,  color: 'text-emerald-600 dark:text-emerald-400', icon: CheckCircle },
        ].map(s => (
          <div key={s.label} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-5
            hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 cursor-default">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">{s.label}</p>
              <s.icon size={15} className={s.color} />
            </div>
            <p className={`text-4xl font-extrabold ${s.color} tabular-nums`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-700">
          <h2 className="text-base font-bold text-gray-800 dark:text-gray-100">Danh sách vi phạm</h2>
        </div>

        {reports.length === 0 ? (
          <div className="px-5 py-16 text-center text-gray-400 dark:text-gray-500 text-sm">
            Chưa có báo cáo nào
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100 dark:border-gray-700">
                {['Người bị báo cáo', 'Loại vi phạm', 'Thời gian', 'Mức độ', 'Trạng thái', 'Thao tác'].map(h => (
                  <th key={h} className="text-left text-xs font-extrabold text-gray-400 dark:text-gray-500
                    uppercase tracking-widest px-4 py-3.5">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-700">
              {reports.map(r => {
                const sv = getSeverity(r.type)
                const st = STATUS[r.status] ?? STATUS.pending
                return (
                  <tr key={r.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/60 transition-colors duration-100">
                    <td className="px-4 py-4 text-sm font-bold text-gray-800 dark:text-gray-100">
                      {r.reportedUserName ?? r.reportedUserId ?? '—'}
                    </td>
                    <td className="px-4 py-4 text-sm font-semibold text-gray-600 dark:text-gray-400">{r.type ?? '—'}</td>
                    <td className="px-4 py-4 text-xs font-semibold text-gray-400 dark:text-gray-500">{timeAgo(r.createdAt)}</td>
                    <td className="px-4 py-4">
                      <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${sv.cls}`}>{sv.label}</span>
                    </td>
                    <td className="px-4 py-4">
                      <span className={`text-sm font-bold ${st.color}`}>{st.label}</span>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex gap-1">
                        <button
                          onClick={() => setDetail(r)}
                          title="Xem chi tiết"
                          className="p-2 text-primary hover:bg-primary-light dark:hover:bg-primary/20
                            rounded-lg transition-all duration-150 active:scale-95 cursor-pointer">
                          <Eye size={15} />
                        </button>
                        <button
                          onClick={() => setStatus(r.id, 'resolved')}
                          title="Đánh dấu đã giải quyết"
                          className="p-2 text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-950
                            rounded-lg transition-all duration-150 active:scale-95 cursor-pointer">
                          <CheckCircle size={15} />
                        </button>
                        <button
                          onClick={() => banUser(r)}
                          title="Ban người dùng"
                          className="p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-950
                            rounded-lg transition-all duration-150 active:scale-95 cursor-pointer">
                          <Ban size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Detail modal */}
      {detail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setDetail(null)}>
          <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700
            shadow-2xl w-full max-w-md p-6 space-y-4"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">Chi tiết báo cáo</h3>
              <button onClick={() => setDetail(null)}
                className="p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">
                <X size={16} />
              </button>
            </div>
            <div className="space-y-2 text-sm">
              <Row label="Người bị báo cáo" value={detail.reportedUserName ?? detail.reportedUserId ?? '—'} />
              <Row label="Bài đăng"         value={detail.reportedPostId ?? '—'} />
              <Row label="Loại vi phạm"     value={detail.type ?? '—'} />
              <Row label="Mô tả"            value={detail.description ?? '—'} />
              <Row label="Trạng thái"       value={STATUS[detail.status]?.label ?? '—'} />
              <Row label="Thời gian"        value={detail.createdAt?.toDate().toLocaleString('vi-VN') ?? '—'} />
            </div>
            <div className="flex gap-2 pt-2">
              {detail.status !== 'reviewing' && (
                <button onClick={() => { setStatus(detail.id, 'reviewing'); setDetail(d => ({ ...d, status: 'reviewing' })) }}
                  className="flex-1 py-2 rounded-xl text-sm font-semibold border border-gray-200 dark:border-gray-700
                    text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition-all cursor-pointer">
                  Đang xem xét
                </button>
              )}
              {detail.status !== 'resolved' && (
                <button onClick={() => { setStatus(detail.id, 'resolved'); setDetail(null) }}
                  className="flex-1 py-2 rounded-xl text-sm font-semibold bg-emerald-500 text-white
                    hover:bg-emerald-600 transition-all cursor-pointer">
                  Giải quyết
                </button>
              )}
              <button onClick={() => banUser(detail)}
                className="flex-1 py-2 rounded-xl text-sm font-semibold bg-red-500 text-white
                  hover:bg-red-600 transition-all cursor-pointer">
                Ban người dùng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function Row({ label, value }) {
  return (
    <div className="flex gap-2">
      <span className="w-36 flex-shrink-0 text-gray-400 dark:text-gray-500 font-medium">{label}:</span>
      <span className="text-gray-800 dark:text-gray-100 font-semibold break-all">{value}</span>
    </div>
  )
}
