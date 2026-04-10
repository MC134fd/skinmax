# Skinmax Operator Runbook

## Log Subsystems

All structured logs use subsystem `com.skinmax.app`. Filter in Console.app or `log stream`:

| Category    | What it covers                              |
|-------------|---------------------------------------------|
| `config`    | API key validation at startup               |
| `analysis`  | AnalysisCoordinator lifecycle + cancellation |
| `dataStore` | Save/delete/prune operations                |
| `skinAPI`   | SkinAnalysisService request/response cycle  |
| `foodAPI`   | FoodAnalysisService request/response cycle  |

### Quick filter (Terminal)

```bash
# All Skinmax logs
log stream --predicate 'subsystem == "com.skinmax.app"' --level info

# Only analysis coordinator (cancellation races)
log stream --predicate 'subsystem == "com.skinmax.app" AND category == "analysis"'

# Only errors across all categories
log stream --predicate 'subsystem == "com.skinmax.app"' --level error
```

## Diagnosing Scan Failures

**Symptom:** Face or food scan shows error screen.

1. Filter logs by the relevant category (`skinAPI` or `foodAPI`).
2. Look for the last `Request dispatched` entry — if missing, the request never left the device (serialization failure or cancellation).
3. Check `HTTP status=` line:
   - `401` → invalid API key. Check Config validation log at startup (`config` category).
   - `429` → rate limited. Wait and retry.
   - `5xx` → OpenAI outage.
4. If status is `200` but scan still fails, look for `Failed to parse` or `malformedAnalysis` errors — the AI returned unexpected JSON structure.

## Identifying Cancellation Races

**Symptom:** User reports seeing a result from a previous scan, or a result appearing after dismissal.

1. Filter: `category == "analysis"`.
2. Look for the correlation pattern `face-N` or `food-N` where N is the `analysisID`.
3. A healthy cancel looks like:
   ```
   face-3 started
   face-3 cancelled at=post-analysis (stale write prevented)
   ```
4. A race that was **caught** shows `stale write prevented` — the guard worked.
5. If you see two different IDs both reaching `complete`, that indicates a guard bypass — file a bug.

**Key invariant:** Only one `*-N complete` should exist per dismiss/restart cycle.

## Verifying Cache Health

```bash
# Check prune results at startup
log show --predicate 'subsystem == "com.skinmax.app" AND category == "dataStore"' --last 5m \
  | grep "Cache pruned"
```

Expected output:
```
Cache pruned, cutoff=<date>, skin=45->12 (-33), food=30->8 (-22)
```

- If `-0` for both: no stale data (healthy).
- If prune failed: look for `Cache prune failed` error in same category.

## CI Guardrails

### Secret leak check
```bash
./scripts/check-secrets.sh
```
- **PASS:** No `sk-` key patterns in tracked source.
- **FAIL:** Lists file:line with the offending pattern. Remove the key immediately.

## Privacy Invariants

These must never appear in logs:
- API key values (only length is logged)
- Base64 image data
- Raw API response content (only parsed field names and scores)
- User photos or PII

If any of these appear in `log stream` output, treat as a P0 security incident.
