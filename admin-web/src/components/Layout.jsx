import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import Header from './Header'

export default function Layout() {
  return (
    <div className="flex min-h-screen bg-gray-50 dark:bg-gray-800">
      <Sidebar />
      <div className="flex-1 ml-56">
        <Header />
        <main className="pt-20 px-8 pb-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
