---
title: "Extreme Values vs Outliers: What's the Difference?"
date: 2025-12-03
categories: [tutorials, codes]
tags: [Data Science]
summary: "In almost every dataset, there's that observation:"
---
<section id="introduction-not-every-weird-data-point-is-a-villain" class="level1">
<h1>1. Introduction: not every weird data point is a villain</h1>
<p>In almost every dataset, there's <em>that</em> observation:</p>
<ul>
<li>The patient who is 110 years old,</li>
<li>The hospital stay that cost ten times more than the others,</li>
<li>The BMI of 3 or 300,</li>
<li>The length of stay of 0 days (...somehow).</li>
</ul>
<p>Our first instinct is often: <strong>"Outlier! Get rid of it!"</strong><br>
But not every unusual data point is a mistake. Some are:</p>
<ul>
<li>Real but <strong>rare</strong> (e.g., a genuinely very expensive ICU stay),</li>
<li>Real but <strong>interesting</strong> (e.g., a high-risk subgroup),</li>
<li>Or yes, <strong>just wrong</strong> (coding errors, unit mix-ups, data entry typos).</li>
</ul>
<p>Spoiler: "Delete it because it looks ugly" is not the recommended strategy.</p>
<hr>
</section>
<section id="extreme-values-rare-but-sometimes-perfectly-legitimate" class="level1">
<h1>2. Extreme values: rare but (sometimes) perfectly legitimate</h1>
<section id="what-is-an-extreme-value" class="level2">
<h2 class="anchored" data-anchor-id="what-is-an-extreme-value">2.1. What is an extreme value?</h2>
<p>An <strong>extreme value</strong> is a data point that lies in the <strong>tails of the distribution</strong>: it's unusually high or unusually low compared to most of the observations.</p>
<p>Examples:</p>
<ul>
<li>A patient with <strong>very high costs</strong> because of a long ICU stay,</li>
<li>A <strong>very young</strong> or <strong>very old</strong> patient in a predominantly middle-aged cohort,</li>
<li>An unusually <strong>high dosage</strong> or <strong>long treatment duration</strong> in a clinical dataset.</li>
</ul>
<p>Key idea:</p>
<ul>
<li>Extreme values are <strong>uncommon</strong>, but they may still be <strong>valid</strong> and <strong>expected</strong> given the underlying population and process.</li>
</ul>
<p>We can often spot extreme values using:</p>
<ul>
<li>Histograms,</li>
<li>Boxplots (points beyond the "whiskers"),</li>
<li>Z-scores (values several standard deviations from the mean),</li>
<li>Quantiles (e.g., below the 1st percentile or above the 99th).</li>
</ul>
</section>
<section id="when-are-extreme-values-not-a-problem" class="level2">
<h2 class="anchored" data-anchor-id="when-are-extreme-values-not-a-problem">2.2. When are extreme values <em>not</em> a problem?</h2>
<p>Extreme values are not automatically "bad." They might:</p>
<ul>
<li>Reflect real heterogeneity in the population,</li>
<li>Be clinically meaningful (e.g., very severe disease),</li>
<li>Be economically important (e.g., rare catastrophic costs that drive policy).</li>
</ul>
<p>If your model or question cares about <strong>extreme risk</strong> or <strong>tail behavior</strong>, then extreme values may be exactly what you <em>need</em> to study.</p>
<hr>
</section>
</section>
<section id="outliers-when-the-data-point-doesnt-fit-the-story" class="level1">
<h1>3. Outliers: when the data point doesn't "fit" the story</h1>
<section id="what-is-an-outlier" class="level2">
<h2 class="anchored" data-anchor-id="what-is-an-outlier">3.1. What is an outlier?</h2>
<p>An <strong>outlier</strong> is a data point that is <strong>unusually inconsistent with the rest of the data</strong> or with the assumed model. It "doesn't fit" in some important sense.</p>
<p>Outliers can be:</p>
<ul>
<li><strong>Data errors</strong>: wrong units, mis-typed values (e.g., age = 999),</li>
<li><strong>Measurement issues</strong>: faulty devices, recording problems,</li>
<li><strong>Model outliers</strong>: observations that don't follow the pattern of the model, even if they are numerically not extremely large/small.</li>
</ul>
<p>So:</p>
<ul>
<li>An outlier may be extreme (far in the tail) <strong>or not</strong>.</li>
<li>Something can be an outlier because it violates the pattern, not just the scale.</li>
</ul>
</section>
<section id="how-do-we-detect-outliers" class="level2">
<h2 class="anchored" data-anchor-id="how-do-we-detect-outliers">3.2. How do we detect outliers?</h2>
<p>There's no single "official" definition, but common approaches include:</p>
<ul>
<li><strong>Visual</strong>:
<ul>
<li>Points far from others on scatterplots,</li>
<li>Unusual patterns on residual plots in regression.</li>
</ul></li>
<li><strong>Statistical rules of thumb</strong>:
<ul>
<li>Values beyond 1.5 × IQR from the quartiles (boxplot rule),</li>
<li>Z-scores above a certain threshold (e.g., |z| &gt; 3),</li>
<li>Large residuals or high leverage in regression models.</li>
</ul></li>
<li><strong>Contextual checks</strong>:
<ul>
<li>Age &lt; 0 or &gt; 130,</li>
<li>Negative costs,</li>
<li>Impossible lab values.</li>
</ul></li>
</ul>
<p>Outlier detection is partly about <strong>statistics</strong>, but also heavily about <strong>subject-matter knowledge</strong>.</p>
<hr>
</section>
</section>
<section id="extreme-value-vs-outlier-same-thing-not-quite." class="level1">
<h1>4. Extreme value vs outlier: same thing? not quite.</h1>
<p>It's tempting to treat "extreme value" and "outlier" as synonyms, but they're not exactly the same.</p>
<section id="conceptual-difference" class="level2">
<h2 class="anchored" data-anchor-id="conceptual-difference">4.1. Conceptual difference</h2>
<ul>
<li><strong>Extreme value</strong>:
<ul>
<li>A point that lies far in the tail of the <strong>distribution</strong>.</li>
<li>It might be rare but still consistent with the process generating the data.</li>
<li>Example: A very high but plausible ICU cost in a dataset of hospital costs.</li>
</ul></li>
<li><strong>Outlier</strong>:
<ul>
<li>A point that is <strong>inconsistent</strong> with the rest of the data or the assumed model.</li>
<li>It might be due to error, or it might represent a different process or population.</li>
<li>Example: A negative length of stay, or a cost value that looks like the result of a coding error (e.g., missing decimal).</li>
</ul></li>
</ul>
<p>So:</p>
<ul>
<li><strong>Every outlier is "weird", but not every extreme value is an outlier.</strong></li>
<li>Some extreme values are <strong>expected rare events</strong>; removing them can bias your analysis.</li>
<li>Some outliers may not be numerically extreme (for example, a point with weird covariate combinations that breaks the model).</li>
</ul>
</section>
<section id="quick-thought-experiment" class="level2">
<h2 class="anchored" data-anchor-id="quick-thought-experiment">4.2. Quick thought experiment</h2>
<p>Imagine hospital costs in a sample:</p>
<ul>
<li>Most are between $1,000 and $20,000.</li>
<li>One cost is $95,000 from a long ICU stay with multiple complications.</li>
</ul>
<p>If this $95,000 is real and documented, it's likely an <strong>extreme value</strong> but not an "outlier" in the sense of being an error. In fact, it might be very important for evaluating financial risk and policy.</p>
<p>On the other hand:</p>
<ul>
<li>If you see a cost of $9,999,999 that came from a mis-typed date field, that's an <strong>outlier</strong> (data error) that you should probably fix or exclude.</li>
</ul>
<hr>
</section>
</section>
<section id="what-should-we-do-with-these-points" class="level1">
<h1>5. What should we <em>do</em> with these points?</h1>
<section id="dont-delete-first-ask-questions-later" class="level2">
<h2 class="anchored" data-anchor-id="dont-delete-first-ask-questions-later">5.1. Don't delete first, ask questions later</h2>
<p>Good practice:</p>
<ol type="1">
<li><strong>Investigate</strong>:
<ul>
<li>Check data entry,</li>
<li>Verify units (kg vs g, days vs hours),</li>
<li>Look for documentation or clinical notes if available.</li>
</ul></li>
<li><strong>Consider the context</strong>:
<ul>
<li>Is this value plausible given the clinical/health system context?</li>
<li>Would removing it change important conclusions?</li>
</ul></li>
<li><strong>Document decisions</strong>:
<ul>
<li>If you recode, truncate, or exclude values, say <strong>why</strong> and <strong>how</strong>.</li>
</ul></li>
</ol>
</section>
<section id="strategies-for-handling-extreme-values-and-outliers" class="level2">
<h2 class="anchored" data-anchor-id="strategies-for-handling-extreme-values-and-outliers">5.2. Strategies for handling extreme values and outliers</h2>
<p>Depending on the situation, you might:</p>
<ul>
<li><strong>Keep them</strong> as is (especially if they're real and relevant),</li>
<li><strong>Winsorize</strong> or truncate (cap values at certain percentiles),</li>
<li><strong>Transform</strong> variables (e.g., log-transform costs),</li>
<li>Use <strong>robust methods</strong> less sensitive to extremes (e.g., robust regression),</li>
<li><strong>Model tails explicitly</strong> in specialized contexts (e.g., extreme value theory).</li>
</ul>
<p>The key is to match your approach to:</p>
<ul>
<li>Your <strong>research question</strong>,</li>
<li>The <strong>data quality</strong>, and</li>
<li>The <strong>impact</strong> these values have on your inferences.</li>
</ul>
<hr>
</section>
</section>
<section id="why-this-matters-in-heor-and-health-policy" class="level1">
<h1>6. Why this matters in HEOR and health policy</h1>
<p>In HEOR and health policy, extreme values and outliers are not just technical curiosities-they can change decisions.</p>
<section id="catastrophic-costs-and-resource-use" class="level2">
<h2 class="anchored" data-anchor-id="catastrophic-costs-and-resource-use">6.1. Catastrophic costs and resource use</h2>
<p>A small number of patients often account for a large share of:</p>
<ul>
<li>Total healthcare costs,</li>
<li>ICU bed days,</li>
<li>Emergency department visits.</li>
</ul>
<p>These are <strong>extreme values</strong> that may be:</p>
<ul>
<li>Central to understanding financial risk,</li>
<li>Crucial for planning capacity,</li>
<li>Important for designing interventions (e.g., targeting high-cost patients).</li>
</ul>
<p>Removing them because they "look weird" can severely <strong>underestimate</strong> the economic burden and mislead policy.</p>
</section>
<section id="quality-and-safety-signals" class="level2">
<h2 class="anchored" data-anchor-id="quality-and-safety-signals">6.2. Quality and safety signals</h2>
<p>Some outliers might:</p>
<ul>
<li>Indicate <strong>data problems</strong>, which can bias analyses,</li>
<li>Signal <strong>safety concerns</strong> or unusual care patterns,</li>
<li>Reflect <strong>subgroups</strong> that are systematically different (e.g., underserved populations).</li>
</ul>
<p>If you always ignore or delete them, you might miss:</p>
<ul>
<li>Disparities in care,</li>
<li>Problems in data systems,</li>
<li>Important lessons for health system performance.</li>
</ul>
</section>
<section id="impact-on-model-based-evaluations" class="level2">
<h2 class="anchored" data-anchor-id="impact-on-model-based-evaluations">6.3. Impact on model-based evaluations</h2>
<p>Decision models can be sensitive to:</p>
<ul>
<li>A few very high-cost or high-risk observations,</li>
<li>The way you handle extreme inputs (e.g., extreme utilities, rare events).</li>
</ul>
<p>Choices about trimming, transforming, or modeling extreme values can:</p>
<ul>
<li>Influence ICERs, net benefit, and uncertainty,</li>
<li>Affect whether an intervention appears "cost-effective" or not,</li>
<li>Shape policy recommendations.</li>
</ul>
<p>Being explicit about how you treat extreme values and outliers is part of <strong>transparent and credible</strong> HEOR.</p>
<hr>
</section>
</section>
<section id="further-reading" class="level1">
<h1>7. Further reading</h1>
<p>For a deeper dive on outliers, extreme values, and robust analysis, you might explore:</p>
<ol type="1">
<li><p><strong>Barnett &amp; Lewis - <em>Outliers in Statistical Data</em></strong><br>
A classic reference on definitions, detection methods, and theory.</p></li>
<li><p><strong>Rousseeuw &amp; Leroy - <em>Robust Regression and Outlier Detection</em></strong><br>
Focuses on methods that remain stable in the presence of outliers.</p></li>
<li><p><strong>W. N. Venables &amp; B. D. Ripley - <em>Modern Applied Statistics with S</em></strong><br>
Includes practical discussions on diagnostics and dealing with unusual data.</p></li>
<li><p><strong>Tukey - <em>Exploratory Data Analysis</em></strong><br>
A foundational text emphasizing plots, summaries, and the importance of understanding your data before rushing into models.</p></li>
</ol>
<p>Use these when you're ready to move from "that point looks weird" to a more systematic strategy for diagnosing and handling unusual data.</p>


<!-- -->

</section>
