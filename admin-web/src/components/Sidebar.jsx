import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard, Users, FileText, Wallet,
  SlidersHorizontal, Image, HelpCircle, AlertTriangle, LogOut,
} from 'lucide-react'
import { useAuth } from '../context/AuthContext'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Bảng điều khiển' },
  { to: '/users', icon: Users, label: 'Người dùng' },
  { to: '/posts', icon: FileText, label: 'Bài viết' },
  { to: '/expenses', icon: Wallet, label: 'Chi phí' },
  { to: '/criteria', icon: SlidersHorizontal, label: 'Tiêu chí' },
  { to: '/media', icon: Image, label: 'Đa phương tiện' },
  { to: '/support', icon: HelpCircle, label: 'Hỗ trợ' },
  { to: '/violations', icon: AlertTriangle, label: 'Vi phạm' },
]

export default function Sidebar() {
  const { user, logout } = useAuth()

  return (
    <aside className="w-56 min-h-screen bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700
      flex flex-col fixed left-0 top-0 bottom-0">
      {/* Logo */}
      <div className="px-5 h-14 flex items-center border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center flex-shrink-0">
            <span className="text-white font-bold text-xs">R</span>
          </div>
          <span className="text-sm font-bold text-gray-900 dark:text-white">RoomMate</span>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-3 space-y-0.5 overflow-y-auto">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-all duration-150 ${
                isActive
                  ? 'bg-blue-50 dark:bg-primary/10 text-primary font-semibold'
                  : 'text-gray-500 dark:text-gray-400 font-medium hover:bg-gray-50 dark:hover:bg-gray-700 hover:text-gray-800 dark:hover:text-gray-200'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <Icon size={16} className={isActive ? 'text-primary' : 'text-gray-400 dark:text-gray-500'} />
                {label}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Bottom */}
      <div className="border-t border-gray-200 dark:border-gray-700 p-3 space-y-1">
        <div className="flex items-center gap-2.5 px-3 py-2 rounded-lg">
          <div className="w-7 h-7 rounded-full bg-primary flex items-center justify-center text-white font-semibold text-xs flex-shrink-0">
            {user?.displayName?.[0]?.toUpperCase() ?? 'A'}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-gray-800 dark:text-gray-100 truncate">
              {user?.displayName ?? user?.email}
            </p>
            <p className="text-[11px] text-gray-400 dark:text-gray-500">Quản trị viên</p>
          </div>
        </div>
        <button
          onClick={logout}
          className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm font-medium
            text-gray-500 dark:text-gray-400 hover:bg-red-50 dark:hover:bg-red-950/50 hover:text-red-500
            transition-all duration-150 cursor-pointer"
        >
          <LogOut size={15} />
          Đăng xuất
        </button>
      </div>
    </aside>
  )
}
