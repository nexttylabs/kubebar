# Phase 05 Discussion Log

**Date:** 2026-04-21
**Source issue:** https://github.com/nexttylabs/kubebar/issues/4

## Selected Gray Area

The user first selected:

- Warning event display

The user then updated the context and selected:

- Workload unhealthy reason priority
- Tracked item detail depth
- Partial / malformed `kubectl` JSON handling

## Questions And Answers

### Warning event display

| Question | Options | User choice |
| --- | --- | --- |
| First-screen warning event count | A. Show up to 3 recent warning events. B. Show only count, put details in an expanded area. C. Show up to 5 warning events. | A. Show up to 3 recent warning events. |
| Event row fields | A. `Reason + namespace/object + age`. B. `Reason + message`. C. `Reason + object`. | A. `Reason + namespace/object + age`. |
| Duplicate event handling | A. Group same `reason + involved object`, showing count and most recent time. B. Show raw events one by one. C. Show only latest and count the rest. | A. Group same `reason + involved object`, showing count and most recent time. |
| Event detail depth | A. Confirm only with reason, object, namespace, age, and short message. B. Add full message. C. Add more Kubernetes fields. | A. Confirm only with reason, object, namespace, age, and short message. |

### Workload unhealthy reason priority

| Question | Options | User choice |
| --- | --- | --- |
| Multiple workload problems exist at once | A. `missing/failed > restarting > pending/unready > warning`. B. `failed > pending > restarting > missing`. C. Most recent problem first. | A. `missing/failed > restarting > pending/unready > warning`. |
| Restarting pod description | A. Show affected pod count, such as `2 pods restarting`. B. Show highest restart count. C. Show only `restarting pods`. | A. Show affected pod count. |
| Pending / unready pod description | A. Merge into one short reason, such as `3 pods not ready`. B. Split pending and unready. C. Show only the most serious pod name. | A. Merge into one short reason. |

### Tracked item detail depth

| Question | Options | User choice |
| --- | --- | --- |
| Detail context | A. `state + reason + affected pod count + 1-3 example pod names + latest related warning`. B. Only `state + reason`. C. Full pod/event message. | A. `state + reason + affected pod count + 1-3 example pod names + latest related warning`. |

### Partial / malformed kubectl JSON handling

| Question | Options | User choice |
| --- | --- | --- |
| One kubectl data section fails | A. Keep available sections and mark failed section unavailable / stale reason. B. Mark whole display `Stale`. C. Ignore failed section. | A. Keep available sections and mark failed section unavailable / stale reason. |
| Malformed / empty JSON | A. Empty list is normal; malformed JSON is a section failure. B. Empty and malformed both fail the whole refresh. C. Empty and malformed both silently become no data. | A. Empty list is normal; malformed JSON is a section failure. |

## Captured Decisions

- Keep the warning counter.
- Show at most 3 warning summaries in the warning event section.
- Use `Reason + namespace/object + age` for warning event rows.
- Group repeated warning events by `reason + involved object`.
- Keep warning details short and confirmatory.
- Prioritize workload reasons as `missing/failed > restarting > pending/unready
  > warning`.
- Describe restarting pods by affected pod count.
- Merge pending and unready pods into one short `not ready` style reason.
- Tracked item details show state, reason, affected count, 1-3 pod examples,
  and latest related warning.
- Partial section failures keep usable data visible but mark the failed section.
- Empty JSON lists are normal empty states; malformed JSON is a section failure.

## Deferred Or Undiscussed

- Exact copy, truncation, and missing-field fallback wording were not discussed.
- Exact section-unavailable wording was not discussed.
