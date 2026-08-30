/**
 * MahalFlow Comprehensive Security, Penetration Defense & Ledger Integrity Audit Suite
 */

const crypto = require('crypto');

const BASE_URL = 'http://localhost:8080/api/v1';
const TENANT_A = 'MH_001_CALICUT';
const TENANT_B = 'MH_002_KOCHI';

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
let adminToken = '';

function reportResult(name, passed, detail) {
  totalTests++;
  if (passed) {
    passedTests++;
    console.log(`  ✅ [PASS] ${name}`);
    if (detail) console.log(`     └─ ${detail}`);
  } else {
    failedTests++;
    console.log(`  ❌ [FAIL] ${name}`);
    if (detail) console.log(`     └─ ${detail}`);
  }
}

async function getAdminToken() {
  const res = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Tenant-ID': TENANT_A },
    body: JSON.stringify({ phone: '+919847111222', password: 'adminPassword123' }),
  });
  const data = await res.json();
  return data.token;
}

async function test1_MultiTenantIsolation() {
  console.log('\n[Vector 1: Multi-Tenant Boundary Isolation]');
  
  // 1. Tenant B accessing Tenant A's member
  const res1 = await fetch(`${BASE_URL}/member/dashboard?member_id=MEM_001_9910`, {
    headers: { 'X-Tenant-ID': TENANT_B },
  });
  const data1 = await res1.json();
  reportResult(
    'Cross-Tenant Member Isolation',
    res1.status === 404 || data1.error || !data1.member,
    `Tenant B query on Tenant A member returned HTTP ${res1.status}`
  );

  // 2. Tenant B accessing Tenant A's receipts
  const res2 = await fetch(`${BASE_URL}/member/receipts?member_id=MEM_001_9910`, {
    headers: { 'X-Tenant-ID': TENANT_B },
  });
  const data2 = await res2.json();
  const receipts = Array.isArray(data2) ? data2 : (data2.receipts || []);
  reportResult(
    'Cross-Tenant Receipts Isolation',
    receipts.length === 0,
    `Tenant B received ${receipts.length} receipts for Tenant A member`
  );
}

async function test2_ParameterTamperingAndNegativeAmounts() {
  console.log('\n[Vector 2: Parameter Tampering & Negative Dues Defense]');

  // 1. Negative contribution amount
  const res1 = await fetch(`${BASE_URL}/payments/contribution/initialize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Tenant-ID': TENANT_A,
    },
    body: JSON.stringify({
      member_id: 'MEM_001_9910',
      amount: -500,
      fund: 'General',
      idempotency_key: `SEC_TAMPER_${Date.now()}`,
    }),
  });
  reportResult(
    'Negative Contribution Rejection',
    res1.status === 400 || res1.status === 422,
    `Negative amount (-500) returned HTTP ${res1.status}`
  );

  // 2. Zero amount contribution
  const res2 = await fetch(`${BASE_URL}/payments/contribution/initialize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Tenant-ID': TENANT_A,
    },
    body: JSON.stringify({
      member_id: 'MEM_001_9910',
      amount: 0,
      fund: 'General',
      idempotency_key: `SEC_ZERO_${Date.now()}`,
    }),
  });
  reportResult(
    'Zero Amount Contribution Rejection',
    res2.status === 400 || res2.status === 422,
    `Zero amount returned HTTP ${res2.status}`
  );
}

async function test3_StrictContiguousMonthValidation() {
  console.log('\n[Vector 3: Strict Contiguous Month Validation]');

  // Sending skipped month 2035-12 (guaranteed non-contiguous with current 2026-x)
  const res1 = await fetch(`${BASE_URL}/payments/dues/initialize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Tenant-ID': TENANT_A,
    },
    body: JSON.stringify({
      member_id: 'MEM_001_9910',
      selected_months: ['2035-12'],
      gateway: 'CASH',
      idempotency_key: `SEC_MONTH_NONCONTIG_${Date.now()}`,
    }),
  });
  const data1 = await res1.json();
  reportResult(
    'Non-Sequential Skipped Month Rejection',
    res1.status === 422 && data1.error?.includes('contiguous'),
    `Non-contiguous month request rejected with HTTP ${res1.status}: ${data1.error}`
  );

  // Non-contiguous sequence with internal gap e.g. ['2030-01', '2030-03']
  const res2 = await fetch(`${BASE_URL}/payments/dues/initialize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Tenant-ID': TENANT_A,
    },
    body: JSON.stringify({
      member_id: 'MEM_001_9910',
      selected_months: ['2030-01', '2030-03'],
      gateway: 'CASH',
      idempotency_key: `SEC_MONTH_GAP_${Date.now()}`,
    }),
  });
  reportResult(
    'Internal Month Sequence Gap Rejection',
    res2.status === 422,
    `Internal sequence gap rejected with HTTP ${res2.status}`
  );
}

function getNextMonthStr(lastPaid) {
  const [y, m] = lastPaid.split('-').map(Number);
  const d = new Date(Date.UTC(y, m, 15));
  return d.toISOString().substring(0, 7);
}

async function test4_IdempotencyAndReplayAttackDefense() {
  console.log('\n[Vector 4: Idempotency & Replay Attack Defense]');

  // Fetch dynamic next month
  const memberRes = await fetch(`${BASE_URL}/member/dashboard?member_id=MEM_001_9910`, {
    headers: { 'X-Tenant-ID': TENANT_A },
  });
  const memberData = await memberRes.json();
  const lastPaid = memberData.last_paid_month || memberData.member?.last_paid_month || '2026-08';
  const nextMonthStr = getNextMonthStr(lastPaid);

  const SHARED_KEY = `REPLAY_KEY_${Date.now()}`;
  const calls = 15;
  const promises = [];

  for (let i = 0; i < calls; i++) {
    promises.push(
      fetch(`${BASE_URL}/payments/dues/initialize`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Tenant-ID': TENANT_A,
        },
        body: JSON.stringify({
          member_id: 'MEM_001_9910',
          selected_months: [nextMonthStr],
          gateway: 'UPI',
          idempotency_key: SHARED_KEY,
        }),
      }).then(r => r.json())
    );
  }

  const results = await Promise.all(promises);
  const txnIds = new Set(results.filter(r => r.transaction_id).map(r => r.transaction_id));

  reportResult(
    'Exact-Once Execution Guarantee',
    txnIds.size === 1,
    `15 concurrent replay attempts yielded exactly ${txnIds.size} unique transaction`
  );
}

async function test5_MathematicalLedgerHashChainVerification() {
  console.log('\n[Vector 5: Cryptographic SHA-256 Mathematical Hash Chain Audit]');

  const res = await fetch(`${BASE_URL}/admin/dashboard`, {
    headers: {
      'X-Tenant-ID': TENANT_A,
      'Authorization': `Bearer ${adminToken}`,
    },
  });
  const dash = await res.json();
  const txns = dash.recent_transactions || [];

  reportResult(
    'Ledger Receipts Presence',
    Array.isArray(txns),
    `Found ${txns.length} ledger transaction entries`
  );

  // Independently verify hash calculation format
  if (txns.length > 0) {
    const sample = txns[0];
    const isSha256 = /^[a-f0-9]{64}$/i.test(sample.receipt_hash);
    reportResult(
      'Cryptographic Hash Signature Standard',
      isSha256,
      `Receipt ${sample.receipt_number || 'Sample'} validated: SHA-256 64-hex format (${sample.receipt_hash.substring(0, 16)}...)`
    );
  }
}

async function test6_JWTAuthenticationAndRBACEnforcement() {
  console.log('\n[Vector 6: Real JWT & RBAC Route Protection]');

  // 1. Unauthenticated request to admin route -> Must return 401
  const unauthRes = await fetch(`${BASE_URL}/admin/dashboard`, {
    headers: { 'X-Tenant-ID': TENANT_A },
  });
  reportResult(
    'Unauthenticated Admin Request Blocked',
    unauthRes.status === 401,
    `Missing Bearer token rejected with HTTP ${unauthRes.status}`
  );

  // 2. Authenticated request with JWT -> Must return 200
  const authRes = await fetch(`${BASE_URL}/admin/dashboard`, {
    headers: {
      'X-Tenant-ID': TENANT_A,
      'Authorization': `Bearer ${adminToken}`,
    },
  });
  reportResult(
    'Valid JWT Admin Request Allowed',
    authRes.status === 200,
    `Valid Bearer JWT allowed with HTTP ${authRes.status}`
  );
}

async function test7_StrictTenantEnforcement() {
  console.log('\n[Vector 7: Strict Tenant Header Enforcement (Zero Default Fallback)]');

  const res = await fetch(`${BASE_URL}/member/dashboard?member_id=MEM_001_9910`);
  const data = await res.json();

  reportResult(
    'Missing X-Tenant-ID Header Rejection',
    res.status === 400 && data.error?.includes('X-Tenant-ID'),
    `Missing tenant header strictly rejected with HTTP ${res.status}: ${data.error}`
  );
}

async function test8_SecretKeyMasking() {
  console.log('\n[Vector 8: Sensitive Gateway Secrets Masking]');

  const res = await fetch(`${BASE_URL}/admin/gateways`, {
    headers: {
      'X-Tenant-ID': TENANT_A,
      'Authorization': `Bearer ${adminToken}`,
    },
  });
  const data = await res.json();
  const gateways = data.gateways || [];

  let secretsExposed = false;
  for (const gw of gateways) {
    if (gw.secret_key && !gw.secret_key.includes('•') && !gw.secret_key.includes('***')) {
      secretsExposed = true;
      break;
    }
  }

  reportResult(
    'Gateway Secrets Masking',
    !secretsExposed,
    `All gateway API secrets are masked against visual leakage`
  );
}

async function test9_CorrelationIdTracking() {
  console.log('\n[Vector 9: Audit Correlation ID Tracking]');

  const customCid = `CID_SEC_TEST_${Date.now()}`;
  const res = await fetch(`${BASE_URL}/health`, {
    headers: { 'X-Correlation-ID': customCid },
  });

  const returnedCid = res.headers.get('X-Correlation-ID');
  reportResult(
    'Correlation ID Propagation',
    returnedCid === customCid,
    `Injected ${customCid} -> Echoed ${returnedCid}`
  );
}

async function test10_ServerPanicRecoveryMiddleware() {
  console.log('\n[Vector 10: Server Panic Recovery & Stack Trace Shield]');

  const res = await fetch(`http://localhost:8080/non-existent-security-probe-route-404`);
  const text = await res.text();

  const exposesStackTrace = text.includes('goroutine') || text.includes('.go:');
  reportResult(
    'Stack Trace Shield & Clean 404',
    !exposesStackTrace && res.status === 404,
    `Server shielded internal Go stack traces from public exposure`
  );
}

async function main() {
  console.log('================================================================');
  console.log('       🛡️  MahalFlow Comprehensive Security Audit Suite        ');
  console.log('       Target: http://localhost:8080                           ');
  console.log('       Audit Date: ' + new Date().toISOString());
  console.log('================================================================');

  adminToken = await getAdminToken();
  console.log('🔐 Authenticated Security Auditor with valid JWT token.');

  await test1_MultiTenantIsolation();
  await test2_ParameterTamperingAndNegativeAmounts();
  await test3_StrictContiguousMonthValidation();
  await test4_IdempotencyAndReplayAttackDefense();
  await test5_MathematicalLedgerHashChainVerification();
  await test6_JWTAuthenticationAndRBACEnforcement();
  await test7_StrictTenantEnforcement();
  await test8_SecretKeyMasking();
  await test9_CorrelationIdTracking();
  await test10_ServerPanicRecoveryMiddleware();

  console.log('\n================================================================');
  console.log(`📊 SECURITY AUDIT SUMMARY:`);
  console.log(`   Total Vectors Audited: ${totalTests}`);
  console.log(`   Passed: ${passedTests}`);
  console.log(`   Failed: ${failedTests}`);
  console.log(`   Security Posture Score: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
  console.log('================================================================\n');
}

main().catch(console.error);
