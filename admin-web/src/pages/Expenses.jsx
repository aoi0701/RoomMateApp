import { useEffect, useMemo, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { Download, AlertTriangle, MoreVertical, RotateCcw } from 'lucide-react'
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts'
import { db } from '../firebase'
import {
  compareByDateDesc,
  displayText,
  formatCurrency,
  formatDateTime,
  getFirstNumber,
  getFirstText,
  matchesKeywords,
} from '../utils/firestoreDisplay'

const tabs = ['Tat ca chi phi', 'Dang cho', 'Bi gan co']

const pieColors = ['#2563EB', '#E2E8F0', '#EF4444', '#10B981', '#F59E0B']

function statusClasses(status) {
  if (matchesKeywords(status, ['dispute', 'flag', 'tranh chap'])) {
    return 'text-red-500'
  }
  if (matchesKeywords(status, ['pending', 'cho'])) {
    return 'text-yellow-600'
  }
  if (matchesKeywords(status, ['paid', 'done', 'complete', 'resolved', 'da thanh toan', 'hoan tat'])) {
    return 'text-green-600'
  }
  return 'text-gray-500'
}

export default function Expenses() {
  const [expenses, setExpenses] = useState([])
  const [activeTab, setActiveTab] = useState('Tat ca chi phi')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, 'expenses'),
      snap => {
        const nextExpenses = snap.docs
          .map(docItem => ({ id: docItem.id, ...docItem.data() }))
          .sort((left, right) => compareByDateDesc(left, right))
        setExpenses(nextExpenses)
        setLoading(false)
        setError('')
      },
      snapshotError => {
        setError(snapshotError.message || 'Khong the tai du lieu chi phi.')
        setLoading(false)
      },
    )

    return unsub
  }, [])

  const filtered = useMemo(() => {
    return expenses.filter(expense => {
      const status = getFirstText(expense, ['status'])
      if (activeTab === 'Dang cho') return matchesKeywords(status, ['pending', 'cho'])
      if (activeTab === 'Bi gan co') {
        return matchesKeywords(status, ['flag', 'dispute', 'tranh chap'])
      }
      return true
    })
  }, [activeTab, expenses])

  const totalAmount = expenses.reduce((sum, expense) => sum + (getFirstNumber(expense, ['amount', 'totalAmount', 'price']) ?? 0), 0)
  const flaggedCount = expenses.filter(expense => {
    const status = getFirstText(expense, ['status'])
    return matchesKeywords(status, ['flag', 'dispute', 'tranh chap'])
  }).length

  const pieData = useMemo(() => {
    const grouped = expenses.reduce((accumulator, expense) => {
      const method = getFirstText(expense, ['splitMethod', 'method', 'type']) || '—'
      accumulator[method] = (accumulator[method] ?? 0) + 1
      return accumulator
    }, {})

    return Object.entries(grouped).map(([name, value], index) => ({
      name,
      value,
      color: pieColors[index % pieColors.length],
    }))
  }, [expenses])

  const recentActivity = expenses.slice(0, 5)

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Quan ly Chi tieu</h1>
          <p className="text-gray-500 text-sm mt-1">Tong quan du lieu chi phi hien co trong Firestore.</p>
        </div>
        <div className="flex gap-2">
          <button className="flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-lg text-sm font-medium text-gray-600 hover:bg-gray-50">
            <Download size={15} /> Xuat CSV
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-red-500 text-white rounded-lg text-sm font-semibold hover:bg-red-600">
            <AlertTriangle size={15} /> Xem tranh chap
          </button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Tong thanh toan</p>
          <p className="text-4xl font-bold text-gray-900 mt-2">{formatCurrency(totalAmount)}</p>
          <p className="text-sm text-gray-500 font-medium mt-2">{expenses.length} ban ghi chi phi</p>
        </div>
        <div className="bg-red-500 rounded-xl p-6 text-white">
          <p className="text-xs font-semibold text-red-200 uppercase tracking-wider">Muc can xem xet</p>
          <p className="text-5xl font-bold mt-2">{flaggedCount}</p>
          <p className="text-sm text-red-200 mt-2">Tinh tu cac trang thai dang tranh chap hoac bi gan co.</p>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 className="font-semibold text-gray-800">So cai chung</h2>
          <div className="flex gap-1">
            {tabs.map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-1.5 text-sm rounded-lg font-medium transition-colors ${
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
        ) : filtered.length === 0 ? (
          <div className="p-8 text-center text-gray-400">No data available</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100">
                {['Ten nhom', 'Tong so tien', 'Cach chia', 'Trang thai'].map(header => (
                  <th key={header} className="text-left text-xs font-semibold text-gray-500 uppercase tracking-wider px-5 py-3">
                    {header}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map(expense => {
                const title = getFirstText(expense, ['name', 'title', 'groupName'])
                const subtitle = getFirstText(expense, ['description', 'sub', 'note'])
                const method = getFirstText(expense, ['splitMethod', 'method', 'type'])
                const status = getFirstText(expense, ['status'])
                const amount = getFirstNumber(expense, ['amount', 'totalAmount', 'price'])
                return (
                  <tr key={expense.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center text-sm font-semibold flex-shrink-0">
                          {title?.[0]?.toUpperCase() || '—'}
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-gray-800">{displayText(title)}</p>
                          <p className="text-xs text-gray-400">{displayText(subtitle)}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-sm font-semibold text-gray-800">{formatCurrency(amount)}</td>
                    <td className="px-5 py-4">
                      <span className="text-xs border border-gray-200 px-2 py-1 rounded text-gray-600">{displayText(method)}</span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center justify-between">
                        <span className={`text-sm font-medium ${statusClasses(status)}`}>● {displayText(status)}</span>
                        {matchesKeywords(status, ['flag', 'dispute', 'tranh chap']) ? (
                          <button className="px-3 py-1 bg-red-600 text-white text-xs font-semibold rounded-lg hover:bg-red-700">Xem</button>
                        ) : (
                          <button className="p-1 text-gray-400"><MoreVertical size={15} /></button>
                        )}
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}

        <div className="px-5 py-3 border-t border-gray-100 flex items-center justify-between">
          <p className="text-sm text-gray-500">Hien thi {filtered.length} / {expenses.length} giao dich</p>
          <div className="text-xs text-gray-400">Realtime Firestore</div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800 mb-3">Lich su cap nhat</h3>
          {loading ? (
            <p className="text-sm text-gray-400">Dang tai...</p>
          ) : error ? (
            <p className="text-sm text-red-500">{error}</p>
          ) : recentActivity.length === 0 ? (
            <p className="text-sm text-gray-400">No data available</p>
          ) : (
            <div className="space-y-3">
              {recentActivity.map(expense => (
                <div key={expense.id} className="flex items-start gap-2.5">
                  <div className="w-2.5 h-2.5 rounded-full bg-blue-500 flex-shrink-0 mt-1.5" />
                  <div>
                    <p className="text-sm font-medium text-gray-800">{displayText(getFirstText(expense, ['name', 'title', 'groupName']))}</p>
                    <p className="text-xs text-gray-400">
                      {displayText(getFirstText(expense, ['status']))} · {formatDateTime(expense?.createdAt || expense?.updatedAt)}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800 mb-1">Phan bo cach chia</h3>
          <p className="text-xs text-blue-600 mb-2">Tinh tu truong splitMethod / method / type</p>
          {loading ? (
            <div className="h-[160px] flex items-center justify-center text-sm text-gray-400">Dang tai...</div>
          ) : error ? (
            <div className="h-[160px] flex items-center justify-center text-sm text-red-500">{error}</div>
          ) : pieData.length === 0 ? (
            <div className="h-[160px] flex items-center justify-center text-sm text-gray-400">No data available</div>
          ) : (
            <>
              <ResponsiveContainer width="100%" height={160}>
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={45} outerRadius={70} dataKey="value">
                    {pieData.map(item => <Cell key={item.name} fill={item.color} />)}
                  </Pie>
                  <Tooltip formatter={value => [value, 'So ban ghi']} />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex justify-center gap-4 mt-2 flex-wrap">
                {pieData.map(item => (
                  <div key={item.name} className="flex items-center gap-1.5">
                    <div className="w-3 h-3 rounded-full" style={{ background: item.color }} />
                    <span className="text-xs text-gray-600">{item.name}</span>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
