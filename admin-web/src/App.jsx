import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Users from './pages/Users'
import Posts from './pages/Posts'
import Expenses from './pages/Expenses'
import Criteria from './pages/Criteria'
import Media from './pages/Media'
import Support from './pages/Support'
import Violations from './pages/Violations'

function ProtectedRoutes() {
  const { user, loading } = useAuth()
  if (loading) return <div className="min-h-screen flex items-center justify-center text-gray-400">Đang tải...</div>
  if (!user) return <Navigate to="/login" replace />
  return <Layout />
}

function LoginGuard() {
  const { user, loading } = useAuth()
  if (loading) return <div className="min-h-screen flex items-center justify-center text-gray-400">Đang tải...</div>
  if (user) return <Navigate to="/" replace />
  return <Login />
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginGuard />} />
          <Route path="/" element={<ProtectedRoutes />}>
            <Route index element={<Dashboard />} />
            <Route path="users" element={<Users />} />
            <Route path="posts" element={<Posts />} />
            <Route path="expenses" element={<Expenses />} />
            <Route path="criteria" element={<Criteria />} />
            <Route path="media" element={<Media />} />
            <Route path="support" element={<Support />} />
            <Route path="violations" element={<Violations />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
