package com.example.vocabuilder.ui.screens.addword

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vocabuilder.VocabuilderApp
import com.example.vocabuilder.data.entity.Book
import com.example.vocabuilder.data.entity.Word
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class AddWordViewModel : ViewModel() {

    private val repository = VocabuilderApp.instance.repository

    private val _word = MutableStateFlow<Word?>(null)
    val word: StateFlow<Word?> = _word.asStateFlow()

    val books: StateFlow<List<Book>> = repository.getAllBooks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun loadWord(id: Long) {
        viewModelScope.launch { _word.value = repository.getWordById(id) }
    }

    fun saveWord(
        term: String,
        definition: String,
        exampleSentence: String,
        category: String,
        notes: String,
        bookId: Long?,
        existingId: Long?
    ) {
        viewModelScope.launch {
            val existing = existingId?.let { repository.getWordById(it) }
            if (existing != null) {
                repository.updateWord(
                    existing.copy(term = term, definition = definition,
                        exampleSentence = exampleSentence, category = category,
                        notes = notes, bookId = bookId, updatedAt = System.currentTimeMillis())
                )
            } else {
                if (!repository.wordExists(term, bookId)) {
                    repository.insertWord(
                        Word(term = term, definition = definition,
                            exampleSentence = exampleSentence, category = category,
                            notes = notes, bookId = bookId)
                    )
                }
            }
        }
    }

    companion object {
        val Factory: ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = AddWordViewModel() as T
        }
    }
}
