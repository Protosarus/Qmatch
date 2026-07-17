#!/usr/bin/env python3
"""Generate assets/data/assessment_sets/frequency_sets.json with 50 sets (Step 15A)."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/data/assessment_sets/frequency_sets.json"

DIMS = [
    "depth",
    "socialEnergy",
    "spontaneity",
    "stability",
    "emotionalOpenness",
    "conversationPace",
]


def depth_lines() -> list[str]:
    a = [
        "When I'm drawn to someone, I naturally steer toward topics that feel substantive.",
        "I feel most engaged when we move past polite updates and share what actually matters.",
        "I'm refreshed when a date skips rehearsed small talk and explores real motivations.",
        "Meaningful dialogue helps me sense whether we're compatible beyond surface charm.",
        "I notice chemistry more when conversations reveal values, not just weekend plans.",
        "I'm energized when someone asks thoughtful questions instead of staying generic.",
        "I warm up faster when we trade perspectives that feel honest rather than performative.",
        "I appreciate partners who make space for nuanced feelings, not only headlines.",
        "I'm curious about someone's inner life—not only their itinerary.",
        "Connection clicks for me when we talk about what shapes us, not only what we do.",
        "I enjoy noticing how someone thinks, not only what they've achieved socially.",
        "I'm more present when dialogue invites reflection rather than constant banter.",
        "I feel closer when we explore intentions behind choices, not only outcomes.",
        "I'm attracted to conversations that leave room for ambiguity and sincerity.",
        "I value rhythm that lets ideas breathe instead of rushing topic to topic.",
        "I'm drawn to exchanges where humor carries warmth, not avoidance.",
        "I like when someone shares what they're weighing—not only polished conclusions.",
        "I feel trust emerging when stories include vulnerability, not only highlights.",
        "I'm interested in how someone sees relationships, not only hobbies.",
        "I relax when we can speak plainly about needs without performing cool detachment.",
        "I'm motivated when dialogue explores boundaries and comfort openly.",
        "I appreciate when someone asks how I'm processing—not only how my day went.",
        "I feel seen when conversations acknowledge mixed feelings, not only certainty.",
        "I'm aligned when we discuss what emotional safety looks like for each of us.",
        "I prefer pacing that allows curiosity rather than racing through checkpoints.",
    ]
    b = [
        "Surface-level chatter alone rarely helps me decide if we're a fit.",
        "Light banter is enjoyable, yet depth is what signals compatibility to me.",
        "Skimming topics tends to leave me unsure about emotional alignment.",
        "Staying generic makes it harder for me to sense authenticity.",
        "Without substance, I struggle to picture how we'd navigate conflict kindly.",
        "Cheerful fluff is fine briefly, but meaning anchors my interest.",
        "If everything stays playful, I wonder whether we can discuss hard topics calmly.",
        "I don't need intensity constantly—just enough sincerity to feel grounded.",
        "I'd rather pause than pretend we're connecting when topics stay shallow.",
        "Polished answers interest me less than honest, imperfect reflections.",
        "I'm wary when dates avoid anything personal beyond hobbies.",
        "I lose momentum if we're only swapping headlines without context.",
        "I'm hoping for dialogue that explores priorities, not only preferences.",
        "I notice discomfort when sensitive themes never surface naturally.",
        "I'm hoping we can name feelings without treating them as drama.",
        "I prefer mutual curiosity over performing breeziness for hours.",
        "I feel stalled when questions never invite reflection.",
        "I'm hoping depth feels mutual—not like I'm interviewing alone.",
        "I'm cautious when charm replaces disclosure entirely.",
        "I lean toward partners who can articulate what they're feeling roughly.",
        "I notice alignment when we can disagree without shutting down warmth.",
        "I'm reassured when someone shares perspective, not only consensus.",
        "I appreciate nuance more than perfectly curated answers.",
        "I'm hoping conversations sometimes slow down on purpose.",
        "I'm drawn to emotional literacy—not constant seriousness, but sincerity.",
    ]
    out = []
    for i in range(100):
        out.append(f"{a[i % len(a)]} {b[i // len(a) % len(b)]}")
    return out


def grid_100(a25: list[str], b25: list[str]) -> list[str]:
    """100 unique pairwise combos for indices 0..99 (25x25 grid)."""
    assert len(a25) == 25 and len(b25) == 25
    return [f"{a25[i % 25]} {b25[(i // 25) % 25]}" for i in range(100)]


def social_energy_lines() -> list[str]:
    a = [
        "I often bring upbeat energy to dates when I'm comfortable.",
        "Playful teasing can feel connecting when trust is forming.",
        "I enjoy lively back-and-forth when it still feels respectful.",
        "I like social warmth that feels inviting rather than performative.",
        "I'm animated when conversation flows without needing perfect restraint.",
        "I appreciate spontaneous laughter during getting-to-know-you moments.",
        "I sometimes match higher energy when it helps someone relax.",
        "I enjoy dates that feel socially alive without turning chaotic.",
        "I like charisma that feels grounded—not loud for its own sake.",
        "I'm comfortable keeping pace when excitement stays mutual.",
        "I enjoy flirtation that feels playful rather than pressured.",
        "I feel engaged when banter leaves space for sincerity too.",
        "I'm drawn to people who can lighten tension without dismissing feelings.",
        "I like energetic chemistry when it doesn't dominate every silence.",
        "I appreciate enthusiasm that reads as interest, not auditioning.",
        "I often mirror relaxed confidence when the vibe feels mutual.",
        "I enjoy meeting someone's friends when timing feels natural.",
        "I like group hangouts once we've established a baseline one-on-one rhythm.",
        "I'm comfortable at upbeat venues when conversation can still happen.",
        "I warm up when someone's energy feels welcoming, not competitive.",
        "I enjoy vivid storytelling when it invites dialogue rather than monologue.",
        "I'm responsive when someone initiates plans with clear enthusiasm.",
        "I like texting energy that feels steady—not constant ping-pong.",
        "I'm drawn to social confidence paired with emotional attentiveness.",
        "I enjoy novelty when it doesn't erase calm moments entirely.",
    ]
    b = [
        "Nonstop stimulation usually wears me down faster than it thrills me.",
        "I still need pockets of calm even when chemistry feels electric.",
        "Long stretches of high stimulation leave me needing quiet recovery.",
        "I'm sensitive to environments that feel loud or rushed every time.",
        "If energy stays maxed out, I struggle to hear myself think.",
        "I prefer ebbs and flows rather than constant performance.",
        "I can't sustain endless hype without feeling depleted.",
        "I appreciate mutual pacing rather than one person steering intensity.",
        "I sometimes tap out when interactions feel like a spotlight marathon.",
        "I'm cautious when excitement masks avoidance of deeper topics.",
        "I value downtime after busy social stretches.",
        "I notice burnout when plans ignore restoration entirely.",
        "I prefer partners who read fatigue without taking it personally.",
        "I'm happier when social plans leave breathing room.",
        "I recharge alone sometimes—even when I'm genuinely interested.",
        "I notice friction when my lower-energy nights are misread as disinterest.",
        "I appreciate sensitivity to overstimulation without guilt trips.",
        "I'm steadier when chemistry includes calm companionship too.",
        "I prefer signals that distinguish excitement from pressure.",
        "I feel safest when someone checks in on comfort, not only vibe.",
        "I enjoy lively moments most when they're chosen—not constant.",
        "I'm attentive to whether enthusiasm respects boundaries.",
        "I hope playful energy never overrides consent or cues.",
        "I prefer mutual initiation rather than one-sided chasing.",
        "I'm grounded when warmth feels sustainable week to week.",
    ]
    return grid_100(a, b)


def spontaneity_lines() -> list[str]:
    a = [
        "I enjoy unexpected plans when they still feel considerate.",
        "Impromptu outings can feel romantic when logistics aren't reckless.",
        "I like flexibility that signals curiosity—not chaos.",
        "I'm open to changing plans when communication stays clear.",
        "Last-minute ideas appeal when they respect my bandwidth.",
        "I appreciate spontaneity paired with basic reliability.",
        "I enjoy surprises that align with boundaries we've discussed.",
        "I'm drawn to playful deviations from routine—within reason.",
        "I like partners who can pivot plans without guilt trips.",
        "Weekend shifts feel energizing when they're mutual.",
        "I'm intrigued when someone suggests small adventures on ordinary days.",
        "I enjoy novelty that feels collaborative, not dominating.",
        "I like keeping some openness in the calendar.",
        "I'm refreshed when dates aren't identical scripts each time.",
        "I'm responsive to invitations that feel inviting, not ambushing.",
        "I enjoy improvising once basic trust exists.",
        "I'm animated when plans leave room for wandering conversation.",
        "I appreciate playful risk-taking that still feels respectful.",
        "I like exploring new neighborhoods together casually.",
        "I'm drawn to low-stakes spontaneity early on.",
        "I'm excited when someone proposes a twist without pressure.",
        "I enjoy fluid evenings that don't require rigid itineraries.",
        "I'm comfortable changing venues if mood shifts naturally.",
        "I value spontaneity that doesn't dismiss preparation entirely.",
        "I'm curious about micro-surprises—thoughtful, not extreme.",
    ]
    b = [
        "I still prefer emotional attraction to deepen steadily rather than spike overnight.",
        "Quick intensity can feel thrilling yet unsettling without consistency beside it.",
        "I'm cautious when chemistry races ahead of trust-building.",
        "I like pacing that lets affection accumulate naturally.",
        "Slow-burn connection tends to feel steadier in my body.",
        "I'm wary when urgency replaces mutual calibration.",
        "I appreciate gradual revelation rather than instant merger vibes.",
        "I'm soothed when progression respects ambiguity.",
        "I'm attentive to whether momentum matches mutual readiness.",
        "I prefer clarity over whirlwind confusion—even when sparks exist.",
        "I'm grounded when labels and pacing aren't rushed by adrenaline.",
        "I notice comfort when intensity rises with reciprocity, not pressure.",
        "I'm attracted to patience alongside passion.",
        "I value simmering chemistry as much as flashy sparks.",
        "I'm steadier when novelty doesn't erase consistency.",
        "I appreciate partners who don't interpret slowness as rejection.",
        "I'm hoping momentum reflects mutual curiosity—not persuasion.",
        "I'm reassured when attraction includes calm intimacy too.",
        "I prefer unfolding stories rather than instant fairy tales.",
        "I'm careful when spontaneity signals avoidance of steadiness.",
        "I'm aligned when excitement doesn't shortcut boundaries.",
        "I enjoy sparks most when safety isn't sacrificed.",
        "I'm nourished when pacing honors nervous systems on both sides.",
        "I prefer sustainable heat over unsustainable highs.",
        "I'm hoping spontaneity complements—not replaces—intention.",
    ]
    return grid_100(a, b)


def stability_lines() -> list[str]:
    a = [
        "I feel safest when plans and follow-through generally align.",
        "Consistency helps me relax into vulnerability.",
        "Predictable kindness matters as much as peaks of romance.",
        "I appreciate texts that don't disappear for days without context.",
        "I value showing up—emotionally and practically—more than grand gestures alone.",
        "I'm reassured when words and actions track together over time.",
        "I navigate uncertainty better when baseline reliability exists.",
        "I appreciate clarity about availability—even imperfect clarity.",
        "I'm soothed by steady warmth rather than intermittent intensity.",
        "I prefer transparent scheduling conflicts over vague disappearance.",
        "I'm attentive to whether someone honors simple commitments.",
        "I feel respected when check-ins feel dependable, not sporadic.",
        "I'm grounded when conflict repair happens without ghosting.",
        "I value routines that protect connection—date nights, rituals, small rituals.",
        "I'm hoping reliability includes emotional steadiness too.",
        "I appreciate partners who name limits honestly rather than overpromising.",
        "I'm calmer when jealousy isn't managed through withdrawal.",
        "I prefer repair attempts soonish—not perfection, just effort.",
        "I'm reassured when apologies translate into changed behavior sometimes.",
        "I notice safety when disagreements don't redefine the entire bond overnight.",
        "I'm steadier when affection isn't used as leverage.",
        "I appreciate calm reassurance during stressful weeks.",
        "I'm aligned when both people invest consistently—not perfectly evenly every day.",
        "I value transparency about travel, workload, or bandwidth dips.",
        "I'm nourished when steadiness includes gentle initiation.",
    ]
    b = [
        "Chaos without repair tends to drain my sense of safety.",
        "Mixed signals make it harder for me to stay open-hearted.",
        "I'm cautious when affection swings wildly without explanation.",
        "I'm unsettled by frequent last-minute cancellations without care.",
        "I'm wary when promises accumulate without follow-through.",
        "I struggle when conflict erupts then gets buried silently.",
        "I'm sensitive to stonewalling—even brief patterns.",
        "I'm cautious when jealousy shows up as punishment.",
        "I'm drained when reliability disappears during stress.",
        "I'm watchful when excitement replaces accountability.",
        "I'm hesitant when someone jokes away serious breaches of trust.",
        "I'm cautious when boundaries shift unpredictably.",
        "I'm tired when I'm expected to decode silence.",
        "I'm guarded when affection correlates only with convenience.",
        "I'm cautious when apologies repeat without adjustment.",
        "I'm unsettled when plans constantly dissolve without mutual problem-solving.",
        "I'm careful when intensity returns only after distance.",
        "I'm drained when communication drops after intimacy milestones.",
        "I'm wary when exclusivity talk oscillates without grounding.",
        "I'm drained when competition replaces cooperation during stress.",
        "I'm cautious when reassurance is offered rarely and vaguely.",
        "I'm hesitant when emotional bids are chronically missed.",
        "I'm guarded when affection feels conditional on performance.",
        "I'm tired when reliability is framed as 'not romantic.'",
        "I'm cautious when volatility is romanticized without repair skills.",
    ]
    return grid_100(a, b)


def openness_lines() -> list[str]:
    a = [
        "I'm willing to name feelings roughly—even when wording isn't perfect.",
        "I prefer honesty over pristine image management.",
        "I'm open to discussing attachment fears without shame.",
        "I'm comfortable acknowledging jealousy as information—not verdicts.",
        "I'm responsive when someone shares insecurity kindly.",
        "I'm willing to revisit misunderstandings instead of freezing.",
        "I appreciate direct asks rather than prolonged guessing games.",
        "I'm open to naming boundaries early—even imperfectly.",
        "I'm willing to apologize specifically—not only generally.",
        "I'm curious about emotional bids beneath sarcasm or jokes.",
        "I'm attentive to tone because kindness matters during hard talks.",
        "I'm open to couples-ish pacing conversations when mutual.",
        "I'm willing to disclose dealbreakers without catastrophizing.",
        "I'm comfortable naming needs without demanding instant fixes.",
        "I'm interested in learning someone's love languages loosely—not rigidly.",
        "I'm open to feedback about how my communication lands.",
        "I'm willing to slow down when someone feels flooded.",
        "I'm attentive to consent language around intimacy milestones.",
        "I'm open to discussing mental health logistics pragmatically.",
        "I'm willing to share rough drafts of feelings before they're polished.",
        "I'm responsive when someone asks for clarification kindly.",
        "I'm open to naming disappointment without contempt.",
        "I'm curious how someone defines emotional safety.",
        "I'm willing to discuss money attitudes without shame when timing fits.",
        "I'm open to naming fears about commitment without panic framing.",
    ]
    b = [
        "I pace vulnerability carefully until reciprocity feels plausible.",
        "I'm selective about early disclosures—not secretive, just paced.",
        "I don't narrate every emotion immediately—context matters.",
        "I sometimes need time before putting feelings into words.",
        "I'm cautious about oversharing before trust exists.",
        "I protect tender topics until consistency shows up.",
        "I'm thoughtful about family histories—not hiding, just timing.",
        "I'm gradual about trauma disclosures—not performative.",
        "I'm careful about texting intensely personal details late at night.",
        "I prefer emotional intimacy that earns quiet—not demanded instantly.",
        "I'm wary when vulnerability feels like leverage.",
        "I'm hesitant when curiosity feels interrogative.",
        "I'm protective of privacy early—even while hopeful.",
        "I'm gradual about merging friend groups.",
        "I'm cautious when emotional dumping skips reciprocity.",
        "I'm careful when humor deflects from heartfelt answers repeatedly.",
        "I'm hesitant when someone presses for vulnerability prematurely.",
        "I'm gradual about sharing insecurities without reassurance scaffolding.",
        "I'm cautious when comparisons to exes appear constantly.",
        "I'm selective about conflict escalation—I prefer pauses.",
        "I'm careful when jealousy narratives arrive without listening.",
        "I'm hesitant when vulnerability becomes one-sided labor.",
        "I'm gradual about attachment labels.",
        "I'm cautious when disclosures ignore my boundaries.",
        "I'm protective of calm—I won't force catharsis on command.",
    ]
    return grid_100(a, b)


def pace_lines() -> list[str]:
    a = [
        "When I'm interested, I like thoughtful messages—not necessarily constant, but present.",
        "I'm soothed by predictable rhythms—good morning check-ins sometimes, not surveillance.",
        "I'm attentive to response latency without treating it as a verdict.",
        "I'm hoping texting feels mutual—not always perfectly balanced, but reciprocal.",
        "I appreciate voice notes when nuance matters.",
        "I'm comfortable naming preferred communication cadence.",
        "I'm responsive when plans include realistic texting expectations.",
        "I enjoy depthful threads even if they're asynchronous.",
        "I'm okay with quiet days when trust explains bandwidth shifts.",
        "I'm reassured when silence isn't punitive.",
        "I'm hoping closeness includes initiation from both sides sometimes.",
        "I'm attentive to whether someone listens fully—not only replies quickly.",
        "I'm comfortable pausing chats when either of us is overwhelmed.",
        "I'm hoping conflict doesn't happen only via text forever.",
        "I'm nourished by quality contact over quantity alone.",
        "I'm clear when I need slower texting seasons.",
        "I'm hoping partners interpret offline hours generously.",
        "I'm responsive when someone names texting boundaries kindly.",
        "I'm attentive to whether affection shows between dates—not only during dates.",
        "I'm hoping logistics texts include warmth sometimes.",
        "I'm comfortable with asynchronous romance when trust exists.",
        "I'm attentive to whether praise arrives verbally—not only implied.",
        "I'm hoping mutual curiosity survives mundane weeks.",
        "I'm reassured when someone follows through on 'talk tomorrow.'",
        "I'm hoping communication adapts during travel or crunch weeks.",
    ]
    b = [
        "I rarely feel comfortable texting all day every day—it's not my baseline.",
        "I often need quiet stretches without it meaning withdrawal.",
        "I'm sensitive to rapid-fire texting expectations daily.",
        "I'm cautious when frequent contact feels like monitoring.",
        "I'm drained when missed replies trigger spirals.",
        "I'm slower to merge calendars digitally early on.",
        "I'm gradual about sharing locations or passwords—boundaries matter.",
        "I'm protective of focus time during workweeks.",
        "I'm hesitant when someone interprets slower texting as punishment.",
        "I'm gradual about sleeping over rhythms.",
        "I'm cautious when intimacy pacing speeds up primarily through texting intensity.",
        "I'm slower to voice-call constantly—timing matters.",
        "I'm gradual about meeting daily—especially early.",
        "I'm cautious when someone expects immediate reads always.",
        "I'm protective of sleep—I don't promise midnight marathon chats nightly.",
        "I'm gradual about trip planning together.",
        "I'm cautious when communication doubles during jealousy spikes only.",
        "I'm slower to narrate every hour-by-hour detail.",
        "I'm gradual about shared playlists, accounts, or logistics merges.",
        "I'm hesitant when someone frames boundaries as lack of interest.",
        "I'm cautious when texting substitutes for in-person repair.",
        "I'm gradual about moving from dating apps to other platforms.",
        "I'm slower to integrate weekend ritual assumptions instantly.",
        "I'm cautious when affection correlates with constant connectivity.",
        "I'm gradual about promising perpetual availability.",
    ]
    return grid_100(a, b)


POOLS: dict[str, list[str]] = {
    "depth": depth_lines(),
    "socialEnergy": social_energy_lines(),
    "spontaneity": spontaneity_lines(),
    "stability": stability_lines(),
    "emotionalOpenness": openness_lines(),
    "conversationPace": pace_lines(),
}


def reverse_slots_for_set(s: int) -> set[int]:
    """Indices 0..5 dimension order; mark second question reverse for 3 dims (2-4 reverses per set when counting questions: 3 reverse questions)."""
    return {(s + k) % 6 for k in (0, 2, 4)}


def build_sets() -> list[dict]:
    sets_out: list[dict] = []

    for s in range(50):
        sid = f"frequency_set_{s + 1:03d}"
        rev_dims = reverse_slots_for_set(s)
        qs: list[dict] = []
        qn = 1
        for di, dim in enumerate(DIMS):
            lines = POOLS[dim]
            # Use each pool index exactly once per dimension across 50 sets: pairs (s, 99-s).
            idx1 = s
            idx2 = 99 - s
            t1 = lines[idx1]
            t2 = lines[idx2]
            r1 = False
            r2 = di in rev_dims

            def pack(text: str, rev: bool, n: int) -> dict:
                return {
                    "id": f"{sid}_q{n:02d}",
                    "question": text,
                    "dimension": dim,
                    "reverseScored": rev,
                }

            qs.append(pack(t1, r1, qn))
            qn += 1
            qs.append(pack(t2, r2, qn))
            qn += 1

        sets_out.append(
            {
                "id": sid,
                "type": "frequency",
                "set_number": s + 1,
                "version": "2026_01",
                "active": True,
                "question_count": 12,
                "questions": qs,
            }
        )
    return sets_out


def validate(sets: list[dict]) -> None:
    assert len(sets) == 50
    texts: set[str] = set()
    qids: set[str] = set()
    sids: set[str] = set()
    for st in sets:
        assert st["id"] not in sids
        sids.add(st["id"])
        assert st["type"] == "frequency"
        assert st["active"] is True
        assert st["version"] == "2026_01"
        assert st["set_number"] == int(st["id"].split("_")[-1])
        qs = st["questions"]
        assert len(qs) == 12
        assert st["question_count"] == 12
        rev_ct = sum(1 for q in qs if q["reverseScored"])
        assert 2 <= rev_ct <= 4, rev_ct
        dim_counts: dict[str, int] = {}
        for q in qs:
            assert q["id"] not in qids
            qids.add(q["id"])
            txt = q["question"].strip()
            assert txt not in texts, txt[:80]
            texts.add(txt)
            assert q["dimension"] in DIMS
            dim_counts[q["dimension"]] = dim_counts.get(q["dimension"], 0) + 1
        assert dim_counts == {d: 2 for d in DIMS}


def main() -> None:
    sets = build_sets()
    validate(sets)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"sets": sets}, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(sets)} sets, {len(sets)*12} questions)")


if __name__ == "__main__":
    main()
