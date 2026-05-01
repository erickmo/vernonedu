# Domain: Facilitator

> **DEPRECATED** — This domain has been merged into [team-member](../team-member/team-member.md). Do not extend this file. All facilitator logic now lives in the Team Member domain.

## Migration Note

All references to the `Facilitator` entity should now point to `TeamMember` with `is_facilitator = true`. Event sources (`facilitator.proposed`, `facilitator.approved`, `facilitator.rejected`) are now fired by the Team Member domain.

## Related Domains

- [team-member](../team-member/team-member.md)
