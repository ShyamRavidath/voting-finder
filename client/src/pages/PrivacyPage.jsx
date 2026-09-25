import { usePageTitle } from '../hooks/usePageTitle';

const UPDATED = 'September 24, 2026';

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
          <strong>ZIP codes you search.</strong> Sent to our server to look up nearby voting locations. Results may
          be cached by ZIP code so repeat searches are fast. The ZIP can also appear in hosting request logs.
        </li>
        <li>
          <strong>Your last searched ZIP code</strong> is saved only on your device so it's pre-filled next time. You
          can clear it by clearing your browser's site data.
        </li>
        <li>
          <strong>Standard request logs.</strong> Our hosting provider (Vercel) keeps technical request information,
          including search parameters, IP address, browser type, status, and timing, to operate and secure the service.
        </li>
      </ul>

      <h2 className="pt-2 text-xl font-bold text-slate-900">Third-party services</h2>
      <p>To answer ZIP searches, our server contacts these services on your behalf with the ZIP code or the city and state it resolves to. An optional location search also sends rounded coordinates to Nominatim for reverse geocoding:</p>
      <ul className="list-disc space-y-2 pl-5">
        <li>Zippopotam.us (ZIP code to city and coordinates)</li>
        <li>Google Civic Information API (official polling locations)</li>
        <li>OpenStreetMap Nominatim (nearby public buildings)</li>
        <li>Google News (headlines)</li>
      </ul>
      <p>
        Your browser loads map images directly from OpenStreetMap and news thumbnails directly from publishers. Links to
        articles, maps, and official election sites open those sites, which have their own privacy policies.
      </p>

      <h2 className="pt-2 text-xl font-bold text-slate-900">The Vote4U iOS app</h2>
      <p>
        The iOS app talks to the same server and follows the same rules as this website. There are still no accounts,
        no ads, and no analytics. Two things are specific to the app:
      </p>
      <ul className="list-disc space-y-2 pl-5">
        <li>
          <strong>Location (optional).</strong> If you tap &ldquo;Use my location&rdquo;, the app asks for permission to
          read your location while you're using it. Your coordinates are rounded to roughly 110 metres before they
          leave your device, then sent to our server and Nominatim to work out which ZIP code you're in. The rounded
          coordinates can appear in Vercel request logs. If database caching is enabled, the coordinate pair is a
          cache key for one day of serving and is deleted by a daily cleanup job, normally within two days of the
          search; a failed cleanup may delay deletion. We don't use coordinates to track you across apps or websites.
          You can decline, or turn the permission off later in Settings, and the app keeps working normally &mdash;
          ZIP code entry is always available.
        </li>
        <li>
          <strong>Election reminders and your saved polling place (optional).</strong> Reminders are scheduled by your
          iPhone itself. There is no push server, so nothing about them reaches us &mdash; we never learn that you turned
          them on. A polling place you save is stored only on your device, so it stays readable without a signal, and
          removing it or deleting the app erases it.
        </li>
      </ul>
      <p>
        The app draws its maps with Apple Maps, which is governed by{' '}
        <a
          href="https://www.apple.com/legal/privacy/"
          target="_blank"
          rel="noopener noreferrer"
          className="font-semibold text-blue-700 underline underline-offset-2"
        >
          Apple&rsquo;s privacy policy
        </a>
        . Tapping a headline opens the publisher&rsquo;s own page inside the app, where that publisher&rsquo;s privacy
        policy applies.
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
