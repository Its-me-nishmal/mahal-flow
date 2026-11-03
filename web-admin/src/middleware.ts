import { NextResponse, type NextRequest } from "next/server";

// Coarse gate: signed-out visitors are sent to /login before any admin page
// renders. The cookie is only a presence flag set by the client after login;
// it carries no secret. Real authorization is the bearer token checked by the
// API, and the admin layout still verifies the stored session client-side.
export function middleware(req: NextRequest) {
  if (req.cookies.get("mf_session")?.value === "1") return NextResponse.next();
  const url = req.nextUrl.clone();
  url.pathname = "/login";
  url.search = "";
  return NextResponse.redirect(url);
}

export const config = {
  matcher: ["/((?!login|_next/|api/|favicon.ico|.*\\..*).*)"],
};
