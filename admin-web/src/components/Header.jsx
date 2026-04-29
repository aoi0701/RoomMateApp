import { Search, Bell, Settings, Sun, Moon } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useTheme } from '../context/ThemeContext'

export default function Header({ placeholder = 'Tìm kiếm...' }) {
  const { user } = useAuth()
  const { dark, toggle } = useTheme()
  const initials = user?.displayName?.[0]?.toUpperCase() ?? 'A'

  return (
    <header className="h-14 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700
      flex items-center px-6 gap-4 fixed top-0 left-56 right-0 z-10">
      <div className="flex-1 relative max-w-xs">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        <input
          type="text"
          placeholder={placeholder}
          className="w-full pl-9 pr-4 py-1.5 text-sm
            bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700
            text-gray-700 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500
            rounded-lg outline-none focus:border-primary focus:ring-2 focus:ring-primary/10
            transition-all duration-150"
        />
      </div>

      <div className="flex items-center gap-1 ml-auto">
        <button
          onClick={toggle}
          title={dark ? 'Light mode' : 'Dark mode'}
          className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200
            hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-all cursor-pointer"
        >
          {dark ? <Sun size={16} /> : <Moon size={16} />}
        </button>
        <button className="relative p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200
          hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-all cursor-pointer">
          <Bell size={16} />
          <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 bg-red-500 rounded-full" />
        </button>
        <button className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200
          hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-all cursor-pointer">
          <Settings size={16} />
        </button>
        <div className="w-7 h-7 rounded-full bg-primary flex items-center justify-center text-white
          font-semibold text-xs ml-1 cursor-pointer">
          {initials}
        </div>
      </div>
    </header>
  )
}
