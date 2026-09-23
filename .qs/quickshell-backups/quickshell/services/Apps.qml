// App index service: entities come from the XDG desktop-entry database.
// Searching uses a fuzzy subsequence scorer (fzf-style: order-preserving
// character matching weighted toward word boundaries and prefix matches)
// and results are ranked best-first.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: apps

  readonly property var all: DesktopEntries.applications.values
  readonly property var allSorted: all.slice().sort((a, b) => a.name.localeCompare(b.name))

  function query(text) {
    const q = String(text || "").trim()
    if (q === "") return allSorted
    const lq = q.toLowerCase()
    const scored = []
    for (const entry of all) {
      const s = fuzzyEntry(entry, lq)
      if (s >= 0) scored.push({ entry, score: s })
    }
    scored.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score
      return a.entry.name.localeCompare(b.entry.name)
    })
    return scored.map(item => item.entry)
  }

  // Best fuzzy score over the candidate fields of a desktop entry.
  function fuzzyEntry(entry, pattern) {
    let best = -1
    for (const f of [entry.name, entry.genericName, entry.comment]) {
      if (!f) continue
      const s = fuzzyScore(String(f), pattern)
      if (s > best) best = s
    }
    if (entry.keywords) {
      for (const kw of Array.from(entry.keywords)) {
        if (!kw) continue
        const s = fuzzyScore(String(kw), pattern)
        if (s > best) best = s
      }
    }
    return best
  }

  // Order-preserving subsequence match with scoring, fzf-style.
  // Returns a non-negative score, or -1 if `pattern` is not a subsequence
  // of `hay`. Substring/prefix matches always outrank scattered ones.
  function fuzzyScore(hay, pattern) {
    const lh = hay.toLowerCase()
    const lp = pattern.toLowerCase()
    if (lp === "") return 1

    // Fast path: contiguous substring match wins big.
    const idx = lh.indexOf(lp)
    if (idx >= 0) {
      return 10000 - idx + countBoundaries(hay, idx, idx + lp.length) * 40
    }

    // Slow path: DP over the haystack; dp[j] = best score up to pattern
    // position j. Infeasible states stay -1, so failures return -1.
    const dp = new Array(lp.length + 1).fill(-1)
    dp[0] = 0
    for (let i = 0; i < lh.length; i++) {
      for (let j = lp.length; j >= 1; j--) {
        if (dp[j - 1] < 0) continue
        if (lh[i] !== lp[j - 1]) continue
        const gain = scoreGain(hay, i, j, lp.length)
        const cand = dp[j - 1] + gain
        if (cand > dp[j]) dp[j] = cand
      }
    }
    return dp[lp.length]
  }

  // Gain for matching pattern position `j` at haystack index `i`.
  // Word boundaries (start, separators) and the final pattern char pay more.
  function scoreGain(hay, i, j, total) {
    let g = 1
    if (i === 0) g += 6
    else {
      const prev = hay[i - 1]
      if (prev === " " || prev === "-" || prev === "_" || prev === ".")
        g += 6
    }
    if (j === total) g += 2
    return g
  }

  // How many word boundaries a substring run touches (bonus in fast path).
  function countBoundaries(hay, start, end) {
    let count = 0
    for (let i = start; i < end; i++) {
      if (i === 0) { count++; continue }
      const prev = hay[i - 1]
      if (prev === " " || prev === "-" || prev === "_" || prev === ".") count++
    }
    return count
  }

  function launch(entry) {
    if (entry && typeof entry.execute === "function") entry.execute()
  }
}