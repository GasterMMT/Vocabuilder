package com.example.vocabuilder.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "words")
data class Word(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val term: String,
    val definition: String,
    val exampleSentence: String = "",
    val category: String = "",
    val notes: String = "",
    val bookId: Long? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val easeFactor: Double = 2.5,
    val intervalDays: Int = 0,
    val repetitions: Int = 0,
    val nextReviewDate: Long = System.currentTimeMillis(),
    val consecutiveCorrect: Int = 0,
    val totalReviews: Int = 0,
    val totalCorrect: Int = 0
)
