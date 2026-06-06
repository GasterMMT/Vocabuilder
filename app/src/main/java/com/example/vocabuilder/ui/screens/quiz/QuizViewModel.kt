package com.example.vocabuilder.ui.screens.quiz

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vocabuilder.VocabuilderApp
import com.example.vocabuilder.data.entity.Word
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class QuizQuestion(
    val correctWord: Word,
    val options: List<String>,
    val correctIndex: Int
)

data class QuizState(
    val questions: List<QuizQuestion> = emptyList(),
    val currentIndex: Int = 0,
    val score: Int = 0,
    val selectedAnswer: Int? = null,
    val isAnswered: Boolean = false,
    val isLoading: Boolean = true,
    val isComplete: Boolean = false,
    val totalQuestions: Int = 0
)

class QuizViewModel : ViewModel() {

    private val repository = VocabuilderApp.instance.repository

    private val _state = MutableStateFlow(QuizState())
    val state: StateFlow<QuizState> = _state.asStateFlow()

    init {
        generateQuiz()
    }

    private fun generateQuiz() {
        viewModelScope.launch {
            repository.getAllWords().collect { allWords ->
                if (allWords.size < 4) {
                    _state.value = QuizState(isLoading = false, isComplete = true)
                    return@collect
                }

                val shuffled = allWords.shuffled()
                val questionCount = minOf(10, shuffled.size)
                val selectedWords = shuffled.take(questionCount)

                val questions = selectedWords.map { word ->
                    val wrongOptions = allWords
                        .filter { it.id != word.id }
                        .shuffled()
                        .take(3)
                        .map { it.definition }

                    val allOptions = (wrongOptions + word.definition).shuffled()
                    val correctIndex = allOptions.indexOf(word.definition)

                    QuizQuestion(
                        correctWord = word,
                        options = allOptions,
                        correctIndex = correctIndex
                    )
                }

                _state.value = QuizState(
                    questions = questions,
                    totalQuestions = questions.size,
                    isLoading = false
                )
            }
        }
    }

    fun selectAnswer(index: Int) {
        if (_state.value.isAnswered) return

        val current = _state.value
        val isCorrect = index == current.questions[current.currentIndex].correctIndex

        _state.value = current.copy(
            selectedAnswer = index,
            isAnswered = true,
            score = if (isCorrect) current.score + 1 else current.score
        )
    }

    fun nextQuestion() {
        val current = _state.value
        val nextIndex = current.currentIndex + 1

        if (nextIndex >= current.questions.size) {
            _state.value = current.copy(isComplete = true)
            // Record quiz results
            viewModelScope.launch {
                repository.recordStudy(
                    wordsReviewed = current.totalQuestions,
                    wordsCorrect = current.score,
                    quizScore = (current.score.toFloat() / current.totalQuestions * 100).toInt()
                )
            }
        } else {
            _state.value = current.copy(
                currentIndex = nextIndex,
                selectedAnswer = null,
                isAnswered = false
            )
        }
    }

    fun resetQuiz() {
        _state.value = QuizState(isLoading = true)
        generateQuiz()
    }

    companion object {
        val Factory: ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return QuizViewModel() as T
            }
        }
    }
}
