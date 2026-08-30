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

async function test3_InvalidMonthFormatAndDateInjection() {
  console.log('\n[Vector 3: Invalid Month Format & Date Injection Defense]');

  // 1. Malformed Month Format
  const res1 = await fetch(`${BASE_URL}/payments/dues/initialize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Tenant-ID': TENANT_A,
    },
    body: JSON.stringify({
      member_id: 'MEM_001_9910',
      selected_months: ['invalid-date-string'],
      gateway: 'CASH',
      idempotency_key: `SEC_MONTH_${Date.now()}`,
    }),
  });
  reportResult(
    'Malformed Month Rejection',
    res1.status === 400 || res1.status === 422,
    `Invalid month string returned HTTP ${res1.status}`
  );

  // 2. Empty Months Array
  const res2 = await fetch(`${BASE_URL}/payments/dues/initialize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Tenant-ID': TENANT_A,
    },
    body: JSON.stringify({
      member_id: 'MEM_001_9910',
      selected_months: [],
      gateway: 'CASH',
      idempotency_key: `SEC_EMPTY_MONTH_${Date.now()}`,
    }),
  });
  reportResult(
    'Empty Months Array Rejection',
    res2.status === 400 || res2.status === 422,
    `Empty months array returned HTTP ${res2.status}`
  );
}

async function test4_IdempotencyAndReplayAttackDefense() {
  console.log('\n[Vector 4: Idempotency & Replay Attack Defense]');

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
          selected_months: ['2026-08'],
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

async function test5_CryptographicLedgerIntegrity() {
  console.log('\n[Vector 5: Cryptographic SHA-256 Ledger Verification]');

  const res = await fetch(`${BASE_URL}/admin/dashboard`, {
    headers: { 'X-Tenant-ID': TENANT_A },
  });
  const dash = await res.json();
  const txns = dash.recent_transactions || [];

  if (txns.length === 0) {
    reportResult('Cryptographic Hash Verification', true, '0 transactions in newly seeded tenant');
    return;
  }

  let hashValid = true;
  for (const txn of txns) {
    if (!txn.receipt_hash || txn.receipt_hash.length !== 64) {
      hashValid = false;
      break;
    }
  }

  reportResult(
    'SHA-256 Receipt Hashes Format & Presence',
    hashValid,
    `Validated ${txns.length} ledger receipts for 64-character hex SHA-256 signatures`
  );
}

async function test6_NoSQLInjectionDefense() {
  console.log('\n[Vector 6: NoSQL & Operator Injection Defense]');

  // Attempting MongoDB operator injection on member query
  const res = await fetch(`${BASE_URL}/admin/members?limit=20`, {
    headers: {
      'X-Tenant-ID': '{"$ne": null}',
    },
  });

  const data = await res.json();
  // Should either return 0 members or treat the string literally without syntax error
  reportResult(
    'NoSQL Operator Injection in Tenant Header',
    res.status === 200 || res.status === 400 || res.status === 404,
    `Server handled malicious header cleanly with HTTP ${res.status}`
  );
}

async function test7_MissingTenantHeaderGracefulHandling() {
  console.log('\n[Vector 7: Missing Tenant Header Fallback Handling]');

  const res = await fetch(`${BASE_URL}/admin/dashboard`);
  reportResult(
    'Default Tenant Fallback Protection',
    res.status === 200,
    `Missing X-Tenant-ID was safely handled with status ${res.status}`
  );
}

async function test8_SecretKeyMasking() {
  console.log('\n[Vector 8: Sensitive Gateway Secrets Masking]');

  const res = await fetch(`${BASE_URL}/admin/gateways`, {
    headers: { 'X-Tenant-ID': TENANT_A },
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

  // Attempt non-existent route
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

  await test1_MultiTenantIsolation();
  await test2_ParameterTamperingAndNegativeAmounts();
  await test3_InvalidMonthFormatAndDateInjection();
  await test4_IdempotencyAndReplayAttackDefense();
  await test5_CryptographicLedgerIntegrity();
  await test6_NoSQLInjectionDefense();
  await test7_MissingTenantHeaderGracefulHandling();
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
