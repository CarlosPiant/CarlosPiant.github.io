---
title: "Extreme Values vs Outliers: What's the Difference?"
date: 2025-12-03
categories: [tutorials, codes]
---

# 1. Introduction: not every weird data point is a villain

In almost every dataset, there's *that* observation:

- The patient who is 110 years old,
- The hospital stay that cost ten times more than the others,
- The BMI of 3 or 300,
- The length of stay of 0 days (...somehow).

Our first instinct is often: **"Outlier! Get rid of it!"**  
But not every unusual data point is a mistake. Some are:

- Real but **rare** (e.g., a genuinely very expensive ICU stay),
- Real but **interesting** (e.g., a high-risk subgroup),
- Or yes, **just wrong** (coding errors, unit mix-ups, data entry typos).

Spoiler: "Delete it because it looks ugly" is not the recommended strategy.

---

# 2. Extreme values: rare but (sometimes) perfectly legitimate

## 2.1. What is an extreme value?

An **extreme value** is a data point that lies in the **tails of the distribution**:
it's unusually high or unusually low compared to most of the observations.

Examples:

- A patient with **very high costs** because of a long ICU stay,
- A **very young** or **very old** patient in a predominantly middle-aged cohort,
- An unusually **high dosage** or **long treatment duration** in a clinical dataset.

Key idea:

- Extreme values are **uncommon**, but they may still be **valid** and **expected**
  given the underlying population and process.

We can often spot extreme values using:

- Histograms,
- Boxplots (points beyond the "whiskers"),
- Z-scores (values several standard deviations from the mean),
- Quantiles (e.g., below the 1st percentile or above the 99th).

## 2.2. When are extreme values *not* a problem?

Extreme values are not automatically "bad." They might:

- Reflect real heterogeneity in the population,
- Be clinically meaningful (e.g., very severe disease),
- Be economically important (e.g., rare catastrophic costs that drive policy).

If your model or question cares about **extreme risk** or **tail behavior**,
then extreme values may be exactly what you *need* to study.

---

# 3. Outliers: when the data point doesn't "fit" the story

## 3.1. What is an outlier?

An **outlier** is a data point that is **unusually inconsistent with the rest of the data**
or with the assumed model. It "doesn't fit" in some important sense.

Outliers can be:

- **Data errors**: wrong units, mis-typed values (e.g., age = 999),
- **Measurement issues**: faulty devices, recording problems,
- **Model outliers**: observations that don't follow the pattern of the model,
  even if they are numerically not extremely large/small.

So:

- An outlier may be extreme (far in the tail) **or not**.
- Something can be an outlier because it violates the pattern, not just the scale.

## 3.2. How do we detect outliers?

There's no single "official" definition, but common approaches include:

- **Visual**:
  - Points far from others on scatterplots,
  - Unusual patterns on residual plots in regression.
- **Statistical rules of thumb**:
  - Values beyond 1.5 × IQR from the quartiles (boxplot rule),
  - Z-scores above a certain threshold (e.g., |z| > 3),
  - Large residuals or high leverage in regression models.
- **Contextual checks**:
  - Age < 0 or > 130,
  - Negative costs,
  - Impossible lab values.

Outlier detection is partly about **statistics**, but also heavily about
**subject-matter knowledge**.

---

# 4. Extreme value vs outlier: same thing? not quite.

It's tempting to treat "extreme value" and "outlier" as synonyms, but they're
not exactly the same.

## 4.1. Conceptual difference

- **Extreme value**:
  - A point that lies far in the tail of the **distribution**.
  - It might be rare but still consistent with the process generating the data.
  - Example: A very high but plausible ICU cost in a dataset of hospital costs.

- **Outlier**:
  - A point that is **inconsistent** with the rest of the data or the assumed model.
  - It might be due to error, or it might represent a different process or population.
  - Example: A negative length of stay, or a cost value that looks like the
    result of a coding error (e.g., missing decimal).

So:

- **Every outlier is "weird", but not every extreme value is an outlier.**
- Some extreme values are **expected rare events**; removing them can bias your analysis.
- Some outliers may not be numerically extreme (for example, a point with
  weird covariate combinations that breaks the model).

## 4.2. Quick thought experiment

Imagine hospital costs in a sample:

- Most are between \$1,000 and \$20,000.
- One cost is \$95,000 from a long ICU stay with multiple complications.

If this \$95,000 is real and documented, it's likely an **extreme value** but
not an "outlier" in the sense of being an error. In fact, it might be very
important for evaluating financial risk and policy.

On the other hand:

- If you see a cost of \$9,999,999 that came from a mis-typed date field,
  that's an **outlier** (data error) that you should probably fix or exclude.

---

# 5. What should we *do* with these points?

## 5.1. Don't delete first, ask questions later

Good practice:

1. **Investigate**:
   - Check data entry,
   - Verify units (kg vs g, days vs hours),
   - Look for documentation or clinical notes if available.

2. **Consider the context**:
   - Is this value plausible given the clinical/health system context?
   - Would removing it change important conclusions?

3. **Document decisions**:
   - If you recode, truncate, or exclude values, say **why** and **how**.

## 5.2. Strategies for handling extreme values and outliers

Depending on the situation, you might:

- **Keep them** as is (especially if they're real and relevant),
- **Winsorize** or truncate (cap values at certain percentiles),
- **Transform** variables (e.g., log-transform costs),
- Use **robust methods** less sensitive to extremes (e.g., robust regression),
- **Model tails explicitly** in specialized contexts (e.g., extreme value theory).

The key is to match your approach to:

- Your **research question**,
- The **data quality**, and
- The **impact** these values have on your inferences.

---

# 6. Why this matters in HEOR and health policy

In HEOR and health policy, extreme values and outliers are not just technical
curiosities-they can change decisions.

## 6.1. Catastrophic costs and resource use

A small number of patients often account for a large share of:

- Total healthcare costs,
- ICU bed days,
- Emergency department visits.

These are **extreme values** that may be:

- Central to understanding financial risk,
- Crucial for planning capacity,
- Important for designing interventions (e.g., targeting high-cost patients).

Removing them because they "look weird" can severely **underestimate** the
economic burden and mislead policy.

## 6.2. Quality and safety signals

Some outliers might:

- Indicate **data problems**, which can bias analyses,
- Signal **safety concerns** or unusual care patterns,
- Reflect **subgroups** that are systematically different (e.g., underserved populations).

If you always ignore or delete them, you might miss:

- Disparities in care,
- Problems in data systems,
- Important lessons for health system performance.

## 6.3. Impact on model-based evaluations

Decision models can be sensitive to:

- A few very high-cost or high-risk observations,
- The way you handle extreme inputs (e.g., extreme utilities, rare events).

Choices about trimming, transforming, or modeling extreme values can:

- Influence ICERs, net benefit, and uncertainty,
- Affect whether an intervention appears "cost-effective" or not,
- Shape policy recommendations.

Being explicit about how you treat extreme values and outliers is part of
**transparent and credible** HEOR.

---

# 7. Further reading

For a deeper dive on outliers, extreme values, and robust analysis, you might
explore:

1. **Barnett & Lewis - _Outliers in Statistical Data_**  
   A classic reference on definitions, detection methods, and theory.

2. **Rousseeuw & Leroy - _Robust Regression and Outlier Detection_**  
   Focuses on methods that remain stable in the presence of outliers.

3. **W. N. Venables & B. D. Ripley - _Modern Applied Statistics with S_**  
   Includes practical discussions on diagnostics and dealing with unusual data.

4. **Tukey - _Exploratory Data Analysis_**  
   A foundational text emphasizing plots, summaries, and the importance of
   understanding your data before rushing into models.

Use these when you're ready to move from "that point looks weird" to
a more systematic strategy for diagnosing and handling unusual data.
