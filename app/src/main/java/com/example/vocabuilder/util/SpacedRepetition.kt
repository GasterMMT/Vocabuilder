package com.example.vocabuilder.util

import com.example.vocabuilder.data.entity.Word

object SpacedRepetition {

    fun calculateNextReview(
        word: Word,
        quality: Int
    ): Word {
        val newEaseFactor = (word.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
            .coerceAtLeast(1.3)

        val newConsecutiveCorrect = if (quality >= 3) word.consecutiveCorrect + 1 else 0
        val newRepetitions = word.repetitions + 1

        val newInterval = when {
            quality < 3 -> 1
            newRepetitions == 1 -> 1
            newRepetitions == 2 -> 6
            else -> (word.intervalDays * newEaseFactor).toInt().coerceAtLeast(1)
        }

        val nextReview = System.currentTimeMillis() + (newInterval * 24L * 60 * 60 * 1000)

        return word.copy(
            easeFactor = newEaseFactor,
            intervalDays = newInterval,
            repetitions = newRepetitions,
            nextReviewDate = nextReview,
            consecutiveCorrect = newConsecutiveCorrect,
            totalReviews = word.totalReviews + 1,
            totalCorrect = word.totalCorrect + if (quality >= 3) 1 else 0,
            updatedAt = System.currentTimeMillis()
        )
    }

    fun getQualityFromRating(rating: Int): Int = when (rating) {
        1 -> 0
        2 -> 1
        3 -> 2
        4 -> 3
        5 -> 5
        else -> 0
    }
}
