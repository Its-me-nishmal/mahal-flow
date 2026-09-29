"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { MahalFlowLogo } from "@/components/ui/MahalFlowLogo";
import { ApiClient, LoginError } from "@/lib/api-client";

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  // Only filled when one phone administers several Mahals (server 409).
  const [mahalChoices, setMahalChoices] = useState<string[]>([]);
  const [mahalId, setMahalId] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (ApiClient.isAuthenticated()) {
      router.replace("/dashboard");
    }
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanPhone = phone.trim();
    if (!cleanPhone) {
      setError("Please enter your mobile number");
      return;
    }
    if (!password) {
      setError("Please enter your password");
      return;
    }
    if (mahalChoices.length > 0 && !mahalId) {
      setError("Choose the Mahal you want to manage");
      return;
    }

    setLoading(true);
    setError("");

    try {
      await ApiClient.login(cleanPhone, password, mahalId || undefined);
      router.push("/dashboard");
    } catch (err: unknown) {
      if (err instanceof LoginError && err.status === 409 && err.mahalIds?.length) {
        setMahalChoices(err.mahalIds);
        setMahalId("");
        setError("This phone manages more than one Mahal. Choose one to continue.");
      } else {
        setError(err instanceof Error && err.message ? err.message : "Authentication failed. Check backend connection.");
        setPassword("");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="flex-grow flex flex-col justify-center items-center p-margin-mobile md:p-margin-desktop min-h-screen bg-background">
      <div className="w-full max-w-[400px] bg-surface border border-border-base rounded-xl shadow-[0_2px_8px_rgba(23,32,29,0.08)] overflow-hidden">
        <div className="p-xl flex flex-col items-center text-center border-b border-border-base gap-2">
          <MahalFlowLogo size="xl" />
          <p className="font-body text-body text-text-secondary">Sign in to MahalFlow Admin</p>
        </div>

        <div className="p-xl flex flex-col gap-lg">
          {error && (
            <div className="p-3 text-xs bg-error-bg text-error border border-error/20 rounded-lg flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px]">error</span>
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="flex flex-col gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary" htmlFor="mobile">
                Mobile Number
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-md text-text-muted material-symbols-outlined pointer-events-none">
                  phone_iphone
                </span>
                <input
                  id="mobile"
                  className="w-full h-12 pl-[44px] pr-md rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent transition-shadow placeholder:text-text-muted"
                  placeholder="10-digit mobile number"
                  type="tel"
                  value={phone}
                  autoComplete="username"
                  onChange={(e) => {
                    setPhone(e.target.value);
                    setMahalChoices([]);
                    setMahalId("");
                  }}
                  disabled={loading}
                  autoFocus
                />
              </div>
            </div>

            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary" htmlFor="password">
                Password
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 flex items-center pl-md text-text-muted material-symbols-outlined pointer-events-none">
                  lock
                </span>
                <input
                  id="password"
                  className="w-full h-12 pl-[44px] pr-[48px] rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent transition-shadow placeholder:text-text-muted"
                  placeholder="Your admin password"
                  type={showPassword ? "text" : "password"}
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 flex items-center pr-md text-text-muted hover:text-text-primary cursor-pointer"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  aria-pressed={showPassword}
                  disabled={loading}
                >
                  <span className="material-symbols-outlined text-[20px]">
                    {showPassword ? "visibility_off" : "visibility"}
                  </span>
                </button>
              </div>
            </div>

            {mahalChoices.length > 0 && (
              <div className="flex flex-col gap-sm">
                <label className="font-card-title text-card-title text-text-primary" htmlFor="mahal">
                  Mahal
                </label>
                <select
                  id="mahal"
                  className="w-full h-12 px-md rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container"
                  value={mahalId}
                  onChange={(e) => setMahalId(e.target.value)}
                  disabled={loading}
                >
                  <option value="">Select a Mahal</option>
                  {mahalChoices.map((id) => (
                    <option key={id} value={id}>
                      {id}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <button
              className="w-full h-12 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center justify-center gap-2 disabled:opacity-60 cursor-pointer active:scale-[0.99] duration-150"
              type="submit"
              disabled={loading}
            >
              {loading ? (
                <>
                  <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Logging in...</span>
                </>
              ) : (
                <>
                  <span>Continue</span>
                  <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                </>
              )}
            </button>
          </form>
        </div>

        <div className="bg-surface-container-low p-md text-center border-t border-border-base">
          <p className="font-small text-small text-text-muted">
            By continuing, you agree to our{" "}
            <a className="text-primary-container hover:underline" href="#">
              Terms of Service
            </a>{" "}
            &amp;{" "}
            <a className="text-primary-container hover:underline" href="#">
              Privacy Policy
            </a>
            .
          </p>
        </div>
      </div>
    </main>
  );
}
