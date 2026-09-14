import { usePageTitle } from '../hooks/usePageTitle';

const UPDATED = 'September 13, 2026';

export default function PrivacyPage() {
  usePageTitle('Privacy policy');
  return (
    <article className="fade-in mx-auto max-w-2xl space-y-5 leading-relaxed text-slate-700">
      <div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">Privacy policy</h1>
        <p className="mt-1 text-sm text-slate-600">Last updated {UPDATED}</p>
      </div>

      <p>
        Vote4U is built to be useful without knowing who you are. There are no accounts, no ads, and no tracking or
        analytics cookies.
      </p>

      <h2 className="pt-2 text-xl font-bold text-slate-900">What we process</h2>
      <ul className="list-disc space-y-2 pl-5">
        <li>
          <strong>ZIP codes you search.</strong> Sent to our server to look up nearby voting locations. We don't
          link them to you. Results may be cached by ZIP code so repeat searches are fast.
        </li>
        <li>
          <strong>Your last searched ZIP code</strong> is saved only on your device so it's pre-filled next time. You
          can clear it by clearing your browser's site data.
        </li>
        <li>
          <strong>Standard request logs.</strong> Our hosting provider (Vercel) keeps routine technical logs, such as
          IP address and browser type, to operate and secure the service.
        </li>
      </ul>

      <h2 className="pt-2 text-xl font-bold text-slate-900">Third-party services</h2>
      <p>To answer your searches, our server contacts these services on your behalf, sending only the ZIP code or the city and state it resolves to:</p>
      <ul className="list-disc space-y-2 pl-5">
        <li>Zippopotam.us (ZIP code to city and coordinates)</li>
        <li>Google Civic Information API (official polling locations)</li>
        <li>OpenStreetMap Nominatim (nearby public buildings)</li>
        <li>NewsAPI.org and Google News (headlines)</li>
      </ul>
      <p>
        Your browser loads map images directly from OpenStreetMap and news thumbnails directly from publishers. Links to
        articles, maps, and official election sites open those sites, which have their own privacy policies.
      </p>

      <h2 className="pt-2 text-xl font-bold text-slate-900">Children</h2>
      <p>Vote4U doesn't knowingly collect personal information from anyone, including children under 13.</p>

      <h2 className="pt-2 text-xl font-bold text-slate-900">Changes and contact</h2>
      <p>
        If this policy changes, we'll update the date above. Questions or concerns? Open an issue on our{' '}
        <a
          href="https://github.com/ShyamRavidath/voting-finder/issues"
          target="_blank"
          rel="noopener noreferrer"
          className="font-semibold text-blue-700 underline underline-offset-2"
        >
          GitHub project page
        </a>
        .
      </p>
    </article>
  );
}
