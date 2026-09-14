import { Component } from 'react';

export default class ErrorBoundary extends Component {
  state = { error: null };

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error('UI error:', error, info.componentStack);
  }

  render() {
    if (!this.state.error) return this.props.children;
    // A failed lazy-loaded chunk usually means a new version was deployed; a reload fixes it.
    return (
      <div role="alert" className="mx-auto max-w-md py-16 text-center">
        <h1 className="text-2xl font-bold">Something went wrong</h1>
        <p className="mt-2 text-slate-600">This page hit an unexpected error. Reloading usually fixes it.</p>
        <button
          type="button"
          onClick={() => window.location.reload()}
          className="mt-6 min-h-11 rounded-xl bg-blue-600 px-6 font-semibold text-white hover:bg-blue-700"
        >
          Reload page
        </button>
      </div>
    );
  }
}
