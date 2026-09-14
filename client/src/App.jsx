import { lazy, Suspense, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Link, useLocation } from 'react-router-dom';
import { SiteHeader, TabBar } from './components/NavBar';
import ErrorBoundary from './components/ErrorBoundary';
import HomePage from './pages/HomePage';

const AboutPage = lazy(() => import('./pages/AboutPage'));
const ToolsPage = lazy(() => import('./pages/ToolsPage'));
const NewsPage = lazy(() => import('./pages/NewsPage'));
const PrivacyPage = lazy(() => import('./pages/PrivacyPage'));
const NotFoundPage = lazy(() => import('./pages/NotFoundPage'));

function ScrollToTop() {
  const { pathname } = useLocation();
  // Block body on purpose: newer Chromium's scrollTo() returns a Promise, and React treats any
  // non-function effect return value as a cleanup and crashes the whole tree on navigation.
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

function PageFallback() {
  return (
    <div className="space-y-4 py-4" aria-busy="true" aria-label="Loading">
      <div className="skeleton h-10 w-2/3 rounded-lg" />
      <div className="skeleton h-5 w-1/2 rounded" />
      <div className="skeleton h-64 rounded-2xl" />
    </div>
  );
}

function AppRoutes() {
  const { pathname } = useLocation();
  // Keyed by path so an error on one page clears when the user navigates away
  return (
    <ErrorBoundary key={pathname}>
      <Suspense fallback={<PageFallback />}>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/about" element={<AboutPage />} />
          <Route path="/tools" element={<ToolsPage />} />
          <Route path="/news" element={<NewsPage />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <ScrollToTop />
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:rounded-lg focus:bg-white focus:px-4 focus:py-2 focus:shadow"
      >
        Skip to content
      </a>
      <div className="flex min-h-dvh flex-col">
        <SiteHeader />
        <main id="main" className="mx-auto w-full max-w-6xl flex-1 px-4 pt-6 pb-10 sm:px-6 sm:pt-10 sm:pb-16">
          <AppRoutes />
        </main>
        <footer className="border-t border-slate-200 bg-white pb-[calc(4.5rem+env(safe-area-inset-bottom))] sm:pb-0">
          <div className="mx-auto flex max-w-6xl flex-col gap-2 px-4 py-6 text-sm text-slate-600 sm:flex-row sm:items-center sm:justify-between sm:px-6">
            <p>© {new Date().getFullYear()} Vote4U · Independent and nonpartisan. Not affiliated with any government agency.</p>
            <nav aria-label="Footer" className="flex gap-4">
              <Link to="/about" className="hover:text-slate-900">About</Link>
              <Link to="/privacy" className="hover:text-slate-900">Privacy</Link>
            </nav>
          </div>
        </footer>
        <TabBar />
      </div>
    </BrowserRouter>
  );
}
