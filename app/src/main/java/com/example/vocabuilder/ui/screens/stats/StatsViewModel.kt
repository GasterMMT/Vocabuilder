package com.example.vocabuilder.ui.screens.stats

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vocabuilder.VocabuilderApp
import com.example.vocabuilder.data.entity.StudyRecord
import com.example.vocabuilder.data.entity.Word
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class StatsState(
    val totalWords: Int = 0,
    val learnedWords: Int = 0,
    val totalReviewed: Int = 0,
    val totalCorrect: Int = 0,
    val totalStudyTime: Int = 0,
    val weeklyRecords: List<StudyRecord> = emptyList()
)

class StatsViewModel : ViewModel() {

    private val repository = VocabuilderApp.instance.repository
    private val db = VocabuilderApp.instance.database

    private val _words = MutableStateFlow<List<Word>>(emptyList())

    init {
        viewModelScope.launch {
            repository.getAllWords().collect { _words.value = it }
        }
    }

    val state: StateFlow<StatsState> = combine(
        _words,
        repository.getLast7DaysRecords()
    ) { words, records ->
        val learned = words.count { it.consecutiveCorrect >= 3 }
        val reviewed = words.sumOf { it.totalReviews }
        val correct = words.sumOf { it.totalCorrect }
        val time = records.sumOf { it.studyTimeMinutes }
        StatsState(
            totalWords = words.size,
            learnedWords = learned,
            totalReviewed = reviewed,
            totalCorrect = correct,
            totalStudyTime = time,
            weeklyRecords = records
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), StatsState())

    fun clearRecords() {
        viewModelScope.launch {
            val records = repository.getLast7DaysRecords().first()
            records.forEach { repository.deleteStudyRecord(it) }
            val words = _words.value
            words.forEach { word ->
                repository.updateWord(word.copy(
                    easeFactor = 2.5, intervalDays = 0, repetitions = 0,
                    nextReviewDate = System.currentTimeMillis(),
                    consecutiveCorrect = 0, totalReviews = 0, totalCorrect = 0
                ))
            }
        }
    }

    companion object {
        val Factory: ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = StatsViewModel() as T
        }
    }
}
