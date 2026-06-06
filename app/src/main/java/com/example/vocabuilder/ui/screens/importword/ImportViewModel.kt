package com.example.vocabuilder.ui.screens.importword

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vocabuilder.VocabuilderApp
import com.example.vocabuilder.data.entity.Book
import com.example.vocabuilder.data.entity.Word
import com.example.vocabuilder.network.LlmParsedWord
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class ImportState(
    val inputText: String = "",
    val targetLanguage: String = "Chinese (中文)",
    val parsedWords: List<LlmParsedWord> = emptyList(),
    val selectedIndices: Set<Int> = emptySet(),
    val isLoading: Boolean = false,
    val isComplete: Boolean = false,
    val error: String? = null,
    val selectedBookId: Long? = null,
    val includeExample: Boolean = true,
    val includeCategory: Boolean = false,
    val includeNotes: Boolean = false
)

class ImportViewModel : ViewModel() {

    private val repository = VocabuilderApp.instance.repository
    private val llmService = VocabuilderApp.instance.llmService
    private val prefs = VocabuilderApp.instance.preferencesManager

    private val _state = MutableStateFlow(ImportState())
    val state: StateFlow<ImportState> = _state.asStateFlow()

    val books: StateFlow<List<Book>> = repository.getAllBooks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        viewModelScope.launch {
            val lang = prefs.targetLanguage.first()
            _state.value = _state.value.copy(targetLanguage = lang)
        }
    }

    fun onInputTextChanged(text: String) { _state.value = _state.value.copy(inputText = text) }
    fun onTargetLanguageChanged(lang: String) {
        _state.value = _state.value.copy(targetLanguage = lang)
        viewModelScope.launch { prefs.setTargetLanguage(lang) }
    }
    fun setIncludeExample(v: Boolean) { _state.value = _state.value.copy(includeExample = v); viewModelScope.launch { prefs.setIncludeExample(v) } }
    fun setIncludeCategory(v: Boolean) { _state.value = _state.value.copy(includeCategory = v); viewModelScope.launch { prefs.setIncludeCategory(v) } }
    fun setIncludeNotes(v: Boolean) { _state.value = _state.value.copy(includeNotes = v); viewModelScope.launch { prefs.setIncludeNotes(v) } }

    fun toggleWordSelection(index: Int) {
        val current = _state.value.selectedIndices.toMutableSet()
        if (current.contains(index)) current.remove(index) else current.add(index)
        _state.value = _state.value.copy(selectedIndices = current)
    }
    fun selectAll() { _state.value = _state.value.copy(selectedIndices = _state.value.parsedWords.indices.toSet()) }
    fun deselectAll() { _state.value = _state.value.copy(selectedIndices = emptySet()) }
    fun setSelectedBook(bookId: Long?) { _state.value = _state.value.copy(selectedBookId = bookId) }

    fun createBook(name: String) {
        viewModelScope.launch {
            val id = repository.insertBook(com.example.vocabuilder.data.entity.Book(name = name))
            _state.value = _state.value.copy(selectedBookId = id)
        }
    }

    fun parseWithLLM() {
        val text = _state.value.inputText.trim()
        if (text.isEmpty()) return
        doParse { llmService.parseTextToWords(text, _state.value.targetLanguage) }
    }

    fun parseWithFileContent(content: String) {
        doParse { llmService.parseFileToWords(content, _state.value.targetLanguage) }
    }

    private fun doParse(parseBlock: suspend () -> Result<List<LlmParsedWord>>) {
        _state.value = _state.value.copy(isLoading = true, error = null, parsedWords = emptyList(), selectedIndices = emptySet(), isComplete = false)
        viewModelScope.launch {
            parseBlock().fold(
                onSuccess = { words -> _state.value = _state.value.copy(isLoading = false, parsedWords = words, selectedIndices = words.indices.toSet()) },
                onFailure = { e -> _state.value = _state.value.copy(isLoading = false, error = e.message ?: "Unknown error") }
            )
        }
    }

    fun importSelectedWords() {
        val s = _state.value
        val selected = s.parsedWords.filterIndexed { i, _ -> s.selectedIndices.contains(i) }
        if (selected.isEmpty()) return
        viewModelScope.launch {
            val words = selected.mapNotNull { p ->
                if (repository.wordExists(p.term, s.selectedBookId)) null
                else Word(term = p.term, definition = p.definition, exampleSentence = p.exampleSentence, category = p.category, notes = p.partOfSpeech, bookId = s.selectedBookId)
            }
            if (words.isNotEmpty()) repository.insertWords(words)
            _state.value = _state.value.copy(isComplete = true)
        }
    }

    fun reset() { _state.value = ImportState(targetLanguage = _state.value.targetLanguage, includeExample = _state.value.includeExample, includeCategory = _state.value.includeCategory, includeNotes = _state.value.includeNotes) }

    companion object {
        val Factory: ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = ImportViewModel() as T
        }
    }
}
