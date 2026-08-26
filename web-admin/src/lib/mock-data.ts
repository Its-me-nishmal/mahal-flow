export const mockMahals = [
  { id: "MHL-8492", name: "Central Juma Masjid", location: "Kochi", status: "Active", members: 2450, collections: "₹8.4L", plan: "Premium Annual" },
  { id: "MHL-3321", name: "Al-Huda Community Center", location: "Calicut", status: "Grace Period", members: 850, collections: "₹2.1L", plan: "Standard Monthly" },
  { id: "MHL-9941", name: "Darussalam Trust", location: "Deira Dubai", status: "Read Only", members: 1200, collections: "₹0", plan: "Enterprise" },
  { id: "MHL-1102", name: "Town Mosque Committee", location: "Trivandrum", status: "Suspended", members: 420, collections: "₹0", plan: "Standard Annual" },
  { id: "MHL-5567", name: "Malabar Grand Mosque", location: "Kozhikode", status: "Active", members: 3120, collections: "₹12.5L", plan: "Premium Annual" },
  { id: "MHL-2214", name: "Kerala Muslim Jamaat", location: "Malappuram", status: "Active", members: 1245, collections: "₹6.2L", plan: "Standard Monthly" },
  { id: "MHL-7789", name: "Green Valley Mosque", location: "Wayanad", status: "Active", members: 680, collections: "₹3.4L", plan: "Standard Annual" },
  { id: "MHL-4432", name: "Sunni Mahal Federation", location: "Palakkad", status: "Active", members: 850, collections: "₹4.1L", plan: "Standard Monthly" },
];

export const mockMembers = [
  { id: "MEM-9910", name: "Abdul Malik", phone: "+91 98765 43210", status: "Active", dues: "₹500", lastPaid: "Aug 2026" },
  { id: "MEM-8834", name: "Fatima Khan", phone: "+91 91234 56789", status: "Pending", dues: "₹500", lastPaid: "Jun 2026" },
  { id: "MEM-7756", name: "Mohammed Raza", phone: "+91 99887 76655", status: "Suspended", dues: "₹500", lastPaid: "Mar 2026" },
  { id: "MEM-6623", name: "Syed Ali", phone: "+91 94444 33333", status: "Active", dues: "₹500", lastPaid: "Aug 2026" },
  { id: "MEM-5512", name: "Rahul Sharma", phone: "+91 98765 12345", status: "Active", dues: "₹750", lastPaid: "Aug 2026" },
  { id: "MEM-4401", name: "Priya Patel", phone: "+91 91234 98765", status: "Active", dues: "₹500", lastPaid: "Jul 2026" },
];

export const mockTransactions = [
  { id: "TXN-98245", member: "Zainab Ibrahim", mahal: "Al-Huda", amount: "₹2,500", date: "Aug 23, 2026", status: "Pending" },
  { id: "TXN-98240", member: "Mohammed Ali", mahal: "Malabar Grand", amount: "₹5,000", date: "Aug 22, 2026", status: "Success" },
  { id: "TXN-98211", member: "Fatima Rahman", mahal: "Kozhikode South", amount: "₹1,200", date: "Aug 21, 2026", status: "Failed" },
  { id: "TXN-98199", member: "Salim Khan", mahal: "Green Valley", amount: "₹3,500", date: "Aug 20, 2026", status: "Pending" },
  { id: "TXN-98188", member: "Aisha Begum", mahal: "Central Juma", amount: "₹1,500", date: "Aug 19, 2026", status: "Success" },
  { id: "TXN-98175", member: "Ibrahim Khalil", mahal: "Sunni Federation", amount: "₹8,000", date: "Aug 18, 2026", status: "Refunded" },
];

export const mockSubscriptions = [
  { mahal: "Juma Masjid Downtown", id: "MHL-1042", plan: "₹499/mo", payment: "AutoPay Active", status: "Active", renewal: "Oct 15, 2026" },
  { mahal: "Al-Huda Islamic Center", id: "MHL-0891", plan: "₹499/mo", payment: "Manual Pay", status: "Grace Period", renewal: "Oct 01, 2026" },
  { mahal: "Greenwood Noor Mosque", id: "MHL-1105", plan: "₹499/mo", payment: "AutoPay Active", status: "Active", renewal: "Nov 22, 2026" },
  { mahal: "Kerala Muslim Jamaat", id: "MHL-0221", plan: "₹999/mo", payment: "AutoPay Active", status: "Active", renewal: "Sep 30, 2026" },
  { mahal: "Town Mosque Committee", id: "MHL-1102", plan: "₹499/mo", payment: "Manual Pay", status: "Suspended", renewal: "Aug 01, 2026" },
];

export const mockAuditLogs = [
  { id: "LOG-001", admin: "Rahul Sharma", adminId: "ADM-092", action: "Gateway Config", type: "warning", detail: "Updated gateway credentials for Razorpay (changed API Key and Webhook Secret for Production).", time: "2 hours ago", ip: "192.168.1.45" },
  { id: "LOG-002", admin: "Priya Patel", adminId: "ADM-104", action: "Deletion", type: "error", detail: "Deleted Member Profile (removed MEM-8834).", time: "Oct 24, 10:30 AM", ip: "10.0.0.12" },
  { id: "LOG-003", admin: "System Admin", adminId: "SYS-001", action: "Bulk Import", type: "success", detail: "Completed Monthly Dues Import (processed 450 records, 2 skipped).", time: "Oct 23, 09:15 PM", ip: "Cron Job" },
  { id: "LOG-004", admin: "Rahul Sharma", adminId: "ADM-092", action: "Member Update", type: "info", detail: "Updated member phone number for MEM-9910.", time: "Oct 22, 03:45 PM", ip: "192.168.1.45" },
];

export const mockAlerts = [
  { id: "ALT-001", type: "Payment Due", title: "Monthly Subscription", message: "₹1,500 due today.", unread: true, action: "Pay ₹1,500" },
  { id: "ALT-002", type: "Committee Meeting", title: "General Body Meeting", message: "Meeting scheduled Sunday at 10:00 AM.", unread: true, action: null },
  { id: "ALT-003", type: "Receipt Generated", title: "Payment Receipt", message: "Receipt #REC-8924 for ₹5,000 payment.", unread: false, action: "View Receipt" },
  { id: "ALT-004", type: "System Update", title: "Maintenance Notice", message: "Scheduled maintenance Saturday 2 AM - 4 AM.", unread: false, action: null },
];

export const mockGateways = [
  { name: "Federal Bank", status: "Connected", type: "Primary Route", credentials: "••••••••••" },
  { name: "Razorpay", status: "Connected", type: "Fallback Route", credentials: "••••••••••" },
];
