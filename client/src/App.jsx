import { BrowserRouter, Routes, Route } from 'react-router-dom';
import NavBar from './components/NavBar';
import HomePage from './pages/HomePage';
import AboutPage from './pages/AboutPage';
import ToolsPage from './pages/ToolsPage';
import NewsPage from './pages/NewsPage';

export default function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-50 text-slate-900">
        <NavBar />
        <main className="max-w-6xl mx-auto px-6 py-12 space-y-12">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/about" element={<AboutPage />} />
            <Route path="/tools" element={<ToolsPage />} />
            <Route path="/news" element={<NewsPage />} />
          </Routes>
        </main>
        <footer className="mt-20 py-12 border-t border-slate-200 bg-white/50">
          <div className="max-w-6xl mx-auto px-6 text-center">
            <p className="text-slate-600 text-sm">© 2024 Vote4U. Nonpartisan civic engagement platform.</p>
          </div>
        </footer>
      </div>
    </BrowserRouter>
  );
}
