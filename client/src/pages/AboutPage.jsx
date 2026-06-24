import { useState } from 'react';

const TABS = ['why', 'goal', 'what'];
const TAB_LABELS = { why: 'Why', goal: 'Our Goal', what: 'What' };

export default function AboutPage() {
  const [tab, setTab] = useState('why');

  return (
    <div className="space-y-10 fade-in max-w-4xl mx-auto">
      <div className="text-center mb-8">
        <h1 className="text-5xl font-bold mb-4">About Vote4U</h1>
        <p className="text-slate-600 text-lg">Empowering the next generation of voters</p>
      </div>

      <div className="flex bg-slate-100 p-1.5 rounded-2xl w-fit mx-auto gap-2 mb-8">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-8 py-3 rounded-xl font-semibold transition-all capitalize ${
              tab === t ? 'bg-white text-blue-600 shadow-md' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            {TAB_LABELS[t]}
          </button>
        ))}
      </div>

      <div className="bg-white p-12 rounded-3xl shadow-lg border border-slate-100 min-h-[400px]">
        {tab === 'why' && (
          <div className="space-y-6 fade-in">
            <h2 className="text-4xl font-bold text-slate-900">Why This Matters</h2>
            <div className="space-y-4 text-slate-700 leading-relaxed text-lg">
              <p>
                Voting is one of the most crucial civil liberties granted in the United States. It embodies the
                freedom to improve the future of society for the betterment of the public as a whole.
              </p>
              <p>
                Suffrage allows American citizens to retain the freedoms stated in the Constitution and its
                amendments—a gift many globally are restricted from. Voting is more than simply checking a box
                on a piece of paper; it is the ability to influence and change the political landscape that
                shapes our daily lives.
              </p>
              <p className="pt-4 border-t border-slate-200 italic text-slate-600">
                Every vote cast is a voice heard, every voice heard is a future shaped.
              </p>
            </div>
          </div>
        )}
        {tab === 'goal' && (
          <div className="space-y-6 fade-in">
            <h2 className="text-4xl font-bold text-slate-900">Our Goal</h2>
            <div className="space-y-5 text-slate-700 leading-relaxed text-lg">
              <p>
                Vote4U is addressing the issue of low young adult voter turnout throughout the United States,
                from the local to the national levels. Despite young adults being a critical and crucial
                demographic when it comes to shaping our world today, this demographic often shares a lack of
                engagement with voting and participation in government activities.
              </p>
              <p>
                This app works to solve the lack of accessible, nonpartisan civic information. The main reason
                why people ages 18–22 do not vote is due to the lack of resources, knowledge, and confidence
                needed to actually participate and vote.
              </p>
              <p>
                We are focusing on helping individuals who have not received accessible civic information and
                education.
              </p>
            </div>
          </div>
        )}
        {tab === 'what' && (
          <div className="space-y-6 fade-in">
            <h2 className="text-4xl font-bold text-slate-900">What Is Voting?</h2>
            <div className="space-y-4 text-slate-700 leading-relaxed text-lg">
              <p>
                Voting is the foundation of democracy—the process through which citizens have a direct say in
                shaping their communities, states, and nation.
              </p>
              <p>
                Every ballot cast, whether for a city measure or the presidency, is a step toward ensuring
                that every voice is heard and every opinion counts.
              </p>
              <p className="pt-4 border-t border-slate-200 text-blue-600 font-semibold">
                Ready to make your voice heard? Start by finding your polling location and staying informed.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
