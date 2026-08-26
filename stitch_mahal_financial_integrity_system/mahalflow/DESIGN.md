---
name: MahalFlow
colors:
  surface: '#FFFFFF'
  surface-dim: '#d7dbd8'
  surface-bright: '#f7faf7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4f1'
  surface-container: '#ebefec'
  surface-container-high: '#e6e9e6'
  surface-container-highest: '#e0e3e0'
  on-surface: '#181c1b'
  on-surface-variant: '#3f4945'
  inverse-surface: '#2d3130'
  inverse-on-surface: '#eef1ee'
  outline: '#6f7975'
  outline-variant: '#bec9c4'
  surface-tint: '#116a5a'
  primary: '#005244'
  on-primary: '#ffffff'
  primary-container: '#146c5b'
  on-primary-container: '#9bead4'
  inverse-primary: '#87d5c0'
  secondary: '#2d685b'
  on-secondary: '#ffffff'
  secondary-container: '#b2efde'
  on-secondary-container: '#346e61'
  tertiary: '#3f4a48'
  on-tertiary: '#ffffff'
  tertiary-container: '#576260'
  on-tertiary-container: '#d1ddda'
  error: '#C93B3B'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a3f2dc'
  primary-fixed-dim: '#87d5c0'
  on-primary-fixed: '#00201a'
  on-primary-fixed-variant: '#005143'
  secondary-fixed: '#b2efde'
  secondary-fixed-dim: '#97d2c2'
  on-secondary-fixed: '#00201a'
  on-secondary-fixed-variant: '#0f5044'
  tertiary-fixed: '#d9e5e2'
  tertiary-fixed-dim: '#bdc9c6'
  on-tertiary-fixed: '#131e1c'
  on-tertiary-fixed-variant: '#3e4947'
  background: '#f7faf7'
  on-background: '#181c1b'
  surface-variant: '#e0e3e0'
  bg-app: '#F7F9F8'
  text-primary: '#17201D'
  text-secondary: '#5E6864'
  text-muted: '#8A9390'
  border-base: '#E3E8E6'
  success: '#16834B'
  success-bg: '#EAF7EF'
  warning: '#B77900'
  warning-bg: '#FFF5DC'
  error-bg: '#FDECEC'
  info: '#3478B8'
  info-bg: '#EAF3FB'
typography:
  display:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  page-title:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  amount-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  section-title:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  card-title:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  button:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  small:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  gutter: 16px
  margin-mobile: 16px
  margin-tablet: 24px
  margin-desktop: 32px
---

Yes. design.md should contain the actual design system, not just "use modern UI." It should be detailed enough that Stitch, Flutter, React, and an AI coding agent all converge on the same visual language.
Create:
docs/21-design.md
# 21 — MahalFlow Design System

## 1. Design Identity

Product: MahalFlow  
Platform: RayanPortal

MahalFlow is a modern digital payment and Mahal-management product.

The visual identity should communicate:

- Trust
- Simplicity
- Reliability
- Community
- Financial clarity
- Modern technology
- Calmness

The product must NOT look like:
- A generic banking app
- A government portal
- A traditional mosque website
- A complicated ERP
- A flashy fintech trading application

The visual direction is:

> Modern SaaS + trusted fintech + subtle community character.

Religious identity should be respectful and subtle. Avoid excessive Islamic patterns, decorative Arabic typography, crescents, mosque illustrations, or ornamental backgrounds.

---

# 2. Design Principles

## 2.1 Simplicity First

Every screen should answer:

> What does the user need to do here?

Avoid unnecessary controls and decoration.

## 2.2 Financial Clarity

Money must always be visually clear.

For example:

```text
Monthly Dues
₹1,500
The amount should have strong visual hierarchy.
Do not hide:


payable amount

selected months

payment status

receipt number

refund status
2.3 Progressive Disclosure
Show the most important information first.
Secondary information can appear through:


details

expandable sections

dialogs

secondary screens
2.4 Consistency
The same component must look and behave consistently throughout the application.
2.5 Trust
Payment and account actions should feel predictable.
Avoid:


unnecessary animations

surprising navigation

unclear payment states

ambiguous buttons

excessive colors
3. Brand Personality
MahalFlow should feel:


Clean

Friendly

Professional

Reliable

Calm

Modern

Human
It should NOT feel:


Corporate-heavy

Luxury

Aggressive fintech

Childish

Overly decorative

Technically complicated
4. Color System
Use a restrained palette.
Primary
Primary brand color:
#146C5B
Use for:


primary buttons

selected navigation

important links

active states

primary highlights
Primary Dark
#0D4F43
Use for:


pressed states

strong headings when appropriate

dark primary elements
Primary Light
#E8F4F1
Use for:


selected backgrounds

information cards

subtle highlights
Background
Main application background:
#F7F9F8
Surface:
#FFFFFF
Text
Primary:
#17201D
Secondary:
#5E6864
Muted:
#8A9390
Borders
#E3E8E6
Semantic Colors
Success:
#16834B
Success background:
#EAF7EF
Warning:
#B77900
Warning background:
#FFF5DC
Error:
#C93B3B
Error background:
#FDECEC
Info:
#3478B8
Info background:
#EAF3FB
Color rule
Do not use semantic colors as decoration.
Use them to communicate state.
5. Typography
Use a modern sans-serif font.
Preferred:
Inter
Fallback:
System UI
For Flutter, use the same visual characteristics with a suitable bundled/web font.
Type scale
Display:
32px / 40px
Weight: 700
Page title:
24px / 32px
Weight: 700
Section title:
18px / 26px
Weight: 600
Card title:
16px / 24px
Weight: 600
Body:
14px / 22px
Weight: 400
Small:
12px / 18px
Weight: 400
Button:
14px / 20px
Weight: 600
Large financial amount:
28–32px
Weight: 700
Do not use more than 3–4 font weights throughout the application.
6. Spacing
Use an 8px spacing system.
Base values:
4
8
12
16
24
32
40
48
64
Preferred:


Screen horizontal padding: 16px mobile

Screen horizontal padding: 24px tablet

Desktop content padding: 32px

Card padding: 16–20px

Section spacing: 24–32px

Form field gap: 16px

Button height: 44–48px
Avoid arbitrary spacing values unless required by a specific component.
7. Border Radius
Use moderate rounding.
Small:
8px
Cards:
12px
Large containers:
16px
Buttons:
10px
Inputs:
10px
Pills/status badges:
999px
Avoid excessive rounded/pill-shaped UI.
8. Shadows
Use shadows very sparingly.
Default cards should primarily use:
border + surface
rather than heavy shadows.
If a shadow is needed:
0 2px 8px rgba(...)
Dialogs and floating elements can use stronger elevation.
Avoid floating-everything design.
9. Icons
Use a consistent outline icon family.
Preferred visual style:


simple

1.5–2px stroke

rounded where appropriate

minimal detail
Do not mix multiple unrelated icon styles.
Icons should support text, not replace important labels.
10. Buttons
Primary Button
Use primary brand color.
Example:
┌─────────────────────────┐
│       Pay ₹1,500        │
└─────────────────────────┘
Primary buttons should contain a clear action.
Good:
Pay ₹1,500
Continue to Payment
Save Member
Confirm Refund
Avoid:
Submit
Proceed
Continue
Action
when a more descriptive label is possible.
Secondary Button
Use white/surface background with border.
Destructive Button
Use error styling only for genuinely destructive actions.
Example:
Refund Payment
Deactivate Member
Suspend Mahal
Destructive actions require confirmation.
11. Form Fields
Inputs should have:


clear label

consistent height

visible focus state

clear error state

optional helper text
Do not rely only on placeholder text.
Example:
Monthly Amount

[ ₹ 500                         ]

Amount charged every month
Error:
Monthly Amount

[ ₹ 0                           ]

Minimum amount is ₹1
12. Cards
Cards should group related information.
Avoid using cards for every small piece of information.
Good:
┌──────────────────────────────────┐
│ Outstanding Dues                 │
│                                  │
│ ₹2,500                           │
│ 5 unpaid months                  │
│                                  │
│ [ Pay Now ]                      │
└──────────────────────────────────┘
Cards should have clear hierarchy.
13. Status Badges
Use consistent status badges.
ACTIVE
Green.
GRACE PERIOD
Amber.
READ ONLY
Neutral/amber.
SUSPENDED
Red.
PENDING
Amber.
SUCCESS
Green.
FAILED
Red.
CANCELLED
Neutral.
EXPIRED
Neutral/dark.
REFUNDED
Blue/neutral.
Never communicate status through color alone.
Always include the status text.
14. Loading States
Use skeleton loaders for larger page content.
For actions:
Paying...
Saving...
Processing...
Generating...
Do not leave the user wondering whether something is happening.
Disable duplicate submission while an operation is processing.
15. Empty States
Empty states should be useful.
Example:
No payment history yet

Your completed payments will appear here.

[ Make a Payment ]
Admin:
No members found

Add your first member or import members from Excel.

[ Add Member ] [ Import Excel ]
Avoid overly large illustrations.
16. Error States
Every important page needs an API/network error state.
Example:
Something went wrong

We couldn't load your payments.

[ Try Again ]
Payment error:
Payment could not be completed

Your payment was not confirmed.

Check your payment status before trying again.
Never tell users to immediately retry if a payment may have been processed.
17. Confirmation Dialogs
Use confirmation dialogs for:


Refund

Deactivate member

Reactivate member where relevant

Deactivate admin

Suspend Mahal

Cancel AutoPay

Important configuration changes
Dialog structure:
Title
Description
Optional consequences
Cancel
Confirm action
Destructive action should be visually clear.
18. Member Navigation
Mobile bottom navigation:
Home
Payments
Receipts
Notifications
Profile
Keep navigation to approximately 4–5 primary destinations.
Secondary functions belong inside relevant pages or Profile/Settings.
19. Member Home
The Member home screen should prioritize:


Mahal identity

Outstanding amount

Pending months

Pay action

Recent payment

Contribution action

Important notification
Example:
Assalamu Alaikum, Muhammed

Mahal Name

Outstanding
₹1,500
3 months

[ Pay Dues ]

Recent Payment
₹500
August 2026
Paid
Do not overcrowd the dashboard.
20. Monthly Payment UI
The monthly payment screen must clearly show:
Monthly Dues

Select months

☑ June 2026       ₹500
☑ July 2026       ₹500
☑ August 2026     ₹500

-------------------------
3 months           ₹1,500

[ Pay ₹1,500 ]
All unpaid months are selected by default.
The user must clearly understand:


which months are selected

monthly amount

total amount
Do not allow partial payment of an individual monthly obligation.
21. Contribution UI
Contribution is visually separate from monthly dues.
Example:
Make a Contribution

Amount

[ ₹ 1,000 ]

Note (optional)

[ __________________ ]

[ Continue to Payment ]
Do not combine contribution and monthly dues into one confusing form.
22. Payment Result
Success
Show:


Success indicator

Amount

Payment type

Date

Receipt number

Paid months if monthly

View receipt
Example:
Payment Successful

₹1,500

3 months paid

Receipt
GV1MH00120260803R00002

[ View Receipt ]
Failure
Clearly distinguish:
Payment Failed
from:
Payment Pending
Never display "Failed" when the gateway status is still uncertain.
23. Receipt UI
Receipt should look official and trustworthy.
Include:


Mahal logo/name

Mahal details

Member name

Member mobile where appropriate

Receipt number

Payment date

Payment type

Paid months

Amount

Gateway/reference information where appropriate

Footer/contact information
Receipt number must be prominent.
Example:
RECEIPT

GV1MH00120260803R00002

Mahal Name
-------------------------
Member       Muhammed
Payment      Monthly
Months       Jun–Aug 2026
Amount       ₹1,500
Date         03 Aug 2026
-------------------------

Payment Successful

[ Download / View PDF ]
24. Mahal Admin Dashboard
The Mahal Admin dashboard should focus on operations.
Primary metrics:
Collected
₹85,500

Pending
₹12,000

Paid Members
171

Pending Members
24
Then:


recent transactions

unpaid member list

quick actions

subscription state
Avoid complex analytics in V1.
25. Admin Member List
Desktop/tablet:
Members

[ Search ] [ Filter ] [ Add Member ] [ Import ]

Name       Mobile       Amount    Status
Muhammed   98xxxxxxx    ₹500      Active
Ameen      97xxxxxxx    ₹500      Active
...
Mobile should transform rows into cards/list items.
26. Bulk Excel Import
Use a guided process:
1. Upload
2. Validate
3. Preview
4. Confirm
5. Completed
Show:


total rows

valid rows

invalid rows

duplicate rows

specific validation errors
Never silently skip invalid data.
27. Admin Reports
Reports should be functional rather than decorative.
Provide:
Date range
Payment status
Payment type
Member
Gateway

[ Apply Filters ]

[ Export PDF ]
[ Export Excel ]
The export must use the same filters currently applied.
28. Subscription UI
Show clearly:
MahalFlow Subscription

₹499 / month

Status
ACTIVE

Next billing
03 September 2026

AutoPay
Enabled

[ Manage Subscription ]
For trial:
Free Trial

12 days remaining
For grace:
Payment required

Your Mahal is currently in the 7-day grace period.

[ Manage Subscription ]
For READ ONLY:
Read Only

New payment collection is currently unavailable.

[ Renew Subscription ]
29. Super Admin Layout
Desktop PWA should use:
┌──────────────┬──────────────────────────────┐
│              │                              │
│ RayanPortal  │ Top bar                      │
│              │                              │
│ Dashboard    │                              │
│ Mahals       │ Main content                 │
│ Members      │                              │
│ Payments     │                              │
│ Subscriptions│                              │
│ Gateways     │                              │
│ Refunds      │                              │
│ Reports      │                              │
│ Audit Logs   │                              │
│ Settings     │                              │
│              │                              │
└──────────────┴──────────────────────────────┘
Sidebar should be stable and predictable.
30. Super Admin Dashboard
Show platform metrics separately.
Mahals
128

Active
110

Grace
8

Read Only
6

Suspended
4
Financial sections:
Mahal Collections
₹12,50,000

Contributions
₹2,10,000

MahalFlow Revenue
₹63,500
Never visually merge Mahal money and RayanPortal/MahalFlow revenue.
31. Super Admin Tables
Tables should support:


search

filtering

sorting where useful

pagination

row actions

status badges
Avoid excessive columns.
Use detail pages/drawers for secondary information.
32. Gateway Configuration UI
Gateway secrets must NEVER be displayed.
Example:
Payment Gateways

Federal Bank
Status: Connected
Credentials: ••••••••••

Razorpay
Status: Connected
Credentials: ••••••••••

Primary Gateway
[ Federal Bank ]

Secondary Gateway
[ Razorpay ]

[ Test Connection ]
Never display actual secret values after saving.
33. Refund UI
Refund requires strong confirmation.
Show:
Refund Payment

Receipt
GV1MH00120260803R00002

Original amount
₹1,500

Refund amount
₹1,500

Gateway
Razorpay

This action cannot be undone.

[ Cancel ] [ Confirm Refund ]
V1 supports full transaction refund only.
34. Impersonation UI
When Super Admin is viewing as a Mahal Admin, show a persistent banner:
Viewing as:
Mahal Admin — Muhammed

Mahal:
Mahal Name

[ Exit View ]
This must never look like normal admin login.
35. Login Design
Member/Admin:
MahalFlow

Welcome back

Mobile number

[ Continue ]

or

[ Continue with Google ]   ← only if Google authentication is officially enabled

OTP verification
Super Admin:
RayanPortal

Super Admin

Email
Password

[ Sign In ]

Email OTP verification
Authentication options must match the actual backend authentication specification.
Do not add Google authentication to production behavior unless it is approved and implemented.
36. Responsive Design
Mobile
Primary target:
360–430px
Use:


bottom navigation

stacked cards

full-width buttons

simple forms
Tablet
Use:
600–1024px
Allow:


two-column layouts

wider tables where useful
Desktop
Use:
1024px+
Super Admin is desktop-first but must remain responsive.
37. Accessibility
Target WCAG 2.1 AA principles.
Requirements:


sufficient contrast

visible focus states

keyboard navigation for web

semantic labels

accessible form errors

buttons must have meaningful labels

status must not rely only on color

touch targets should be comfortably tappable

screen readers should understand important financial information
38. Animation
Animation should be subtle.
Allowed:


page transitions

skeleton loading

button loading

success feedback

small modal transitions
Avoid:


excessive motion

bouncing elements

decorative animations

long transitions
Typical duration:
150–250ms
39. Dark Mode
V1 should prioritize a polished light theme.
Dark mode should NOT be partially implemented.
If dark mode is introduced later, create a complete semantic dark theme rather than simply inverting colors.
40. Design Tokens
The implementation should centralize:


colors

typography

spacing

radii

elevation

component dimensions

semantic status colors
Flutter and React should use equivalent semantic tokens.
Do not scatter raw color values throughout the application.
41. Stitch AI Rules
When generating MahalFlow screens in Stitch:


Use this document as the visual source of truth.

Keep all screens visually consistent.

Reuse the same components.

Do not invent a new design language for different roles.

Do not add features that are not in the product requirements.

Prioritize mobile usability for Member/Admin.

Prioritize data density and clarity for Super Admin.

Use realistic INR payment examples.

Include loading, empty, error, success, pending and read-only states.

Keep religious visual elements subtle.

Never use fake financial claims or unrealistic dashboards.

Keep payment actions extremely clear.

Do not make payment success dependent on visual assumptions.

Do not display gateway secrets.

Maintain the MahalFlow brand consistently.
42. Design Quality Standard
A screen is considered complete only when it includes the appropriate:


default state

loading state

empty state

error state

success state

disabled state

permission/read-only state
where applicable.
The goal is not maximum visual complexity.
The goal is:
A Mahal member should understand what to do within seconds, and a Mahal Admin should be able to operate the system without training.