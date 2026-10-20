# Weight trend insights, algorithm 1

Implemented in `lib/services/weight_trend_insights_service.dart`; explanatory output in `lib/models/weight_trend_insight.dart`. This is a conservative description of observed weight, **not a medical plateau diagnosis**. No source below validates the numerical thresholds as clinical cutoffs. They are engineering parameters tested on synthetic cases; independent cohort calibration remains necessary.

## Input and recomputation

Only real `WeightEntry` records enter the calculation. Forecasts and energy-derived weights are excluded by the API. The most recent 28 local calendar days form the window. Actual dates are sorted; multiple readings in a day become one median, with their original records preserved. Repeated identical IDs do not increase coverage. Conflicting IDs, nonfinite/out-of-range values and future dates count as disputed records. Records older than the window are irrelevant. Daily coordinates use civil dates across month and timezone boundaries, not elapsed 24-hour assumptions.

The service is pure and returns a fresh result with `calculatedAt`, state, reason, measured-day count, calendar span, largest gap, rejected-record count, observed weekly percentage slope, end-week change, residual noise and preliminary status. There is no persistent insight cache to become stale after edits, deletion, restoration, goal changes or travel. The provider refreshes recommendation context after mutations and on the existing lifecycle refresh path.

## Classification

1. Fewer than 4 measured days or a span below 7 days: `insufficientData`. Equal weights for two or three days never imply a plateau.
2. Disputed records, latest reading more than 7 days old, a gap above 7 days, or measured-day coverage below 30%: `uncertainTrend`. No values are invented for missing dates.
3. Fit the Theil–Sen median pairwise slope of daily medians, with a median-residual intercept. Normalize by median body weight to express percent/week. Also compare medians in the first and last seven-day blocks and inspect consecutive weekly medians.
4. Median absolute residual above 0.6% of median mass, a robust observed slope above 1.5%/week, or weekly reversals exceeding 0.3% in both directions: `uncertainTrend`. This is a quality gate, not a claim that such a change cannot occur or a safe weight-loss target.
5. Stable candidates require absolute fitted slope no greater than 0.1%/week **and** absolute first/last-week difference no greater than 0.4%. Up/down trends require a slope beyond ±0.1%/week and a matching endpoint direction. Disagreement remains uncertain.
6. Stable candidates with fewer than 14 calendar days or fewer than 8 measured days remain `uncertainTrend`. At 14–20 days, stability is provisional (`stableTrend`), never a plateau.
7. Stronger stability needs a span of at least 21 days, at least 12 measured days, coverage at least 50%, no gap above 4 days, and at least 3 measured days in each of the latest three weekly blocks. This extra coverage requirement reduces the chance of calling sparse endpoints stable.
8. A stable maintenance goal or a stable losing goal at/below the target plus a 0.5% display tolerance yields `maintenance`. The tolerance accommodates scale/display noise, not a clinical healthy-weight range. A target is user-entered, not medical approval. Provider safeguards also stop further-loss suggestions after a target has already been reached during a directional trend.
9. Only a strong stable candidate, a current weight-loss goal, an explicitly adult profile and a confirmed safety context without relevant restrictions can produce `possiblePlateau`. Otherwise descriptive stability remains `stableTrend`. No cause is assigned, and no calorie target changes.

The UI exposes all seven states: `insufficientData`, `decreasingTrend`, `stableTrend`, `increasingTrend`, `possiblePlateau`, `uncertainTrend`, `maintenance`. Every result has observations, an explanation, limitations, an action and calculation date. There are no pseudo-precise confidence percentages.

## Why these engineering thresholds

The stability band deliberately describes a small observed change over weeks. Scaling by body mass avoids treating the same absolute slope identically at 50 and 140 kg. Requiring both slope and separate week medians prevents an endpoint-only classification. Residual and reversal gates address oscillation/outliers; coverage gates address missing data. The 7/14/21-day stages implement progressively stronger observation windows rather than a universal biological onset of plateau.

Sensitivity tests cover 50, 80 and 140 kg; slopes of 0.02%, 0.05%, 0.08%, 0.15%, 0.3% and 0.6%/week; dense and alternate-day data; oscillations, reversals, conflicting IDs and stale records. These verify intended boundaries and refusal behavior. They **do not establish medical accuracy**, detect all outliers or rule out illness. Weekly/monthly weighing may never meet the strict plateau gates; the app does not ask people to weigh more often to qualify.

## Nutrition and recommendation context

The last seven completed days establish only whether entries exist. No day is marked complete from its calories, meal count or macro totals. A low-log flag uses at least three completed days below 75% of their existing goal; it is a conservative prompt to review completeness/adequacy, not a measure of actual energy intake, a diagnosis or proof of deficit. Today is excluded from this flag. Missing food, steps, water or body data remain unknown. Logged macro totals and distinct logged foods describe records only; nutrient deficiency, full diet variety and total energy expenditure are not inferred.

Personalized rotation requires opt-in plus the relevant actual signal. Low logs veto weight-loss articles. Goal maintenance/reached targets veto further-loss articles. Age is read only from an onboarded stored profile; unknown age and minors block weight-loss eligibility. Pregnancy, breastfeeding, eating-disorder risk and medical restrictions have independent flags, plus an explicit context confirmation. Unchecked/malformed flags stay unknown. Nothing is inferred from sex. No advice contains personal calorie/macronutrient targets or intense exercise prescriptions even after confirmation.

Today’s assignment ID remains stable. Its original bilingual rationale and catalog version are saved additively. If a goal or safety condition changes, unsafe weight-loss content is replaced by general support under the same assignment ID. History retains its previous rationale with a dated-context limitation; old completion marks are labelled as belonging to an earlier content version. The 60-day repeat exclusion uses canonical article IDs, including retired aliases. Relevant priority alternates with general rotation, avoiding daily plateau repetition.

## Evidence boundary

[NIDDK](https://www.niddk.nih.gov/health-information/weight-management/adult-overweight-obesity/eating-physical-activity) supports changing energy needs and sustainable habits. [Mayo Clinic](https://www.mayoclinic.org/healthy-lifestyle/weight-loss/in-depth/weight-loss-plateau/art-20044615) discusses plateaus and water/glycogen; its calorie-cut instructions are deliberately not implemented. [NHS weighing guidance](https://www.england.nhs.uk/wp-content/uploads/2021/06/PRN00916-how-to-record-your-weight.pdf) supports comparable conditions and optional regular intervals. [NIDDK planner restrictions](https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner) inform adult/pregnancy/breastfeeding scope. Detailed content-to-source mapping and exclusions are in `DAILY_TIPS_EVIDENCE.md`.
