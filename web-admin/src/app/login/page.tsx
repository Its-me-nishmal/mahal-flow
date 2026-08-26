import { MahalFlowLogo } from "@/components/ui/MahalFlowLogo";

export default function LoginPage() {
  return (
    <main className="flex-grow flex flex-col justify-center items-center p-margin-mobile md:p-margin-desktop min-h-screen bg-background">
      <div className="w-full max-w-[400px] bg-surface border border-border-base rounded-xl shadow-[0_2px_8px_rgba(23,32,29,0.08)] overflow-hidden">
        <div className="p-xl flex flex-col items-center text-center border-b border-border-base gap-2">
          <MahalFlowLogo size="xl" />
          <p className="font-body text-body text-text-secondary">Welcome back to Super Admin</p>
        </div>
        <div className="p-xl flex flex-col gap-lg">
          <form className="flex flex-col gap-lg">
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
                  placeholder="Enter your mobile number"
                  type="tel"
                />
              </div>
            </div>
            <button
              className="w-full h-12 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center justify-center gap-2"
              type="submit"
            >
              Continue
              <span className="material-symbols-outlined text-[18px]">
                arrow_forward
              </span>
            </button>
          </form>
          <div className="relative flex py-2 items-center">
            <div className="flex-grow border-t border-border-base" />
            <span className="flex-shrink-0 mx-4 font-small text-small text-text-muted">
              or
            </span>
            <div className="flex-grow border-t border-border-base" />
          </div>
          <button
            className="w-full h-12 bg-surface text-primary-container border border-primary-container font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center justify-center gap-2"
            type="button"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24">
              <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
              <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
              <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
              <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
            </svg>
            Continue with Google
          </button>
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
