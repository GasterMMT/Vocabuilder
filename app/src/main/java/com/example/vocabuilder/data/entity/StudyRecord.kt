package com.example.vocabuilder.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "study_records")
data class StudyRecord(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val date: String,
    val wordsReviewed: Int = 0,
    val wordsLearned: Int = 0,
    val wordsCorrect: Int = 0,
    val quizScore: Int = 0,
    val studyTimeMinutes: Int = 0
)
