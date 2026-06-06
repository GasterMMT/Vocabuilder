package com.example.vocabuilder.ui.screens.flashcard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vocabuilder.VocabuilderApp
import com.example.vocabuilder.data.entity.Word
import com.example.vocabuilder.util.SpacedRepetition
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class FlashcardState(
    val words: List<Word> = emptyList(),
    val currentIndex: Int = 0,
    val isFlipped: Boolean = false,
    val isLoading: Boolean = true,
    val isComplete: Boolean = false,
    val reviewedCount: Int = 0,
    val knownCount: Int = 0,
    val totalCount: Int = 0
)

class FlashcardViewModel(
    private val bookId: Long?,
    private val mode: String,
    private val limit: Int?
) : ViewModel() {

    private val repository = VocabuilderApp.instance.repository
    private val sessionStart = System.currentTimeMillis()

    private val _state = MutableStateFlow(FlashcardState())
    val state: StateFlow<FlashcardState> = _state.asStateFlow()

    init { loadWords() }

    private fun loadWords() {
        viewModelScope.launch {
            val words = when (mode) {
                "all" -> repository.getAllWordsOnce()
                else -> repository.getWordsDueForReviewOnceByBook(System.currentTimeMillis(), bookId)
            }
            val filtered = if (bookId != null) words.filter { it.bookId == bookId } else words
            val limited = if (limit != null && limit > 0) filtered.take(limit) else filtered
            val shuffled = limited.shuffled()
            _state.value = _state.value.copy(words = shuffled, totalCount = shuffled.size, isLoading = false, isComplete = shuffled.isEmpty())
        }
    }

    fun flipCard() { _state.value = _state.value.copy(isFlipped = !_state.value.isFlipped) }

    fun rateWord(rating: Int) {
        val current = _state.value
        if (current.words.isEmpty() || current.currentIndex >= current.words.size) return
        val word = current.words[current.currentIndex]
        val quality = SpacedRepetition.getQualityFromRating(rating)
        val updated = SpacedRepetition.calculateNextReview(word, quality)
        viewModelScope.launch {
            repository.updateWord(updated)
            val next = current.currentIndex + 1
            val isDone = next >= current.words.size
            val elapsed = ((System.currentTimeMillis() - sessionStart) / 60000).toInt()
            _state.value = current.copy(
                currentIndex = next, isFlipped = false, isComplete = isDone,
                reviewedCount = current.reviewedCount + 1, knownCount = current.knownCount + if (rating >= 4) 1 else 0
            )
            if (isDone) {
                repository.recordStudy(
                    wordsReviewed = current.reviewedCount + 1,
                    wordsCorrect = current.knownCount + if (rating >= 4) 1 else 0,
                    studyTimeMinutes = elapsed.coerceAtLeast(1)
                )
            }
        }
    }

    fun resetAndReload() { _state.value = FlashcardState(isLoading = true); loadWords() }
    fun skipWord() {
        val c = _state.value
        if (c.words.isEmpty() || c.currentIndex >= c.words.size) return
        val next = c.currentIndex + 1
        _state.value = c.copy(currentIndex = next, isFlipped = false, isComplete = next >= c.words.size)
    }

    companion object {
        fun factory(bookId: Long?, mode: String, limit: Int?): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = FlashcardViewModel(bookId, mode, limit) as T
        }
    }
}
