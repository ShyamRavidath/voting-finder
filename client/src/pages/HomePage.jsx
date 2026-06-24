import { useNavigate } from 'react-router-dom';

export default function HomePage() {
  const navigate = useNavigate();
  return (
    <div className="text-center py-24 space-y-8 fade-in">
      <h2 className="text-7xl font-bold leading-tight tracking-tight">
        Ready for <br />
        <span className="text-red-600">November</span> <span className="text-blue-600">2028?</span>
      </h2>
      <p className="text-slate-600 text-xl max-w-2xl mx-auto leading-relaxed font-light">
        The next generation of leadership starts with your vote. Access nonpartisan tools, real-time election
        news, and polling locations to make your voice heard.
      </p>
      <div className="flex gap-4 justify-center pt-4">
        <button
          onClick={() => navigate('/tools')}
          className="bg-blue-600 text-white px-10 py-4 rounded-xl font-semibold text-lg hover:bg-blue-700 transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
        >
          Get Started
        </button>
        <button
          onClick={() => navigate('/about')}
          className="bg-white border-2 border-slate-200 text-slate-900 px-10 py-4 rounded-xl font-semibold text-lg hover:bg-slate-50 hover:border-slate-300 transition-all"
        >
          Learn More
        </button>
      </div>
    </div>
  );
}
