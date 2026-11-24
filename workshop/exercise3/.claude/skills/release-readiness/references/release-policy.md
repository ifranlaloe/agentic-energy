# Release policy

## Versioning (SemVer)

| Change | Bump |
|---|---|
| Fixes with no behaviour change for users | patch |
| New behaviour that keeps existing behaviour working | minor |
| Removed or changed behaviour that users or integrations rely on | major |

## Changelog

`CHANGELOG.md` follows Keep a Changelog. New entries go under Unreleased, grouped as Added, Changed, Fixed, Removed or Security. One line per change, written for a customer or operator, and cite the criterion ID.

```markdown
# Changelog

## Unreleased

### Added

- Customers can request a callback from the contact page (AC-1, AC-2).
```

## Risk tiers

| Tier | Typical change | Recommended rollout |
|---|---|---|
| Low | Copy, styling, no new input or data | Ship normally |
| Medium | New user journey or new input field | Ship with the tests and security review attached to the release notes |
| High | Handles personal data, authentication, payments, or a major dependency upgrade | Staged rollout. State which monitoring is missing in the readiness section |

When in doubt, take the higher tier.

## Rollback

Every release names its rollback. For this static app that means redeploying the previous build artifact. State how long it takes and whether anything the new version wrote makes the old version misbehave.
