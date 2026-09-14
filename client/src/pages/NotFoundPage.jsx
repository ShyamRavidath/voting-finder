import { Link } from 'react-router-dom';
import { usePageTitle } from '../hooks/usePageTitle';

export default function NotFoundPage() {
  usePageTitle('Page not found');
  return (
    <div className="fade-in mx-auto max-w-md py-12 text-center">
      <p className="text-sm font-semibold text-blue-700">404</p>
      <h1 className="mt-2 text-3xl font-bold tracking-tight">We couldn't find that page</h1>
      <p className="mt-2 text-slate-600">The link may be broken, or the page may have moved.</p>
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:justify-center">
        <Link to="/" className="inline-flex min-h-11 items-center justify-center rounded-xl bg-blue-600 px-6 font-semibold text-white hover:bg-blue-700">
          Go home
        </Link>
        <Link
          to="/tools?tab=booths"
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-slate-300 bg-white px-6 font-semibold text-slate-900 hover:bg-slate-50"
        >
          Find my polling place
        </Link>
      </div>
    </div>
  );
}
